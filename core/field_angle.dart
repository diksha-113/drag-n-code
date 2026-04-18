import 'dart:math' as math;
import 'package:flutter/material.dart';

typedef AngleValidator = double? Function(double newValue);
typedef AngleChanged = void Function(double newValue);

class AngleField extends StatefulWidget {
  final double initialValue;
  final AngleChanged? onChanged;
  final AngleValidator? validator;
  final double round;
  final bool clockwise;
  final double offset;
  final double wrap;

  const AngleField({
    super.key,
    this.initialValue = 0,
    this.onChanged,
    this.validator,
    this.round = 15,
    this.clockwise = true,
    this.offset = 90,
    this.wrap = 180,
  });

  @override
  State<AngleField> createState() => _AngleFieldState();
}

class _AngleFieldState extends State<AngleField> {
  late double _angle;

  @override
  void initState() {
    super.initState();
    _angle = _normalise(widget.initialValue);
  }

  double _normalise(double v) {
    double n = v % 360;
    if (n < 0) {
      n += 360;
    }
    if (n > widget.wrap) {
      n -= 360;
    }
    return n;
  }

  void _updateAngle(double v, {bool callCallback = true}) {
    double newVal = v;
    if (widget.round > 0) {
      newVal = (newVal / widget.round).round() * widget.round;
    }
    if (widget.validator != null) {
      final validated = widget.validator!(newVal);
      if (validated == null) return;
      newVal = validated;
    }
    setState(() {
      _angle = _normalise(newVal);
    });
    if (callCallback && widget.onChanged != null) {
      widget.onChanged!(_angle);
    }
  }

  Future<void> _openPicker() async {
    final pickedAngle = await showDialog<double>(
      context: context,
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: AnglePickerDialog(
            initialAngle: _angle,
            round: widget.round,
            clockwise: widget.clockwise,
            offset: widget.offset,
            wrap: widget.wrap,
            validator: widget.validator,
          ),
        ),
      ),
    );

    if (pickedAngle != null) {
      _updateAngle(pickedAngle, callCallback: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = '${_angle.round()}°';
    return InkWell(
      onTap: _openPicker,
      child: InputDecorator(
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            const Icon(Icons.explore_outlined, size: 18),
          ],
        ),
      ),
    );
  }
}

class AnglePickerDialog extends StatefulWidget {
  final double initialAngle;
  final double round;
  final bool clockwise;
  final double offset;
  final double wrap;
  final AngleValidator? validator;

  const AnglePickerDialog({
    super.key,
    required this.initialAngle,
    required this.round,
    required this.clockwise,
    required this.offset,
    required this.wrap,
    this.validator,
  });

  @override
  State<AnglePickerDialog> createState() => _AnglePickerDialogState();
}

class _AnglePickerDialogState extends State<AnglePickerDialog> {
  late double _angle;

  @override
  void initState() {
    super.initState();
    _angle = widget.initialAngle % 360;
  }

  void _onAngleChanged(double value) {
    double v = value;
    if (widget.round > 0) {
      v = (v / widget.round).round() * widget.round;
    }
    if (widget.validator != null) {
      final validated = widget.validator!(v);
      if (validated == null) return;
      v = validated;
    }
    setState(() {
      _angle = v % 360;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).dialogBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnglePicker(
            angle: _angle,
            onChanged: _onAngleChanged,
            clockwise: widget.clockwise,
            offset: widget.offset,
          ),
          const SizedBox(height: 12),
          Text('Angle: ${_angle.toStringAsFixed(0)}°',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel')),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(_angle),
                child: const Text('OK'),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class AnglePicker extends StatefulWidget {
  final double angle;
  final ValueChanged<double> onChanged;
  final bool clockwise;
  final double offset;

  const AnglePicker({
    super.key,
    required this.angle,
    required this.onChanged,
    this.clockwise = true,
    this.offset = 90,
  });

  @override
  State<AnglePicker> createState() => _AnglePickerState();
}

class _AnglePickerState extends State<AnglePicker> {
  static const double size = 240;
  late double angle;

  @override
  void initState() {
    super.initState();
    angle = widget.angle;
  }

  Offset _centerOffset() => const Offset(size / 2, size / 2);

  void _updateAngleFromLocal(Offset local) {
    final center = _centerOffset();
    final dx = local.dx - center.dx;
    final dy = local.dy - center.dy;
    double theta = math.atan2(-dy, dx);
    double deg = theta * 180 / math.pi;
    if (deg < 0) deg += 360;
    double result;
    if (widget.clockwise) {
      result = widget.offset + 360 - deg;
    } else {
      result = deg - widget.offset;
    }
    result = result % 360;
    if (result < 0) result += 360;
    setState(() {
      angle = result;
      widget.onChanged(angle);
    });
  }

  @override
  void didUpdateWidget(covariant AnglePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.angle != angle) {
      angle = widget.angle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: (e) => _updateAngleFromLocal(e.localPosition),
      onPanUpdate: (e) => _updateAngleFromLocal(e.localPosition),
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _AnglePainter(
            angle: angle,
            clockwise: widget.clockwise,
            offset: widget.offset,
          ),
        ),
      ),
    );
  }
}

class _AnglePainter extends CustomPainter {
  final double angle;
  final bool clockwise;
  final double offset;

