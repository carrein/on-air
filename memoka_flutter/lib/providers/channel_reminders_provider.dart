import 'package:memoka_client/memoka_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../main.dart';

part 'channel_reminders_provider.g.dart';

/// Provides all reminders for a channel (for MediaPanel Reminders tab).
@riverpod
Future<List<Reminder>> channelReminders(Ref ref, int channelId) async {
  return client.reminder.getReminders(channelId);
}
