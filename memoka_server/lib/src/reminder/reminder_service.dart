import 'dart:async';

import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../shared/constants.dart';

/// Entry in the priority queue — lightweight record without DB session.
typedef _QueueEntry = ({
  int id,
  int noteId,
  int channelId,
  String? noteContent,
  String? recurrenceRule,
  DateTime? recurrenceEndAt,
  DateTime scheduledAt,
});

/// Per-reminder timer scheduler. Replaces the old 60-second batch poll.
///
/// Maintains a sorted queue of unfired reminders. A single [Timer] always
/// points at the soonest entry. When it fires, the entry is processed
/// (broadcast, reschedule/mark-fired) and the timer advances to the next.
///
/// The endpoint must call [onReminderCreated], [onReminderUpdated], and
/// [onReminderDeleted] after every mutation so the queue stays in sync.
class ReminderService {
  static final List<_QueueEntry> _queue = [];
  static Timer? _nextTimer;
  static Serverpod? _pod;

  /// Load all unfired reminders from the DB and schedule the first timer.
  /// Called once from `server.dart` after `pod.start()`.
  static Future<void> init(Serverpod pod) async {
    _pod = pod;
    _queue.clear();
    _nextTimer?.cancel();
    _nextTimer = null;

    final session = await pod.createSession();
    try {
      final rows = await session.db.unsafeQuery(
        'SELECT "id", "noteId", "channelId", "noteContent", '
        '"recurrenceRule", "recurrenceEndAt", "scheduledAt" '
        'FROM "reminders" WHERE "fired" = false '
        'ORDER BY "scheduledAt" ASC',
      );

      for (final row in rows) {
        final cols = row.toColumnMap();
        _queue.add((
          id: cols['id'] as int,
          noteId: cols['noteId'] as int,
          channelId: cols['channelId'] as int,
          noteContent: cols['noteContent'] as String?,
          recurrenceRule: cols['recurrenceRule'] as String?,
          recurrenceEndAt: cols['recurrenceEndAt'] as DateTime?,
          scheduledAt: cols['scheduledAt'] as DateTime,
        ));
      }

      session.log('ReminderService: loaded ${_queue.length} unfired reminders');
    } finally {
      await session.close();
    }

    _scheduleNext();
  }

  /// Cancel the current timer and set a new one for the queue head.
  static void _scheduleNext() {
    _nextTimer?.cancel();
    _nextTimer = null;

    if (_queue.isEmpty || _pod == null) return;

    final first = _queue.first;
    final now = DateTime.now().toUtc();
    final delay = first.scheduledAt.difference(now);

    // If already past due, fire immediately (Duration.zero)
    _nextTimer = Timer(
      delay.isNegative ? Duration.zero : delay,
      () => _fire(first),
    );
  }

  /// Process a fired entry: broadcast, handle one-shot vs recurring, advance.
  static Future<void> _fire(_QueueEntry entry) async {
    final pod = _pod;
    if (pod == null) return;

    // Remove from queue
    _queue.removeWhere((e) => e.noteId == entry.noteId);

    final session = await pod.createSession();
    try {
      // Broadcast reminderDue event
      await ServerConstants.broadcastEvent(
        session,
        ChatEvent(
          type: 'reminderDue',
          noteId: entry.noteId,
          channelId: entry.channelId,
          note: Note(
            channelId: entry.channelId,
            content: entry.noteContent ?? '',
          ),
        ),
      );

      if (entry.recurrenceRule != null) {
        // Recurring: compute next occurrence
        final next = _computeNextOccurrence(
          entry.recurrenceRule!,
          DateTime.now().toUtc(),
          entry.recurrenceEndAt,
        );
        if (next != null) {
          // Reschedule in DB
          final nextIso = next.toUtc().toIso8601String();
          await session.db.unsafeQuery(
            'UPDATE "reminders" SET "scheduledAt" = \'$nextIso\' '
            'WHERE "id" = ${entry.id}',
          );
          // Re-insert into queue
          final newEntry = (
            id: entry.id,
            noteId: entry.noteId,
            channelId: entry.channelId,
            noteContent: entry.noteContent,
            recurrenceRule: entry.recurrenceRule,
            recurrenceEndAt: entry.recurrenceEndAt,
            scheduledAt: next,
          );
          _insertSorted(newEntry);
          session.log(
            'Recurring reminder ${entry.id} rescheduled to $nextIso for note ${entry.noteId}',
          );
        } else {
          // Series complete — delete the row
          await session.db.unsafeQuery(
            'DELETE FROM "reminders" WHERE "id" = ${entry.id}',
          );
          await ServerConstants.broadcastEvent(
            session,
            ChatEvent(
              type: 'reminderDeleted',
              noteId: entry.noteId,
              channelId: entry.channelId,
            ),
          );
          session.log(
            'Recurring reminder ${entry.id} series complete for note ${entry.noteId}',
          );
        }
      } else {
        // One-shot: mark as fired
        await session.db.unsafeQuery(
          'UPDATE "reminders" SET "fired" = true WHERE "id" = ${entry.id}',
        );
        session.log('Reminder ${entry.id} fired for note ${entry.noteId}');
      }
    } catch (e, stackTrace) {
      session.log(
        'Reminder fire failed: $e\n$stackTrace',
        level: LogLevel.error,
      );
    } finally {
      await session.close();
    }

    _scheduleNext();
  }

