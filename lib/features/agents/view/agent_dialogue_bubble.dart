import 'dart:async';

import 'package:flutter/material.dart';
import 'package:aslan_pixel/core/enums/agent_type.dart';

// ---------------------------------------------------------------------------
// Agent colour palette
// ---------------------------------------------------------------------------

Color _agentColor(AgentType type) {
  switch (type) {
    case AgentType.analyst:
      return const Color(0xFF00F5A0); // neon green
    case AgentType.scout:
      return const Color(0xFFFFD700); // gold
    case AgentType.risk:
      return const Color(0xFF7B2FFF); // purple
    case AgentType.social:
      return const Color(0xFF00E5FF); // cyan
  }
}

// ---------------------------------------------------------------------------
// AgentDialogueBubble
// ---------------------------------------------------------------------------

/// Animated speech bubble that displays an agent dialogue line.
///
/// Slides in from below and fades in over 300 ms.
/// Auto-hides after 4 seconds.
/// Returns [SizedBox.shrink] immediately when [isVisible] is false.
class AgentDialogueBubble extends StatefulWidget {
  const AgentDialogueBubble({
    super.key,
    required this.text,
    required this.agentType,
    this.isVisible = true,
  });

  final String text;
  final AgentType agentType;
  final bool isVisible;

  @override
  State<AgentDialogueBubble> createState() => _AgentDialogueBubbleState();
}

class _AgentDialogueBubbleState extends State<AgentDialogueBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    if (widget.isVisible) {
      _playIn();
    }
  }

  @override
  void didUpdateWidget(covariant AgentDialogueBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _playIn();
    } else if (!widget.isVisible) {
      _controller.reverse();
      _hideTimer?.cancel();
    }
  }

  void _playIn() {
    _controller.forward(from: 0);
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    final color = _agentColor(widget.agentType);
    final displayText = widget.text.length > 60
        ? '${widget.text.substring(0, 60)}…'
        : widget.text;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0F2040),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(12),
            ),
            border: Border.all(color: color, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Text(
            displayText,
            style: const TextStyle(
              color: Color(0xFFE8F4F8),
              fontSize: 12,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
