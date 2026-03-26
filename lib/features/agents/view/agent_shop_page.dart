import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aslan_pixel/core/config/app_colors.dart';
import 'package:aslan_pixel/core/enums/agent_type.dart';
import 'package:aslan_pixel/features/agents/bloc/agent_bloc.dart';
import 'package:aslan_pixel/features/agents/data/agent_shop.dart';
import 'package:aslan_pixel/features/agents/data/datasources/firestore_agent_datasource.dart';
import 'package:aslan_pixel/features/inventory/data/datasources/firestore_economy_datasource.dart';
import 'package:aslan_pixel/features/inventory/data/models/economy_model.dart';
import 'package:aslan_pixel/shared/widgets/confetti_overlay.dart';

// ---------------------------------------------------------------------------
// AgentShopPage
// ---------------------------------------------------------------------------

class AgentShopPage extends StatefulWidget {
  const AgentShopPage({super.key});

  static const String routeName = '/agent-shop';

  @override
  State<AgentShopPage> createState() => _AgentShopPageState();
}

class _AgentShopPageState extends State<AgentShopPage> {
  late final AgentBloc _agentBloc;
  late final Stream<EconomyModel> _economyStream;
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _agentBloc = AgentBloc(repository: FirestoreAgentDatasource());
    if (_uid.isNotEmpty) {
      _agentBloc.add(AgentWatchStarted(_uid));
    }
    _economyStream = FirestoreEconomyDatasource().watchEconomy(_uid);
  }

  @override
  void dispose() {
    _agentBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AgentBloc>.value(
      value: _agentBloc,
      child: _AgentShopView(uid: _uid, economyStream: _economyStream),
    );
  }
}

// ---------------------------------------------------------------------------
// _AgentShopView
// ---------------------------------------------------------------------------

class _AgentShopView extends StatelessWidget {
  const _AgentShopView({required this.uid, required this.economyStream});

  final String uid;
  final Stream<EconomyModel> economyStream;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return BlocListener<AgentBloc, AgentState>(
      listener: (context, state) {
        if (state is AgentPurchaseSuccess) {
          HapticFeedback.heavyImpact();
          ConfettiOverlay.burst(context);
          final item = kAgentShop.firstWhere(
            (s) => s.type == state.agentType,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: colors.primary,
              content: Text(
                '\u0e44\u0e14\u0e49\u0e23\u0e31\u0e1a ${item.nameEn} \u0e41\u0e25\u0e49\u0e27!',
                style: TextStyle(
                  color: colors.textOnPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          // The real-time Firestore stream will auto-refresh the agent list.
        } else if (state is AgentPurchaseError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: colors.error,
              content: Text(
                state.message,
                style: const TextStyle(color: Colors.white),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.appBarBackground,
          foregroundColor: colors.appBarForeground,
          elevation: 0,
          title: const Text(
            'Agent Shop',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            // Coin balance display
            StreamBuilder<EconomyModel>(
              stream: economyStream,
              builder: (context, snap) {
                final coins = snap.data?.coins ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '\u{1fa99}',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$coins',
                        style: TextStyle(
                          color: colors.accent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: StreamBuilder<EconomyModel>(
          stream: economyStream,
          builder: (context, econSnap) {
            final economy = econSnap.data;
            final coins = economy?.coins ?? 0;
            final playerLevel = economy?.level ?? 1;

            return BlocBuilder<AgentBloc, AgentState>(
              buildWhen: (prev, curr) =>
                  curr is AgentLoaded ||
                  curr is AgentLoading ||
                  curr is AgentInitial,
              builder: (context, state) {
                final ownedTypes = <AgentType>{};
                if (state is AgentLoaded) {
                  for (final agent in state.agents) {
                    ownedTypes.add(agent.type);
                  }
                }

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: kAgentShop.length,
                    itemBuilder: (context, index) {
                      final item = kAgentShop[index];
                      final isOwned = ownedTypes.contains(item.type);
                      final isLocked = playerLevel < item.unlockLevel;
                      final canAfford = coins >= item.price;

                      return _AgentShopCard(
                        item: item,
                        isOwned: isOwned,
                        isLocked: isLocked,
                        canAfford: canAfford,
                        onBuy: () => _confirmPurchase(
                          context,
                          item,
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _confirmPurchase(BuildContext context, AgentShopItem item) {
    final colors = AppColors.of(context);

    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colors.border,
            width: 1,
          ),
        ),
        title: Text(
          '\u0e0b\u0e37\u0e49\u0e2d ${item.nameEn}?',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '\u0e43\u0e0a\u0e49 ${item.price} \u0e40\u0e2b\u0e23\u0e35\u0e22\u0e0d\u0e0b\u0e37\u0e49\u0e2d ${item.nameTh}?',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              '\u0e22\u0e01\u0e40\u0e25\u0e34\u0e01',
              style: TextStyle(color: colors.textTertiary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.textOnPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
            child: Text(
              '\u0e0b\u0e37\u0e49\u0e2d \u{1fa99} ${item.price}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && context.mounted) {
        context.read<AgentBloc>().add(
              AgentPurchaseRequested(
                agentType: item.type,
                uid: uid,
                price: item.price,
              ),
            );
      }
    });
  }
}

// ---------------------------------------------------------------------------
// _AgentShopCard
// ---------------------------------------------------------------------------

class _AgentShopCard extends StatelessWidget {
  const _AgentShopCard({
    required this.item,
    required this.isOwned,
    required this.isLocked,
    required this.canAfford,
    required this.onBuy,
  });

  final AgentShopItem item;
  final bool isOwned;
  final bool isLocked;
  final bool canAfford;
  final VoidCallback onBuy;

  Color _cardAccent() {
    switch (item.type) {
      case AgentType.analyst:
        return const Color(0xFF00F5A0);
      case AgentType.scout:
        return const Color(0xFFF5C518);
      case AgentType.risk:
        return const Color(0xFF7B2FFF);
      case AgentType.social:
        return const Color(0xFF00D9FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final accent = _cardAccent();

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOwned
              ? colors.primary.withValues(alpha: 0.5)
              : accent.withValues(alpha: 0.25),
          width: isOwned ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Emoji
            Text(
              item.emoji,
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 8),

            // Name
            Text(
              item.nameEn,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              item.nameTh,
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),

            // Description
            Expanded(
              child: Text(
                item.descriptionTh,
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 11,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),

            // Button
            SizedBox(
              width: double.infinity,
              child: _buildButton(colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(AppColorScheme colors) {
    if (isOwned) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '\u0e21\u0e35\u0e41\u0e25\u0e49\u0e27 \u2713',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      );
    }

    if (isLocked) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: colors.textDisabled.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '\u0e1b\u0e25\u0e14\u0e25\u0e47\u0e2d\u0e04\u0e17\u0e35\u0e48 Lv ${item.unlockLevel}',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textDisabled,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      );
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: canAfford ? colors.primary : colors.textDisabled,
        foregroundColor: colors.textOnPrimary,
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 0,
      ),
      onPressed: canAfford ? onBuy : null,
      child: Text(
        item.price == 0
            ? '\u0e1f\u0e23\u0e35!'
            : '\u0e0b\u0e37\u0e49\u0e2d ${item.price} \u{1fa99}',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}
