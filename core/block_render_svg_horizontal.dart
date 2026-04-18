import 'package:flutter/material.dart';

/// Core constants (equivalent to Blockly.BlockSvg constants)
class BlockConstants {
  static const double gridUnit = 4.0;
  static const double sepSpaceX = 3 * gridUnit;
  static const double sepSpaceY = 3 * gridUnit;
  static const double statementBlockSpace = 3 * gridUnit;

  static const double fieldHeight = 8 * gridUnit;
  static const double fieldWidth = 12 * gridUnit;
  static const double fieldWidthMinEdit = 13 * gridUnit;
  static const double fieldWidthMaxEdit = 24 * gridUnit;
  static const double fieldHeightMaxEdit = 10 * gridUnit;
  static const double fieldTopPadding = 0.25 * gridUnit;

  static const double numberFieldCornerRadius = 4 * gridUnit;
  static const double textFieldCornerRadius = 1 * gridUnit;
  static const double fieldDefaultCornerRadius = 4 * gridUnit;

  static const double minBlockX = 0.5 * 16 * gridUnit;
  static const double minBlockY = 16 * gridUnit;

  static const double tabWidth = 2 * gridUnit;
  static const double cornerRadius = gridUnit;
  static const double hatCornerRadius = 8 * gridUnit;

  static const double notchHeight = 8 * gridUnit + 2;
  static const double notchWidth = 2 * gridUnit;

  static const double imageFieldWidth = 10 * gridUnit;
  static const double imageFieldHeight = 10 * gridUnit;

  static const double fieldYOffset = -2 * gridUnit;
}

/// Represents the computed measurements for a block
class BlockMetrics {
  bool startHat = false;
  bool endCap = false;

  double width = 0;
  double height = 0;

  double bayWidth = 0;
  double bayHeight = 0;

  double fieldRadius = BlockConstants.fieldDefaultCornerRadius;

  bool bayNotchAtRight = true;
  bool hasStatement = false;
}

/// Represents a connection (simplified)
class BlockConnection {
  Offset position = Offset.zero;

  void moveTo(double x, double y) {
    position = Offset(x, y);
  }
}

/// Represents a horizontal block
class HorizontalBlock {
  bool isShadow = false;

  bool previousConnectionExists = false;
  bool nextConnectionExists = false;

  BlockConnection? previousConnection;
  BlockConnection? nextConnection;

  double width = 0;
  double height = 0;

  HorizontalBlock({this.isShadow = false});
}

/// CustomPainter to render a horizontal block
class HorizontalBlockPainter extends CustomPainter {
  final BlockMetrics metrics;

  HorizontalBlockPainter(this.metrics);

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();

    // Top-left corner / hat
    if (metrics.startHat) {
      path.moveTo(BlockConstants.hatCornerRadius, 0);
      path.arcToPoint(
        Offset(0, BlockConstants.hatCornerRadius),
        radius: Radius.circular(BlockConstants.hatCornerRadius),
        clockwise: false,
      );
    } else {
      path.moveTo(metrics.fieldRadius, 0);
      path.arcToPoint(
        Offset(0, metrics.fieldRadius),
        radius: Radius.circular(metrics.fieldRadius),
        clockwise: false,
      );
    }

    // Left vertical
    path.lineTo(0, metrics.height - metrics.fieldRadius);
    path.arcToPoint(
      Offset(metrics.fieldRadius, metrics.height),
      radius: Radius.circular(metrics.fieldRadius),
      clockwise: false,
    );

    // Bottom horizontal
    path.lineTo(metrics.width - metrics.fieldRadius, metrics.height);
    path.arcToPoint(
      Offset(metrics.width, metrics.height - metrics.fieldRadius),
      radius: Radius.circular(metrics.fieldRadius),
      clockwise: false,
    );

    // Right vertical
    path.lineTo(metrics.width, metrics.fieldRadius);
    path.arcToPoint(
      Offset(metrics.width - metrics.fieldRadius, 0),
      radius: Radius.circular(metrics.fieldRadius),
      clockwise: false,
    );

    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
