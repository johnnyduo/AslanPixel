import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aslan_pixel/features/inventory/data/datasources/firestore_economy_datasource.dart';
import 'package:aslan_pixel/features/inventory/data/models/economy_model.dart';
import 'package:aslan_pixel/features/quests/bloc/quest_bloc.dart';
import 'package:aslan_pixel/features/quests/data/datasources/firestore_quest_datasource.dart';
import 'package:aslan_pixel/features/quests/data/models/quest_model.dart';

/// Inventory / economy page — shows balance, level, and active quests.
class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  static const routeName = '/inventory';

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final economySource = FirestoreEconomyDatasource();
    final questSource = FirestoreQuestDatasource();

    return BlocProvider<QuestBloc>(
      create: (_) => QuestBloc(repository: questSource)
        ..add(QuestWatchStarted(uid)),
      child: Scaffold(
        backgroundColor: const Color(0xFF0A1628),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0A1628),
          foregroundColor: const Color(0xFFE8F4F8),
          title: const Text(
            'คลัง',
            style: TextStyle(color: Color(0xFFE8F4F8)),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: const Color(0xFF1E3050)),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Economy card ───────────────────────────────────────────────
            StreamBuilder<EconomyModel>(
              stream: economySource.watchEconomy(uid),
              builder: (context, snap) {
                final economy = snap.data ??
                    EconomyModel(
                      coins: 0,
                      xp: 0,
                      unlockPoints: 0,
                      lastUpdated: DateTime.now(),
                    );
                return _EconomyCard(economy: economy);
              },
            ),

            const SizedBox(height: 24),

            // ── Active quests ──────────────────────────────────────────────
            const Text(
              'Quest ที่กำลังทำ',
              style: TextStyle(
                color: Color(0xFFE8F4F8),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            BlocBuilder<QuestBloc, QuestState>(
              builder: (context, state) {
                if (state is QuestLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF00F5A0),
                    ),
                  );
                }
                if (state is QuestError) {
                  return Text(
                    state.message,
                    style: const TextStyle(color: Color(0xFFFF4D4F)),
                  );
                }
                if (state is QuestLoaded) {
                  if (state.quests.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'ยังไม่มี Quest\nโปรดลองใหม่ในภายหลัง',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF6B8AAB),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: state.quests
                        .map((q) => _QuestCard(quest: q, uid: uid))
                        .toList(),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Economy Card ─────────────────────────────────────────────────────────────

class _EconomyCard extends StatelessWidget {
  const _EconomyCard({required this.economy});

  final EconomyModel economy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2040),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E3050)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatChip(
            icon: Icons.monetization_on,
            iconColor: const Color(0xFFF5C518),
            value: economy.coins.toString(),
            label: 'Coins',
          ),
          _StatChip(
            icon: Icons.star,
            iconColor: const Color(0xFF4FC3F7),
            value: economy.xp.toString(),
            label: 'XP',
          ),
          _StatChip(
            icon: Icons.shield,
            iconColor: const Color(0xFF7B2FFF),
            value: 'Lv.${economy.level}',
            label: 'Level',
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFE8F4F8),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B8AAB),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ── Quest Card ────────────────────────────────────────────────────────────────

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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2040),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: quest.isComplete
              ? const Color(0xFF00F5A0)
              : const Color(0xFF1E3050),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type badge + completion icon
          Row(
            children: [
              _TypeBadge(type: quest.type),
              const Spacer(),
              if (quest.isComplete)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF00F5A0),
                  size: 18,
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Objective text (Thai preferred)
          Text(
            quest.objectiveTh.isNotEmpty
                ? quest.objectiveTh
                : quest.objective,
            style: const TextStyle(
              color: Color(0xFFE8F4F8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 10),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: clampedProgress,
              minHeight: 6,
              backgroundColor: const Color(0xFF1A2F50),
              color: const Color(0xFF00F5A0),
            ),
          ),

          const SizedBox(height: 4),

          Text(
            '${quest.progress} / ${quest.target}',
            style: const TextStyle(
              color: Color(0xFF6B8AAB),
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 10),

          // Reward preview + claim button
          Row(
            children: [
              const Icon(Icons.monetization_on,
                  color: Color(0xFFF5C518), size: 14),
              const SizedBox(width: 4),
              Text(
                '+$rewardCoins',
                style: const TextStyle(
                  color: Color(0xFFF5C518),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.star, color: Color(0xFF4FC3F7), size: 14),
              const SizedBox(width: 4),
              Text(
                '+$rewardXp XP',
                style: const TextStyle(
                  color: Color(0xFF4FC3F7),
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              _ClaimButton(quest: quest, uid: uid),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final Color badgeColor;
    switch (type) {
      case 'weekly':
        badgeColor = const Color(0xFF7B2FFF);
      case 'achievement':
        badgeColor = const Color(0xFFF5C518);
      default:
        badgeColor = const Color(0xFF00D9FF);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        type.toUpperCase(),
        style: TextStyle(
          color: badgeColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ClaimButton extends StatelessWidget {
  const _ClaimButton({required this.quest, required this.uid});

  final QuestModel quest;
  final String uid;

  @override
  Widget build(BuildContext context) {
    final canClaim = quest.isComplete && !quest.completed;

    return GestureDetector(
      onTap: canClaim
          ? () => context.read<QuestBloc>().add(
                QuestRewardClaimed(questId: quest.questId, uid: uid),
              )
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: canClaim
              ? const Color(0xFF00F5A0)
              : const Color(0xFF1A2F50),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'รับรางวัล',
          style: TextStyle(
            color: canClaim
                ? const Color(0xFF0A1628)
                : const Color(0xFF3D5A78),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
