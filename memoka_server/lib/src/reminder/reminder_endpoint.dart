import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../shared/constants.dart';
import 'reminder_service.dart';

/// Endpoint for managing reminders on notes.
class ReminderEndpoint extends Endpoint {
  /// Creates or upserts a reminder for a note.
  Future<Reminder> createReminder(
    Session session,
    int noteId,
    DateTime scheduledAt, {
    String? recurrenceRule,
    DateTime? recurrenceEndAt,
  }) async {
    // Validate note exists
    final noteRows = await session.db.unsafeQuery(
      'SELECT "id", "channelId", "content" FROM "notes" '
      'WHERE "id" = $noteId AND "deletedAt" IS NULL AND "archived" = false',
    );
    if (noteRows.isEmpty) {
      throw Exception('Note not found');
    }

    final cols = noteRows.first.toColumnMap();
    final channelId = cols['channelId'] as int;
    final content = cols['content'] as String?;
    final escapedContent = content != null
        ? "'${ServerConstants.escapeSql(content)}'"
        : 'NULL';
    final scheduledIso = scheduledAt.toUtc().toIso8601String();
    final ruleSql = recurrenceRule != null
        ? "'${ServerConstants.escapeSql(recurrenceRule)}'"
        : 'NULL';
    final endAtSql = recurrenceEndAt != null
        ? "'${recurrenceEndAt.toUtc().toIso8601String()}'"
        : 'NULL';

    // Upsert — replace if exists
    final existing = await session.db.unsafeQuery(
      'SELECT "id" FROM "reminders" WHERE "noteId" = $noteId',
    );

    if (existing.isNotEmpty) {
      await session.db.unsafeQuery(
        'UPDATE "reminders" SET '
        '"scheduledAt" = \'${ServerConstants.escapeSql(scheduledIso)}\', '
        '"noteContent" = $escapedContent, '
        '"fired" = false, '
        '"recurrenceRule" = $ruleSql, '
        '"recurrenceEndAt" = $endAtSql '
        'WHERE "noteId" = $noteId',
      );
    } else {
      await session.db.unsafeQuery(
        'INSERT INTO "reminders" '
        '("noteId", "channelId", "scheduledAt", "noteContent", "recurrenceRule", "recurrenceEndAt") '
        'VALUES ($noteId, $channelId, \'${ServerConstants.escapeSql(scheduledIso)}\', $escapedContent, $ruleSql, $endAtSql)',
      );
    }

    await _incrementGlobalVersion(session);

    // Fetch the created/updated row for its id
    final reminder = await _getReminderByNoteId(session, noteId);

    // Notify the in-memory scheduler
    ReminderService.onReminderCreated(
      id: await _getReminderId(session, noteId),
      noteId: noteId,
      channelId: channelId,
      scheduledAt: scheduledAt.toUtc(),
      noteContent: content,
      recurrenceRule: recurrenceRule,
      recurrenceEndAt: recurrenceEndAt,
    );

    await ServerConstants.broadcastEvent(
      session,
      ChatEvent(
        type: 'reminderCreated',
        noteId: noteId,
        channelId: channelId,
      ),
    );

    return reminder;
  }

  /// Deletes a reminder for a note.
  Future<void> deleteReminder(Session session, int noteId) async {
    final rows = await session.db.unsafeQuery(
      'SELECT "channelId" FROM "reminders" WHERE "noteId" = $noteId',
    );
    if (rows.isEmpty) return;

    final channelId = rows.first.toColumnMap()['channelId'] as int;

    await session.db.unsafeQuery(
      'DELETE FROM "reminders" WHERE "noteId" = $noteId',
    );

    await _incrementGlobalVersion(session);

    // Notify the in-memory scheduler
    ReminderService.onReminderDeleted(noteId);

    await ServerConstants.broadcastEvent(
      session,
      ChatEvent(
        type: 'reminderDeleted',
        noteId: noteId,
        channelId: channelId,
      ),
    );
  }

  /// Returns the reminder for a note, or null if none.
  Future<Reminder?> getReminder(Session session, int noteId) async {
    final rows = await session.db.unsafeQuery(
      'SELECT * FROM "reminders" WHERE "noteId" = $noteId',
    );
    if (rows.isEmpty) return null;
    return _rowToReminder(rows.first.toColumnMap());
  }

