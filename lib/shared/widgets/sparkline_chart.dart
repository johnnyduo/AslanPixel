import 'package:flutter/material.dart';

/// A minimal sparkline chart drawn with CustomPainter.
///
/// Shows [values] as a connected line in neon green with a subtle gradient fill.
/// Ideal for agent XP progress or portfolio micro-charts.
///
/// Usage:
/// ```dart
/// SparklineChart(values: [1.2, 3.4, 2.1, 5.0, 4.3])
/// ```
class SparklineChart extends StatelessWidget {
  const SparklineChart({
    super.key,
    required this.values,
    this.lineColor = const Color(0xFF00F5A0), // neon green
    this.width = 120,
    this.height = 40,
    this.strokeWidth = 2.0,
    this.showDot = true,
  });

  final List<double> values;
  final Color lineColor;
  final double width;
  final double height;
  final double strokeWidth;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return SizedBox(width: width, height: height);
    return CustomPaint(
      size: Size(width, height),
      painter: _SparklinePainter(
        values: values,
        lineColor: lineColor,
        strokeWidth: strokeWidth,
        showDot: showDot,
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.lineColor,
    required this.strokeWidth,
    required this.showDot,
  });

  final List<double> values;
  final Color lineColor;
  final double strokeWidth;
  final bool showDot;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final range = (maxVal - minVal).abs();
    final safeRange = range < 1e-6 ? 1.0 : range;

    // Map value → canvas coordinate
    Offset toPoint(int index, double value) {
      final x = (index / (values.length - 1)) * size.width;
      final y = size.height -
          ((value - minVal) / safeRange) * size.height * 0.85 -
          size.height * 0.05;
      return Offset(x, y);
    }

    // Build line path
    final path = Path();
    final first = toPoint(0, values[0]);
    path.moveTo(first.dx, first.dy);
    for (int i = 1; i < values.length; i++) {
      final pt = toPoint(i, values[i]);
      path.lineTo(pt.dx, pt.dy);
    }

    // Fill path (gradient under the line)
    final last = toPoint(values.length - 1, values.last);
    final fillPath = Path.from(path)
      ..lineTo(last.dx, size.height)
      ..lineTo(first.dx, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.25),
          lineColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    // Endpoint dot
    if (showDot) {
      canvas.drawCircle(
        last,
        strokeWidth + 1.5,
        Paint()..color = lineColor,
      );
      canvas.drawCircle(
        last,
        strokeWidth + 3,
        Paint()..color = lineColor.withValues(alpha: 0.3),
      );
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values ||
      old.lineColor != lineColor ||
      old.strokeWidth != strokeWidth ||
      old.showDot != showDot;
}
