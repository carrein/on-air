import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// A spinning Phosphor spinner-gap icon.
/// Replaces all CircularProgressIndicator instances across the app.
class AppSpinner extends StatefulWidget {
  final double size;
  final Color color;
  const AppSpinner({
    super.key,
    this.size = 24,
    this.color = const Color(0xFF3450A3),
  });

  @override
  State<AppSpinner> createState() => _AppSpinnerState();
}

class _AppSpinnerState extends State<AppSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: PhosphorIcon(
        PhosphorIcons.spinnerGap(),
        size: widget.size,
        color: widget.color,
      ),
    );
  }
}
