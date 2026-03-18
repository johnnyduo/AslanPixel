import 'package:flutter/material.dart';

/// Generic empty-state placeholder used by feed, quests, and badges.
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.emoji,
    required this.titleTh,
    this.subtitleTh,
    this.onAction,
    this.actionLabelTh,
  });

  final String emoji;
  final String titleTh;
  final String? subtitleTh;
  final VoidCallback? onAction;
  final String? actionLabelTh;

  static const Color _textWhite = Color(0xFFe8f4f8);
  static const Color _textSecondary = Color(0xFFa8c4e0);
  static const Color _neonGreen = Color(0xFF00f5a0);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            Text(
              titleTh,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textWhite,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitleTh != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitleTh!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
            if (onAction != null && actionLabelTh != null) ...[
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _neonGreen),
                  foregroundColor: _neonGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(
                  actionLabelTh!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
