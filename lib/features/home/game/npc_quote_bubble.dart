// ---------------------------------------------------------------------------
// npc_quote_bubble.dart
//
// A Flame PositionComponent that renders a speech-bubble above an NPC.
//
// Design:
//   - White rounded rectangle on a navy (#0A1628) background, neon-green
//     (#00F5A0) 1.5-px border.
//   - A small equilateral triangle "tail" points downward from the bubble
//     toward the NPC.
//   - Text auto word-wraps at max 160 px.
//   - The component fades out over the final second of its 3-second lifetime
//     and calls removeFromParent() when fully transparent.
// ---------------------------------------------------------------------------

import 'dart:ui' as ui;

import 'package:flame/components.dart';


// ---------------------------------------------------------------------------
// NpcQuoteBubble
// ---------------------------------------------------------------------------

/// A speech-bubble component that floats above the NPC, displays [text], and
/// auto-fades out after [displaySeconds] seconds.
///
/// Position the component with [npcPosition] — the bubble will place itself
/// [_yOffset] pixels above the NPC centre.
class NpcQuoteBubble extends PositionComponent {
  NpcQuoteBubble({
    required String text,
    required Vector2 npcPosition,
    double displaySeconds = 3.0,
  })  : _text = text,
        _displaySeconds = displaySeconds,
        super(
          // Anchor is top-centre; we shift x by half the bubble width so the
          // tail stays centred on the NPC horizontally.
          position: Vector2(
            npcPosition.x.clamp(_maxBubbleWidth / 2 + 10, 400 - _maxBubbleWidth / 2 - 10),
            (npcPosition.y - _yOffset).clamp(10, 400 - _estimatedHeight),
          ),
          anchor: Anchor.bottomCenter,
          // Size is determined after layout; use a generous initial size.
          size: Vector2(_maxBubbleWidth + _horizontalPadding * 2,
              _estimatedHeight),
        );

  final String _text;
  final double _displaySeconds;

  double _elapsed = 0;

  // Fade starts this many seconds before the bubble disappears.
  static const double _fadeDuration = 1.0;

  // Vertical gap between NPC centre and the bottom of the bubble (tail tip).
  static const double _yOffset = 70.0;

  // Layout constants
  static const double _maxBubbleWidth = 160.0;
  static const double _horizontalPadding = 10.0;
  static const double _verticalPadding = 8.0;
  static const double _cornerRadius = 8.0;
  static const double _tailHeight = 8.0;
  static const double _tailHalfWidth = 6.0;
  static const double _estimatedHeight = 60.0;
  static const double _fontSize = 10.5;
  static const double _borderWidth = 1.5;

  static const _colorNavy = ui.Color(0xFF0A1628);
  static const _colorNeonGreen = ui.Color(0xFF00F5A0);
  static const _colorText = ui.Color(0xFFFFFFFF);

  // Built lazily in render to avoid depending on game reference.
  ui.Paragraph? _paragraph;
  double _bubbleWidth = 0;
  double _bubbleHeight = 0;
  bool _layoutDone = false;

  // Opacity in 0..1 range; used for the whole component.
  double _opacity = 1.0;

  // ---------------------------------------------------------------------------
  // Update
  // ---------------------------------------------------------------------------

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;

    // Fade phase
    final fadeStartAt = _displaySeconds - _fadeDuration;
    if (_elapsed >= fadeStartAt) {
      _opacity =
          1.0 - ((_elapsed - fadeStartAt) / _fadeDuration).clamp(0.0, 1.0);
    }

    if (_elapsed >= _displaySeconds) {
      removeFromParent();
    }
  }

  // ---------------------------------------------------------------------------
  // Render
  // ---------------------------------------------------------------------------

  @override
  void render(ui.Canvas canvas) {
    if (_opacity <= 0) return;

    _ensureLayout();

    canvas.save();
    canvas.translate(-_bubbleWidth / 2, -_bubbleHeight - _tailHeight);

    // Fade via layer opacity.
    final alphaByte = (_opacity * 255).round().clamp(0, 255);
    canvas.saveLayer(
      ui.Rect.fromLTWH(0, 0, _bubbleWidth, _bubbleHeight + _tailHeight),
      ui.Paint()..color = ui.Color.fromARGB(alphaByte, 255, 255, 255),
    );

    _drawBubbleBackground(canvas);
    _drawBubbleBorder(canvas);
    _drawTail(canvas);
    _drawText(canvas);

    canvas.restore(); // layer
    canvas.restore(); // translate
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _ensureLayout() {
    if (_layoutDone) return;
    _layoutDone = true;

    final pb = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: ui.TextAlign.center,
        fontSize: _fontSize,
        fontWeight: ui.FontWeight.w600,
      ),
    )
      ..pushStyle(
        ui.TextStyle(
          color: _colorText,
          fontSize: _fontSize,
          fontWeight: ui.FontWeight.w600,
        ),
      )
      ..addText(_text);

    final paragraph = pb.build();
    paragraph.layout(
      const ui.ParagraphConstraints(width: _maxBubbleWidth),
    );
    _paragraph = paragraph;

    _bubbleWidth =
        paragraph.longestLine.clamp(40.0, _maxBubbleWidth) +
            _horizontalPadding * 2;
    _bubbleHeight = paragraph.height + _verticalPadding * 2;

    size = Vector2(_bubbleWidth, _bubbleHeight + _tailHeight);
  }

  void _drawBubbleBackground(ui.Canvas canvas) {
    final rect = ui.RRect.fromLTRBR(
      0,
      0,
      _bubbleWidth,
      _bubbleHeight,
      const ui.Radius.circular(_cornerRadius),
    );
    canvas.drawRRect(
      rect,
      ui.Paint()..color = _colorNavy,
    );
  }

  void _drawBubbleBorder(ui.Canvas canvas) {
    final rect = ui.RRect.fromLTRBR(
      _borderWidth / 2,
      _borderWidth / 2,
      _bubbleWidth - _borderWidth / 2,
      _bubbleHeight - _borderWidth / 2,
      const ui.Radius.circular(_cornerRadius),
    );
    canvas.drawRRect(
      rect,
      ui.Paint()
        ..color = _colorNeonGreen
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = _borderWidth,
    );
  }

  void _drawTail(ui.Canvas canvas) {
    // Triangle pointing downward from the bottom-centre of the bubble.
    final midX = _bubbleWidth / 2;
    final tailTop = _bubbleHeight;
    final tailTip = _bubbleHeight + _tailHeight;

    final path = ui.Path()
      ..moveTo(midX - _tailHalfWidth, tailTop)
      ..lineTo(midX + _tailHalfWidth, tailTop)
      ..lineTo(midX, tailTip)
      ..close();

    canvas.drawPath(path, ui.Paint()..color = _colorNavy);

    // Neon border on the tail edges (left + right sides only).
    final borderPath = ui.Path()
      ..moveTo(midX - _tailHalfWidth, tailTop)
      ..lineTo(midX, tailTip)
      ..lineTo(midX + _tailHalfWidth, tailTop);

    canvas.drawPath(
      borderPath,
      ui.Paint()
        ..color = _colorNeonGreen
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = _borderWidth
        ..strokeCap = ui.StrokeCap.round,
    );
  }

  void _drawText(ui.Canvas canvas) {
    final para = _paragraph;
    if (para == null) return;
    canvas.drawParagraph(
      para,
      ui.Offset(_horizontalPadding, _verticalPadding),
    );
  }
}

