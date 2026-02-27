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

class _OfflineBannerState extends ConsumerState<OfflineBanner>
    with WidgetsBindingObserver {
  bool _showBanner = false;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // ref.listen only fires on *changes*, not the initial value. If the app
    // loads while already offline (e.g. hard refresh), kick the timer now.
    if (ref.read(conn.connectionProvider) ==
        conn.ConnectionState.disconnected) {
      _delayTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showBanner = true);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) {
      // Hide banner immediately on resume to prevent flash.
      // If still disconnected, the 3-second timer will re-show it.
      _delayTimer?.cancel();
      if (_showBanner && mounted) {
        setState(() => _showBanner = false);
      }
      if (ref.read(conn.connectionProvider) ==
          conn.ConnectionState.disconnected) {
        _delayTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _showBanner = true);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(conn.connectionProvider, (prev, next) {
      if (next == conn.ConnectionState.disconnected) {
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

    if (!_showBanner) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      color: const Color(0xFFFFE236),
      child: const Text(
        'Offline',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFF00171F),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
