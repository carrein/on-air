import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connection_provider.dart' as conn;
import '../providers/debounced_connection_provider.dart';

/// Banner displayed when the server connection is lost.
///
/// Watches [debouncedConnectionProvider] which delays the transition to
/// [disconnected] by 1.5s, preventing a brief flash when the app resumes
/// from background and the health ping hasn't completed yet.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(debouncedConnectionProvider);

    if (state != conn.ConnectionState.disconnected) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      color: const Color(0xFF3450A3),
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
