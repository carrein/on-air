import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_air_client/on_air_client.dart';
import '../providers/notes_provider.dart';
import '../providers/current_channel_provider.dart';
import '../providers/editing_note_provider.dart';

/// Chat view displaying notes in an inverted list (newest at bottom).
class ChatView extends ConsumerStatefulWidget {
  const ChatView({super.key});

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  final ScrollController _scrollController = ScrollController();
  bool _userScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Load more when scrolling near top (in reversed list)
    if (_scrollController.position.pixels < 100) {
      final channelId = ref.read(currentChannelProvider).value;
      if (channelId != null) {
        ref.read(notesProvider(channelId).notifier).loadMore();
      }
    }

    // Track if user is scrolling history
    _userScrolling = _scrollController.position.pixels > 50;
  }

  @override
  Widget build(BuildContext context) {
    final currentChannelAsync = ref.watch(currentChannelProvider);

    return currentChannelAsync.when(
      data: (channelId) {
        final notesAsync = ref.watch(notesProvider(channelId));

        return notesAsync.when(
          data: (notes) {
            if (notes.isEmpty) {
              return const Center(
                child: Text('No notes yet. Start typing below!'),
              );
            }

            return ListView.builder(
              controller: _scrollController,
              reverse: true, // Newest at bottom
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return _buildNoteItem(note, channelId);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildNoteItem(Note note, int channelId) {
    return ListTile(
      title: Text(note.content),
      subtitle: Text(
        _formatDateTime(note.createdAt),
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      onLongPress: () => _startEditing(note),
      trailing: IconButton(
        icon: const Icon(Icons.delete, size: 20),
        onPressed: () => _deleteNote(note, channelId),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _startEditing(Note note) {
    ref.read(editingNoteProvider.notifier).startEditing(note.id!);
  }

  void _deleteNote(Note note, int channelId) {
    ref.read(notesProvider(channelId).notifier).deleteNote(note.id!);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
