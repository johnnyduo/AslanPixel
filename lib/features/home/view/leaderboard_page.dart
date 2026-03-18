import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aslan_pixel/core/config/app_colors.dart';
import 'package:aslan_pixel/features/home/bloc/ranking_bloc.dart';
import 'package:aslan_pixel/features/home/data/models/ranking_entry_model.dart';
import 'package:aslan_pixel/shared/widgets/animated_coin_counter.dart';
import 'package:aslan_pixel/shared/widgets/empty_state_widget.dart';

// ── LeaderboardPage ───────────────────────────────────────────────────────────

/// Full-screen leaderboard showing weekly and all-time rankings.
///
/// Expects a [RankingBloc] and the current user's [uid] to be provided by the
/// route (see route_generator.dart).
class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key, required this.uid});

  static const String routeName = '/leaderboard';

  /// The currently signed-in user's uid — used to highlight their row.
  final String uid;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: _LeaderboardShell(uid: uid),
    );
  }
}

// ── _LeaderboardShell ─────────────────────────────────────────────────────────

class _LeaderboardShell extends StatefulWidget {
  const _LeaderboardShell({required this.uid});

  final String uid;

  @override
  State<_LeaderboardShell> createState() => _LeaderboardShellState();
}

class _LeaderboardShellState extends State<_LeaderboardShell>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  static const _periods = ['weekly', 'alltime'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final period = _periods[_tabController.index];
    context.read<RankingBloc>().add(
          RankingWatchStarted(uid: widget.uid, period: period),
        );
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: colors.appBarBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: colors.appBarForeground),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'อันดับ',
          style: TextStyle(
            color: colors.appBarForeground,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colors.primary,
          indicatorWeight: 2.5,
          labelColor: colors.primary,
          unselectedLabelColor: colors.textSecondary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'รายสัปดาห์'),
            Tab(text: 'ตลอดกาล'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _LeaderboardTab(uid: widget.uid, period: 'weekly'),
          _LeaderboardTab(uid: widget.uid, period: 'alltime'),
        ],
      ),
    );
  }
}

// ── _LeaderboardTab ───────────────────────────────────────────────────────────

class _LeaderboardTab extends StatelessWidget {
  const _LeaderboardTab({required this.uid, required this.period});

