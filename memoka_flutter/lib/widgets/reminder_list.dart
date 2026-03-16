import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../providers/channel_reminders_provider.dart';
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
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PhosphorIcon(
                  PhosphorIcons.clock(),
                  size: 48,
                  color: const Color(0xFF00171F).withValues(alpha: 0.3),
                ),
                const SizedBox(height: 8),
                Text(
                  'No reminders',
                  style: TextStyle(
                    color: const Color(0xFF00171F).withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
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
