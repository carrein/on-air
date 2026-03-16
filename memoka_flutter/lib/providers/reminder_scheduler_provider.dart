import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:memoka_client/memoka_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../main.dart';
import '../services/notification_service.dart';
import '../services/reminder_timer.dart';
import 'channel_reminders_provider.dart';
import 'reminder_provider.dart';

part 'reminder_scheduler_provider.g.dart';

/// Client-side timer orchestration for precise reminder delivery.
///
/// - **Web**: Uses a Web Worker (`reminder_worker.js`) whose timers are NOT
///   throttled in background tabs.
/// - **Android**: Uses `zonedSchedule` (OS alarm system) which survives app
///   kill, background, and phone reboot.
///
/// Tracks `_firedLocally` to deduplicate with WebSocket backup delivery.
@Riverpod(keepAlive: true)
class ReminderScheduler extends _$ReminderScheduler {
  final Set<int> _firedLocally = {};

  /// Set of noteIds that were fired locally — used by the listener to
  /// deduplicate with server-side WebSocket events.
  Set<int> get firedLocally => _firedLocally;

  @override
  void build() {
    _init();
    ref.onDispose(_dispose);
  }

  Future<void> _init() async {
    if (kIsWeb) {
      initWorker(_onLocalFire);
    }

    try {
      final reminders = await client.reminder.getActiveReminders();
      for (final r in reminders) {
        _scheduleOne(r);
      }
    } catch (_) {
      // Server may not support getActiveReminders yet
    }
  }

  void _dispose() {
    if (kIsWeb) {
      disposeWorker();
    }
  }

  /// Schedule a reminder for local delivery.
  void schedule(Reminder reminder) {
    _firedLocally.remove(reminder.noteId);
    _scheduleOne(reminder);
  }

  /// Cancel a locally scheduled reminder.
  void cancel(int noteId) {
    _firedLocally.remove(noteId);
    if (kIsWeb) {
      cancelWorkerTimer(noteId);
    } else {
      cancelScheduledReminder(noteId);
    }
  }

  void _scheduleOne(Reminder reminder) {
    final now = DateTime.now().toUtc();
    final delay = reminder.scheduledAt.difference(now);

    // Skip past-due reminders — the reconnect pull handles those
    if (delay.isNegative) return;

    if (kIsWeb) {
      scheduleWorkerTimer(reminder.noteId, delay.inMilliseconds);
    } else {
      final body = _buildBody(reminder);
      scheduleReminderNotification(
        noteId: reminder.noteId,
        channelId: reminder.channelId,
        scheduledAt: reminder.scheduledAt,
        body: body,
      );
    }
  }

  void _onLocalFire(int noteId) {
    _firedLocally.add(noteId);
    _fetchAndNotify(noteId);
  }

  Future<void> _fetchAndNotify(int noteId) async {
    try {
      final reminder = await client.reminder.getReminder(noteId);
      final body = reminder != null ? _buildBody(reminder) : 'Reminder';

      showReminderNotification(
        noteId: noteId,
        channelId: reminder?.channelId ?? 0,
        body: body,
      );

      // Acknowledge one-shot only
      if (reminder == null || reminder.recurrenceRule == null) {
        await client.reminder.acknowledgeReminder(noteId);
      }

      // Invalidate UI
      ref.invalidate(reminderProvider(noteId));
      if (reminder?.channelId != null) {
        ref.invalidate(channelRemindersProvider(reminder!.channelId));
      }
    } catch (_) {
      // Best-effort: show generic notification
      showReminderNotification(
        noteId: noteId,
        channelId: 0,
        body: 'Reminder',
      );
    }
  }

  static String _buildBody(Reminder reminder) {
    final content = reminder.noteContent ?? '';
    if (content.isEmpty) return 'Media note';
    return content.length > 100 ? '${content.substring(0, 100)}...' : content;
  }
}
