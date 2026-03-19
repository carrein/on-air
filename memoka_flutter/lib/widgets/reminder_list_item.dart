import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memoka_client/memoka_client.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../providers/channel_reminders_provider.dart';
import '../providers/reminder_provider.dart';
import '../utils/reminder_picker.dart';
import '../utils/toast_utils.dart';

/// A single reminder item in the MediaPanel Reminders tab.
class ReminderListItem extends ConsumerWidget {
  final Reminder reminder;
  final int channelId;

  const ReminderListItem({
    super.key,
    required this.reminder,
    required this.channelId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snippet = reminder.noteContent ?? 'Media note';
    final displaySnippet = snippet.length > 80
        ? '${snippet.substring(0, 80)}...'
        : snippet;
    final isPast = reminder.scheduledAt.isBefore(DateTime.now());
    final timeStr = _formatScheduledAt(reminder.scheduledAt);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF6),
        border: Border.all(
          color: const Color(0xFF3450A3).withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displaySnippet,
            style: const TextStyle(fontSize: 13, color: Color(0xFF00171F)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              PhosphorIcon(
                isPast
                    ? PhosphorIcons.siren(PhosphorIconsStyle.fill)
                    : PhosphorIcons.clock(),
                size: 14,
                color: isPast
                    ? const Color(0xFF3450A3)
                    : const Color(0xFF00171F).withValues(alpha: 0.5),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  isPast ? 'Fired $timeStr' : timeStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: isPast
                        ? const Color(0xFF3450A3)
                        : const Color(0xFF00171F).withValues(alpha: 0.5),
                  ),
                ),
              ),
              if (!isPast) ...[
                _ActionButton(
                  icon: PhosphorIcons.pencilSimple(),
                  onTap: () => _onEdit(context, ref),
                ),
                const SizedBox(width: 8),
              ],
              _ActionButton(
                icon: PhosphorIcons.trash(),
                onTap: () => _onCancel(context, ref),
              ),
            ],
          ),
          if (reminder.recurrenceRule != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                PhosphorIcon(
                  PhosphorIcons.arrowsClockwise(),
                  size: 12,
                  color: const Color(0xFF00171F).withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatRecurrence(reminder.recurrenceRule!),
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFF00171F).withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _onEdit(BuildContext context, WidgetRef ref) async {
    final result = await showReminderPicker(
      context,
      initialResult: ReminderPickerResult(
        scheduledAt: reminder.scheduledAt,
        recurrenceRule: reminder.recurrenceRule,
        recurrenceEndAt: reminder.recurrenceEndAt,
      ),
    );
    if (result == null) return;
    try {
      await ref
          .read(reminderProvider(reminder.noteId).notifier)
          .updateReminder(
            result.scheduledAt,
            recurrenceRule: result.recurrenceRule,
            recurrenceEndAt: result.recurrenceEndAt,
          );
      ref.invalidate(channelRemindersProvider(channelId));
      if (context.mounted) {
        ToastUtils.show(context, 'Reminder updated', type: ToastType.success);
      }
    } catch (e) {
      if (context.mounted) {
        ToastUtils.show(context, 'Failed: $e', type: ToastType.error);
      }
    }
  }

  Future<void> _onCancel(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(reminderProvider(reminder.noteId).notifier)
          .deleteReminder();
      ref.invalidate(channelRemindersProvider(channelId));
      if (context.mounted) {
        ToastUtils.show(context, 'Reminder cancelled', type: ToastType.success);
      }
    } catch (e) {
      if (context.mounted) {
        ToastUtils.show(context, 'Failed: $e', type: ToastType.error);
      }
    }
  }

  String _formatScheduledAt(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    final time = '$hh:$mm';

    if (diff.isNegative) {
      return '${local.day}/${local.month} $time';
    }
    if (diff.inMinutes < 60) {
      return 'In ${diff.inMinutes}m ($time)';
    }
    if (diff.inHours < 24) {
      return 'In ${diff.inHours}h ($time)';
    }
    return '${local.day}/${local.month} $time';
  }
}

String _formatRecurrence(String rule) {
  if (rule.startsWith('FREQ=MINUTELY')) return 'Every Minute';
  if (rule.startsWith('FREQ=HOURLY')) return 'Hourly';
  if (rule.startsWith('FREQ=DAILY')) return 'Daily';
  if (rule.startsWith('FREQ=WEEKLY')) {
    final match = RegExp(r'BYDAY=(\w+)').firstMatch(rule);
    if (match != null) {
      const dayNames = {
        'MO': 'Mon',
        'TU': 'Tue',
        'WE': 'Wed',
        'TH': 'Thu',
        'FR': 'Fri',
        'SA': 'Sat',
        'SU': 'Sun',
      };
      final dayName = dayNames[match.group(1)] ?? match.group(1)!;
      return 'Weekly ($dayName)';
    }
    return 'Weekly';
  }
  if (rule.startsWith('FREQ=MONTHLY')) {
    final match = RegExp(r'BYMONTHDAY=(\d+)').firstMatch(rule);
    if (match != null) {
      final day = int.parse(match.group(1)!);
      return 'Monthly (${_ordinal(day)})';
    }
    return 'Monthly';
  }
  return 'Recurring';
}

String _ordinal(int n) {
  if (n >= 11 && n <= 13) return '${n}th';
  switch (n % 10) {
    case 1:
      return '${n}st';
    case 2:
      return '${n}nd';
    case 3:
      return '${n}rd';
    default:
      return '${n}th';
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: PhosphorIcon(
          icon,
          size: 16,
          color: const Color(0xFF00171F).withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
