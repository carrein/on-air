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
import 'chat/archive_item.dart' as _i2;
import 'chat/channel.dart' as _i3;
import 'chat/chat_event.dart' as _i4;
import 'chat/link_preview.dart' as _i5;
import 'chat/note.dart' as _i6;
import 'media/media_attachment.dart' as _i7;
import 'sync/sync_change.dart' as _i8;
import 'sync/sync_pull_response.dart' as _i9;
import 'sync/sync_push_response.dart' as _i10;
import 'sync/sync_result.dart' as _i11;
import 'package:memoka_client/src/protocol/chat/channel.dart' as _i12;
import 'package:memoka_client/src/protocol/chat/note.dart' as _i13;
import 'package:memoka_client/src/protocol/chat/archive_item.dart' as _i14;
import 'package:memoka_client/src/protocol/sync/sync_change.dart' as _i15;
export 'chat/archive_item.dart';
export 'chat/channel.dart';
export 'chat/chat_event.dart';
export 'chat/link_preview.dart';
export 'chat/note.dart';
export 'media/media_attachment.dart';
export 'sync/sync_change.dart';
export 'sync/sync_pull_response.dart';
export 'sync/sync_push_response.dart';
export 'sync/sync_result.dart';
export 'client.dart';

class Protocol extends _i1.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on FormatException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i2.ArchiveItem) {
      return _i2.ArchiveItem.fromJson(data) as T;
    }
    if (t == _i3.Channel) {
      return _i3.Channel.fromJson(data) as T;
    }
    if (t == _i4.ChatEvent) {
      return _i4.ChatEvent.fromJson(data) as T;
    }
    if (t == _i5.LinkPreview) {
      return _i5.LinkPreview.fromJson(data) as T;
    }
    if (t == _i6.Note) {
      return _i6.Note.fromJson(data) as T;
    }
    if (t == _i7.MediaAttachment) {
      return _i7.MediaAttachment.fromJson(data) as T;
    }
    if (t == _i8.SyncChange) {
      return _i8.SyncChange.fromJson(data) as T;
    }
    if (t == _i9.SyncPullResponse) {
      return _i9.SyncPullResponse.fromJson(data) as T;
    }
    if (t == _i10.SyncPushResponse) {
      return _i10.SyncPushResponse.fromJson(data) as T;
    }
    if (t == _i11.SyncResult) {
      return _i11.SyncResult.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.ArchiveItem?>()) {
      return (data != null ? _i2.ArchiveItem.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.Channel?>()) {
      return (data != null ? _i3.Channel.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.ChatEvent?>()) {
      return (data != null ? _i4.ChatEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.LinkPreview?>()) {
      return (data != null ? _i5.LinkPreview.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.Note?>()) {
      return (data != null ? _i6.Note.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.MediaAttachment?>()) {
      return (data != null ? _i7.MediaAttachment.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.SyncChange?>()) {
      return (data != null ? _i8.SyncChange.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.SyncPullResponse?>()) {
      return (data != null ? _i9.SyncPullResponse.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.SyncPushResponse?>()) {
      return (data != null ? _i10.SyncPushResponse.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.SyncResult?>()) {
      return (data != null ? _i11.SyncResult.fromJson(data) : null) as T;
    }
    if (t == List<_i7.MediaAttachment>) {
      return (data as List)
              .map((e) => deserialize<_i7.MediaAttachment>(e))
              .toList()
          as T;
    }
    if (t == _i1.getType<List<_i7.MediaAttachment>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_i7.MediaAttachment>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_i3.Channel>) {
      return (data as List).map((e) => deserialize<_i3.Channel>(e)).toList()
          as T;
    }
    if (t == List<_i6.Note>) {
      return (data as List).map((e) => deserialize<_i6.Note>(e)).toList() as T;
    }
    if (t == List<_i11.SyncResult>) {
      return (data as List).map((e) => deserialize<_i11.SyncResult>(e)).toList()
          as T;
    }
    if (t == List<_i12.Channel>) {
      return (data as List).map((e) => deserialize<_i12.Channel>(e)).toList()
          as T;
    }
    if (t == List<_i13.Note>) {
      return (data as List).map((e) => deserialize<_i13.Note>(e)).toList() as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == List<_i14.ArchiveItem>) {
      return (data as List)
              .map((e) => deserialize<_i14.ArchiveItem>(e))
              .toList()
          as T;
    }
    if (t == List<_i15.SyncChange>) {
      return (data as List).map((e) => deserialize<_i15.SyncChange>(e)).toList()
          as T;
    }
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.ArchiveItem => 'ArchiveItem',
      _i3.Channel => 'Channel',
      _i4.ChatEvent => 'ChatEvent',
      _i5.LinkPreview => 'LinkPreview',
      _i6.Note => 'Note',
      _i7.MediaAttachment => 'MediaAttachment',
      _i8.SyncChange => 'SyncChange',
      _i9.SyncPullResponse => 'SyncPullResponse',
      _i10.SyncPushResponse => 'SyncPushResponse',
      _i11.SyncResult => 'SyncResult',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('memoka.', '');
    }

    switch (data) {
      case _i2.ArchiveItem():
        return 'ArchiveItem';
      case _i3.Channel():
        return 'Channel';
      case _i4.ChatEvent():
        return 'ChatEvent';
      case _i5.LinkPreview():
        return 'LinkPreview';
      case _i6.Note():
        return 'Note';
      case _i7.MediaAttachment():
        return 'MediaAttachment';
      case _i8.SyncChange():
        return 'SyncChange';
      case _i9.SyncPullResponse():
        return 'SyncPullResponse';
      case _i10.SyncPushResponse():
        return 'SyncPushResponse';
      case _i11.SyncResult():
        return 'SyncResult';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'ArchiveItem') {
      return deserialize<_i2.ArchiveItem>(data['data']);
    }
    if (dataClassName == 'Channel') {
      return deserialize<_i3.Channel>(data['data']);
    }
    if (dataClassName == 'ChatEvent') {
      return deserialize<_i4.ChatEvent>(data['data']);
    }
    if (dataClassName == 'LinkPreview') {
      return deserialize<_i5.LinkPreview>(data['data']);
    }
    if (dataClassName == 'Note') {
      return deserialize<_i6.Note>(data['data']);
    }
    if (dataClassName == 'MediaAttachment') {
      return deserialize<_i7.MediaAttachment>(data['data']);
    }
    if (dataClassName == 'SyncChange') {
      return deserialize<_i8.SyncChange>(data['data']);
    }
    if (dataClassName == 'SyncPullResponse') {
      return deserialize<_i9.SyncPullResponse>(data['data']);
    }
    if (dataClassName == 'SyncPushResponse') {
      return deserialize<_i10.SyncPushResponse>(data['data']);
    }
    if (dataClassName == 'SyncResult') {
      return deserialize<_i11.SyncResult>(data['data']);
    }
    return super.deserializeByClassName(data);
  }

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
