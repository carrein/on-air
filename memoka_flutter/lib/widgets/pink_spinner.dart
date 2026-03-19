import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// A spinning pink Phosphor spinner-ball icon.
/// Replaces all CircularProgressIndicator instances across the app.
class PinkSpinner extends StatefulWidget {
  final double size;
  const PinkSpinner({super.key, this.size = 24});

  @override
  State<PinkSpinner> createState() => _PinkSpinnerState();
}

class _PinkSpinnerState extends State<PinkSpinner>
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
        color: const Color(0xFF3450A3),
      ),
    );
  }
}
