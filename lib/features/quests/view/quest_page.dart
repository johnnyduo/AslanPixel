import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aslan_pixel/features/home/bloc/room_bloc.dart';
import 'package:aslan_pixel/features/home/bloc/room_event.dart';
import 'package:aslan_pixel/features/quests/bloc/quest_bloc.dart';
import 'package:aslan_pixel/features/quests/data/datasources/firestore_quest_datasource.dart';
import 'package:aslan_pixel/features/quests/data/models/quest_model.dart';
import 'package:aslan_pixel/shared/widgets/animated_coin_counter.dart';
import 'package:aslan_pixel/shared/widgets/confetti_overlay.dart';
import 'package:aslan_pixel/shared/widgets/floating_reward_text.dart';
import 'package:aslan_pixel/shared/widgets/pixel_icon.dart';

// ── Palette ──────────────────────────────────────────────────────────────────
const _kNavy = Color(0xFF0A1628);
const _kSurface = Color(0xFF0F2040);
const _kBorder = Color(0xFF1E3050);
const _kBorderActive = Color(0xFF1A2F50);
const _kNeonGreen = Color(0xFF00F5A0);
const _kGold = Color(0xFFF5C518);
const _kCyan = Color(0xFF4FC3F7);
const _kCyberPurple = Color(0xFF7B2FFF);
const _kTextPrimary = Color(0xFFE8F4F8);
const _kTextSecondary = Color(0xFF6B8AAB);
const _kError = Color(0xFFFF4D4F);

/// Full-screen dedicated quest page showing daily and weekly quests.
///
/// Route: [QuestPage.routeName]
class QuestPage extends StatelessWidget {
  const QuestPage({super.key, String? uid})
      : _uid = uid ?? '';

  static const routeName = '/quests';

  final String _uid;

  String get _resolvedUid =>
      _uid.isNotEmpty
          ? _uid
          : (FirebaseAuth.instance.currentUser?.uid ?? '');

  @override
  Widget build(BuildContext context) {
    final uid = _resolvedUid;
    return BlocProvider<QuestBloc>(
      create: (_) => QuestBloc(repository: FirestoreQuestDatasource())
        ..add(QuestWatchStarted(uid)),
      child: _QuestView(uid: uid),
    );
  }
}

// ── _QuestView ────────────────────────────────────────────────────────────────

