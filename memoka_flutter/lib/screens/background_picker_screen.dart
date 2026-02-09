import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/background_provider.dart';
import '../providers/settings_page_provider.dart';

/// Screen for selecting chat background
class BackgroundPickerScreen extends ConsumerWidget {
  const BackgroundPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentBackground = ref.watch(backgroundPreferenceProvider);

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header with back button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue[700],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    // Go back to settings main
                    ref.read(currentSettingsPageProvider.notifier).showMain();
                  },
                ),
                const SizedBox(width: 8),
                const Text(
                  'Chat Background',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Background options grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.8,
                children: BackgroundType.values.map((background) {
                  final isSelected = background == currentBackground;
                  return _buildBackgroundOption(
                    context,
                    ref,
                    background,
                    isSelected,
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundOption(
    BuildContext context,
    WidgetRef ref,
    BackgroundType background,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        ref.read(backgroundPreferenceProvider.notifier).setBackground(background);
      },
      child: Column(
        children: [
          // Preview card
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background preview
                    Image.asset(
                      background.assetPath,
                      fit: BoxFit.cover,
                    ),
                    // Mock chat bubbles
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const SizedBox(width: 60, height: 8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const SizedBox(width: 80, height: 8),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Selected indicator
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.blue[700],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Label
          Text(
            background.displayName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.blue[700] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
