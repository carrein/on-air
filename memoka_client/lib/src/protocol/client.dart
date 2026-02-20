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
import 'package:memoka_client/src/protocol/media/media_attachment.dart' as _i7;
import 'protocol.dart' as _i8;

/// Endpoint for managing channels and notes with real-time updates.
/// {@category Endpoint}
class EndpointChat extends _i1.EndpointRef {
  EndpointChat(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'chat';

  /// Returns all channels sorted by pinned first, then sortOrder, then updatedAt.
  _i2.Future<List<_i3.Channel>> getChannels() =>
      caller.callServerEndpoint<List<_i3.Channel>>(
        'chat',
        'getChannels',
        {},
      );

  /// Returns notes for a channel with cursor-based pagination.
  /// Uses [beforeId] for loading older messages (scroll up behavior).
  /// Efficiently loads attachments with LEFT JOIN to prevent N+1 queries.
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
  /// Accepts an ordered list of channel IDs; assigns sortOrder = index.
  _i2.Future<void> reorderChannels(List<int> channelIds) =>
      caller.callServerEndpoint<void>(
        'chat',
        'reorderChannels',
        {'channelIds': channelIds},
      );

  /// Deletes a channel and cascades to delete its notes and media files.
  /// Rejects if it's the last remaining active (non-archived) channel.
  _i2.Future<void> deleteChannel(int id) => caller.callServerEndpoint<void>(
    'chat',
    'deleteChannel',
    {'id': id},
  );

  /// Creates a new note and broadcasts the event.
  /// Also updates the channel's updatedAt timestamp.
  /// Asynchronously fetches link preview if URL is detected in content.
  _i2.Future<_i4.Note> createNote(
    int channelId,
    String content,
  ) => caller.callServerEndpoint<_i4.Note>(
    'chat',
    'createNote',
    {
      'channelId': channelId,
      'content': content,
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

  /// Deletes a note - archives it if in a regular channel, permanently deletes if in Archive.
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

/// Endpoint for media upload and management.
/// {@category Endpoint}
class EndpointMedia extends _i1.EndpointRef {
  EndpointMedia(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'media';

  /// Upload a media file as bytes and create a note with it.
  ///
  /// Uses two-phase commit:
  /// 1. Write bytes to temporary file
  /// 2. Process image
  /// 3. Insert database records (note + attachment) in transaction
  /// 4. Rename to final filename
  /// 5. On error: cleanup temp file
  _i2.Future<_i4.Note> uploadMediaAndCreateNote(
    int channelId,
    String noteContent,
    String fileBytesBase64,
    String originalFilename,
    String mimeType,
    bool compress,
  ) => caller.callServerEndpoint<_i4.Note>(
    'media',
    'uploadMediaAndCreateNote',
    {
      'channelId': channelId,
      'noteContent': noteContent,
      'fileBytesBase64': fileBytesBase64,
      'originalFilename': originalFilename,
      'mimeType': mimeType,
      'compress': compress,
    },
  );

  /// Upload a media file with streaming (for future use).
  ///
  /// Uses two-phase commit:
  /// 1. Stream to temporary file
  /// 2. Process image
  /// 3. Insert database record
  /// 4. Rename to final filename
  /// 5. On error: cleanup temp file
  _i2.Future<_i7.MediaAttachment> uploadMedia(
    int channelId,
    String originalFilename,
    String mimeType,
    bool compress,
    _i2.Stream<List<int>> fileStream,
  ) =>
      caller.callStreamingServerEndpoint<
        _i2.Future<_i7.MediaAttachment>,
        _i7.MediaAttachment
      >(
        'media',
        'uploadMedia',
        {
          'channelId': channelId,
          'originalFilename': originalFilename,
          'mimeType': mimeType,
          'compress': compress,
        },
        {'fileStream': fileStream},
      );

  /// Delete a media attachment and its files.
  _i2.Future<void> deleteAttachment(int attachmentId) =>
      caller.callServerEndpoint<void>(
        'media',
        'deleteAttachment',
        {'attachmentId': attachmentId},
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
         _i8.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
       ) {
    chat = EndpointChat(this);
    media = EndpointMedia(this);
  }

  late final EndpointChat chat;

  late final EndpointMedia media;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
    'chat': chat,
    'media': media,
  };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {};
}
