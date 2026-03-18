import 'package:flutter/material.dart';

/// Interactive pixel canvas with zoom/pan support.
///
/// Each cell is [cellSize] × [cellSize] logical pixels.
/// Grid lines are drawn when [cellSize] >= 6.
class PixelCanvasWidget extends StatefulWidget {
  const PixelCanvasWidget({
    super.key,
    required this.pixels,
    this.cellSize = 12,
    required this.onPixelTap,
  });

  final List<List<int>> pixels;
  final int cellSize;
  final void Function(int row, int col) onPixelTap;

  @override
  State<PixelCanvasWidget> createState() => _PixelCanvasWidgetState();
}

class _PixelCanvasWidgetState extends State<PixelCanvasWidget> {
  // Track last painted cell to avoid duplicate events during pan.
  int _lastRow = -1;
  int _lastCol = -1;

  void _handlePointer(Offset localPos) {
    if (widget.pixels.isEmpty) return;
    final row = (localPos.dy / widget.cellSize).floor();
    final col = (localPos.dx / widget.cellSize).floor();
    if (row < 0 || row >= widget.pixels.length) return;
    if (col < 0 || col >= widget.pixels[0].length) return;
    if (row == _lastRow && col == _lastCol) return;
    _lastRow = row;
    _lastCol = col;
    widget.onPixelTap(row, col);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pixels.isEmpty) return const SizedBox.shrink();
    final rows = widget.pixels.length;
    final cols = widget.pixels[0].length;
    final canvasWidth = (cols * widget.cellSize).toDouble();
    final canvasHeight = (rows * widget.cellSize).toDouble();

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 16.0,
      child: GestureDetector(
        onPanStart: (details) {
          _lastRow = -1;
          _lastCol = -1;
          _handlePointer(details.localPosition);
        },
        onPanUpdate: (details) => _handlePointer(details.localPosition),
        onPanEnd: (_) {
          _lastRow = -1;
          _lastCol = -1;
        },
        onTapDown: (details) {
          _lastRow = -1;
          _lastCol = -1;
          _handlePointer(details.localPosition);
        },
        child: SizedBox(
          width: canvasWidth,
          height: canvasHeight,
          child: CustomPaint(
            size: Size(canvasWidth, canvasHeight),
            painter: _PixelCanvasPainter(
              pixels: widget.pixels,
              cellSize: widget.cellSize,
            ),
          ),
        ),
      ),
    );
  }
}

class _PixelCanvasPainter extends CustomPainter {
  _PixelCanvasPainter({
    required this.pixels,
    required this.cellSize,
  });

  final List<List<int>> pixels;
  final int cellSize;

  @override
  void paint(Canvas canvas, Size size) {
    final cellW = cellSize.toDouble();
    final rows = pixels.length;
    if (rows == 0) return;
    final cols = pixels[0].length;

    // Draw filled pixel rectangles.
    final paint = Paint()..style = PaintingStyle.fill;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final argb = pixels[r][c];
        paint.color = Color(argb);
        canvas.drawRect(
          Rect.fromLTWH(c * cellW, r * cellW, cellW, cellW),
          paint,
        );
      }
    }

    // Draw grid lines when cell size is large enough to be legible.
    if (cellSize >= 6) {
      final gridPaint = Paint()
        ..color = const Color(0xFF1A2F50)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      for (int r = 0; r <= rows; r++) {
        canvas.drawLine(
          Offset(0, r * cellW),
          Offset(cols * cellW, r * cellW),
          gridPaint,
        );
      }
      for (int c = 0; c <= cols; c++) {
        canvas.drawLine(
          Offset(c * cellW, 0),
          Offset(c * cellW, rows * cellW),
          gridPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PixelCanvasPainter oldDelegate) =>
      oldDelegate.pixels != pixels || oldDelegate.cellSize != cellSize;
}
