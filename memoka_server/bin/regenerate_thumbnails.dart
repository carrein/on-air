// ignore_for_file: avoid_print
import 'dart:io';

import 'package:memoka_server/src/generated/endpoints.dart';
import 'package:memoka_server/src/generated/protocol.dart';
import 'package:memoka_server/src/media/ffmpeg_utils.dart';
import 'package:memoka_server/src/media/thumbnail_regen_service.dart';
import 'package:serverpod/serverpod.dart';

/// Regenerates thumbnails for all image and video attachments.
///
/// Overwrites existing thumbnails with the current 1200px lossless-WebP
/// settings. For attachments that never had a thumbnail (thumbnailPath IS NULL),
/// generates one and updates the DB row.
///
/// The server does NOT need to be running, but the database must be up.
/// Run from memoka_server/:
///   dart run bin/regenerate_thumbnails.dart
void main(List<String> args) async {
  print('Memoka — Regenerate Thumbnails');
  print('=' * 50);

  if (!await FfmpegUtils.checkAvailable()) {
    print('ERROR: ffmpeg not found. Install ffmpeg and retry.');
    exit(1);
  }

  final pod = Serverpod(args, Protocol(), Endpoints());
  try {
    final session = await pod.createSession();

    final total = await ThumbnailRegenService.countEligible(session);
    print('Found $total attachment(s) to process.\n');

    final result = await ThumbnailRegenService.regenerateAll(
      session,
      log: print,
    );

    await session.close();
    print('\n${'=' * 50}');
    print(
      'Done.  ok=${result.ok}  skipped=${result.skipped}  failed=${result.failed}',
    );
  } finally {
    await pod.shutdown();
  }
}
