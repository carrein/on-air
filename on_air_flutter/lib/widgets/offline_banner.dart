import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connection_provider.dart' as conn;

/// Banner displayed when connection is lost (after 3 second delay).
class OfflineBanner extends ConsumerStatefulWidget {
  const OfflineBanner({super.key});

  @override
  ConsumerState<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends ConsumerState<OfflineBanner> {
  bool _showBanner = false;
  Timer? _delayTimer;

  @override
  Widget build(BuildContext context) {
    ref.listen(conn.connectionStreamProvider, (prev, next) {
      next.whenData((state) {
        if (state == conn.ConnectionState.disconnected) {
          // Show banner after 3s delay
          _delayTimer?.cancel();
          _delayTimer = Timer(const Duration(seconds: 3), () {
            if (mounted) setState(() => _showBanner = true);
          });
        } else {
          // Hide banner immediately when reconnected
          _delayTimer?.cancel();
          if (mounted) setState(() => _showBanner = false);
        }
      });
    });

    if (!_showBanner) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      color: Colors.orange,
      child: const Text(
        'Offline - Reconnecting...',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    super.dispose();
  }
}
