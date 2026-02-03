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

/// A media attachment (image) associated with a note.
abstract class MediaAttachment implements _i1.SerializableModel {
  MediaAttachment._({
    this.id,
    required this.noteId,
    required this.channelId,
    required this.filePath,
    required this.originalFilename,
    required this.mimeType,
    required this.fileSize,
    this.width,
    this.height,
    this.thumbnailPath,
    bool? compressed,
    bool? animated,
    this.contentHash,
    DateTime? uploadedAt,
  }) : compressed = compressed ?? false,
       animated = animated ?? false,
       uploadedAt = uploadedAt ?? DateTime.now();

  factory MediaAttachment({
    int? id,
    required int noteId,
    required int channelId,
    required String filePath,
    required String originalFilename,
    required String mimeType,
    required int fileSize,
    int? width,
    int? height,
    String? thumbnailPath,
    bool? compressed,
    bool? animated,
    String? contentHash,
    DateTime? uploadedAt,
  }) = _MediaAttachmentImpl;

  factory MediaAttachment.fromJson(Map<String, dynamic> jsonSerialization) {
    return MediaAttachment(
      id: jsonSerialization['id'] as int?,
      noteId: jsonSerialization['noteId'] as int,
      channelId: jsonSerialization['channelId'] as int,
      filePath: jsonSerialization['filePath'] as String,
      originalFilename: jsonSerialization['originalFilename'] as String,
      mimeType: jsonSerialization['mimeType'] as String,
      fileSize: jsonSerialization['fileSize'] as int,
      width: jsonSerialization['width'] as int?,
      height: jsonSerialization['height'] as int?,
      thumbnailPath: jsonSerialization['thumbnailPath'] as String?,
      compressed: jsonSerialization['compressed'] as bool?,
      animated: jsonSerialization['animated'] as bool?,
      contentHash: jsonSerialization['contentHash'] as String?,
      uploadedAt: jsonSerialization['uploadedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['uploadedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// The ID of the note this attachment belongs to.
  int noteId;

  /// The ID of the channel this attachment belongs to (for efficient querying).
  int channelId;

  /// The file path (UUID-based filename with extension).
  String filePath;

  /// The original filename provided by the user.
  String originalFilename;

  /// The MIME type of the file.
  String mimeType;

  /// The file size in bytes.
  int fileSize;

  /// The width of the image in pixels.
  int? width;

  /// The height of the image in pixels.
  int? height;

  /// The path to the thumbnail image.
  String? thumbnailPath;

  /// Whether the image was compressed.
  bool compressed;

  /// Whether the image is animated (GIF).
  bool animated;

  /// Content hash (first 8 chars of SHA-256) for cache busting.
  String? contentHash;

  /// When the attachment was uploaded.
  DateTime uploadedAt;

  /// Returns a shallow copy of this [MediaAttachment]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MediaAttachment copyWith({
    int? id,
    int? noteId,
    int? channelId,
    String? filePath,
    String? originalFilename,
    String? mimeType,
    int? fileSize,
    int? width,
    int? height,
    String? thumbnailPath,
    bool? compressed,
    bool? animated,
    String? contentHash,
    DateTime? uploadedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MediaAttachment',
      if (id != null) 'id': id,
      'noteId': noteId,
      'channelId': channelId,
      'filePath': filePath,
      'originalFilename': originalFilename,
      'mimeType': mimeType,
      'fileSize': fileSize,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (thumbnailPath != null) 'thumbnailPath': thumbnailPath,
      'compressed': compressed,
      'animated': animated,
      if (contentHash != null) 'contentHash': contentHash,
      'uploadedAt': uploadedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MediaAttachmentImpl extends MediaAttachment {
  _MediaAttachmentImpl({
    int? id,
    required int noteId,
    required int channelId,
    required String filePath,
    required String originalFilename,
    required String mimeType,
    required int fileSize,
    int? width,
    int? height,
    String? thumbnailPath,
    bool? compressed,
    bool? animated,
    String? contentHash,
    DateTime? uploadedAt,
  }) : super._(
         id: id,
         noteId: noteId,
         channelId: channelId,
         filePath: filePath,
         originalFilename: originalFilename,
         mimeType: mimeType,
         fileSize: fileSize,
         width: width,
         height: height,
         thumbnailPath: thumbnailPath,
         compressed: compressed,
         animated: animated,
         contentHash: contentHash,
         uploadedAt: uploadedAt,
       );

  /// Returns a shallow copy of this [MediaAttachment]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MediaAttachment copyWith({
    Object? id = _Undefined,
    int? noteId,
    int? channelId,
    String? filePath,
    String? originalFilename,
    String? mimeType,
    int? fileSize,
    Object? width = _Undefined,
    Object? height = _Undefined,
    Object? thumbnailPath = _Undefined,
    bool? compressed,
    bool? animated,
    Object? contentHash = _Undefined,
    DateTime? uploadedAt,
  }) {
    return MediaAttachment(
      id: id is int? ? id : this.id,
      noteId: noteId ?? this.noteId,
      channelId: channelId ?? this.channelId,
      filePath: filePath ?? this.filePath,
      originalFilename: originalFilename ?? this.originalFilename,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      width: width is int? ? width : this.width,
      height: height is int? ? height : this.height,
      thumbnailPath: thumbnailPath is String?
          ? thumbnailPath
          : this.thumbnailPath,
      compressed: compressed ?? this.compressed,
      animated: animated ?? this.animated,
      contentHash: contentHash is String? ? contentHash : this.contentHash,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }
}
