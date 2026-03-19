import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../providers/channel_reminders_provider.dart';
import 'media_panel_empty_state.dart';
import 'reminder_list_item.dart';

/// List of reminders for the current channel, displayed in the MediaPanel.
class ReminderList extends ConsumerWidget {
  final int channelId;

  const ReminderList({super.key, required this.channelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(channelRemindersProvider(channelId));

    return remindersAsync.when(
      skipLoadingOnRefresh: true,
      data: (reminders) {
        if (reminders.isEmpty) {
          return MediaPanelEmptyState(
            icon: PhosphorIcons.bellSimple(PhosphorIconsStyle.bold),
            message: 'No reminders',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: reminders.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final reminder = reminders[index];
            return ReminderListItem(
              reminder: reminder,
              channelId: channelId,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Failed to load reminders')),
    );
  }
}
