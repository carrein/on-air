import 'package:memoka_client/memoka_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../main.dart';
import 'reminder_scheduler_provider.dart';

part 'reminder_provider.g.dart';

/// Provides the Reminder state for a specific note.
/// Returns null when the note has no reminder.
@riverpod
class ReminderNotifier extends _$ReminderNotifier {
  @override
  Future<Reminder?> build(int noteId) async {
    return client.reminder.getReminder(noteId);
  }

  /// Creates a reminder. Returns the reminder on success.
  Future<Reminder> createReminder(
    DateTime scheduledAt, {
    String? recurrenceRule,
    DateTime? recurrenceEndAt,
  }) async {
    final reminder = await client.reminder.createReminder(
      arg,
      scheduledAt,
      recurrenceRule: recurrenceRule,
      recurrenceEndAt: recurrenceEndAt,
    );
    state = AsyncData(reminder);
    ref.read(reminderSchedulerProvider.notifier).schedule(reminder);
    return reminder;
  }

  /// Deletes the reminder.
  Future<void> deleteReminder() async {
    await client.reminder.deleteReminder(arg);
    state = const AsyncData(null);
    ref.read(reminderSchedulerProvider.notifier).cancel(arg);
  }

  /// Updates the scheduled time.
  Future<Reminder> updateReminder(
    DateTime scheduledAt, {
    String? recurrenceRule,
    DateTime? recurrenceEndAt,
  }) async {
    final reminder = await client.reminder.updateReminder(
      arg,
      scheduledAt,
      recurrenceRule: recurrenceRule,
      recurrenceEndAt: recurrenceEndAt,
    );
    state = AsyncData(reminder);
    ref.read(reminderSchedulerProvider.notifier).schedule(reminder);
    return reminder;
  }

  /// Force refresh from server.
  Future<void> refresh() async {
    final reminder = await client.reminder.getReminder(arg);
    state = AsyncData(reminder);
  }

  int get arg => noteId;
}
