import 'package:flutter/material.dart';

import 'package:aslan_pixel/features/home/data/models/ranking_entry_model.dart';
import 'package:aslan_pixel/features/home/data/repositories/ranking_repository.dart';
import 'package:aslan_pixel/shared/widgets/empty_state_widget.dart';

// ── Color constants ──────────────────────────────────────────────────────────
const Color _navy = Color(0xFF0A1628);
const Color _surface = Color(0xFF0F2040);
const Color _neonGreen = Color(0xFF00F5A0);
const Color _gold = Color(0xFFF5C518);
const Color _silver = Color(0xFFB0BEC5);
const Color _bronze = Color(0xFFCD7F32);
const Color _textWhite = Color(0xFFE8F4F8);
const Color _textSecondary = Color(0xFFA8C4E0);

// ── LeaderboardPage ───────────────────────────────────────────────────────────

/// Full-screen leaderboard showing weekly and all-time rankings.
class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key, required this.rankingRepository});

  static const String routeName = '/leaderboard';

  final RankingRepository rankingRepository;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _navy,
        appBar: AppBar(
          backgroundColor: _navy,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: _textWhite),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'อันดับ',
            style: TextStyle(
              color: _textWhite,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: _neonGreen,
            indicatorWeight: 2.5,
            labelColor: _neonGreen,
            unselectedLabelColor: _textSecondary,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'สัปดาห์นี้'),
              Tab(text: 'ตลอดกาล'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _LeaderboardTab(
              period: 'weekly',
              rankingRepository: rankingRepository,
            ),
            _LeaderboardTab(
              period: 'alltime',
              rankingRepository: rankingRepository,
            ),
          ],
        ),
      ),
    );
  }
}

// ── _LeaderboardTab ───────────────────────────────────────────────────────────

class _LeaderboardTab extends StatelessWidget {
  const _LeaderboardTab({
    required this.period,
    required this.rankingRepository,
  });

  final String period;
  final RankingRepository rankingRepository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RankingEntryModel>>(
      stream: rankingRepository.watchLeaderboard(period),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: _neonGreen,
              strokeWidth: 2,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'เกิดข้อผิดพลาด: ${snapshot.error}',
              style: const TextStyle(color: _textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          );
        }

        final entries = snapshot.data ?? [];

        if (entries.isEmpty) {
          return const EmptyStateWidget(
            emoji: '🏆',
            titleTh: 'ยังไม่มีข้อมูลอันดับ',
            subtitleTh: 'ทำ Quest เพื่อขึ้นอันดับแรก!',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final entry = entries[index];
            final displayRank = index + 1;
            return _RankEntryTile(entry: entry, displayRank: displayRank);
          },
        );
      },
    );
  }
}

// ── _RankEntryTile ────────────────────────────────────────────────────────────

class _RankEntryTile extends StatelessWidget {
  const _RankEntryTile({
    required this.entry,
    required this.displayRank,
  });

  final RankingEntryModel entry;
  final int displayRank;

  Color get _rankColor {
    switch (displayRank) {
      case 1:
        return _gold;
      case 2:
        return _silver;
      case 3:
        return _bronze;
      default:
        return _textSecondary;
    }
  }

  bool get _isTopThree => displayRank <= 3;

  @override
  Widget build(BuildContext context) {
    final rankColor = _rankColor;

    return Container(
      decoration: BoxDecoration(
        color: _isTopThree
            ? rankColor.withValues(alpha: 0.08)
            : _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isTopThree
              ? rankColor.withValues(alpha: 0.35)
              : _textSecondary.withValues(alpha: 0.1),
          width: _isTopThree ? 1.2 : 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 36,
            child: Text(
              '#$displayRank',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: rankColor,
                fontSize: _isTopThree ? 17 : 15,
                fontWeight: _isTopThree
                    ? FontWeight.bold
                    : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Avatar circle
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rankColor.withValues(alpha: 0.15),
              border: Border.all(
                color: rankColor.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                _initials(entry.displayName),
                style: TextStyle(
                  color: rankColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Display name
          Expanded(
            child: Text(
              entry.displayName ?? '—',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _isTopThree ? _textWhite : _textSecondary,
                fontSize: 14,
                fontWeight: _isTopThree ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          // Score
          Text(
            _formatScore(entry.score),
            style: TextStyle(
              color: _neonGreen,
              fontSize: _isTopThree ? 16 : 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _formatScore(int score) {
    if (score >= 1000000) {
      return '${(score / 1000000).toStringAsFixed(1)}M';
    } else if (score >= 1000) {
      return '${(score / 1000).toStringAsFixed(1)}K';
    }
    return score.toString();
  }
}
