import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aslan_pixel/core/config/app_colors.dart';
import 'package:aslan_pixel/features/home/bloc/room_bloc.dart';
import 'package:aslan_pixel/features/home/bloc/room_event.dart';
import 'package:aslan_pixel/features/home/bloc/room_state.dart';
import 'package:aslan_pixel/features/home/data/datasources/firestore_room_datasource.dart';
import 'package:aslan_pixel/features/home/data/room_theme_shop.dart';
import 'package:aslan_pixel/features/inventory/data/datasources/firestore_economy_datasource.dart';
import 'package:aslan_pixel/shared/widgets/animated_coin_counter.dart';
import 'package:aslan_pixel/shared/widgets/confetti_overlay.dart';

// ---------------------------------------------------------------------------
// Route name
// ---------------------------------------------------------------------------

class RoomThemeShopPage extends StatefulWidget {
  const RoomThemeShopPage({super.key});

  static const String routeName = '/room-theme-shop';

  @override
  State<RoomThemeShopPage> createState() => _RoomThemeShopPageState();
}

class _RoomThemeShopPageState extends State<RoomThemeShopPage> {
  late final RoomBloc _roomBloc;
  late final FirestoreRoomDatasource _roomDs;
  late final FirestoreEconomyDatasource _econDs;

  String _activeTheme = 'starter';
  List<String> _ownedThemes = ['starter'];
  int _coins = 0;
  int _playerLevel = 1;
  bool _loading = true;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _roomDs = FirestoreRoomDatasource();
    _econDs = FirestoreEconomyDatasource();
    _roomBloc = RoomBloc(repository: _roomDs);
    _loadData();
  }

  Future<void> _loadData() async {
    if (_uid.isEmpty) return;
    final owned = await _roomDs.getOwnedThemes(_uid);
    final active = await _roomDs.getActiveTheme(_uid);

    // Listen to economy for live coin updates.
    _econDs.watchEconomy(_uid).listen((economy) {
      if (mounted) {
        setState(() {
          _coins = economy.coins;
          _playerLevel = economy.level;
        });
      }
    });

    if (mounted) {
      setState(() {
        _ownedThemes = owned;
        _activeTheme = active;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _roomBloc.close();
    super.dispose();
  }

  // ── Purchase flow ────────────────────────────────────────────────────────────

  Future<void> _confirmPurchase(BuildContext context, RoomTheme theme) async {
    final colors = AppColors.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.border),
        ),
        title: Text(
          'ซื้อ ${theme.nameEn}?',
          style: TextStyle(color: colors.textPrimary, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                theme.previewAsset,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  color: colors.backgroundSecondary,
                  child: Icon(Icons.image_not_supported,
                      color: colors.textTertiary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.monetization_on_rounded,
                    color: colors.accent, size: 22),
                const SizedBox(width: 6),
                Text(
                  '${theme.price}',
                  style: TextStyle(
                    color: colors.accent,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              theme.descriptionTh,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('ยกเลิก',
                style: TextStyle(color: colors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.textOnPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('ซื้อเลย',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    _roomBloc.add(RoomThemePurchaseRequested(
      themeId: theme.themeId,
      uid: _uid,
      price: theme.price,
    ));
  }

  void _activateTheme(String themeId) {
    _roomBloc.add(RoomThemeChanged(themeId: themeId, uid: _uid));
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return BlocProvider<RoomBloc>.value(
      value: _roomBloc,
      child: BlocListener<RoomBloc, RoomState>(
        listener: (context, state) {
          if (state is RoomThemePurchaseSuccess) {
            HapticFeedback.heavyImpact();
            ConfettiOverlay.burst(context);
            setState(() {
              _ownedThemes = [..._ownedThemes, state.themeId];
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: colors.primary,
                content: Text(
                  'ปลดล็อคธีมสำเร็จ!',
                  style: TextStyle(color: colors.textOnPrimary),
                ),
              ),
            );
          } else if (state is RoomThemeChangeSuccess) {
            HapticFeedback.mediumImpact();
            setState(() {
              _activeTheme = state.themeId;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: colors.cyber,
                content: const Text(
                  'เปลี่ยนธีมห้องแล้ว!',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
          } else if (state is RoomThemePurchaseFailure) {
            HapticFeedback.vibrate();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: colors.error,
                content: Text(
                  state.message.contains('Insufficient')
                      ? 'เหรียญไม่เพียงพอ!'
                      : state.message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: colors.scaffoldBackground,
          appBar: AppBar(
            backgroundColor: colors.appBarBackground,
            foregroundColor: colors.appBarForeground,
            elevation: 0,
            title: const Text(
              'Room Themes',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: colors.appBarBorder,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: AnimatedCoinCounter(toAmount: _coins),
              ),
            ],
          ),
          body: _loading
              ? Center(
                  child: CircularProgressIndicator(
                    color: colors.primary,
                    strokeWidth: 3,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: kRoomThemes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final theme = kRoomThemes[index];
                    return _ThemeCard(
                      theme: theme,
                      isOwned: _ownedThemes.contains(theme.themeId),
                      isActive: _activeTheme == theme.themeId,
                      canAfford: _coins >= theme.price,
                      playerLevel: _playerLevel,
                      onBuy: () => _confirmPurchase(context, theme),
                      onActivate: () => _activateTheme(theme.themeId),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ThemeCard
// ---------------------------------------------------------------------------

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.theme,
    required this.isOwned,
    required this.isActive,
    required this.canAfford,
    required this.playerLevel,
    required this.onBuy,
    required this.onActivate,
  });

  final RoomTheme theme;
  final bool isOwned;
  final bool isActive;
  final bool canAfford;
  final int playerLevel;
  final VoidCallback onBuy;
  final VoidCallback onActivate;

  bool get _levelLocked => playerLevel < theme.unlockLevel;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? colors.accent : colors.border,
          width: isActive ? 2 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: colors.accent.withValues(alpha: 40 / 255),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Preview image ──
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(13)),
            child: Stack(
              children: [
                Image.asset(
                  theme.previewAsset,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 140,
                    color: colors.backgroundSecondary,
                    child: Center(
                      child: Text(
                        theme.emoji,
                        style: const TextStyle(fontSize: 48),
                      ),
                    ),
                  ),
                ),
                // Active badge overlay
                if (isActive)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ACTIVE',
                        style: TextStyle(
                          color: colors.textOnPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                // Level-locked overlay
                if (_levelLocked)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 150 / 255),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(13)),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_outline,
                                color: colors.textTertiary, size: 32),
                            const SizedBox(height: 4),
                            Text(
                              'Lv ${theme.unlockLevel}',
                              style: TextStyle(
                                color: colors.textTertiary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Info + action row ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              children: [
                // Name + description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${theme.emoji}  ${theme.nameEn}',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        theme.nameTh,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Action button
                _buildActionButton(context, colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, AppColorScheme colors) {
    // Level locked
    if (_levelLocked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: colors.backgroundTertiary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.border),
        ),
        child: Text(
          'Lv ${theme.unlockLevel}',
          style: TextStyle(
            color: colors.textDisabled,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    // Already active
    if (isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: colors.accent.withValues(alpha: 30 / 255),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.accent.withValues(alpha: 100 / 255)),
        ),
        child: Text(
          'ใช้งานอยู่',
          style: TextStyle(
            color: colors.accent,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    // Owned but not active — can activate
    if (isOwned) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.cyber,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        onPressed: onActivate,
        child: const Text(
          'ใช้งาน',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      );
    }

    // Not owned — buy button
    if (theme.price == 0) {
      // Free theme — just activate
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.textOnPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        onPressed: onActivate,
        child: const Text(
          'ฟรี!',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      );
    }

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: canAfford
            ? colors.primary
            : colors.backgroundTertiary,
        foregroundColor: canAfford
            ? colors.textOnPrimary
            : colors.textDisabled,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 0,
      ),
      onPressed: canAfford ? onBuy : null,
      icon: Icon(
        Icons.monetization_on_rounded,
        size: 16,
        color: canAfford ? colors.textOnPrimary : colors.textDisabled,
      ),
      label: Text(
        '${theme.price}',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}
