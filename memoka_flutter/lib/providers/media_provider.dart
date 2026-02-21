import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'media_provider.g.dart';

/// Legacy provider — upload operations now go through [PendingUploads].
/// Kept to avoid breaking generated code references.
@riverpod
class MediaUpload extends _$MediaUpload {
  @override
  FutureOr<void> build() {}
}
