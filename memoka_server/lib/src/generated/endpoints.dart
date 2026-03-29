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
import '../pagewatch/page_watch_endpoint.dart' as _i4;
import '../reminder/reminder_endpoint.dart' as _i5;
import '../search/search_endpoint.dart' as _i6;
import '../settings/settings_endpoint.dart' as _i7;
import '../sync/sync_endpoint.dart' as _i8;
import 'package:memoka_server/src/generated/settings/app_settings.dart' as _i9;
import 'package:memoka_server/src/generated/sync/sync_change.dart' as _i10;

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
      'pageWatch': _i4.PageWatchEndpoint()
        ..initialize(
          server,
          'pageWatch',
          null,
        ),
      'reminder': _i5.ReminderEndpoint()
        ..initialize(
          server,
          'reminder',
          null,
        ),
      'search': _i6.SearchEndpoint()
        ..initialize(
          server,
          'search',
          null,
        ),
      'settings': _i7.SettingsEndpoint()
        ..initialize(
          server,
          'settings',
          null,
        ),
      'sync': _i8.SyncEndpoint()
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
        'combineNotes': _i1.MethodConnector(
          name: 'combineNotes',
          params: {
            'channelId': _i1.ParameterDescription(
              name: 'channelId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'noteIds': _i1.ParameterDescription(
              name: 'noteIds',
              type: _i1.getType<List<int>>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['chat'] as _i2.ChatEndpoint).combineNotes(
                session,
                params['channelId'],
                params['noteIds'],
              ),
        ),
        'explodeNote': _i1.MethodConnector(
          name: 'explodeNote',
          params: {
            'noteId': _i1.ParameterDescription(
              name: 'noteId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['chat'] as _i2.ChatEndpoint).explodeNote(
                session,
                params['noteId'],
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
    connectors['pageWatch'] = _i1.EndpointConnector(
      name: 'pageWatch',
      endpoint: endpoints['pageWatch']!,
      methodConnectors: {
        'createWatch': _i1.MethodConnector(
          name: 'createWatch',
          params: {
            'noteId': _i1.ParameterDescription(
              name: 'noteId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['pageWatch'] as _i4.PageWatchEndpoint).createWatch(
                    session,
                    params['noteId'],
                  ),
        ),
        'deleteWatch': _i1.MethodConnector(
          name: 'deleteWatch',
          params: {
            'noteId': _i1.ParameterDescription(
              name: 'noteId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['pageWatch'] as _i4.PageWatchEndpoint).deleteWatch(
                    session,
                    params['noteId'],
                  ),
        ),
        'getWatch': _i1.MethodConnector(
          name: 'getWatch',
          params: {
            'noteId': _i1.ParameterDescription(
              name: 'noteId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['pageWatch'] as _i4.PageWatchEndpoint).getWatch(
                    session,
                    params['noteId'],
                  ),
        ),
        'getWatches': _i1.MethodConnector(
          name: 'getWatches',
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
              ) async =>
                  (endpoints['pageWatch'] as _i4.PageWatchEndpoint).getWatches(
                    session,
                    params['channelId'],
                  ),
        ),
        'acknowledgeChange': _i1.MethodConnector(
          name: 'acknowledgeChange',
          params: {
            'noteId': _i1.ParameterDescription(
              name: 'noteId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['pageWatch'] as _i4.PageWatchEndpoint)
                  .acknowledgeChange(
                    session,
                    params['noteId'],
                  ),
        ),
      },
    );
    connectors['reminder'] = _i1.EndpointConnector(
      name: 'reminder',
      endpoint: endpoints['reminder']!,
      methodConnectors: {
        'createReminder': _i1.MethodConnector(
          name: 'createReminder',
          params: {
            'noteId': _i1.ParameterDescription(
              name: 'noteId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'scheduledAt': _i1.ParameterDescription(
              name: 'scheduledAt',
              type: _i1.getType<DateTime>(),
              nullable: false,
            ),
            'recurrenceRule': _i1.ParameterDescription(
              name: 'recurrenceRule',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'recurrenceEndAt': _i1.ParameterDescription(
              name: 'recurrenceEndAt',
              type: _i1.getType<DateTime?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['reminder'] as _i5.ReminderEndpoint)
                  .createReminder(
                    session,
                    params['noteId'],
                    params['scheduledAt'],
                    recurrenceRule: params['recurrenceRule'],
                    recurrenceEndAt: params['recurrenceEndAt'],
                  ),
        ),
        'deleteReminder': _i1.MethodConnector(
          name: 'deleteReminder',
          params: {
            'noteId': _i1.ParameterDescription(
              name: 'noteId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['reminder'] as _i5.ReminderEndpoint)
                  .deleteReminder(
                    session,
                    params['noteId'],
                  ),
        ),
        'getReminder': _i1.MethodConnector(
          name: 'getReminder',
          params: {
            'noteId': _i1.ParameterDescription(
              name: 'noteId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['reminder'] as _i5.ReminderEndpoint).getReminder(
                    session,
                    params['noteId'],
                  ),
        ),
        'updateReminder': _i1.MethodConnector(
          name: 'updateReminder',
          params: {
            'noteId': _i1.ParameterDescription(
              name: 'noteId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'scheduledAt': _i1.ParameterDescription(
              name: 'scheduledAt',
              type: _i1.getType<DateTime>(),
              nullable: false,
            ),
            'recurrenceRule': _i1.ParameterDescription(
              name: 'recurrenceRule',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
            'recurrenceEndAt': _i1.ParameterDescription(
              name: 'recurrenceEndAt',
              type: _i1.getType<DateTime?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['reminder'] as _i5.ReminderEndpoint)
                  .updateReminder(
                    session,
                    params['noteId'],
                    params['scheduledAt'],
                    recurrenceRule: params['recurrenceRule'],
                    recurrenceEndAt: params['recurrenceEndAt'],
                  ),
        ),
        'getReminders': _i1.MethodConnector(
          name: 'getReminders',
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
              ) async =>
                  (endpoints['reminder'] as _i5.ReminderEndpoint).getReminders(
                    session,
                    params['channelId'],
                  ),
        ),
        'getFiredReminders': _i1.MethodConnector(
          name: 'getFiredReminders',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['reminder'] as _i5.ReminderEndpoint)
                  .getFiredReminders(session),
        ),
        'getActiveReminders': _i1.MethodConnector(
          name: 'getActiveReminders',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['reminder'] as _i5.ReminderEndpoint)
                  .getActiveReminders(session),
        ),
        'acknowledgeReminder': _i1.MethodConnector(
          name: 'acknowledgeReminder',
          params: {
            'noteId': _i1.ParameterDescription(
              name: 'noteId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['reminder'] as _i5.ReminderEndpoint)
                  .acknowledgeReminder(
                    session,
                    params['noteId'],
                  ),
        ),
      },
    );
    connectors['search'] = _i1.EndpointConnector(
      name: 'search',
      endpoint: endpoints['search']!,
      methodConnectors: {
        'searchNotes': _i1.MethodConnector(
          name: 'searchNotes',
          params: {
            'query': _i1.ParameterDescription(
              name: 'query',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'channelId': _i1.ParameterDescription(
              name: 'channelId',
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
              ) async =>
                  (endpoints['search'] as _i6.SearchEndpoint).searchNotes(
                    session,
                    params['query'],
                    channelId: params['channelId'],
                    limit: params['limit'],
                  ),
        ),
        'getNotesAroundId': _i1.MethodConnector(
          name: 'getNotesAroundId',
          params: {
            'channelId': _i1.ParameterDescription(
              name: 'channelId',
              type: _i1.getType<int>(),
              nullable: false,
            ),
            'noteId': _i1.ParameterDescription(
              name: 'noteId',
              type: _i1.getType<int>(),
              nullable: false,
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
              ) async =>
                  (endpoints['search'] as _i6.SearchEndpoint).getNotesAroundId(
                    session,
                    params['channelId'],
                    params['noteId'],
                    limit: params['limit'],
                  ),
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
              ) async => (endpoints['settings'] as _i7.SettingsEndpoint)
                  .getSettings(session),
        ),
        'updateSettings': _i1.MethodConnector(
          name: 'updateSettings',
          params: {
            'settings': _i1.ParameterDescription(
              name: 'settings',
              type: _i1.getType<_i9.AppSettings>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['settings'] as _i7.SettingsEndpoint)
                  .updateSettings(
                    session,
                    params['settings'],
                  ),
        ),
        'startThumbnailRegen': _i1.MethodConnector(
          name: 'startThumbnailRegen',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['settings'] as _i7.SettingsEndpoint)
                  .startThumbnailRegen(session),
        ),
        'getRegenProgress': _i1.MethodConnector(
          name: 'getRegenProgress',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['settings'] as _i7.SettingsEndpoint)
                  .getRegenProgress(session),
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
              ) async => (endpoints['sync'] as _i8.SyncEndpoint).syncPull(
                session,
                params['sinceVersion'],
              ),
        ),
        'syncPush': _i1.MethodConnector(
          name: 'syncPush',
          params: {
            'changes': _i1.ParameterDescription(
              name: 'changes',
              type: _i1.getType<List<_i10.SyncChange>>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['sync'] as _i8.SyncEndpoint).syncPush(
                session,
                params['changes'],
              ),
        ),
      },
    );
  }
}
