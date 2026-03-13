import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../shared/constants.dart';

/// Periodically checks watched URLs for content changes.
/// Follows ArchivePurgeService pattern: static class, _checkInProgress guard.
///
/// Uses HTTP conditional requests (ETag / Last-Modified) to skip re-downloading
/// pages whose content hasn't changed according to the web server, saving
/// bandwidth on frequent polling intervals.
class PageWatchService {
  static bool _checkInProgress = false;

  static const _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  /// Max text length to hash (1MB safety cap).
  static const _maxTextLength = 1024 * 1024;

  /// Runs a single check cycle for all enabled watches.
  static Future<void> runCheck(Serverpod pod) async {
    if (_checkInProgress) return;
    _checkInProgress = true;

    final session = await pod.createSession();
    try {
      final rows = await session.db.unsafeQuery(
        'SELECT "id", "noteId", "channelId", "url", "contentHash", '
        '"etag", "lastModified", "hasUnacknowledgedChange" '
        'FROM "page_watches" WHERE "enabled" = true',
      );

      for (final row in rows) {
        final cols = row.toColumnMap();
        await _checkWatch(
          session,
          watchId: cols['id'] as int,
          noteId: cols['noteId'] as int,
          channelId: cols['channelId'] as int,
          url: cols['url'] as String,
          previousHash: cols['contentHash'] as String?,
          alreadyNotified: cols['hasUnacknowledgedChange'] as bool,
          etag: cols['etag'] as String?,
          lastModified: cols['lastModified'] as String?,
        );
      }
    } catch (e, stackTrace) {
      session.log(
        'Page watch check failed: $e\n$stackTrace',
        level: LogLevel.error,
      );
    } finally {
      await session.close();
      _checkInProgress = false;
    }
  }

  static Future<void> _checkWatch(
    Session session, {
    required int watchId,
    required int noteId,
    required int channelId,
    required String url,
    required String? previousHash,
    required bool alreadyNotified,
    required String? etag,
    required String? lastModified,
  }) async {
    try {
      // Build conditional request headers
      final headers = <String, String>{'User-Agent': _userAgent};
      if (etag != null) headers['If-None-Match'] = etag;
      if (lastModified != null) headers['If-Modified-Since'] = lastModified;

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));

      final now = DateTime.now().toIso8601String();

      // 304 Not Modified — server confirms no change, skip parsing
      if (response.statusCode == 304) {
        await session.db.unsafeQuery(
          'UPDATE "page_watches" SET '
          '"lastCheckedAt" = \'$now\', '
          '"consecutiveFailures" = 0, '
          '"lastError" = NULL, '
          '"updatedAt" = \'$now\' '
          'WHERE "id" = $watchId',
        );
        return;
      }

      if (response.statusCode != 200) {
        await _recordFailure(
          session,
          watchId,
          noteId,
          channelId,
          'HTTP ${response.statusCode}',
        );
        return;
      }

      // Store response cache headers for next conditional request
      final newEtag = response.headers['etag'];
      final newLastModified = response.headers['last-modified'];

      // Parse HTML and extract visible text
      final document = html_parser.parse(response.body);
      document
          .querySelectorAll('script, style, noscript')
          .forEach((e) => e.remove());
      var text = document.body?.text ?? '';
      if (text.length > _maxTextLength) {
        text = text.substring(0, _maxTextLength);
      }

      final newHash = sha256.convert(utf8.encode(text)).toString();

      // Build SET clause for cache headers
      final etagSql = newEtag != null
          ? "'${ServerConstants.escapeSql(newEtag)}'"
          : 'NULL';
      final lastModSql = newLastModified != null
          ? "'${ServerConstants.escapeSql(newLastModified)}'"
          : 'NULL';

      if (previousHash == null) {
        // First check — store hash, no notification
        await session.db.unsafeQuery(
          'UPDATE "page_watches" SET '
          '"contentHash" = \'$newHash\', '
          '"lastCheckedAt" = \'$now\', '
          '"consecutiveFailures" = 0, '
          '"lastError" = NULL, '
          '"etag" = $etagSql, '
          '"lastModified" = $lastModSql, '
          '"updatedAt" = \'$now\' '
          'WHERE "id" = $watchId',
        );
        session.log('Page watch $watchId: initial hash stored for $url');
      } else if (newHash != previousHash) {
        // Content changed — update hash, only notify if user has seen the last change
        await session.db.unsafeQuery(
          'UPDATE "page_watches" SET '
          '"contentHash" = \'$newHash\', '
          '"lastCheckedAt" = \'$now\', '
          '"hasUnacknowledgedChange" = true, '
          '"consecutiveFailures" = 0, '
          '"lastError" = NULL, '
          '"etag" = $etagSql, '
          '"lastModified" = $lastModSql, '
          '"updatedAt" = \'$now\' '
          'WHERE "id" = $watchId',
        );

        if (!alreadyNotified) {
          // Include note so client can use linkPreview for notification
          final note = await Note.db.findById(session, noteId);
          await ServerConstants.broadcastEvent(
            session,
            ChatEvent(
              type: 'pageChanged',
              note: note,
              noteId: noteId,
              channelId: channelId,
            ),
          );
          session.log('Page watch $watchId: content changed for $url');
        }
      } else {
        // No change — just update lastCheckedAt + cache headers
        await session.db.unsafeQuery(
          'UPDATE "page_watches" SET '
          '"lastCheckedAt" = \'$now\', '
          '"consecutiveFailures" = 0, '
          '"lastError" = NULL, '
          '"etag" = $etagSql, '
          '"lastModified" = $lastModSql, '
          '"updatedAt" = \'$now\' '
          'WHERE "id" = $watchId',
        );
      }
    } catch (e) {
      await _recordFailure(session, watchId, noteId, channelId, e.toString());
    }
  }

  static Future<void> _recordFailure(
    Session session,
    int watchId,
    int noteId,
    int channelId,
    String error,
  ) async {
    final escapedError = error.replaceAll("'", "''");
    final now = DateTime.now().toIso8601String();

    final result = await session.db.unsafeQuery(
      'UPDATE "page_watches" SET '
      '"consecutiveFailures" = "consecutiveFailures" + 1, '
      '"lastError" = \'$escapedError\', '
      '"lastCheckedAt" = \'$now\', '
      '"updatedAt" = \'$now\' '
      'WHERE "id" = $watchId '
      'RETURNING "consecutiveFailures"',
    );

    final failures = result.first.toColumnMap()['consecutiveFailures'] as int;

    if (failures >= 5) {
      await session.db.unsafeQuery(
        'UPDATE "page_watches" SET "enabled" = false, '
        '"updatedAt" = \'$now\' '
        'WHERE "id" = $watchId',
      );

      await ServerConstants.broadcastEvent(
        session,
        ChatEvent(
          type: 'pageWatchDisabled',
          noteId: noteId,
          channelId: channelId,
        ),
      );

      session.log(
        'Page watch $watchId: auto-disabled after $failures failures ($error)',
        level: LogLevel.warning,
      );
    }
  }
}
