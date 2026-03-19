import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../utils/icon_utils.dart';

/// Bottom-sheet icon picker with search and scrollable grid.
///
/// Shows all ~1500 Phosphor fill icons in a 6-column grid.
/// A search field at the top filters icons by name in real time.
/// Tapping an icon selects it and closes the picker.
class IconPicker extends StatefulWidget {
  /// Currently selected icon key (highlighted in grid).
  final String selectedKey;

  /// Called with the chosen icon key when the user taps an icon.
  final ValueChanged<String> onSelected;

  const IconPicker({
    super.key,
    required this.selectedKey,
    required this.onSelected,
  });

  /// Shows the picker as a modal bottom sheet. Returns the selected key
  /// or `null` if dismissed.
  static Future<String?> show(
    BuildContext context, {
    required String selectedKey,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFFFFFDF6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scrollController) => IconPicker(
          selectedKey: selectedKey,
          onSelected: (key) => Navigator.pop(ctx, key),
        ),
      ),
    );
  }

  @override
  State<IconPicker> createState() => _IconPickerState();
}

class _IconPickerState extends State<IconPicker> {
  static const _selectedBg = Color(0xFF3450A3);
  static const _gridColumns = 6;
  static const _iconSize = 26.0;
  static const _gridSpacing = 4.0;

  final _searchController = TextEditingController();
  late List<MapEntry<String, PhosphorIconData>> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = kPhosphorFillIcons.entries.toList();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filtered = kPhosphorFillIcons.entries.toList();
      } else {
        _filtered = kPhosphorFillIcons.entries
            .where((e) => _matchesSearch(e.key, query))
            .toList();
      }
    });
  }

  /// Matches camelCase icon names against a search query.
  /// "chatCircle" matches queries "chat", "circle", "chatcircle".
  bool _matchesSearch(String key, String query) {
    // Direct substring match on lowercase key
    if (key.toLowerCase().contains(query)) return true;
    // Split camelCase into words and check
    final words = key
        .replaceAllMapped(RegExp(r'[A-Z]'), (m) => ' ${m[0]}')
        .toLowerCase()
        .trim();
    return words.contains(query);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFF00171F).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Search field
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search icons...',
              prefixIcon: PhosphorIcon(
                PhosphorIcons.magnifyingGlass(),
                size: 20,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        // Grid
        Expanded(
          child: _filtered.isEmpty
              ? const Center(
                  child: Text(
                    'No icons found',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _gridColumns,
                    mainAxisSpacing: _gridSpacing,
                    crossAxisSpacing: _gridSpacing,
                  ),
                  itemCount: _filtered.length,
                  itemBuilder: (context, index) {
                    final entry = _filtered[index];
                    final isSelected = entry.key == widget.selectedKey;

                    return GestureDetector(
                      onTap: () => widget.onSelected(entry.key),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _selectedBg.withValues(alpha: 0.15)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: _selectedBg, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: PhosphorIcon(
                            entry.value,
                            size: _iconSize,
                            color: isSelected
                                ? _selectedBg
                                : const Color(0xFF00171F),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
