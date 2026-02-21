import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum ToastType {
  error,
  success,
  info,
}

class ToastUtils {
  static final List<OverlayEntry> _activeToasts = [];
  static const int _maxToasts = 3;
  static const Duration _defaultDuration = Duration(seconds: 3);

  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = _defaultDuration,
  }) {
    // Remove oldest toast if we're at the limit
    if (_activeToasts.length >= _maxToasts) {
      final oldest = _activeToasts.removeAt(0);
      oldest.remove();
    }

    final notificationData = _NotificationData(
      message: message,
      type: type,
      onDismiss: () {},
    );

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _ToastNotification(
        data: notificationData,
        index: _activeToasts.length,
        onDismiss: () {
          overlayEntry.remove();
          _activeToasts.remove(overlayEntry);
        },
      ),
    );

    _activeToasts.add(overlayEntry);
    overlay.insert(overlayEntry);

    // Auto-dismiss after duration
    Future.delayed(duration, () {
      if (_activeToasts.contains(overlayEntry)) {
        overlayEntry.remove();
        _activeToasts.remove(overlayEntry);
      }
    });
  }
}

class _NotificationData {
  final String message;
  final ToastType type;
  final VoidCallback onDismiss;

  _NotificationData({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  Color get backgroundColor {
    switch (type) {
      case ToastType.error:
        return Colors.red[700]!;
      case ToastType.success:
        return Colors.green[700]!;
      case ToastType.info:
        return Colors.grey[800]!;
    }
  }

  IconData get icon {
    switch (type) {
      case ToastType.error:
        return PhosphorIcons.warning();
      case ToastType.success:
        return PhosphorIcons.checkCircle();
      case ToastType.info:
        return PhosphorIcons.info();
    }
  }
}

class _ToastNotification extends StatefulWidget {
  final _NotificationData data;
  final int index;
  final VoidCallback onDismiss;

  const _ToastNotification({
    required this.data,
    required this.index,
    required this.onDismiss,
  });

  @override
  State<_ToastNotification> createState() => _ToastNotificationState();
}

class _ToastNotificationState extends State<_ToastNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Positioned(
          right: 16,
          bottom: 16 + (widget.index * 60),
          child: Transform.translate(
            offset: Offset((1 - _animation.value) * 100, 0),
            child: Opacity(
              opacity: _animation.value,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                color: widget.data.backgroundColor,
                child: InkWell(
                  onTap: () async {
                    await _controller.reverse();
                    widget.onDismiss();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.data.icon, color: Colors.white, size: 20),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            widget.data.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
