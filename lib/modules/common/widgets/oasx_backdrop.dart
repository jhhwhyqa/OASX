import 'package:flutter/material.dart';

import 'package:oasx/config/design_system.dart';

/// Ambient canvas for the console: a faint engineering grid.
///
/// The texture stays below the content and is painted without animation, so it
/// costs one repaint per size change and respects reduced-motion preferences.
class OasxBackdrop extends StatelessWidget {
  const OasxBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = OasxColors.of(context);
    return ColoredBox(
      color: colors.canvas,
      child: CustomPaint(
        painter: _DotGridPainter(color: colors.gridLine),
        child: child,
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter({required this.color});

  final Color color;

  static const double _spacing = 24;
  static const double _dotRadius = 0.75;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    final paint = Paint()..color = color;
    for (var x = _spacing; x < size.width; x += _spacing) {
      for (var y = _spacing; y < size.height; y += _spacing) {
        canvas.drawCircle(Offset(x, y), _dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
