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
import 'package:memoka_client/src/protocol/chat/channel.dart' as _i8;
import 'package:memoka_client/src/protocol/chat/note.dart' as _i9;
import 'package:memoka_client/src/protocol/chat/archive_item.dart' as _i10;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i11;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i12;
export 'chat/archive_item.dart';
export 'chat/channel.dart';
export 'chat/chat_event.dart';
export 'chat/link_preview.dart';
export 'chat/note.dart';
export 'media/media_attachment.dart';
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
    if (t == List<_i8.Channel>) {
      return (data as List).map((e) => deserialize<_i8.Channel>(e)).toList()
          as T;
    }
    if (t == List<_i9.Note>) {
      return (data as List).map((e) => deserialize<_i9.Note>(e)).toList() as T;
    }
    if (t == List<_i10.ArchiveItem>) {
      return (data as List)
              .map((e) => deserialize<_i10.ArchiveItem>(e))
              .toList()
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    try {
      return _i11.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i12.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
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
    }
    className = _i11.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    className = _i12.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_core.$className';
    }
    if (data is List<int>) {
      return 'List<int>';
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
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i11.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i12.Protocol().deserializeByClassName(data);
    }
    if (dataClassName == 'List<int>') {
      return deserialize<List<int>>(data['data']);
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
    try {
      return _i11.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i12.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
