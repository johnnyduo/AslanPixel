import 'package:flutter/material.dart';

/// A lightweight animated sparkline chart for time-series data.
///
/// Animates from a flat baseline to the full dataset on first display.
/// Supports an optional filled area with a gradient under the line.
///
/// Usage:
/// ```dart
/// AnimatedSparkline(values: [1.2, 3.4, 2.1, 5.0, 4.3])
/// ```
class AnimatedSparkline extends StatefulWidget {
  const AnimatedSparkline({
    super.key,
    required this.values,
    this.lineColor,
    this.fillColor,
    this.height = 48,
    this.strokeWidth = 2.0,
  });

  final List<double> values;
  final Color? lineColor;
  final Color? fillColor;
  final double height;
  final double strokeWidth;

  @override
  State<AnimatedSparkline> createState() => _AnimatedSparklineState();
}

class _AnimatedSparklineState extends State<AnimatedSparkline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedSparkline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.values != widget.values) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const defaultLineColor = Color(0xFF00f5a0); // neon green
    final effectiveLineColor = widget.lineColor ?? defaultLineColor;

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, _) => CustomPaint(
          painter: _SparklinePainter(
            values: widget.values,
            lineColor: effectiveLineColor,
            fillColor: widget.fillColor,
            strokeWidth: widget.strokeWidth,
            progress: _progress.value,
          ),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.lineColor,
    required this.strokeWidth,
    required this.progress,
    this.fillColor,
  });

  final List<double> values;
  final Color lineColor;
  final Color? fillColor;
  final double strokeWidth;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Empty: draw grey flat line
    if (values.isEmpty) {
      final paint = Paint()
        ..color = const Color(0xFF3d5a78)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final midY = size.height / 2;
      canvas.drawLine(Offset(0, midY), Offset(size.width, midY), paint);
      return;
    }

    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final range = maxVal - minVal;

    // All same value: draw flat line at midpoint
    if (range == 0) {
      final paint = Paint()
        ..color = lineColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final midY = size.height / 2;
      canvas.drawLine(Offset(0, midY), Offset(size.width, midY), paint);
      return;
    }

    final count = values.length;
    final stepX = size.width / (count - 1).clamp(1, double.infinity);
    final baselineY = size.height; // flat baseline (progress = 0)

    // Build normalised points — interpolate between baseline and actual
    List<Offset> points = List.generate(count, (i) {
      final x = i * stepX;
      final normalised = (values[i] - minVal) / range; // 0..1
      final fullY = size.height - normalised * size.height;
      final y = baselineY + (fullY - baselineY) * progress;
      return Offset(x, y);
    });

    // ── Fill area ────────────────────────────────────────────────────────────
    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final pt in points) {
      fillPath.lineTo(pt.dx, pt.dy);
    }
    fillPath
      ..lineTo(points.last.dx, size.height)
      ..close();

    final effectiveFillColor = fillColor ?? lineColor;
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          effectiveFillColor.withValues(alpha: 0.2),
          effectiveFillColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // ── Line ─────────────────────────────────────────────────────────────────
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values ||
      old.progress != progress ||
      old.lineColor != lineColor ||
      old.strokeWidth != strokeWidth;
}