  final String uid;
  final String period;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RankingBloc, RankingState>(
      buildWhen: (prev, curr) {
        // Only rebuild this tab when state is either non-period-specific
        // (loading/error/initial) or matches this tab's period.
        if (curr is RankingLoaded) return curr.period == period;
        return true;
      },
      builder: (context, state) {
        if (state is RankingInitial || state is RankingLoading) {
          return const _ShimmerList();
        }

        if (state is RankingError) {
          return _ErrorView(
            message: state.message,
            onRetry: () => context.read<RankingBloc>().add(
                  RankingWatchStarted(uid: uid, period: period),
                ),
          );
        }

        if (state is RankingLoaded) {
          if (state.entries.isEmpty) {
            return const EmptyStateWidget(
              emoji: '🏆',
              titleTh: 'ยังไม่มีข้อมูล',
              subtitleTh: 'ทำ Quest เพื่อขึ้นอันดับแรก!',
            );
          }

          return _RankingList(
            entries: state.entries,
            myUid: uid,
            myRank: state.myRank,
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

// ── _RankingList ──────────────────────────────────────────────────────────────

class _RankingList extends StatelessWidget {
  const _RankingList({
    required this.entries,
    required this.myUid,
    required this.myRank,
  });

  final List<RankingEntryModel> entries;
  final String myUid;
  final int? myRank;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final rank = index + 1;
        final isMe = entry.uid == myUid;
        return _RankEntryTile(
          entry: entry,
          displayRank: rank,
          isCurrentUser: isMe,
          myScore: isMe ? entry.score : null,
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
    required this.isCurrentUser,
    this.myScore,
  });

  final RankingEntryModel entry;
  final int displayRank;
  final bool isCurrentUser;

  /// Non-null only when this tile belongs to the current user — used to
  /// trigger the AnimatedCoinCounter.
  final int? myScore;

  static const Color _gold = Color(0xFFF5C518);
  static const Color _silver = Color(0xFFB0BEC5);
  static const Color _bronze = Color(0xFFCD7F32);

  Color _rankColor(AppColorScheme colors) {
    switch (displayRank) {
      case 1:
        return _gold;
      case 2:
        return _silver;
      case 3:
        return _bronze;
      default:
        return isCurrentUser ? colors.primary : colors.textSecondary;
    }
  }

  bool get _isTopThree => displayRank <= 3;

  String _medalEmoji() {
    switch (displayRank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final rankColor = _rankColor(colors);

    // Highlighted border/background for current user or top-3
    final bool highlighted = isCurrentUser || _isTopThree;

    Color tileBg;
    Color tileBorder;

    if (isCurrentUser) {
      tileBg = colors.primary.withValues(alpha: 0.1);
      tileBorder = colors.primary.withValues(alpha: 0.55);
    } else if (_isTopThree) {
      tileBg = rankColor.withValues(alpha: 0.07);
      tileBorder = rankColor.withValues(alpha: 0.3);
    } else {
      tileBg = colors.surface;
      tileBorder = colors.borderSubtle;
    }

    final double avatarSize = _isTopThree ? 46 : 40;
    final double rankFontSize = _isTopThree ? 17 : 14;

    return Container(
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tileBorder,
          width: highlighted ? 1.3 : 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          // Rank badge
          SizedBox(
            width: 40,
            child: _isTopThree
                ? Text(
                    _medalEmoji(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: _isTopThree ? 22 : 16),
                  )
                : Text(
                    '#$displayRank',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: rankColor,
                      fontSize: rankFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(width: 10),

          // Avatar
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rankColor.withValues(alpha: 0.15),
              border: Border.all(
                color: rankColor.withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                _initials(entry.displayName),
                style: TextStyle(
                  color: rankColor,
                  fontSize: _isTopThree ? 15 : 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.displayName ?? '—',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isCurrentUser
                        ? colors.primary
                        : (_isTopThree
                            ? colors.textPrimary
                            : colors.textSecondary),
                    fontSize: _isTopThree ? 15 : 13,
                    fontWeight: _isTopThree || isCurrentUser
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                if (isCurrentUser) ...[
                  const SizedBox(height: 1),
                  Text(
                    'คุณ',
                    style: TextStyle(
                      color: colors.primary.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Score — animated counter for current user, static for others
          if (myScore != null)
            AnimatedCoinCounter(
              toAmount: myScore!,
              fontSize: _isTopThree ? 16 : 14,
            )
          else
            Text(
              _formatScore(entry.score),
              style: TextStyle(
                color: _isTopThree ? colors.accent : colors.primary,
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

// ── _ShimmerList ──────────────────────────────────────────────────────────────

/// Skeleton placeholder rows shown while data is loading.
class _ShimmerList extends StatefulWidget {
  const _ShimmerList();

  @override
  State<_ShimmerList> createState() => _ShimmerListState();
}

class _ShimmerListState extends State<_ShimmerList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final baseAlpha = 0.35 + 0.25 * _anim.value;
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          itemCount: 8,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            return Container(
              height: 64,
              decoration: BoxDecoration(
                color: colors.shimmerBase.withValues(alpha: baseAlpha),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  // rank placeholder
                  Container(
                    width: 32,
                    height: 18,
                    decoration: BoxDecoration(
                      color: colors.shimmerHighlight.withValues(alpha: baseAlpha),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // avatar placeholder
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.shimmerHighlight.withValues(alpha: baseAlpha),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // name placeholder
                  Expanded(
                    child: Container(
                      height: 14,
                      margin: const EdgeInsets.only(right: 40),
                      decoration: BoxDecoration(
                        color: colors.shimmerHighlight.withValues(alpha: baseAlpha),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  // score placeholder
                  Container(
                    width: 44,
                    height: 14,
                    margin: const EdgeInsets.only(right: 14),
                    decoration: BoxDecoration(
                      color: colors.shimmerHighlight.withValues(alpha: baseAlpha),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── _ErrorView ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, color: colors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'เกิดข้อผิดพลาด',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh_rounded, color: colors.primary),
              label: Text(
                'ลองใหม่',
                style: TextStyle(color: colors.primary),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