class _QuestView extends StatelessWidget {
  const _QuestView({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _kNavy,
        appBar: AppBar(
          backgroundColor: _kNavy,
          foregroundColor: _kTextPrimary,
          elevation: 0,
          title: const Text(
            'Quest',
            style: TextStyle(
              color: _kTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(48),
            child: _QuestTabBar(),
          ),
        ),
        body: BlocConsumer<QuestBloc, QuestState>(
          listener: (context, state) {
            if (state is QuestRewardClaimedSuccess) {
              // Confetti burst on every successful claim.
              ConfettiOverlay.burst(context);
              // Floating coin reward text.
              if (state.coinsEarned > 0) {
                FloatingRewardText.show(context, state.coinsEarned);
              }
              // Unlock room item when applicable.
              if (state.unlockedItemId != null) {
                final currentUid =
                    FirebaseAuth.instance.currentUser?.uid ?? uid;
                context.read<RoomBloc>().add(
                      RoomItemUnlocked(
                        uid: currentUid,
                        itemId: state.unlockedItemId!,
                      ),
                    );
              }
            }
          },
          builder: (context, state) {
            if (state is QuestLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: _kNeonGreen,
                  strokeWidth: 2.5,
                ),
              );
            }
            if (state is QuestError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    state.message,
                    style: const TextStyle(color: _kError, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            if (state is QuestLoaded) {
              final daily =
                  state.quests.where((q) => q.type == 'daily').toList();
              final weekly =
                  state.quests.where((q) => q.type == 'weekly').toList();
              return TabBarView(
                children: [
                  _QuestList(
                    quests: daily,
                    uid: uid,
                    emptyLabel: 'ยังไม่มี Quest ประจำวัน',
                  ),
                  _QuestList(
                    quests: weekly,
                    uid: uid,
                    emptyLabel: 'ยังไม่มี Quest ประจำสัปดาห์',
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

// ── _QuestTabBar ──────────────────────────────────────────────────────────────

class _QuestTabBar extends StatelessWidget {
  const _QuestTabBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _kBorder, width: 1),
        ),
      ),
      child: TabBar(
        indicatorColor: _kNeonGreen,
        indicatorWeight: 2,
        labelColor: _kNeonGreen,
        unselectedLabelColor: _kTextSecondary,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        tabs: const [
          Tab(text: 'วันนี้'),
          Tab(text: 'สัปดาห์'),
        ],
      ),
    );
  }
}

// ── _QuestList ────────────────────────────────────────────────────────────────

class _QuestList extends StatelessWidget {
  const _QuestList({
    required this.quests,
    required this.uid,
    required this.emptyLabel,
  });

  final List<QuestModel> quests;
  final String uid;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (quests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PixelIcon(
                PixelIcon.quest,
                size: 48,
                color: _kTextSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                emptyLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _kTextSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: quests.length,
      itemBuilder: (context, index) =>
          _QuestCard(quest: quests[index], uid: uid),
    );
  }
}

// ── _QuestCard ────────────────────────────────────────────────────────────────

class _QuestCard extends StatelessWidget {
  const _QuestCard({required this.quest, required this.uid});

  final QuestModel quest;
  final String uid;

  @override
  Widget build(BuildContext context) {
    final progressValue =
        quest.target > 0 ? quest.progress / quest.target : 0.0;
    final clampedProgress = progressValue.clamp(0.0, 1.0);
    final rewardCoins = quest.reward['coins'] as int? ?? 0;
    final rewardXp = quest.reward['xp'] as int? ?? 0;
    final isComplete = quest.isComplete;
    final canClaim = isComplete && !quest.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isComplete ? _kNeonGreen : _kBorder,
          width: isComplete ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────────
            Row(
              children: [
                _TypeBadge(type: quest.type),
                const Spacer(),
                if (isComplete && quest.completed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _kNeonGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: _kNeonGreen,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'รับแล้ว',
                          style: TextStyle(
                            color: _kNeonGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Objective ────────────────────────────────────────────────
            Text(
              quest.objectiveTh.isNotEmpty
                  ? quest.objectiveTh
                  : quest.objective,
              style: const TextStyle(
                color: _kTextPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 14),

            // ── Progress bar ─────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: clampedProgress,
                minHeight: 7,
                backgroundColor: _kBorderActive,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isComplete ? _kNeonGreen : _kNeonGreen.withValues(alpha: 0.7),
                ),
              ),
            ),

            const SizedBox(height: 6),

            Row(
              children: [
                Text(
                  '${quest.progress} / ${quest.target}',
                  style: const TextStyle(
                    color: _kTextSecondary,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(clampedProgress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: isComplete ? _kNeonGreen : _kTextSecondary,
                    fontSize: 12,
                    fontWeight:
                        isComplete ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Rewards + claim ──────────────────────────────────────────
            Row(
              children: [
                // Animated coin counter — animates from 0 → reward amount
                AnimatedCoinCounter(
                  toAmount: rewardCoins,
                  fromAmount: 0,
                  fontSize: 13,
                  showIcon: true,
                ),
                const SizedBox(width: 8),
                _RewardChip(
                  icon: Icons.flash_on_rounded,
                  color: _kCyan,
                  label: '+$rewardXp XP',
                ),
                const Spacer(),
                _ClaimButton(quest: quest, uid: uid, canClaim: canClaim),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── _TypeBadge ────────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final Color badgeColor = switch (type) {
      'weekly' => _kCyberPurple,
      'achievement' => _kGold,
      _ => const Color(0xFF00D9FF),
    };

    final String label = switch (type) {
      'weekly' => 'สัปดาห์',
      'achievement' => 'สำเร็จ',
      _ => 'วันนี้',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: badgeColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── _RewardChip ───────────────────────────────────────────────────────────────

class _RewardChip extends StatelessWidget {
  const _RewardChip({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── _ClaimButton ──────────────────────────────────────────────────────────────

class _ClaimButton extends StatelessWidget {
  const _ClaimButton({
    required this.quest,
    required this.uid,
    required this.canClaim,
  });

  final QuestModel quest;
  final String uid;
  final bool canClaim;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canClaim
          ? () => context.read<QuestBloc>().add(
                QuestRewardClaimed(questId: quest.questId, uid: uid),
              )
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: canClaim ? _kNeonGreen : _kBorderActive,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          canClaim ? 'รับรางวัล' : (quest.completed ? 'รับแล้ว' : 'ยังไม่ครบ'),
          style: TextStyle(
            color: canClaim
                ? _kNavy
                : _kTextSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
