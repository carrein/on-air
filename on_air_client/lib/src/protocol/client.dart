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
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i1;
import 'package:serverpod_client/serverpod_client.dart' as _i2;
import 'dart:async' as _i3;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i4;
import 'package:on_air_client/src/protocol/chat/channel.dart' as _i5;
import 'package:on_air_client/src/protocol/chat/note.dart' as _i6;
import 'package:on_air_client/src/protocol/chat/chat_event.dart' as _i7;
import 'package:on_air_client/src/protocol/greetings/greeting.dart' as _i8;
import 'package:on_air_client/src/protocol/media/media_attachment.dart' as _i9;
import 'protocol.dart' as _i10;

/// By extending [EmailIdpBaseEndpoint], the email identity provider endpoints
/// are made available on the server and enable the corresponding sign-in widget
/// on the client.
/// {@category Endpoint}
class EndpointEmailIdp extends _i1.EndpointEmailIdpBase {
  EndpointEmailIdp(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'emailIdp';

  /// Logs in the user and returns a new session.
  ///
  /// Throws an [EmailAccountLoginException] in case of errors, with reason:
  /// - [EmailAccountLoginExceptionReason.invalidCredentials] if the email or
  ///   password is incorrect.
  /// - [EmailAccountLoginExceptionReason.tooManyAttempts] if there have been
  ///   too many failed login attempts.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _i3.Future<_i4.AuthSuccess> login({
    required String email,
    required String password,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'emailIdp',
    'login',
    {
      'email': email,
      'password': password,
    },
  );

  /// Starts the registration for a new user account with an email-based login
  /// associated to it.
  ///
  /// Upon successful completion of this method, an email will have been
  /// sent to [email] with a verification link, which the user must open to
  /// complete the registration.
  ///
  /// Always returns a account request ID, which can be used to complete the
  /// registration. If the email is already registered, the returned ID will not
  /// be valid.
  @override
  _i3.Future<_i2.UuidValue> startRegistration({required String email}) =>
      caller.callServerEndpoint<_i2.UuidValue>(
        'emailIdp',
        'startRegistration',
        {'email': email},
      );