  _AnglePainter({
    required this.angle,
    required this.clockwise,
    required this.offset,
  });

  static const double r = 96.0;
  static const double centerR = 2.0;
  static const double handleR = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final paintBg = Paint()..color = Colors.grey.shade200;
    final paintCircle = Paint()
      ..color = Colors.transparent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final marksPaint = Paint()
      ..color = Colors.white.withAlpha((0.85 * 255).toInt())
      ..strokeWidth = 2;
    final gaugePaint = Paint()
      ..color = Colors.blue.withAlpha((0.25 * 255).toInt())
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, r + 13, paintBg);
    canvas.drawCircle(center, r, paintCircle);

    for (double a = 0; a < 360; a += 15) {
      final rad = a * math.pi / 180.0;
      final inner = Offset(center.dx + (r - 13) * math.cos(rad),
          center.dy - (r - 13) * math.sin(rad));
      final outer = Offset(center.dx + (r - 7) * math.cos(rad),
          center.dy - (r - 7) * math.sin(rad));
      canvas.drawLine(inner, outer, marksPaint);
    }

    double angleDeg = angle + offset;
    double offsetRad = offset * math.pi / 180.0;
    double start = offsetRad;
    double sweep = (angleDeg - offset) * math.pi / 180.0;
    if (clockwise) {
      sweep = -sweep;
    }
    while (sweep <= -2 * math.pi) {
      sweep += 2 * math.pi;
    }
    while (sweep > 2 * math.pi) {
      sweep -= 2 * math.pi;
    }

    final path = Path();
    path.moveTo(center.dx, center.dy);
    final rect = Rect.fromCircle(center: center, radius: r);
    if (sweep.abs() > 1e-6) {
      path.addArc(rect, start, sweep);
      path.close();
      canvas.drawPath(path, gaugePaint);
    }

    final centerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, centerR, centerPaint);

    double drawDeg =
        clockwise ? (offset + 360 - angle) % 360 : (angle + offset) % 360;
    final drawRad = drawDeg * math.pi / 180.0;
    final handleX = center.dx + r * math.cos(drawRad);
    final handleY = center.dy - r * math.sin(drawRad);
    final handleCenter = Offset(handleX, handleY);

    canvas.drawLine(center, handleCenter, linePaint);

    final handlePaint = Paint()..color = Colors.white;
    canvas.drawCircle(handleCenter, handleR, handlePaint);
    final handleBorder = Paint()
      ..color = Colors.black.withAlpha((0.3 * 255).toInt())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(handleCenter, handleR, handleBorder);

    _drawArrow(canvas, handleCenter, drawRad);
  }

  void _drawArrow(Canvas canvas, Offset pos, double rotationRad) {
    final arrowSize = 10.0;
    final p1 = Offset(pos.dx + arrowSize * math.cos(rotationRad),
        pos.dy - arrowSize * math.sin(rotationRad));
    final p2 = Offset(
        pos.dx + arrowSize * 0.5 * math.cos(rotationRad + math.pi * 0.6),
        pos.dy - arrowSize * 0.5 * math.sin(rotationRad + math.pi * 0.6));
    final p3 = Offset(
        pos.dx + arrowSize * 0.5 * math.cos(rotationRad - math.pi * 0.6),
        pos.dy - arrowSize * 0.5 * math.sin(rotationRad - math.pi * 0.6));
    final paint = Paint()..color = Colors.white;
    final border = Paint()
      ..color = Colors.black.withAlpha((0.28 * 255).toInt())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(covariant _AnglePainter oldDelegate) {
    return oldDelegate.angle != angle ||
        oldDelegate.clockwise != clockwise ||
        oldDelegate.offset != offset;
  }
}
