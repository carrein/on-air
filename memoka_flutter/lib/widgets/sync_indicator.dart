import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../providers/connection_provider.dart' as conn;
import '../providers/pending_mutation_count_provider.dart';
import '../providers/sync_engine_provider.dart';

/// Navbar indicator showing offline/syncing state.
///
/// - Hidden when connected with no pending mutations.
/// - Amber cloud-slash icon when offline (with optional count badge).
/// - Spinning arrows icon when online and draining the queue.
class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key});

  static const _amberColor = Color(0xFFD4920B);
  static const _textColor = Color(0xFF00171F);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connState = ref.watch(conn.connectionProvider);
    final countAsync = ref.watch(pendingMutationCountProvider);
    ref.watch(syncEngineProvider);

    final isOnline = connState == conn.ConnectionState.connected;
    final count = countAsync.valueOrNull ?? 0;

    if (isOnline && count == 0) return const SizedBox.shrink();

    if (!isOnline) {
      // Offline indicator
      return _buildBadge(
        icon: PhosphorIcons.cloudSlash(),
        color: _amberColor,
        count: count,
      );
    }

    // Online but draining
    return _SpinningIcon(
      icon: PhosphorIcons.arrowsClockwise(),
      color: _textColor,
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required Color color,
    required int count,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: PhosphorIcon(icon, color: color, size: 22),
        ),
        if (count > 0)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class _SpinningIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const _SpinningIcon({required this.icon, required this.color});

  @override
  State<_SpinningIcon> createState() => _SpinningIconState();
}

class _SpinningIconState extends State<_SpinningIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: RotationTransition(
        turns: _controller,
        child: PhosphorIcon(widget.icon, color: widget.color, size: 22),
      ),
    );
  }
}
