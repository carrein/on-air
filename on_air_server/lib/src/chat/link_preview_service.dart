import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import '../generated/protocol.dart';

/// Service for extracting URLs from content and fetching link preview metadata.
class LinkPreviewService {
  /// Extract first fully qualified URL from content.
  static String? extractFirstUrl(String content) {
    final urlRegex = RegExp(
      r'https?://[^\s<>"{}|\\^`\[\]]+',
      caseSensitive: false,
    );
    final match = urlRegex.firstMatch(content);
    return match?.group(0);
  }

  /// Fetch and parse link preview metadata from a URL.
  /// Returns null if the URL cannot be fetched or parsed.
  static Future<LinkPreview?> fetchPreview(String url) async {
    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {'User-Agent': 'Mozilla/5.0 (compatible; OnAirBot/1.0)'},
          )
          .timeout(const Duration(seconds: 10));

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

      return LinkPreview(
        url: url,
        title: title,
        description: description,
        imageUrl: validImageUrl,
        faviconUrl: faviconUrl,
      );
    } catch (e) {
      // Network error, timeout, or parsing error
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
