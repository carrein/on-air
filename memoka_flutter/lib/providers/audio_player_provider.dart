import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks the filePath of the currently playing audio attachment.
/// When a new player sets itself active, the previous one pauses.
final activeAudioIdProvider = StateProvider<String?>((ref) => null);