  // -- Public API for endpoint notifications --

  /// Called after a reminder is created/upserted.
  static void onReminderCreated({
    required int id,
    required int noteId,
    required int channelId,
    required DateTime scheduledAt,
    String? noteContent,
    String? recurrenceRule,
    DateTime? recurrenceEndAt,
  }) {
    // Remove any existing entry for this noteId (upsert case)
    _queue.removeWhere((e) => e.noteId == noteId);

    final entry = (
      id: id,
      noteId: noteId,
      channelId: channelId,
      noteContent: noteContent,
      recurrenceRule: recurrenceRule,
      recurrenceEndAt: recurrenceEndAt,
      scheduledAt: scheduledAt,
    );
    _insertSorted(entry);
    _scheduleNext();
  }

  /// Called after a reminder's scheduledAt is updated.
  static void onReminderUpdated({
    required int noteId,
    required DateTime scheduledAt,
    int? id,
    int? channelId,
    String? noteContent,
    String? recurrenceRule,
    DateTime? recurrenceEndAt,
  }) {
    final existing = _queue.cast<_QueueEntry?>().firstWhere(
      (e) => e!.noteId == noteId,
      orElse: () => null,
    );
    _queue.removeWhere((e) => e.noteId == noteId);

    final entry = (
      id: id ?? existing?.id ?? 0,
      noteId: noteId,
      channelId: channelId ?? existing?.channelId ?? 0,
      noteContent: noteContent ?? existing?.noteContent,
      recurrenceRule: recurrenceRule ?? existing?.recurrenceRule,
      recurrenceEndAt: recurrenceEndAt ?? existing?.recurrenceEndAt,
      scheduledAt: scheduledAt,
    );
    _insertSorted(entry);
    _scheduleNext();
  }

  /// Called after a reminder is deleted.
  static void onReminderDeleted(int noteId) {
    _queue.removeWhere((e) => e.noteId == noteId);
    _scheduleNext();
  }

  // -- Helpers --

  /// Insert entry into the sorted queue (by scheduledAt ascending).
  static void _insertSorted(_QueueEntry entry) {
    var i = 0;
    while (i < _queue.length &&
        _queue[i].scheduledAt.isBefore(entry.scheduledAt)) {
      i++;
    }
    _queue.insert(i, entry);
  }

  /// Computes the next occurrence for a recurring reminder.
  /// Returns null if the series is complete (past endAt).
  /// Skips missed fires — always returns the next future occurrence.
  static DateTime? _computeNextOccurrence(
    String rule,
    DateTime now,
    DateTime? endAt,
  ) {
    final parts = <String, String>{};
    for (final part in rule.split(';')) {
      final kv = part.split('=');
      if (kv.length == 2) parts[kv[0]] = kv[1];
    }

    final freq = parts['FREQ'];
    if (freq == null) return null;

    DateTime candidate = now;

    switch (freq) {
      case 'MINUTELY':
        candidate = now.add(const Duration(minutes: 1));
        break;

      case 'HOURLY':
        candidate = now.add(const Duration(hours: 1));
        break;

      case 'DAILY':
        candidate = DateTime.utc(
          now.year,
          now.month,
          now.day + 1,
          now.hour,
          now.minute,
        );
        break;

      case 'WEEKLY':
        // Advance by 7 days
        candidate = DateTime.utc(
          now.year,
          now.month,
          now.day + 7,
          now.hour,
          now.minute,
        );
        break;

      case 'MONTHLY':
        final byMonthDay = parts['BYMONTHDAY'];
        final dayOfMonth = byMonthDay != null ? int.tryParse(byMonthDay) : null;

        if (dayOfMonth != null) {
          // Try this month first
          var nextMonth = now.month;
          var nextYear = now.year;
          var next = _clampMonthDay(nextYear, nextMonth, dayOfMonth, now);

          if (!next.isAfter(now)) {
            // Move to next month
            nextMonth++;
            if (nextMonth > 12) {
              nextMonth = 1;
              nextYear++;
            }
            next = _clampMonthDay(nextYear, nextMonth, dayOfMonth, now);
          }
          candidate = next;
        } else {
          // Fallback: same day next month
          var nextMonth = now.month + 1;
          var nextYear = now.year;
          if (nextMonth > 12) {
            nextMonth = 1;
            nextYear++;
          }
          candidate = _clampMonthDay(nextYear, nextMonth, now.day, now);
        }
        break;

      default:
        return null;
    }

    if (endAt != null && candidate.isAfter(endAt)) return null;
    return candidate;
  }

  /// Creates a DateTime for [year]/[month]/[day] clamped to the last day
  /// of the month (e.g. day 31 in February -> Feb 28/29).
  /// Preserves hours/minutes from [timeSource].
  static DateTime _clampMonthDay(
    int year,
    int month,
    int day,
    DateTime timeSource,
  ) {
    final lastDay = DateTime.utc(year, month + 1, 0).day;
    final clampedDay = day > lastDay ? lastDay : day;
    return DateTime.utc(
      year,
      month,
      clampedDay,
      timeSource.hour,
      timeSource.minute,
    );
  }
}