  /// Updates the scheduled time for a reminder.
  Future<Reminder> updateReminder(
    Session session,
    int noteId,
    DateTime scheduledAt, {
    String? recurrenceRule,
    DateTime? recurrenceEndAt,
  }) async {
    final scheduledIso = scheduledAt.toUtc().toIso8601String();
    final ruleSql = recurrenceRule != null
        ? "'${ServerConstants.escapeSql(recurrenceRule)}'"
        : 'NULL';
    final endAtSql = recurrenceEndAt != null
        ? "'${recurrenceEndAt.toUtc().toIso8601String()}'"
        : 'NULL';

    final rows = await session.db.unsafeQuery(
      'SELECT "channelId" FROM "reminders" WHERE "noteId" = $noteId',
    );
    if (rows.isEmpty) {
      throw Exception('Reminder not found');
    }
    final channelId = rows.first.toColumnMap()['channelId'] as int;

    await session.db.unsafeQuery(
      'UPDATE "reminders" SET '
      '"scheduledAt" = \'${ServerConstants.escapeSql(scheduledIso)}\', '
      '"fired" = false, '
      '"recurrenceRule" = $ruleSql, '
      '"recurrenceEndAt" = $endAtSql '
      'WHERE "noteId" = $noteId',
    );

    await _incrementGlobalVersion(session);

    // Notify the in-memory scheduler
    ReminderService.onReminderUpdated(
      noteId: noteId,
      scheduledAt: scheduledAt.toUtc(),
      channelId: channelId,
      recurrenceRule: recurrenceRule,
      recurrenceEndAt: recurrenceEndAt,
    );

    await ServerConstants.broadcastEvent(
      session,
      ChatEvent(
        type: 'reminderCreated',
        noteId: noteId,
        channelId: channelId,
      ),
    );

    return _getReminderByNoteId(session, noteId);
  }

  /// Returns all reminders for a channel (for MediaPanel).
  Future<List<Reminder>> getReminders(Session session, int channelId) async {
    final rows = await session.db.unsafeQuery(
      'SELECT * FROM "reminders" WHERE "channelId" = $channelId '
      'ORDER BY "scheduledAt" ASC',
    );
    return rows.map((r) => _rowToReminder(r.toColumnMap())).toList();
  }

  /// Returns all fired but unacknowledged reminders (for reconnect delivery).
  Future<List<Reminder>> getFiredReminders(Session session) async {
    final rows = await session.db.unsafeQuery(
      'SELECT * FROM "reminders" WHERE "fired" = true '
      'ORDER BY "scheduledAt" ASC',
    );
    return rows.map((r) => _rowToReminder(r.toColumnMap())).toList();
  }

  /// Returns all unfired reminders (for client-side timer seeding).
  Future<List<Reminder>> getActiveReminders(Session session) async {
    final rows = await session.db.unsafeQuery(
      'SELECT * FROM "reminders" WHERE "fired" = false '
      'ORDER BY "scheduledAt" ASC',
    );
    return rows.map((r) => _rowToReminder(r.toColumnMap())).toList();
  }

  /// Acknowledges a fired reminder — deletes the row (one-shot only).
  /// Recurring reminders auto-reschedule and never have fired=true.
  Future<void> acknowledgeReminder(Session session, int noteId) async {
    await session.db.unsafeQuery(
      'DELETE FROM "reminders" WHERE "noteId" = $noteId AND "fired" = true '
      'AND "recurrenceRule" IS NULL',
    );
  }

  // -- Helpers --

  Future<Reminder> _getReminderByNoteId(Session session, int noteId) async {
    final rows = await session.db.unsafeQuery(
      'SELECT * FROM "reminders" WHERE "noteId" = $noteId',
    );
    return _rowToReminder(rows.first.toColumnMap());
  }

  Future<int> _getReminderId(Session session, int noteId) async {
    final rows = await session.db.unsafeQuery(
      'SELECT "id" FROM "reminders" WHERE "noteId" = $noteId',
    );
    return rows.first.toColumnMap()['id'] as int;
  }

  static Reminder _rowToReminder(Map<String, dynamic> cols) {
    return Reminder(
      noteId: cols['noteId'] as int,
      channelId: cols['channelId'] as int,
      scheduledAt: cols['scheduledAt'] as DateTime,
      noteContent: cols['noteContent'] as String?,
      fired: cols['fired'] as bool,
      createdAt: cols['createdAt'] as DateTime,
      recurrenceRule: cols['recurrenceRule'] as String?,
      recurrenceEndAt: cols['recurrenceEndAt'] as DateTime?,
    );
  }

  Future<void> _incrementGlobalVersion(Session session) async {
    await session.db.unsafeQuery(
      'UPDATE "sync_state" SET "globalVersion" = "globalVersion" + 1',
    );
  }
}
