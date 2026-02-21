import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:memoka_flutter/local_db/database.dart';
import 'package:memoka_flutter/providers/connection_provider.dart' as conn;
import 'package:memoka_flutter/providers/pending_mutation_count_provider.dart';
import 'package:memoka_flutter/widgets/sync_indicator.dart';

void main() {
  Widget buildTestWidget({
    required conn.ConnectionState connectionState,
    required int pendingCount,
  }) {
    return ProviderScope(
      overrides: [
        // Provide null db (web mode) so sync engine doesn't try to open SQLite
        appDatabaseProvider.overrideWithValue(null),
        conn.connectionStreamProvider.overrideWith(
          (_) => Stream.value(connectionState),
        ),
        pendingMutationCountProvider.overrideWith(
          (_) => Stream.value(pendingCount),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: SyncIndicator()),
      ),
    );
  }

  group('SyncIndicator', () {
    testWidgets('hidden when connected with zero pending mutations', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          connectionState: conn.ConnectionState.connected,
          pendingCount: 0,
        ),
      );
      await tester.pump();

      // SyncIndicator should render SizedBox.shrink (no visible icon)
      expect(find.byType(PhosphorIcon), findsNothing);
    });

    testWidgets('shows cloud-slash icon when disconnected', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          connectionState: conn.ConnectionState.disconnected,
          pendingCount: 0,
        ),
      );
      await tester.pump();

      expect(find.byType(PhosphorIcon), findsOneWidget);
    });

    testWidgets('shows count badge when disconnected with pending mutations', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          connectionState: conn.ConnectionState.disconnected,
          pendingCount: 3,
        ),
      );
      await tester.pump();

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('shows spinning icon when online with pending mutations', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          connectionState: conn.ConnectionState.connected,
          pendingCount: 2,
        ),
      );
      await tester.pump();

      // Should show a RotationTransition with a PhosphorIcon inside
      expect(
        find.descendant(
          of: find.byType(SyncIndicator),
          matching: find.byType(RotationTransition),
        ),
        findsOneWidget,
      );
    });
  });
}
