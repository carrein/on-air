import 'dart:convert';

import 'package:http/http.dart' as http;

/// A single GIF result from the Klipy API.
class KlipyGif {
  final String id;
  final String title;
  final String url;
  final String previewUrl;
  final int width;
  final int height;

  const KlipyGif({
    required this.id,
    required this.title,
    required this.url,
    required this.previewUrl,
    required this.width,
    required this.height,
  });

  double get aspectRatio => width > 0 && height > 0 ? width / height : 1.0;
}

/// Paginated response from the Klipy API.
class KlipyResponse {
  final List<KlipyGif> gifs;
  final String? next;

  const KlipyResponse({required this.gifs, this.next});
}

/// HTTP client for the Klipy GIF search API (Tenor-compatible).
class KlipyService {
  static const _baseUrl = 'https://api.klipy.com/v2';
  static const _apiKey = String.fromEnvironment('KLIPY_API_KEY');

  /// Whether a Klipy API key was provided at build time.
  static bool get isAvailable => _apiKey.isNotEmpty;

  /// Search GIFs by query.
  static Future<KlipyResponse> search(
    String query, {
    String? pos,
    int limit = 20,
  }) async {
    final params = {
      'key': _apiKey,
      'q': query,
      'limit': limit.toString(),
      'media_filter': 'gif,tinygif',
      if (pos != null) 'pos': pos,
    };
    final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: params);
    return _fetch(uri);
  }

  /// Get trending/featured GIFs.
  static Future<KlipyResponse> featured({
    String? pos,
    int limit = 20,
  }) async {
    final params = {
      'key': _apiKey,
      'limit': limit.toString(),
      'media_filter': 'gif,tinygif',
      if (pos != null) 'pos': pos,
    };
    final uri = Uri.parse(
      '$_baseUrl/featured',
    ).replace(queryParameters: params);
    return _fetch(uri);
  }

  static Future<KlipyResponse> _fetch(Uri uri) async {
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception(
        'Klipy API error: ${response.statusCode} — ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final results = json['results'] as List<dynamic>? ?? [];
    final next = json['next'] as String?;

    final gifs = <KlipyGif>[];
    for (final result in results) {
      final r = result as Map<String, dynamic>;
      final mediaFormats = r['media_formats'] as Map<String, dynamic>?;
      if (mediaFormats == null) continue;

      final gifFormat = mediaFormats['gif'] as Map<String, dynamic>?;
      if (gifFormat == null) continue;

      final url = gifFormat['url'] as String?;
      if (url == null || url.isEmpty) continue;

      // Use tinygif for grid previews (smaller, loads faster).
      final tinyFormat = mediaFormats['tinygif'] as Map<String, dynamic>?;
      final previewUrl = (tinyFormat?['url'] as String?) ?? url;

      final dims = gifFormat['dims'] as List<dynamic>?;
      final width = dims != null && dims.length >= 2
          ? (dims[0] as num).toInt()
          : 0;
      final height = dims != null && dims.length >= 2
          ? (dims[1] as num).toInt()
          : 0;

      gifs.add(
        KlipyGif(
          id: r['id']?.toString() ?? '',
          title: (r['title'] as String?) ?? '',
          url: url,
          previewUrl: previewUrl,
          width: width,
          height: height,
        ),
      );
    }

    return KlipyResponse(gifs: gifs, next: next);
  }
}
