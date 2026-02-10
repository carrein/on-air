import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji;
import 'package:memoka_client/memoka_client.dart';

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
  static const _borderColor = Color(0xFFFF52A1);
  static const _darkColor = Color(0xFF00171F);
  static const _emojiCircleBorder = Color(0xFFDADDD8);

  // -- Dimensions --
  static const _dialogWidth = 350.0;
  static const _emojiCircleSize = 64.0;
  static const _emojiFontSize = 28.0;
  static const _emojiToFieldGap = 20.0;
  static const _emojiPickerHeight = 300.0;
  static const _emojiPickerGridHeight = 256.0;
  static const _emojiGridColumns = 7;
  static const _emojiGridMaxSize = 28.0;

  late final TextEditingController _nameController;
  late String _selectedEmoji;

  bool get _isEditMode => widget.channel != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.channel?.name ?? '');
    _selectedEmoji = widget.channel?.emoji ?? '🍉';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
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
              // Emoji selector (circle, centered)
              GestureDetector(
                onTap: () => _showEmojiPicker(context),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    width: _emojiCircleSize,
                    height: _emojiCircleSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _borderColor, width: 1.0),
                    ),
                    child: Center(
                      child: Text(
                        _selectedEmoji,
                        style: const TextStyle(fontSize: _emojiFontSize),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: _emojiToFieldGap),
              // Channel name text field
              TextField(
                controller: _nameController,
                style: const TextStyle(color: _darkColor),
                decoration: InputDecoration(
                  hintText: 'Channel Name',
                  hintStyle: TextStyle(color: _darkColor.withValues(alpha: 0.4)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: _emojiCircleBorder, width: 1.0),
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
      await widget.onConfirm(name, _selectedEmoji);
      if (mounted) Navigator.pop(context);
    }
  }

  void _showEmojiPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SizedBox(
        height: _emojiPickerHeight,
        child: emoji.EmojiPicker(
          onEmojiSelected: (category, emojiData) {
            setState(() => _selectedEmoji = emojiData.emoji);
            Navigator.pop(ctx);
          },
          config: const emoji.Config(
            height: _emojiPickerGridHeight,
            checkPlatformCompatibility: true,
            emojiViewConfig: emoji.EmojiViewConfig(
              emojiSizeMax: _emojiGridMaxSize,
              columns: _emojiGridColumns,
            ),
          ),
        ),
      ),
    );
  }
}
