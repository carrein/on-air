import 'package:flutter_riverpod/legacy.dart';

/// Tracks the filePath of the currently playing audio attachment.
/// When a new player sets itself active, the previous one pauses.
final activeAudioIdProvider = StateProvider<String?>((ref) => null);
