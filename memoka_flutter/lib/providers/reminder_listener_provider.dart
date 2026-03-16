import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../main.dart';
import '../services/notification_service.dart';
import 'chat_stream_provider.dart';
import 'channel_reminders_provider.dart';
import 'connection_provider.dart';
import 'reminder_provider.dart';
import 'reminder_scheduler_provider.dart';

part 'reminder_listener_provider.g.dart';

/// Listens to the WebSocket stream for reminder events and fires
/// local notifications + invalidates reminder providers.
///
/// On reconnect, pulls all fired reminders to catch any missed while offline.
/// Deduplicates with client-side scheduler fires via `_firedLocally`.
@Riverpod(keepAlive: true)
void reminderListener(Ref ref) {
  // Listen for reminder-related WebSocket events
  ref.listen(chatStreamProvider, (_, next) {
    next.whenData((event) {
      if (event.type == 'reminderDue' && event.noteId != null) {
        // Check if the client-side scheduler already fired this one
        final scheduler = ref.read(reminderSchedulerProvider.notifier);
        if (scheduler.firedLocally.contains(event.noteId)) {
          // Already handled locally — just clean up the flag
          scheduler.firedLocally.remove(event.noteId);
          return;
        }

        // Invalidate per-note provider so siren icon disappears
        ref.invalidate(reminderProvider(event.noteId!));
        if (event.channelId != null) {
          ref.invalidate(channelRemindersProvider(event.channelId!));
        }

        // Show notification
        final content = event.note?.content ?? '';
        final body = content.isNotEmpty
            ? (content.length > 100
                  ? '${content.substring(0, 100)}...'
                  : content)
            : 'Media note';

        showReminderNotification(
          noteId: event.noteId!,
          channelId: event.channelId ?? 0,
          body: body,
        );

        // Cancel any pending local timer (prevent double-fire)
        scheduler.cancel(event.noteId!);

        // Auto-acknowledge one-shot reminders only
        _acknowledgeIfOneShot(event.noteId!);
      } else if (event.type == 'reminderCreated' && event.noteId != null) {
        ref.invalidate(reminderProvider(event.noteId!));
        if (event.channelId != null) {
          ref.invalidate(channelRemindersProvider(event.channelId!));
        }
        // Fetch the new reminder and schedule it locally
        _fetchAndSchedule(ref, event.noteId!);
      } else if (event.type == 'reminderDeleted' && event.noteId != null) {
        ref.invalidate(reminderProvider(event.noteId!));
        if (event.channelId != null) {
          ref.invalidate(channelRemindersProvider(event.channelId!));
        }
        // Cancel local timer
        ref.read(reminderSchedulerProvider.notifier).cancel(event.noteId!);
      }
    });
  });

  // On reconnect, pull any fired reminders that were missed while offline
  ref.listen(connectionProvider, (prev, next) {
    final wasDisconnected =
        prev == ConnectionState.disconnected ||
        prev == ConnectionState.connecting;
    if (wasDisconnected && next == ConnectionState.connected) {
      _pullFiredReminders(ref);
    }
  });
}

Future<void> _fetchAndSchedule(Ref ref, int noteId) async {
  try {
    final reminder = await client.reminder.getReminder(noteId);
    if (reminder != null && !reminder.fired) {
      ref.read(reminderSchedulerProvider.notifier).schedule(reminder);
    }
  } catch (_) {}
}

Future<void> _acknowledgeIfOneShot(int noteId) async {
  try {
    final current = await client.reminder.getReminder(noteId);
    if (current == null || current.recurrenceRule == null) {
      client.reminder.acknowledgeReminder(noteId);
    }
  } catch (_) {
    // Fallback: try to acknowledge anyway
    client.reminder.acknowledgeReminder(noteId);
  }
}

Future<void> _pullFiredReminders(Ref ref) async {
  try {
    final fired = await client.reminder.getFiredReminders();
    for (final reminder in fired) {
      final body =
          reminder.noteContent != null && reminder.noteContent!.isNotEmpty
          ? (reminder.noteContent!.length > 100
                ? '${reminder.noteContent!.substring(0, 100)}...'
                : reminder.noteContent!)
          : 'Media note';

      showReminderNotification(
        noteId: reminder.noteId,
        channelId: reminder.channelId,
        body: body,
      );

      // Acknowledge after showing
      await client.reminder.acknowledgeReminder(reminder.noteId);
      ref.invalidate(reminderProvider(reminder.noteId));
    }
  } catch (_) {
    // Server may not support reminders yet — ignore
  }
}
