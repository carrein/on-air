import 'package:memoka_client/memoka_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../main.dart';

part 'channel_page_watches_provider.g.dart';

/// Provides all page watches for a channel (1 RPC per channel instead of N).
@riverpod
Future<List<PageWatch>> channelPageWatches(Ref ref, int channelId) async {
  return client.pageWatch.getWatches(channelId);
}
