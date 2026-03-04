import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:memoka_client/memoka_client.dart';
import '../main.dart';
import 'current_channel_provider.dart';

part 'search_results_provider.g.dart';

@riverpod
Future<List<SearchResult>> searchResults(Ref ref, String query) async {
  if (query.trim().isEmpty) return [];
  final truncated = query.length > 200 ? query.substring(0, 200) : query;
  final channelId = ref.read(currentChannelProvider).value;
  return await client.search.searchNotes(
    truncated,
    channelId: channelId,
    limit: 20,
  );
}
