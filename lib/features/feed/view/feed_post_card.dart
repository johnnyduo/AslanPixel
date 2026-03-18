import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aslan_pixel/features/feed/bloc/feed_bloc.dart';
import 'package:aslan_pixel/features/feed/data/models/feed_post_model.dart';
import 'package:aslan_pixel/features/feed/utils/post_text_parser.dart';

// ── Colour constants ──────────────────────────────────────────────────────────
const Color _neonGreen = Color(0xFF00F5A0);
const Color _gold = Color(0xFFF5C518);
const Color _purple = Color(0xFF7B2FFF);
const Color _textWhite = Color(0xFFE8F4F8);
const Color _surface = Color(0xFF0F2040);

/// A card widget that renders a single [FeedPostModel] in the feed list.
///
/// Supports:
/// - Hashtag (#) → neon-green bold spans via [buildRichPostText]
/// - Mention (@) → cyan spans via [buildRichPostText]
/// - Animated heart reaction (scale pulse + optimistic like count)
class FeedPostCard extends StatelessWidget {
  const FeedPostCard({super.key, required this.post, this.currentUid});

  final FeedPostModel post;

  /// The authenticated user's UID, used for reaction dispatch.
  final String? currentUid;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.type == 'achievement') _AchievementBanner(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AuthorRow(post: post),
                const SizedBox(height: 10),
                // ── Rich text with hashtag / mention parsing ──────────────
                RichText(
                  text: buildRichPostText(post.contentTh ?? post.content),
                ),
                const SizedBox(height: 12),
                _ReactionRow(post: post, currentUid: currentUid),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _AchievementBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1A2F50),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(
          bottom: BorderSide(color: Color(0xFFF5C518), width: 1),
        ),
      ),
      child: const Text(
        '🏆 ความสำเร็จ',
        style: TextStyle(
          color: Color(0xFFF5C518),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({required this.post});

  final FeedPostModel post;

  @override
  Widget build(BuildContext context) {
    final isSystem = post.type == 'system';
    final initial = isSystem
        ? null
        : (post.authorUid?.isNotEmpty == true
            ? post.authorUid![0].toUpperCase()
            : '?');

    return Row(
      children: [
        // Avatar
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSystem
                ? _neonGreen.withValues(alpha: 0.15)
                : _purple.withValues(alpha: 0.25),
            border: Border.all(
              color: isSystem ? _neonGreen : _purple,
              width: 1.5,
            ),
          ),
          child: Center(
            child: isSystem
                ? const Icon(Icons.smart_toy_outlined, size: 18, color: _neonGreen)
                : Text(
                    initial ?? '?',
                    style: const TextStyle(
                      color: _neonGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSystem ? 'AslanPixel System' : (post.authorUid ?? 'ผู้ใช้'),
                style: const TextStyle(
                  color: _textWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _timeAgoThai(post.createdAt),
                style: TextStyle(
                  color: _textWhite.withValues(alpha: 0.5),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _timeAgoThai(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 2) return 'เมื่อกี้';
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inHours < 24) return '${diff.inHours} ชั่วโมงที่แล้ว';
    return '${diff.inDays} วันที่แล้ว';
  }
}

// ── Reaction row ───────────────────────────────────────────────────────────────

class _ReactionRow extends StatelessWidget {
  const _ReactionRow({required this.post, this.currentUid});

  final FeedPostModel post;
  final String? currentUid;

  @override
  Widget build(BuildContext context) {
    // Sort reactions descending by count and take top 3.
    final sortedReactions = post.reactions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topReactions = sortedReactions.take(3).toList();

    return Row(
      children: [
        // Top reaction chips
        ...topReactions.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _ReactionChip(emoji: entry.key, count: entry.value),
          ),
        ),
        const Spacer(),
        // Animated heart like button
        _HeartButton(post: post, currentUid: currentUid),
      ],
    );
  }
}

// ── Animated heart button ─────────────────────────────────────────────────────

class _HeartButton extends StatefulWidget {
  const _HeartButton({required this.post, this.currentUid});

  final FeedPostModel post;
  final String? currentUid;

  @override
  State<_HeartButton> createState() => _HeartButtonState();
}

class _HeartButtonState extends State<_HeartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  // Optimistic local like state.
  bool _liked = false;
  int _extraLikes = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    if (widget.currentUid != null) {
      context.read<FeedBloc>().add(
            FeedReactionAdded(
              postId: widget.post.postId,
              emoji: '❤️',
              uid: widget.currentUid!,
            ),
          );
    }
    setState(() {
      _liked = !_liked;
      _extraLikes = _liked ? 1 : 0;
    });
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final heartCount =
        (widget.post.reactions['❤️'] ?? 0) + _extraLikes;

    return GestureDetector(
      onTap: _onTap,
      child: ScaleTransition(
        scale: _scale,
        child: Row(
          children: [
            Icon(
              _liked ? Icons.favorite : Icons.favorite_border,
              size: 16,
              color: _liked ? Colors.redAccent : _gold,
            ),
            const SizedBox(width: 4),
            Text(
              heartCount > 0 ? '❤️ $heartCount' : '❤️ ถูกใจ',
              style: TextStyle(
                color: _liked ? Colors.redAccent : _gold,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reaction chip ─────────────────────────────────────────────────────────────

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({required this.emoji, required this.count});

  final String emoji;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2F50),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$emoji $count',
        style: const TextStyle(
          color: Color(0xFFE8F4F8),
          fontSize: 12,
        ),
      ),
    );
  }
}