  /// Verifies an account request code and returns a token
  /// that can be used to complete the account creation.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if no request exists
  ///   for the given [accountRequestId] or [verificationCode] is invalid.
  @override
  _i3.Future<String> verifyRegistrationCode({
    required _i2.UuidValue accountRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyRegistrationCode',
    {
      'accountRequestId': accountRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a new account registration, creating a new auth user with a
  /// profile and attaching the given email account to it.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if the [registrationToken]
  ///   is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  ///
  /// Returns a session for the newly created user.
  @override
  _i3.Future<_i4.AuthSuccess> finishRegistration({
    required String registrationToken,
    required String password,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'emailIdp',
    'finishRegistration',
    {
      'registrationToken': registrationToken,
      'password': password,
    },
  );

  /// Requests a password reset for [email].
  ///
  /// If the email address is registered, an email with reset instructions will
  /// be send out. If the email is unknown, this method will have no effect.
  ///
  /// Always returns a password reset request ID, which can be used to complete
  /// the reset. If the email is not registered, the returned ID will not be
  /// valid.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to request a password reset.
  ///
  @override
  _i3.Future<_i2.UuidValue> startPasswordReset({required String email}) =>
      caller.callServerEndpoint<_i2.UuidValue>(
        'emailIdp',
        'startPasswordReset',
        {'email': email},
      );

  /// Verifies a password reset code and returns a finishPasswordResetToken
  /// that can be used to finish the password reset.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to verify the password reset.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// If multiple steps are required to complete the password reset, this endpoint
  /// should be overridden to return credentials for the next step instead
  /// of the credentials for setting the password.
  @override
  _i3.Future<String> verifyPasswordResetCode({
    required _i2.UuidValue passwordResetRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyPasswordResetCode',
    {
      'passwordResetRequestId': passwordResetRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a password reset request by setting a new password.
  ///
  /// The [verificationCode] returned from [verifyPasswordResetCode] is used to
  /// validate the password reset request.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.policyViolation] if the new
  ///   password does not comply with the password policy.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _i3.Future<void> finishPasswordReset({
    required String finishPasswordResetToken,
    required String newPassword,
  }) => caller.callServerEndpoint<void>(
    'emailIdp',
    'finishPasswordReset',
    {
      'finishPasswordResetToken': finishPasswordResetToken,
      'newPassword': newPassword,
    },
  );
}

/// By extending [RefreshJwtTokensEndpoint], the JWT token refresh endpoint
/// is made available on the server and enables automatic token refresh on the client.
/// {@category Endpoint}
class EndpointJwtRefresh extends _i4.EndpointRefreshJwtTokens {
  EndpointJwtRefresh(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'jwtRefresh';

  /// Creates a new token pair for the given [refreshToken].
  ///
  /// Can throw the following exceptions:
  /// -[RefreshTokenMalformedException]: refresh token is malformed and could
  ///   not be parsed. Not expected to happen for tokens issued by the server.
  /// -[RefreshTokenNotFoundException]: refresh token is unknown to the server.
  ///   Either the token was deleted or generated by a different server.
  /// -[RefreshTokenExpiredException]: refresh token has expired. Will happen
  ///   only if it has not been used within configured `refreshTokenLifetime`.
  /// -[RefreshTokenInvalidSecretException]: refresh token is incorrect, meaning
  ///   it does not refer to the current secret refresh token. This indicates
  ///   either a malfunctioning client or a malicious attempt by someone who has
  ///   obtained the refresh token. In this case the underlying refresh token
  ///   will be deleted, and access to it will expire fully when the last access
  ///   token is elapsed.
  ///
  /// This endpoint is unauthenticated, meaning the client won't include any
  /// authentication information with the call.
  @override
  _i3.Future<_i4.AuthSuccess> refreshAccessToken({
    required String refreshToken,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'jwtRefresh',
    'refreshAccessToken',
    {'refreshToken': refreshToken},
    authenticated: false,
  );
}

/// Endpoint for managing channels and notes with real-time updates.
/// {@category Endpoint}
class EndpointChat extends _i2.EndpointRef {
  EndpointChat(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'chat';

  /// Returns all channels sorted by last modified (newest first).
  /// Pinned channels appear at the top, also sorted by last modified.
  _i3.Future<List<_i5.Channel>> getChannels() =>
      caller.callServerEndpoint<List<_i5.Channel>>(
        'chat',
        'getChannels',
        {},
      );

  /// Returns notes for a channel with cursor-based pagination.
  /// Uses [beforeId] for loading older messages (scroll up behavior).
  /// Efficiently loads attachments with LEFT JOIN to prevent N+1 queries.
  _i3.Future<List<_i6.Note>> getNotes(
    int channelId, {
    int? beforeId,
    required int limit,
  }) => caller.callServerEndpoint<List<_i6.Note>>(
    'chat',
    'getNotes',
    {
      'channelId': channelId,
      'beforeId': beforeId,
      'limit': limit,
    },
  );

  /// Creates a new channel and broadcasts the event.
  _i3.Future<_i5.Channel> createChannel(
    String name, {
    required String emoji,
  }) => caller.callServerEndpoint<_i5.Channel>(
    'chat',
    'createChannel',
    {
      'name': name,
      'emoji': emoji,
    },
  );

  /// Updates a channel's name, emoji, or pinned status.
  _i3.Future<_i5.Channel> updateChannel(
    int id, {
    String? name,
    String? emoji,
    bool? pinned,
  }) => caller.callServerEndpoint<_i5.Channel>(
    'chat',
    'updateChannel',
    {
      'id': id,
      'name': name,
      'emoji': emoji,
      'pinned': pinned,
    },
  );

  /// Deletes a channel and cascades to delete its notes and media files.
  /// Rejects if it's the last remaining channel.
  _i3.Future<void> deleteChannel(int id) => caller.callServerEndpoint<void>(
    'chat',
    'deleteChannel',
    {'id': id},
  );

  /// Creates a new note and broadcasts the event.
  /// Also updates the channel's updatedAt timestamp.
  /// Asynchronously fetches link preview if URL is detected in content.
  _i3.Future<_i6.Note> createNote(
    int channelId,
    String content,
  ) => caller.callServerEndpoint<_i6.Note>(
    'chat',
    'createNote',
    {
      'channelId': channelId,
      'content': content,
    },
  );

  /// Updates a note's content (last-write-wins strategy).
  _i3.Future<_i6.Note> updateNote(
    int id,
    String content,
  ) => caller.callServerEndpoint<_i6.Note>(
    'chat',
    'updateNote',
    {
      'id': id,
      'content': content,
    },
  );

  /// Deletes a note, its media attachments, and broadcasts the event.
  _i3.Future<void> deleteNote(int id) => caller.callServerEndpoint<void>(
    'chat',
    'deleteNote',
    {'id': id},
  );

  /// Streaming endpoint for real-time updates.
  /// Subscribes to all chat events (channel and note changes).
  _i3.Stream<_i7.ChatEvent> chat() => caller
      .callStreamingServerEndpoint<_i3.Stream<_i7.ChatEvent>, _i7.ChatEvent>(
        'chat',
        'chat',
        {},
        {},
      );
}

/// This is an example endpoint that returns a greeting message through
/// its [hello] method.
/// {@category Endpoint}
class EndpointGreeting extends _i2.EndpointRef {
  EndpointGreeting(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'greeting';

  /// Returns a personalized greeting message: "Hello {name}".
  _i3.Future<_i8.Greeting> hello(String name) =>
      caller.callServerEndpoint<_i8.Greeting>(
        'greeting',
        'hello',
        {'name': name},
      );
}

/// Endpoint for media upload and management.
/// {@category Endpoint}
class EndpointMedia extends _i2.EndpointRef {
  EndpointMedia(_i2.EndpointCaller caller) : super(caller);

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
  _i3.Future<_i6.Note> uploadMediaAndCreateNote(
    int channelId,
    String noteContent,
    List<int> fileBytes,
    String originalFilename,
    String mimeType,
    bool compress,
  ) => caller.callServerEndpoint<_i6.Note>(
    'media',
    'uploadMediaAndCreateNote',
    {
      'channelId': channelId,
      'noteContent': noteContent,
      'fileBytes': fileBytes,
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
  _i3.Future<_i9.MediaAttachment> uploadMedia(
    int channelId,
    String originalFilename,
    String mimeType,
    bool compress,
    _i3.Stream<List<int>> fileStream,
  ) =>
      caller.callStreamingServerEndpoint<
        _i3.Future<_i9.MediaAttachment>,
        _i9.MediaAttachment
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
  _i3.Future<void> deleteAttachment(int attachmentId) =>
      caller.callServerEndpoint<void>(
        'media',
        'deleteAttachment',
        {'attachmentId': attachmentId},
      );
}

class Modules {
  Modules(Client client) {
    serverpod_auth_idp = _i1.Caller(client);
    serverpod_auth_core = _i4.Caller(client);
  }

  late final _i1.Caller serverpod_auth_idp;

  late final _i4.Caller serverpod_auth_core;
}

class Client extends _i2.ServerpodClientShared {
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
      _i2.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_i2.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
  }) : super(
         host,
         _i10.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
       ) {
    emailIdp = EndpointEmailIdp(this);
    jwtRefresh = EndpointJwtRefresh(this);
    chat = EndpointChat(this);
    greeting = EndpointGreeting(this);
    media = EndpointMedia(this);
    modules = Modules(this);
  }

  late final EndpointEmailIdp emailIdp;

  late final EndpointJwtRefresh jwtRefresh;

  late final EndpointChat chat;

  late final EndpointGreeting greeting;

  late final EndpointMedia media;

  late final Modules modules;

  @override
  Map<String, _i2.EndpointRef> get endpointRefLookup => {
    'emailIdp': emailIdp,
    'jwtRefresh': jwtRefresh,
    'chat': chat,
    'greeting': greeting,
    'media': media,
  };

  @override
  Map<String, _i2.ModuleEndpointCaller> get moduleLookup => {
    'serverpod_auth_idp': modules.serverpod_auth_idp,
    'serverpod_auth_core': modules.serverpod_auth_core,
  };
}
