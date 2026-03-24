import 'dart:typed_data';

/// In-memory image cache bridging the upload-complete to NoteItem-render gap.
///
/// Sender keeps local bytes keyed by server URL. NoteItem checks here first
/// (instant `Image.memory`) before falling back to `Image.network`.
/// Entries expire after [_ttl] and are bounded by [_maxEntries].
class LocalImageCache {
  static final Map<String, _CacheEntry> _cache = {};
  static const int _maxEntries = 20;
  static const Duration _ttl = Duration(seconds: 60);

  /// Store image bytes under the given URL.
  static void put(String url, Uint8List bytes) {
    _cache[url] = _CacheEntry(bytes, DateTime.now());
    _evictExpired();
    while (_cache.length > _maxEntries) {
      _cache.remove(_cache.keys.first);
    }
  }

  /// Retrieve cached bytes, or null if absent/expired.
  static Uint8List? get(String url) {
    final entry = _cache[url];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.insertedAt) > _ttl) {
      _cache.remove(url);
      return null;
    }
    return entry.bytes;
  }

  static void _evictExpired() {
    final now = DateTime.now();
    _cache.removeWhere((_, e) => now.difference(e.insertedAt) > _ttl);
  }
}

class _CacheEntry {
  final Uint8List bytes;
  final DateTime insertedAt;
  _CacheEntry(this.bytes, this.insertedAt);
}
