import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../services/klipy_service.dart';
import 'pink_spinner.dart';
import 'styled_search_field.dart';

/// Modal bottom sheet for searching and selecting GIFs via the Klipy API.
///
/// Shows trending GIFs initially. Typing in the search field queries the
/// Klipy search endpoint with 300ms debounce. Supports infinite scroll
/// via the `next` pagination token. Masonry layout respects GIF aspect ratios.
///
/// Returns the selected [KlipyGif] when tapped, or null if dismissed.
class GifPickerSheet extends StatefulWidget {
  const GifPickerSheet({super.key});

  @override
  State<GifPickerSheet> createState() => _GifPickerSheetState();
}

class _GifPickerSheetState extends State<GifPickerSheet> {
  // -- Design tokens (DesignSystem.md) --
  static const _surface = Color(0xFFF6F0ED);
  static const _text = Color(0xFF00171F);
  static const _accent = Color(0xFFCE2161);
  static const _textMutedAlpha = 0.5;
  static const _gridColumns = 3;
  static const _gridSpacing = 4.0;
  static const _debounceMs = 300;

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  List<KlipyGif> _gifs = [];
  String? _nextToken;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFeatured();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore || _nextToken == null) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll - 200) {
      _loadMore();
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      final trimmed = query.trim();
      if (trimmed == _lastQuery) return;
      _lastQuery = trimmed;
      if (trimmed.isEmpty) {
        _loadFeatured();
      } else {
        _search(trimmed);
      }
    });
  }

  Future<void> _loadFeatured() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await KlipyService.featured();
      if (!mounted) return;
      setState(() {
        _gifs = response.gifs;
        _nextToken = response.next;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('GIF load error: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load GIFs';
        _isLoading = false;
      });
    }
  }

  Future<void> _search(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await KlipyService.search(query);
      if (!mounted) return;
      if (_lastQuery != query) return;
      setState(() {
        _gifs = response.gifs;
        _nextToken = response.next;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('GIF search error: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Search failed';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_nextToken == null || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final query = _lastQuery;
      final response = query.isEmpty
          ? await KlipyService.featured(pos: _nextToken)
          : await KlipyService.search(query, pos: _nextToken);
      if (!mounted) return;
      setState(() {
        _gifs.addAll(response.gifs);
        _nextToken = response.next;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 1.0,
      minChildSize: 0.4,
      maxChildSize: 1.0,
      builder: (_, scrollController) => Container(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
        decoration: const BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _text.withValues(alpha: 0.15),
              ),
            ),
            // Search field
            StyledSearchField(
              controller: _searchController,
              autofocus: true,
              hintText: 'Search GIFs...',
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),
            // Content
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: PinkSpinner(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PhosphorIcon(
              PhosphorIcons.warning(),
              size: 32,
              color: _text.withValues(alpha: _textMutedAlpha),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                color: _text.withValues(alpha: _textMutedAlpha),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _lastQuery.isEmpty
                  ? _loadFeatured
                  : () => _search(_lastQuery),
              child: const Text(
                'Retry',
                style: TextStyle(color: _accent),
              ),
            ),
          ],
        ),
      );
    }

    if (_gifs.isEmpty) {
      return Center(
        child: Text(
          'No GIFs found',
          style: TextStyle(
            color: _text.withValues(alpha: _textMutedAlpha),
            fontSize: 14,
          ),
        ),
      );
    }

    return MasonryGridView.count(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      crossAxisCount: _gridColumns,
      mainAxisSpacing: _gridSpacing,
      crossAxisSpacing: _gridSpacing,
      itemCount: _gifs.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _gifs.length) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: PinkSpinner(),
            ),
          );
        }

        final gif = _gifs[index];
        return GestureDetector(
          onTap: () => Navigator.pop(context, gif),
          child: _EvictableNetworkImage(
            url: gif.previewUrl,
            aspectRatio: gif.aspectRatio.clamp(0.5, 2.0),
          ),
        );
      },
    );
  }
}

/// Network image that evicts itself from the image cache on dispose.
///
/// Prevents `DomException: AbortError` on web when the GIF picker sheet
/// closes while preview images are still loading — evicting the
/// [NetworkImage] cancels the in-flight load cleanly.
class _EvictableNetworkImage extends StatefulWidget {
  const _EvictableNetworkImage({
    required this.url,
    required this.aspectRatio,
  });

  final String url;
  final double aspectRatio;

  @override
  State<_EvictableNetworkImage> createState() => _EvictableNetworkImageState();
}

class _EvictableNetworkImageState extends State<_EvictableNetworkImage> {
  late final NetworkImage _provider = NetworkImage(widget.url);

  @override
  void dispose() {
    PaintingBinding.instance.imageCache.evict(_provider);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Image(
      image: _provider,
      fit: BoxFit.cover,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (frame == null) {
          return AspectRatio(
            aspectRatio: widget.aspectRatio,
            child: ColoredBox(color: Colors.grey[200]!),
          );
        }
        return child;
      },
      errorBuilder: (_, _, _) => AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: ColoredBox(color: Colors.grey[200]!),
      ),
    );
  }
}
