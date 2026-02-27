import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connection_provider.dart' as conn;

/// Banner displayed when the server connection is lost.
///
/// Purely reactive — watches [connectionProvider] and shows the banner only
/// when the state is [ConnectionState.disconnected]. Hidden during the initial
/// [connecting] phase (before the first health ping completes) and when
/// [connected].
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conn.connectionProvider);

    if (state != conn.ConnectionState.disconnected) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      color: const Color(0xFFCE2161),
      child: const Text(
        'Offline',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
