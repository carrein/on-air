import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:memoka_flutter/local_db/database.dart';
import 'package:memoka_flutter/providers/chat_stream_provider.dart';
import 'package:memoka_flutter/providers/connection_provider.dart' as conn;
import 'package:memoka_flutter/providers/pending_mutation_count_provider.dart';
import 'package:memoka_flutter/widgets/sync_indicator.dart';

void main() {
  // Shared in-memory database across tests to avoid drift's multiple-instance warning.
  late AppDatabase testDb;

  setUp(() {
    testDb = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => testDb.close());

  Widget buildTestWidget({
    required conn.ConnectionState connectionState,
    required int pendingCount,
  }) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(testDb),
        conn.connectionStreamProvider.overrideWith(
          (_) => Stream.value(connectionState),
        ),
        pendingMutationCountProvider.overrideWith(
          (_) => Stream.value(pendingCount),
        ),
        // SyncEngine._drain() invalidates channelsProvider on reconnect,
        // which would start chatStreamProvider (creating a reconnect timer).
        chatStreamProvider.overrideWith((_) => const Stream.empty()),
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
