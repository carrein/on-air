import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:memoka_client/memoka_client.dart';
import '../utils/icon_utils.dart';
import 'icon_picker.dart';

/// Modal dialog for creating or editing a channel.
///
/// In create mode, displays "New Channel" title with a "Create" action button.
/// In edit mode, displays "Edit Channel" title with a "Save" action button,
/// pre-populated with the existing channel's name and emoji.
class NewChannelModal extends StatefulWidget {
  /// If provided, the modal operates in edit mode.
  final Channel? channel;

  /// Called when the user confirms (Create or Save).
  /// Returns the channel name and emoji.
  final Future<void> Function(String name, String emoji) onConfirm;

  const NewChannelModal({
    super.key,
    this.channel,
    required this.onConfirm,
  });

  /// Shows the modal as a dialog.
  static Future<void> show(
    BuildContext context, {
    Channel? channel,
    required Future<void> Function(String name, String emoji) onConfirm,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => NewChannelModal(
        channel: channel,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<NewChannelModal> createState() => _NewChannelModalState();
}

class _NewChannelModalState extends State<NewChannelModal> {
  // -- Colors --
  static const _borderColor = Color(0xFFCE2161);
  static const _darkColor = Color(0xFF00171F);
  static const _emojiCircleBorder = Color(0xFFDADDD8);

  // -- Dimensions --
  static const _dialogWidth = 350.0;
  static const _iconCircleSize = 64.0;
  static const _iconDisplaySize = 28.0;
  static const _iconToFieldGap = 20.0;

  late final TextEditingController _nameController;
  late String _selectedIconKey;

  bool get _isEditMode => widget.channel != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.channel?.name ?? '');
    _selectedIconKey = widget.channel?.emoji ?? kDefaultChannelIcon;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFF6F0ED),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: const BorderSide(color: _borderColor, width: 1.0),
      ),
      child: SizedBox(
        width: _dialogWidth,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _isEditMode ? 'Edit Channel' : 'New Channel',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: _darkColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Icon selector (circle, centered)
              GestureDetector(
                onTap: () => _showIconPicker(context),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    width: _iconCircleSize,
                    height: _iconCircleSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _borderColor, width: 1.0),
                    ),
                    child: Center(
                      child: PhosphorIcon(
                        getChannelIcon(_selectedIconKey),
                        size: _iconDisplaySize,
                        color: _darkColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: _iconToFieldGap),
              // Channel name text field
              TextField(
                controller: _nameController,
                style: const TextStyle(color: _darkColor),
                decoration: InputDecoration(
                  hintText: 'Channel Name',
                  hintStyle: TextStyle(
                    color: _darkColor.withValues(alpha: 0.4),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(
                      color: _emojiCircleBorder,
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: _borderColor, width: 1.0),
                  ),
                ),
                autofocus: true,
                onSubmitted: (_) => _onConfirm(),
              ),
              const SizedBox(height: 24),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: _darkColor,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _darkColor,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: Text(_isEditMode ? 'Save' : 'Create'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onConfirm() async {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      await widget.onConfirm(name, _selectedIconKey);
      if (mounted) Navigator.pop(context);
    }
  }

  void _showIconPicker(BuildContext context) async {
    final key = await IconPicker.show(
      context,
      selectedKey: _selectedIconKey,
    );
    if (key != null) {
      setState(() => _selectedIconKey = key);
    }
  }
}
