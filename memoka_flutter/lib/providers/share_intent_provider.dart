import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// Provides shared media from other apps via share intent.
/// Only active on non-web platforms.
final shareIntentProvider = StreamProvider<List<SharedMediaFile>>((ref) {
  if (kIsWeb) return const Stream.empty();

  final controller = StreamController<List<SharedMediaFile>>();

  // Listen to incoming shares while app is open
  final sub = ReceiveSharingIntent.instance.getMediaStream().listen(
    (files) {
      if (files.isNotEmpty) controller.add(files);
    },
  );

  // Check for initial share (cold start)
  ReceiveSharingIntent.instance.getInitialMedia().then((files) {
    if (files.isNotEmpty) controller.add(files);
  });

  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });

  return controller.stream;
});
