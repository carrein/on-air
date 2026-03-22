import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../utils/image_clipboard.dart';
import '../utils/toast_utils.dart';
import 'icon_button_styled.dart';
import 'app_spinner.dart';

/// Full screen image viewer overlay with gallery support and keyboard navigation.
class FullScreenImageView extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullScreenImageView({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
  });

  /// Show the lightbox as a dialog overlay.
  static void show(
    BuildContext context, {
    required List<String> imageUrls,
    required int initialIndex,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      useSafeArea: false,
      builder: (context) => FullScreenImageView(
        imageUrls: imageUrls,
        initialIndex: initialIndex,
      ),
    ).then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusManager.instance.primaryFocus?.unfocus();
      });
    });
  }

  @override
  State<FullScreenImageView> createState() => _FullScreenImageViewState();
}

class _FullScreenImageViewState extends State<FullScreenImageView> {
  late PageController _pageController;
  late int _currentIndex;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.imageUrls.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index >= 0 && index < widget.imageUrls.length) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _goTo(_currentIndex - 1);
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _goTo(_currentIndex + 1);
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      FocusScope.of(context).unfocus();
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    } else if (kIsWeb &&
        event.logicalKey == LogicalKeyboardKey.keyC &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed)) {
      _copyCurrentImage().ignore();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _copyCurrentImage() async {
    final url = widget.imageUrls[_currentIndex];
    final success = await copyImageToClipboard(url);
    if (!mounted) return;
    ToastUtils.show(
      context,
      success ? 'Image copied to clipboard' : 'Failed to copy image',
      type: success ? ToastType.success : ToastType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          Navigator.of(context).pop();
        },
        child: Stack(
          children: [
            // Image gallery
            PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              pageController: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              backgroundDecoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              builder: (context, index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: CachedNetworkImageProvider(
                    widget.imageUrls[index],
                  ),
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 3.0,
                );
              },
              loadingBuilder: (context, event) => Center(
                child: AppSpinner(),
              ),
            ),
            // Close button
            Positioned(
              top: MediaQuery.paddingOf(context).top + 16,
              right: 16,
              child: IconButtonStyled(
                icon: PhosphorIcons.x(),
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  Navigator.of(context).pop();
                },
                color: Colors.white,
                size: IconButtonStyled.lg,
              ),
            ),
            // Navigation arrows (desktop)
            if (widget.imageUrls.length > 1) ...[
              if (_currentIndex > 0)
                Positioned(
                  left: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButtonStyled(
                      icon: PhosphorIcons.caretLeft(),
                      onPressed: () => _goTo(_currentIndex - 1),
                      color: Colors.white70,
                      size: IconButtonStyled.lg,
                    ),
                  ),
                ),
              if (_currentIndex < widget.imageUrls.length - 1)
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButtonStyled(
                      icon: PhosphorIcons.caretRight(),
                      onPressed: () => _goTo(_currentIndex + 1),
                      color: Colors.white70,
                      size: IconButtonStyled.lg,
                    ),
                  ),
                ),
              // Counter
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.imageUrls.length}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
