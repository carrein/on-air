import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import 'package:mime/mime.dart';
import '../generated/protocol.dart';
import '../shared/constants.dart';

/// Service for extracting URLs from content and fetching link preview metadata.
class LinkPreviewService {
  static const _userAgent = 'Mozilla/5.0 (compatible; MemokaBot/1.0)';
  static const _timeout = Duration(seconds: 10);
  static const _maxImageBytes = 5 * 1024 * 1024; // 5 MB

  /// File extensions that correspond to CanvasKit-safe raster formats.
  static const _rasterExtensions = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'wbmp',
  };

  /// Extract first fully qualified URL from content.
  static String? extractFirstUrl(String content) {
    final match = ServerConstants.urlPattern.firstMatch(content);
    return match?.group(0);
  }

  /// Fetch and parse link preview metadata from a URL.
  /// Downloads OG image and favicon to local disk so they can be served
  /// via /media with proper CORS headers (avoids CanvasKit crash on web).
  static Future<LinkPreview?> fetchPreview(String url) async {
    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {'User-Agent': _userAgent},
          )
          .timeout(_timeout);

      if (response.statusCode != 200) return null;

      final document = html_parser.parse(response.body);

      // Extract OpenGraph or fallback to HTML meta tags
      final title =
          _extractMeta(document, ['og:title', 'twitter:title']) ??
          document.querySelector('title')?.text.trim();

      final description = _extractMeta(
        document,
        ['og:description', 'twitter:description', 'description'],
      );

      final rawImageUrl = _extractMeta(document, ['og:image', 'twitter:image']);
      final imageUrl = rawImageUrl != null
          ? _makeAbsoluteUrl(rawImageUrl, url)
          : null;

      // Validate image URL
      final validImageUrl = imageUrl != null && _isValidUrl(imageUrl)
          ? imageUrl
          : null;

      final faviconUrl = _extractFavicon(document, url);

      // Download images to local disk for CORS-safe serving
      final localImagePath = validImageUrl != null
          ? await _downloadImage(validImageUrl, 'previews')
          : null;
      final localFaviconPath = faviconUrl != null
          ? await _downloadImage(faviconUrl, 'previews/favicons')
          : null;

      return LinkPreview(
        url: url,
        title: title,
        description: description,
        imageUrl: localImagePath,
        faviconUrl: localFaviconPath,
      );
    } catch (e) {
      // Network error, timeout, or parsing error
      stderr.writeln('LinkPreviewService.fetchPreview failed for $url: $e');
      return null;
    }
  }

  /// Download an external image to local storage for CORS-safe serving.
  /// Public entry point used by the one-time preview migration.
  static Future<String?> downloadPreviewImage(String url, String subDir) =>
      _downloadImage(url, subDir);

  /// Download an image from [url] into [subDir] under the media base directory.
  /// Returns the relative path (e.g. "previews/abc123.jpg") or null on failure.
  static Future<String?> _downloadImage(String url, String subDir) async {
    try {
      final request = http.Request('GET', Uri.parse(url))
        ..headers['User-Agent'] = _userAgent;
      final streamed = await request.send().timeout(_timeout);

      if (streamed.statusCode != 200) return null;

      // Check Content-Length if available
      final contentLength = streamed.contentLength;
      if (contentLength != null && contentLength > _maxImageBytes) return null;

      // Determine file extension from Content-Type or URL
      final contentType = streamed.headers['content-type'] ?? '';
      final ext =
          _extensionFromContentType(contentType) ??
          _extensionFromUrl(url) ??
          'bin';

      // Reject non-raster formats (SVG, ICO, etc.) — CanvasKit can't decode them
      if (!_rasterExtensions.contains(ext)) {
        unawaited(streamed.stream.drain<void>());
        return null;
      }

      // Hash the URL for deduplication
      final hash = _hashUrl(url);
      final relativePath = '$subDir/$hash.$ext';
      final destFile = File('${ServerConstants.mediaBaseDir}/$relativePath');

      // Skip download if already cached
      if (await destFile.exists()) {
        unawaited(streamed.stream.drain<void>());
        return relativePath;
      }

      // Ensure directory exists
      await destFile.parent.create(recursive: true);

      // Stream bytes to disk with size guard
      final sink = destFile.openWrite();
      var totalBytes = 0;
      try {
        await for (final chunk in streamed.stream) {
          totalBytes += chunk.length;
          if (totalBytes > _maxImageBytes) {
            await sink.close();
            await destFile.delete();
            return null;
          }
          sink.add(chunk);
        }
        await sink.close();
      } catch (_) {
        await sink.close();
        if (await destFile.exists()) await destFile.delete();
        return null;
      }

      return relativePath;
    } catch (_) {
      return null;
    }
  }

  /// First 16 hex chars of SHA-256 hash of the URL.
  static String _hashUrl(String url) {
    final bytes = utf8.encode(url);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  /// Derive a file extension from a Content-Type header value.
  static String? _extensionFromContentType(String contentType) {
    final mimeType = contentType.split(';').first.trim().toLowerCase();
    if (!mimeType.startsWith('image/')) return null;
    return extensionFromMime(mimeType);
  }

  /// Derive a file extension from the URL path.
  static String? _extensionFromUrl(String url) {
    try {
      final path = Uri.parse(url).path;
      final dot = path.lastIndexOf('.');
      if (dot == -1 || dot == path.length - 1) return null;
      final ext = path.substring(dot + 1).toLowerCase();
      // Only accept short, plausible image extensions
      if (ext.length > 5) return null;
      return ext;
    } catch (_) {
      return null;
    }
  }

  /// Extract meta tag content by property or name.
  static String? _extractMeta(Document document, List<String> properties) {
    for (final prop in properties) {
      final element =
          document.querySelector('meta[property="$prop"]') ??
          document.querySelector('meta[name="$prop"]');
      final content = element?.attributes['content']
          ?.trim()
          .replaceAll(
            RegExp(r'\s+'),
            ' ',
          ) // Replace all whitespace with single space
          .replaceAll('\n', '') // Remove newlines
          .replaceAll('\r', ''); // Remove carriage returns
      if (content != null && content.isNotEmpty) return content;
    }
    return null;
  }

  /// Extract favicon URL and make it absolute.
  static String? _extractFavicon(Document document, String baseUrl) {
    final favicon = document.querySelector('link[rel*="icon"]');
    final href = favicon?.attributes['href'];
    if (href == null) return null;
    return _makeAbsoluteUrl(href, baseUrl);
  }

  /// Convert relative URL to absolute URL.
  static String _makeAbsoluteUrl(String urlString, String baseUrl) {
    // Already absolute
    if (urlString.startsWith('http://') || urlString.startsWith('https://')) {
      return urlString;
    }

    final uri = Uri.parse(baseUrl);

    // Protocol-relative URL
    if (urlString.startsWith('//')) {
      return '${uri.scheme}:$urlString';
    }

    // Absolute path
    if (urlString.startsWith('/')) {
      return '${uri.scheme}://${uri.host}$urlString';
    }

    // Relative path
    final basePath = uri.path.endsWith('/')
        ? uri.path
        : uri.path.substring(0, uri.path.lastIndexOf('/') + 1);
    return '${uri.scheme}://${uri.host}$basePath$urlString';
  }

  /// Validate that a URL is well-formed and accessible.
  static bool _isValidUrl(String urlString) {
    try {
      final uri = Uri.parse(urlString);
      return uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.hasAuthority &&
          !urlString.contains('\n') &&
          !urlString.contains('\r') &&
          !urlString.contains(' ');
    } catch (_) {
      return false;
    }
  }
}
