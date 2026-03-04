/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'dart:async' as _i2;
import 'package:memoka_client/src/protocol/chat/channel.dart' as _i3;
import 'package:memoka_client/src/protocol/chat/note.dart' as _i4;
import 'package:memoka_client/src/protocol/chat/archive_item.dart' as _i5;
import 'package:memoka_client/src/protocol/chat/chat_event.dart' as _i6;
import 'package:memoka_client/src/protocol/search/search_result.dart' as _i7;
import 'package:memoka_client/src/protocol/settings/app_settings.dart' as _i8;
import 'package:memoka_client/src/protocol/sync/sync_pull_response.dart' as _i9;
import 'package:memoka_client/src/protocol/sync/sync_push_response.dart'
    as _i10;
import 'package:memoka_client/src/protocol/sync/sync_change.dart' as _i11;
import 'protocol.dart' as _i12;

/// Endpoint for managing channels and notes with real-time updates.
/// {@category Endpoint}
class EndpointChat extends _i1.EndpointRef {
  EndpointChat(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'chat';

  /// Returns all channels sorted by pinned first, then position, then updatedAt.
  /// Excludes tombstoned channels (deletedAt IS NOT NULL).
  _i2.Future<List<_i3.Channel>> getChannels() =>
      caller.callServerEndpoint<List<_i3.Channel>>(
        'chat',
        'getChannels',
        {},
      );

  /// Returns notes for a channel with cursor-based pagination.
  /// Uses [beforeId] for loading older messages (scroll up behavior).
  /// Efficiently loads attachments with LEFT JOIN to prevent N+1 queries.
  /// Excludes tombstoned notes (deletedAt IS NOT NULL).
  _i2.Future<List<_i4.Note>> getNotes(
    int channelId, {
    int? beforeId,
    required int limit,
  }) => caller.callServerEndpoint<List<_i4.Note>>(
    'chat',
    'getNotes',
    {
      'channelId': channelId,
      'beforeId': beforeId,
      'limit': limit,
    },
  );

  /// Creates a new channel and broadcasts the event.
  _i2.Future<_i3.Channel> createChannel(
    String name, {
    required String emoji,
  }) => caller.callServerEndpoint<_i3.Channel>(
    'chat',
    'createChannel',
    {
      'name': name,
      'emoji': emoji,
    },
  );

  /// Updates a channel's name, emoji, or pinned status.
  _i2.Future<_i3.Channel> updateChannel(
    int id, {
    String? name,
    String? emoji,
    bool? pinned,
  }) => caller.callServerEndpoint<_i3.Channel>(
    'chat',
    'updateChannel',
    {
      'id': id,
      'name': name,
      'emoji': emoji,
      'pinned': pinned,
    },
  );

  /// Reorders channels within a group (pinned or unpinned).
  /// Accepts an ordered list of channel IDs; assigns position = index + 1.
  /// Normalises all positions to 1.0, 2.0, 3.0... when any two adjacent
  /// positions differ by less than epsilon (1e-10).
  _i2.Future<void> reorderChannels(List<int> channelIds) =>
      caller.callServerEndpoint<void>(
        'chat',
        'reorderChannels',
        {'channelIds': channelIds},
      );

  /// Tombstones a channel (sets deletedAt) instead of physically deleting it.
  /// Also tombstones all notes in the channel. Rejects if it's the last channel.
  /// Media file cleanup should happen in a background task.
  _i2.Future<void> deleteChannel(int id) => caller.callServerEndpoint<void>(
    'chat',
    'deleteChannel',
    {'id': id},
  );

  /// Creates a new note and broadcasts the event.
  /// Also updates the channel's updatedAt timestamp.
  /// Asynchronously fetches link preview if URL is detected in content.
  /// [clientMutationId] is an optional idempotency key for offline-created notes.
  /// If a note with this key already exists, it is returned without creating a duplicate.
  _i2.Future<_i4.Note> createNote(
    int channelId,
    String content, {
    String? clientMutationId,
  }) => caller.callServerEndpoint<_i4.Note>(
    'chat',
    'createNote',
    {
      'channelId': channelId,
      'content': content,
      'clientMutationId': clientMutationId,
    },
  );

  /// Updates a note's content (last-write-wins strategy).
  _i2.Future<_i4.Note> updateNote(
    int id,
    String content,
  ) => caller.callServerEndpoint<_i4.Note>(
    'chat',
    'updateNote',
    {
      'id': id,
      'content': content,
    },
  );

  /// Deletes a note - archives it (soft-delete) if in a regular channel,
  /// permanently tombstones it if already archived (from Archive view).
  _i2.Future<void> deleteNote(int id) => caller.callServerEndpoint<void>(
    'chat',
    'deleteNote',
    {'id': id},
  );

  /// Restores a note from Archive back to its channel.
  _i2.Future<void> restoreNote(int id) => caller.callServerEndpoint<void>(
    'chat',
    'restoreNote',
    {'id': id},
  );

  /// Archives a channel (soft delete). Notes stay with the channel.
  _i2.Future<void> archiveChannel(int id) => caller.callServerEndpoint<void>(
    'chat',
    'archiveChannel',
    {'id': id},
  );

  /// Restores an archived channel back to the sidebar.
  _i2.Future<_i3.Channel> restoreChannel(int id) =>
      caller.callServerEndpoint<_i3.Channel>(
        'chat',
        'restoreChannel',
        {'id': id},
      );

  /// Returns a mixed list of archived notes and archived channels,
  /// sorted by archivedAt descending (newest first).
  /// Excludes tombstoned entities (deletedAt IS NOT NULL).
  _i2.Future<List<_i5.ArchiveItem>> getArchiveItems({required int limit}) =>
      caller.callServerEndpoint<List<_i5.ArchiveItem>>(
        'chat',
        'getArchiveItems',
        {'limit': limit},
      );

  /// Returns the count of notes in an archived channel (for confirmation dialog).
  _i2.Future<int> getArchivedChannelNoteCount(int channelId) =>
      caller.callServerEndpoint<int>(
        'chat',
        'getArchivedChannelNoteCount',
        {'channelId': channelId},
      );

  /// Streaming endpoint for real-time updates.
  /// Subscribes to all chat events (channel and note changes).
  _i2.Stream<_i6.ChatEvent> chat() => caller
      .callStreamingServerEndpoint<_i2.Stream<_i6.ChatEvent>, _i6.ChatEvent>(
        'chat',
        'chat',
        {},
        {},
      );
}

/// Lightweight endpoint used by the Flutter client to confirm server
/// reachability before opening the WebSocket stream.
/// {@category Endpoint}
class EndpointHealth extends _i1.EndpointRef {
  EndpointHealth(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'health';

  _i2.Future<bool> ping() => caller.callServerEndpoint<bool>(
    'health',
    'ping',
    {},
  );
}

/// Endpoint for full-text and fuzzy subsequence search across notes.
/// {@category Endpoint}
class EndpointSearch extends _i1.EndpointRef {
  EndpointSearch(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'search';

  /// Searches notes using hybrid FTS prefix + unanchored subsequence matching.
  ///
  /// FTS prefix handles exact prefix matches (fast, GIN-indexed).
  /// Subsequence handles fuzzy matches like "Qck" -> "Quick" or "ick" -> "Quick"
  /// by checking if query chars appear in order within any content word.
  /// Content is split on non-alphanumeric boundaries so punctuation and markdown
  /// syntax act as word separators. Multi-word queries use OR logic.
  /// Results ranked by score DESC, then recency DESC as tiebreaker.
  _i2.Future<List<_i7.SearchResult>> searchNotes(
    String query, {
    int? channelId,
    required int limit,
  }) => caller.callServerEndpoint<List<_i7.SearchResult>>(
    'search',
    'searchNotes',
    {
      'query': query,
      'channelId': channelId,
      'limit': limit,
    },
  );

  /// Loads notes centered around a specific note ID within a channel.
  ///
  /// Returns approximately [limit] notes: half before and half after
  /// the target note (by createdAt), including the target itself.
  /// Used to jump to a search result in context.
  _i2.Future<List<_i4.Note>> getNotesAroundId(
    int channelId,
    int noteId, {
    required int limit,
  }) => caller.callServerEndpoint<List<_i4.Note>>(
    'search',
    'getNotesAroundId',
    {
      'channelId': channelId,
      'noteId': noteId,
      'limit': limit,
    },
  );
}

/// Endpoint for reading and updating application settings.
/// {@category Endpoint}
class EndpointSettings extends _i1.EndpointRef {
  EndpointSettings(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'settings';

  /// Returns the current application settings.
  _i2.Future<_i8.AppSettings> getSettings() =>
      caller.callServerEndpoint<_i8.AppSettings>(
        'settings',
        'getSettings',
        {},
      );

  /// Updates application settings.
  _i2.Future<_i8.AppSettings> updateSettings(_i8.AppSettings settings) =>
      caller.callServerEndpoint<_i8.AppSettings>(
        'settings',
        'updateSettings',
        {'settings': settings},
      );
}

/// Endpoint for state-based reconciliation sync.
///
/// Pull phase: client fetches all entities changed since its last known version.
/// Push phase: client sends dirty local entities; server validates and applies.
/// {@category Endpoint}
class EndpointSync extends _i1.EndpointRef {
  EndpointSync(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'sync';

  /// Returns all channels and notes changed since [sinceVersion].
  ///
  /// Includes tombstoned entities (deletedAt != null) so clients can remove them.
  /// Pass sinceVersion = 0 for a full sync (first launch / fresh install).
  _i2.Future<_i9.SyncPullResponse> syncPull(int sinceVersion) =>
      caller.callServerEndpoint<_i9.SyncPullResponse>(
        'sync',
        'syncPull',
        {'sinceVersion': sinceVersion},
      );

  /// Processes a batch of local dirty entities and applies them to the server.
  ///
  /// Each change is processed in its own transaction — partial apply is supported.
  /// Returns per-entity results: applied / rejected / already_applied.
  _i2.Future<_i10.SyncPushResponse> syncPush(List<_i11.SyncChange> changes) =>
      caller.callServerEndpoint<_i10.SyncPushResponse>(
        'sync',
        'syncPush',
        {'changes': changes},
      );
}

class Client extends _i1.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    @Deprecated(
      'Use authKeyProvider instead. This will be removed in future releases.',
    )
    super.authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _i1.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_i1.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
  }) : super(
         host,
         _i12.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
       ) {
    chat = EndpointChat(this);
    health = EndpointHealth(this);
    search = EndpointSearch(this);
    settings = EndpointSettings(this);
    sync = EndpointSync(this);
  }

  late final EndpointChat chat;

  late final EndpointHealth health;

  late final EndpointSearch search;

  late final EndpointSettings settings;

  late final EndpointSync sync;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
    'chat': chat,
    'health': health,
    'search': search,
    'settings': settings,
    'sync': sync,
  };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {};
}
