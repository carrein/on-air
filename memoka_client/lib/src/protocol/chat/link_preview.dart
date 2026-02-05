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

/// Link preview metadata extracted from URLs.
abstract class LinkPreview implements _i1.SerializableModel {
  LinkPreview._({
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
    this.faviconUrl,
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  factory LinkPreview({
    required String url,
    String? title,
    String? description,
    String? imageUrl,
    String? faviconUrl,
    DateTime? fetchedAt,
  }) = _LinkPreviewImpl;

  factory LinkPreview.fromJson(Map<String, dynamic> jsonSerialization) {
    return LinkPreview(
      url: jsonSerialization['url'] as String,
      title: jsonSerialization['title'] as String?,
      description: jsonSerialization['description'] as String?,
      imageUrl: jsonSerialization['imageUrl'] as String?,
      faviconUrl: jsonSerialization['faviconUrl'] as String?,
      fetchedAt: jsonSerialization['fetchedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['fetchedAt']),
    );
  }

  /// The fully qualified URL.
  String url;

  /// The page title (from OG or <title> tag).
  String? title;

  /// The description (from OG or meta description).
  String? description;

  /// The image URL (from OG image).
  String? imageUrl;

  /// The favicon URL.
  String? faviconUrl;

  /// When the preview was fetched.
  DateTime fetchedAt;

  /// Returns a shallow copy of this [LinkPreview]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  LinkPreview copyWith({
    String? url,
    String? title,
    String? description,
    String? imageUrl,
    String? faviconUrl,
    DateTime? fetchedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LinkPreview',
      'url': url,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (faviconUrl != null) 'faviconUrl': faviconUrl,
      'fetchedAt': fetchedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LinkPreviewImpl extends LinkPreview {
  _LinkPreviewImpl({
    required String url,
    String? title,
    String? description,
    String? imageUrl,
    String? faviconUrl,
    DateTime? fetchedAt,
  }) : super._(
         url: url,
         title: title,
         description: description,
         imageUrl: imageUrl,
         faviconUrl: faviconUrl,
         fetchedAt: fetchedAt,
       );

  /// Returns a shallow copy of this [LinkPreview]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  LinkPreview copyWith({
    String? url,
    Object? title = _Undefined,
    Object? description = _Undefined,
    Object? imageUrl = _Undefined,
    Object? faviconUrl = _Undefined,
    DateTime? fetchedAt,
  }) {
    return LinkPreview(
      url: url ?? this.url,
      title: title is String? ? title : this.title,
      description: description is String? ? description : this.description,
      imageUrl: imageUrl is String? ? imageUrl : this.imageUrl,
      faviconUrl: faviconUrl is String? ? faviconUrl : this.faviconUrl,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }
}
