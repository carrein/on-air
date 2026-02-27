import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../providers/connection_provider.dart' as conn;
import '../providers/debounced_connection_provider.dart';
import '../providers/dirty_sync_count_provider.dart';
import '../providers/sync_engine_provider.dart';

/// Navbar indicator showing offline/syncing state.
///
/// - Hidden when connected with no pending mutations, or during initial boot.
/// - Brand-accent cloud-slash icon when offline (with optional count badge).
/// - Spinning arrows icon when online and draining the queue.
class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key});

  static const _accentColor = Color(0xFFCE2161);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connState = ref.watch(debouncedConnectionProvider);
    final countAsync = ref.watch(dirtySyncCountProvider);
    ref.watch(syncEngineProvider);

    final isOffline = connState == conn.ConnectionState.disconnected;
    final isConnected = connState == conn.ConnectionState.connected;
    final count = countAsync.valueOrNull ?? 0;

    // Hide during initial connecting phase and when online with nothing to sync.
    if (isConnected && count == 0) return const SizedBox.shrink();
    if (!isConnected && !isOffline) return const SizedBox.shrink();

    if (isOffline) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: _accentColor,
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
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

    // Online but draining
    return _SpinningIcon(
      icon: PhosphorIcons.spinnerGap(),
      color: _accentColor,
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
