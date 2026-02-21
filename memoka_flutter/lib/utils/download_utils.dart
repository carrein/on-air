import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'toast_utils.dart';

/// Downloads a file from [url] to a temporary directory and opens the
/// system share sheet so the user can save it to Downloads or another app.
class DownloadUtils {
  static Future<void> downloadToDevice(
    BuildContext context,
    String url,
    String filename, {
    void Function(double)? onProgress,
  }) async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();

      final contentLength = response.contentLength; // -1 if unknown
      final bytes = <int>[];
      var received = 0;

      await for (final chunk in response) {
        bytes.addAll(chunk);
        received += chunk.length;
        if (contentLength > 0) {
          onProgress?.call(received / contentLength);
        }
      }
      client.close();

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      if (context.mounted) {
        ToastUtils.show(context, 'Download failed: $e', type: ToastType.error);
      }
    }
  }
}
