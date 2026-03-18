import 'package:flutter/material.dart';

import 'package:aslan_pixel/features/feed/data/models/feed_post_model.dart';
import 'package:aslan_pixel/features/feed/bloc/feed_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── Colour constants ──────────────────────────────────────────────────────────
const Color _neonGreen = Color(0xFF00F5A0);
const Color _gold = Color(0xFFF5C518);
const Color _purple = Color(0xFF7B2FFF);
const Color _textWhite = Color(0xFFE8F4F8);
const Color _surface = Color(0xFF0F2040);

/// A card widget that renders a single [FeedPostModel] in the feed list.
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
                Text(
                  post.contentTh ?? post.content,
                  style: const TextStyle(
                    color: _textWhite,
                    fontSize: 14,
                    height: 1.5,
                  ),
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
            color: isSystem ? _neonGreen.withValues(alpha: 0.15) : _purple.withValues(alpha: 0.25),
            border: Border.all(
              color: isSystem ? _neonGreen : _purple,
              width: 1.5,
            ),
          ),
          child: Center(
            child: isSystem
                ? Icon(Icons.smart_toy_outlined, size: 18, color: _neonGreen)
                : Text(
                    initial ?? '?',
                    style: TextStyle(
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
        // Like button
        GestureDetector(
          onTap: () {
            if (currentUid != null) {
              context.read<FeedBloc>().add(
                    FeedReactionAdded(
                      postId: post.postId,
                      emoji: '❤️',
                      uid: currentUid!,
                    ),
                  );
            }
          },
          child: Row(
            children: [
              Icon(Icons.favorite_border, size: 16, color: _gold),
              const SizedBox(width: 4),
              Text(
                '❤️ ถูกใจ',
                style: TextStyle(
                  color: _gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

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
