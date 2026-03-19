import 'package:flutter/material.dart';

/// Result from the reminder picker dialog.
class ReminderPickerResult {
  final DateTime scheduledAt;
  final String? recurrenceRule;
  final DateTime? recurrenceEndAt;

  const ReminderPickerResult({
    required this.scheduledAt,
    this.recurrenceRule,
    this.recurrenceEndAt,
  });
}

const _dayAbbreviations = {
  1: 'MO',
  2: 'TU',
  3: 'WE',
  4: 'TH',
  5: 'FR',
  6: 'SA',
  7: 'SU',
};

const _dayNames = {
  1: 'Mon',
  2: 'Tue',
  3: 'Wed',
  4: 'Thu',
  5: 'Fri',
  6: 'Sat',
  7: 'Sun',
};

const _monthNames = [
  '',
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Shows a single compact dialog with date, time, and recurrence controls.
/// Returns null if the user cancels.
Future<ReminderPickerResult?> showReminderPicker(
  BuildContext context, {
  ReminderPickerResult? initialResult,
}) {
  return showDialog<ReminderPickerResult>(
    context: context,
    builder: (_) => _ReminderPickerDialog(initialResult: initialResult),
  );
}

enum _RepeatOption { none, minutely, hourly, daily, weekly, monthly }

enum _EndOption { never, onDate }

_RepeatOption _repeatFromRule(String? rule) {
  if (rule == null) return _RepeatOption.none;
  if (rule.startsWith('FREQ=MINUTELY')) return _RepeatOption.minutely;
  if (rule.startsWith('FREQ=HOURLY')) return _RepeatOption.hourly;
  if (rule.startsWith('FREQ=DAILY')) return _RepeatOption.daily;
  if (rule.startsWith('FREQ=WEEKLY')) return _RepeatOption.weekly;
  if (rule.startsWith('FREQ=MONTHLY')) return _RepeatOption.monthly;
  return _RepeatOption.none;
}

String? _buildRrule(_RepeatOption repeat, DateTime scheduledAt) {
  switch (repeat) {
    case _RepeatOption.none:
      return null;
    case _RepeatOption.minutely:
      return 'FREQ=MINUTELY';
    case _RepeatOption.hourly:
      return 'FREQ=HOURLY';
    case _RepeatOption.daily:
      return 'FREQ=DAILY';
    case _RepeatOption.weekly:
      final day = _dayAbbreviations[scheduledAt.weekday] ?? 'MO';
      return 'FREQ=WEEKLY;BYDAY=$day';
    case _RepeatOption.monthly:
      return 'FREQ=MONTHLY;BYMONTHDAY=${scheduledAt.day}';
  }
}

class _ReminderPickerDialog extends StatefulWidget {
  final ReminderPickerResult? initialResult;

  const _ReminderPickerDialog({this.initialResult});

  @override
  State<_ReminderPickerDialog> createState() => _ReminderPickerDialogState();
}

class _ReminderPickerDialogState extends State<_ReminderPickerDialog> {
  static const _bgColor = Color(0xFFFFFDF6);
  static const _accentColor = Color(0xFF3450A3);
  static const _textColor = Color(0xFF00171F);

  late DateTime _date;
  late TimeOfDay _time;
  late _RepeatOption _repeat;
  late _EndOption _endOption;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final init = widget.initialResult;
    final now = DateTime.now();
    final initial = init?.scheduledAt ?? now.add(const Duration(minutes: 1));
    _date = DateTime(initial.year, initial.month, initial.day);
    _time = TimeOfDay(hour: initial.hour, minute: initial.minute);
    _repeat = init != null
        ? _repeatFromRule(init.recurrenceRule)
        : _RepeatOption.none;
    _endOption = init?.recurrenceEndAt != null
        ? _EndOption.onDate
        : _EndOption.never;
    _endDate = init?.recurrenceEndAt;
  }

  DateTime get _scheduledAt => DateTime(
    _date.year,
    _date.month,
    _date.day,
    _time.hour,
    _time.minute,
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: _accentColor),
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      title: const Text(
        'Set Reminder',
        style: TextStyle(
          color: _textColor,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date + Time row
            Row(
              children: [
                Expanded(child: _buildDateField()),
                const SizedBox(width: 10),
                _buildTimeField(),
              ],
            ),
            const SizedBox(height: 12),
            // Repeat
            _buildDropdown<_RepeatOption>(
              label: 'Repeat',
              value: _repeat,
              items: const {
                _RepeatOption.none: 'None',
                _RepeatOption.minutely: 'Every Minute',
                _RepeatOption.hourly: 'Hourly',
                _RepeatOption.daily: 'Daily',
                _RepeatOption.weekly: 'Weekly',
                _RepeatOption.monthly: 'Monthly',
              },
              onChanged: (v) => setState(() {
                _repeat = v;
                if (v == _RepeatOption.none) {
                  _endOption = _EndOption.never;
                  _endDate = null;
                }
              }),
            ),
            // End (only when repeating)
            if (_repeat != _RepeatOption.none) ...[
              const SizedBox(height: 10),
              _buildEndRow(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: _textColor)),
        ),
        TextButton(
          onPressed: _onConfirm,
          child: const Text('Confirm', style: TextStyle(color: _accentColor)),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    final d = _date;
    final label = '${_dayNames[d.weekday]}, ${_monthNames[d.month]} ${d.day}';
    return _TappableField(
      label: label,
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: _date.isBefore(now) ? now : _date,
          firstDate: now,
          lastDate: now.add(const Duration(days: 365)),
        );
        if (picked != null) setState(() => _date = picked);
      },
    );
  }

  Widget _buildTimeField() {
    final label =
        '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';
    return _TappableField(
      label: label,
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: _time,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
        );
        if (picked != null) setState(() => _time = picked);
      },
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required Map<T, String> items,
    required ValueChanged<T> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: const TextStyle(color: _textColor, fontSize: 13),
          ),
        ),
        Expanded(
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: _accentColor.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                isDense: true,
                dropdownColor: _bgColor,
                style: const TextStyle(color: _textColor, fontSize: 13),
                items: items.entries
                    .map(
                      (e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEndRow() {
    return Row(
      children: [
        const SizedBox(
          width: 52,
          child: Text(
            'End',
            style: TextStyle(color: _textColor, fontSize: 13),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _accentColor.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<_EndOption>(
                      value: _endOption,
                      isExpanded: true,
                      isDense: true,
                      dropdownColor: _bgColor,
                      style: const TextStyle(color: _textColor, fontSize: 13),
                      items: const [
                        DropdownMenuItem(
                          value: _EndOption.never,
                          child: Text('Never'),
                        ),
                        DropdownMenuItem(
                          value: _EndOption.onDate,
                          child: Text('On date...'),
                        ),
                      ],
                      onChanged: (v) async {
                        if (v == _EndOption.onDate) {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate:
                                _endDate ?? _date.add(const Duration(days: 30)),
                            firstDate: _date,
                            lastDate: _date.add(const Duration(days: 365 * 2)),
                          );
                          if (picked != null) {
                            setState(() {
                              _endOption = _EndOption.onDate;
                              _endDate = picked;
                            });
                          }
                        } else if (v != null) {
                          setState(() {
                            _endOption = v;
                            _endDate = null;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
              if (_endOption == _EndOption.onDate && _endDate != null) ...[
                const SizedBox(width: 8),
                Text(
                  '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                  style: TextStyle(
                    color: _textColor.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _onConfirm() {
    final scheduled = _scheduledAt;
    if (scheduled.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Time must be in the future')),
      );
      return;
    }
    final rrule = _buildRrule(_repeat, scheduled);
    Navigator.of(context).pop(
      ReminderPickerResult(
        scheduledAt: scheduled,
        recurrenceRule: rrule,
        recurrenceEndAt:
            (_repeat != _RepeatOption.none && _endOption == _EndOption.onDate)
            ? _endDate
            : null,
      ),
    );
  }
}

class _TappableField extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TappableField({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF3450A3).withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF00171F),
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
