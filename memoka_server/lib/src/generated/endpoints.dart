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
import 'package:serverpod/serverpod.dart' as _i1;
import '../chat/chat_endpoint.dart' as _i2;
import '../health_endpoint.dart' as _i3;
import '../settings/settings_endpoint.dart' as _i4;
import '../sync/sync_endpoint.dart' as _i5;
import 'package:memoka_server/src/generated/settings/app_settings.dart' as _i6;
import 'package:memoka_server/src/generated/sync/sync_change.dart' as _i7;

class Endpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'chat': _i2.ChatEndpoint()
        ..initialize(
          server,
          'chat',
          null,
        ),
      'health': _i3.HealthEndpoint()
        ..initialize(
          server,
          'health',
          null,
        ),
      'settings': _i4.SettingsEndpoint()
        ..initialize(
          server,
          'settings',
          null,
        ),
      'sync': _i5.SyncEndpoint()
        ..initialize(
          server,
          'sync',
          null,
        ),
    };
    connectors['chat'] = _i1.EndpointConnector(
      name: 'chat',
      endpoint: endpoints['chat']!,
      methodConnectors: {
        'getChannels': _i1.MethodConnector(
          name: 'getChannels',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['chat'] as _i2.ChatEndpoint).getChannels(session),
        ),
        'getNotes': _i1.MethodConnector(
          name: 'getNotes',
          params: {
            'channelId': _i1.ParameterDescription(
              name: 'channelId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'beforeId': _i1.ParameterDescription(
              name: 'beforeId',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['chat'] as _i2.ChatEndpoint).getNotes(
                session,
                params['channelId'],
                beforeId: params['beforeId'],
                limit: params['limit'],
              ),
        ),
        'createChannel': _i1.MethodConnector(
          name: 'createChannel',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'emoji': _i1.ParameterDescription(
              name: 'emoji',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['chat'] as _i2.ChatEndpoint).createChannel(
                session,
                params['name'],
                emoji: params['emoji'],
              ),
        ),
        'updateChannel': _i1.MethodConnector(
          name: 'updateChannel',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'emoji': _i1.ParameterDescription(
              name: 'emoji',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'pinned': _i1.ParameterDescription(
              name: 'pinned',
              type: _i1.getType<bool?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['chat'] as _i2.ChatEndpoint).updateChannel(
                session,
                params['id'],
                name: params['name'],
                emoji: params['emoji'],
                pinned: params['pinned'],
              ),
        ),
        'reorderChannels': _i1.MethodConnector(
          name: 'reorderChannels',
          params: {
            'channelIds': _i1.ParameterDescription(
              name: 'channelIds',
              type: _i1.getType<List<int>>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['chat'] as _i2.ChatEndpoint).reorderChannels(
                    session,
                    params['channelIds'],
                  ),
        ),
        'deleteChannel': _i1.MethodConnector(
          name: 'deleteChannel',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['chat'] as _i2.ChatEndpoint).deleteChannel(
                session,
                params['id'],
              ),
        ),
        'createNote': _i1.MethodConnector(
          name: 'createNote',
          params: {
            'channelId': _i1.ParameterDescription(
              name: 'channelId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'content': _i1.ParameterDescription(
              name: 'content',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'clientMutationId': _i1.ParameterDescription(
              name: 'clientMutationId',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['chat'] as _i2.ChatEndpoint).createNote(
                session,
                params['channelId'],
                params['content'],
                clientMutationId: params['clientMutationId'],
              ),
        ),
        'updateNote': _i1.MethodConnector(
          name: 'updateNote',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'content': _i1.ParameterDescription(
              name: 'content',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['chat'] as _i2.ChatEndpoint).updateNote(
                session,
                params['id'],
                params['content'],
              ),
        ),
        'deleteNote': _i1.MethodConnector(
          name: 'deleteNote',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['chat'] as _i2.ChatEndpoint).deleteNote(
                session,
                params['id'],
              ),
        ),
        'restoreNote': _i1.MethodConnector(
          name: 'restoreNote',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['chat'] as _i2.ChatEndpoint).restoreNote(
                session,
                params['id'],
              ),
        ),
        'archiveChannel': _i1.MethodConnector(
          name: 'archiveChannel',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['chat'] as _i2.ChatEndpoint).archiveChannel(
                session,
                params['id'],
              ),
        ),
        'restoreChannel': _i1.MethodConnector(
          name: 'restoreChannel',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['chat'] as _i2.ChatEndpoint).restoreChannel(
                session,
                params['id'],
              ),
        ),
        'getArchiveItems': _i1.MethodConnector(
          name: 'getArchiveItems',
          params: {
            'limit': _i1.ParameterDescription(
              name: 'limit',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['chat'] as _i2.ChatEndpoint).getArchiveItems(
                    session,
                    limit: params['limit'],
                  ),
        ),
        'getArchivedChannelNoteCount': _i1.MethodConnector(
          name: 'getArchivedChannelNoteCount',
          params: {
            'channelId': _i1.ParameterDescription(
              name: 'channelId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['chat'] as _i2.ChatEndpoint)
                  .getArchivedChannelNoteCount(
                    session,
                    params['channelId'],
                  ),
        ),
        'chat': _i1.MethodStreamConnector(
          name: 'chat',
          params: {},
          streamParams: {},
          returnType: _i1.MethodStreamReturnType.streamType,
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['chat'] as _i2.ChatEndpoint).chat(session),
        ),
      },
    );
    connectors['health'] = _i1.EndpointConnector(
      name: 'health',
      endpoint: endpoints['health']!,
      methodConnectors: {
        'ping': _i1.MethodConnector(
          name: 'ping',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['health'] as _i3.HealthEndpoint).ping(session),
        ),
      },
    );
    connectors['settings'] = _i1.EndpointConnector(
      name: 'settings',
      endpoint: endpoints['settings']!,
      methodConnectors: {
        'getSettings': _i1.MethodConnector(
          name: 'getSettings',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['settings'] as _i4.SettingsEndpoint)
                  .getSettings(session),
        ),
        'updateSettings': _i1.MethodConnector(
          name: 'updateSettings',
          params: {
            'settings': _i1.ParameterDescription(
              name: 'settings',
              type: _i1.getType<_i6.AppSettings>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['settings'] as _i4.SettingsEndpoint)
                  .updateSettings(
                    session,
                    params['settings'],
                  ),
        ),
      },
    );
    connectors['sync'] = _i1.EndpointConnector(
      name: 'sync',
      endpoint: endpoints['sync']!,
      methodConnectors: {
        'syncPull': _i1.MethodConnector(
          name: 'syncPull',
          params: {
            'sinceVersion': _i1.ParameterDescription(
              name: 'sinceVersion',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sync'] as _i5.SyncEndpoint).syncPull(
                session,
                params['sinceVersion'],
              ),
        ),
        'syncPush': _i1.MethodConnector(
          name: 'syncPush',
          params: {
            'changes': _i1.ParameterDescription(
              name: 'changes',
              type: _i1.getType<List<_i7.SyncChange>>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sync'] as _i5.SyncEndpoint).syncPush(
                session,
                params['changes'],
              ),
        ),
      },
    );
  }
}
