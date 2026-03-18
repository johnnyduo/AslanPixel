import 'package:flutter/material.dart';

// ── Color constants ───────────────────────────────────────────────────────────
const Color _surface = Color(0xFF0F2040);
const Color _neonGreen = Color(0xFF00f5a0);
const Color _textWhite = Color(0xFFE8F4F8);
const Color _textSecondary = Color(0xFFa8c4e0);

/// A slide-in banner that appears from the top of the screen for foreground
/// FCM notifications. Auto-dismisses after [_autoDismissDelay].
///
/// Usage:
/// ```dart
/// NotificationBanner.show(context, title: 'Title', body: 'Body text');
/// ```
class NotificationBanner extends StatefulWidget {
  const NotificationBanner({
    super.key,
    required this.title,
    required this.body,
    required this.onDismiss,
  });

  final String title;
  final String body;
  final VoidCallback onDismiss;

  static const Duration _autoDismissDelay = Duration(seconds: 4);
  static const Duration _animationDuration = Duration(milliseconds: 350);

  /// Show a sliding notification banner at the top of [context]'s overlay.
  static void show(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _NotificationBannerOverlay(
        title: title,
        body: body,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }

  @override
  State<NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<NotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: NotificationBanner._animationDuration,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // Auto-dismiss after delay
    Future.delayed(NotificationBanner._autoDismissDelay, _dismiss);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (!mounted) return;
    _controller.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: _dismiss,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _neonGreen.withValues(alpha: 0.35),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _neonGreen.withValues(alpha: 0.12),
                    border: Border.all(
                      color: _neonGreen.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: _neonGreen,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.title.isNotEmpty)
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: _textWhite,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (widget.body.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.body,
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _dismiss,
                  child: Icon(
                    Icons.close,
                    color: _textSecondary.withValues(alpha: 0.6),
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Internal overlay widget that positions the banner with safe-area padding.
class _NotificationBannerOverlay extends StatelessWidget {
  const _NotificationBannerOverlay({
    required this.title,
    required this.body,
    required this.onDismiss,
  });

  final String title;
  final String body;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topPadding + 8,
      left: 0,
      right: 0,
      child: NotificationBanner(
        title: title,
        body: body,
        onDismiss: onDismiss,
      ),
    );
  }
}
