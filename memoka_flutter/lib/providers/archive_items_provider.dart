import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:memoka_client/memoka_client.dart';
import '../main.dart';
import 'chat_stream_provider.dart';

part 'archive_items_provider.g.dart';

/// Manages the mixed archive list (notes + channels) with real-time updates.
@riverpod
class ArchiveItems extends _$ArchiveItems {
  @override
  Future<List<ArchiveItem>> build() async {
    ref.listen(chatStreamProvider, (_, event) {
      event.whenData((chatEvent) {
        if ([
          'noteArchived',
          'noteRestored',
          'noteDeleted',
          'channelArchived',
          'channelRestored',
          'channelDeleted',
        ].contains(chatEvent.type)) {
          ref.invalidateSelf();
        }
      });
    });

    return client.chat.getArchiveItems(limit: 50);
  }

  Future<void> restoreNote(int noteId) async {
    await client.chat.restoreNote(noteId);
    // WebSocket will trigger refetch
  }

  Future<void> deleteNote(int noteId) async {
    await client.chat.deleteNote(noteId);
    // Optimistic update
    final current = state.value ?? [];
    state = AsyncValue.data(
      current.where((item) => !(item.type == 'note' && item.note?.id == noteId)).toList(),
    );
  }

  Future<void> restoreChannel(int channelId) async {
    await client.chat.restoreChannel(channelId);
    // WebSocket will trigger refetch
  }

  Future<void> deleteChannel(int channelId) async {
    await client.chat.deleteChannel(channelId);
    // Optimistic update
    final current = state.value ?? [];
    state = AsyncValue.data(
      current.where((item) => !(item.type == 'channel' && item.channel?.id == channelId)).toList(),
    );
  }
}
