// lib/core/grid.dart
import 'package:flutter/material.dart';

class Grid {
  final double spacing;
  final double length;
  final Color color;
  final bool snapToGrid;

  double scale = 1.0;
  Offset position = Offset.zero;

  Grid({
    required this.spacing,
    required this.length,
    required this.color,
    required this.snapToGrid,
  });

  /// Update the grid scale (usually when workspace zoom changes)
  void updateScale(double newScale) {
    scale = newScale;
  }

  /// Move the grid to a new x/y offset
  void moveTo(double x, double y) {
    position = Offset(x, y);
  }

  /// Whether blocks should snap to grid
  bool shouldSnap() => snapToGrid;

  /// Get the scaled spacing
  double getSpacing() => spacing * scale;

  /// Paint the grid on a canvas
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    final scaledSpacing = getSpacing();
    final half = (spacing / 2) * scale;
    final halfLength = (length / 2) * scale;

    // Draw vertical lines
    for (double x = half; x < size.width; x += scaledSpacing) {
      canvas.drawLine(
        Offset(x + position.dx, halfLength + position.dy),
        Offset(x + position.dx, size.height + position.dy - halfLength),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = half; y < size.height; y += scaledSpacing) {
      canvas.drawLine(
        Offset(halfLength + position.dx, y + position.dy),
        Offset(size.width - halfLength + position.dx, y + position.dy),
        paint,
      );
    }
  }
}

/// A CustomPainter widget to display the grid
class GridPainter extends CustomPainter {
  final Grid grid;

  GridPainter(this.grid);

  @override
  void paint(Canvas canvas, Size size) {
    grid.paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.grid != grid;
  }
}
