import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aslan_pixel/core/enums/privacy_mode.dart';
import 'package:aslan_pixel/features/auth/data/models/user_model.dart';
import 'package:aslan_pixel/features/follows/view/follow_button.dart';
import 'package:aslan_pixel/features/inventory/bloc/economy_bloc.dart';
import 'package:aslan_pixel/features/profile/bloc/profile_bloc.dart';
import 'package:aslan_pixel/features/profile/data/datasources/firestore_profile_datasource.dart';
import 'package:aslan_pixel/features/profile/data/models/badge_model.dart';
import 'package:aslan_pixel/features/profile/view/edit_profile_page.dart';
import 'package:aslan_pixel/shared/widgets/animated_coin_counter.dart';

// ── Colour constants ──────────────────────────────────────────────────────────
const Color _navy = Color(0xFF0a1628);
const Color _neonGreen = Color(0xFF00f5a0);
const Color _surface = Color(0xFF0F2040);
const Color _gold = Color(0xFFF5C518);
const Color _textWhite = Color(0xFFE8F4F8);
const Color _textSecondary = Color(0xFFa8c4e0);

/// Profile tab — shows avatar, stats, privacy settings, and earned badges.
///
/// When [profileUid] is provided the page displays that user's public profile
/// (with a FollowButton). When omitted it defaults to the currently signed-in
/// user's own profile.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.profileUid});

  static const String routeName = '/profile';

  /// UID of the profile to display. Defaults to the signed-in user when null.
  final String? profileUid;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileBloc _bloc;
  late final EconomyBloc _economyBloc;
  late final String _currentUid;

  @override
  void initState() {
    super.initState();
    _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final targetUid = widget.profileUid ?? _currentUid;
    _bloc = ProfileBloc(FirestoreProfileDatasource())
      ..add(ProfileLoadRequested(targetUid));

    // Only stream our own economy; public profiles don't expose balance.
    _economyBloc = EconomyBloc();
    if (targetUid == _currentUid && _currentUid.isNotEmpty) {
      _economyBloc.add(EconomyWatchStarted(_currentUid));
    }
  }

  @override
  void dispose() {
    _bloc.close();
    _economyBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final targetUid = widget.profileUid ?? _currentUid;
    final isSelf = targetUid == _currentUid;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _bloc),
        BlocProvider.value(value: _economyBloc),
      ],
      child: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileSignedOut) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/', (route) => false);
          }
        },
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading || state is ProfileInitial) {
              return const Scaffold(
                backgroundColor: _navy,
                body: Center(
                  child: CircularProgressIndicator(color: _neonGreen),
                ),
              );
            }
            if (state is ProfileError) {
              return Scaffold(
                backgroundColor: _navy,
                body: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.message,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => context.read<ProfileBloc>().add(
                              ProfileLoadRequested(targetUid),
                            ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _neonGreen),
                          foregroundColor: _neonGreen,
                        ),
                        child: const Text('ลองใหม่'),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (state is ProfileLoaded || state is ProfileUpdating) {
              final UserModel user = state is ProfileLoaded
                  ? state.user
                  : (state as ProfileUpdating).user;
              final List<BadgeModel> badges =
                  state is ProfileLoaded ? state.badges : const [];
              return _ProfileContent(
                user: user,
                badges: badges,
                currentUid: _currentUid,
                profileUid: targetUid,
                isSelf: isSelf,
              );
            }
            return const Scaffold(backgroundColor: _navy);
          },
        ),
      ),
    );
  }
}

// ── Main content ──────────────────────────────────────────────────────────────

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.user,
    required this.badges,
    required this.currentUid,
    required this.profileUid,
    required this.isSelf,
  });

  final UserModel user;
  final List<BadgeModel> badges;
  final String currentUid;
  final String profileUid;
  final bool isSelf;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(child: _buildStatRow(context)),
          // Follow button — only shown when viewing another user's profile.
          if (!isSelf)
            SliverToBoxAdapter(
              child: _buildFollowSection(context),
            ),
          SliverToBoxAdapter(child: _buildPrivacySection(context)),
          SliverToBoxAdapter(child: _buildBadgesSection()),
          SliverToBoxAdapter(child: _buildActionButtons(context)),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  // ── SliverAppBar ──────────────────────────────────────────────────────────

  Widget _buildSliverAppBar(BuildContext context) {
    final initials = _initials(user.displayName);
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: _surface,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0a1628), Color(0xFF1a2f50)],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                _AvatarCircle(
                  avatarId: user.avatarId,
                  initials: initials,
                ),
                const SizedBox(height: 12),
                Text(
                  user.displayName ?? 'ผู้ใช้',
                  style: const TextStyle(
                    color: _textWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (user.email != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    user.email!,
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Stat Row ──────────────────────────────────────────────────────────────

  Widget _buildStatRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BlocBuilder<EconomyBloc, EconomyState>(
            builder: (context, econState) {
              final level =
                  econState is EconomyLoaded ? econState.level : 1;
              return Row(
                children: [
                  _StatChip(
                    label: 'Lv $level',
                    icon: Icons.star_rounded,
                    color: _gold,
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    label: '0 Quests',
                    icon: Icons.assignment_turned_in_outlined,
                    color: _neonGreen,
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    label: isSelf ? 'โปรไฟล์ฉัน' : 'สาธารณะ',
                    icon: isSelf ? Icons.person : Icons.people_outline,
                    color: const Color(0xFF00d9ff),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          // XP progress bar — only on own profile
          if (isSelf)
            BlocBuilder<EconomyBloc, EconomyState>(
              builder: (context, econState) {
                final xp =
                    econState is EconomyLoaded ? econState.xp : 0;
                final level =
                    econState is EconomyLoaded ? econState.level : 1;
                final xpProgress = (xp % 1000) / 1000.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'XP: $xp',
                            style: const TextStyle(
                              color: _textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Lv $level → Lv ${level + 1}',
                            style: const TextStyle(
                              color: _textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: xpProgress,
                          minHeight: 6,
                          backgroundColor:
                              _surface.withValues(alpha: 0.8),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            _neonGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          // Coin balance with animated counter — only on own profile
          if (isSelf)
            BlocBuilder<EconomyBloc, EconomyState>(
              builder: (context, econState) {
                final coins =
                    econState is EconomyLoaded ? econState.coins : 0;
                final prevCoins = econState is EconomyLoaded ? coins : 0;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: _gold.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined,
                          color: _gold, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'ยอดเหรียญ',
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      AnimatedCoinCounter(
                        toAmount: coins,
                        fromAmount: prevCoins,
                        fontSize: 15,
                        showIcon: true,
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ── Follow Section ────────────────────────────────────────────────────────

  Widget _buildFollowSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Center(
        child: Column(
          children: [
            FollowButton(
              uid: currentUid,
              targetUid: profileUid,
            ),
            const SizedBox(height: 8),
            if (!isSelf)
              OutlinedButton.icon(
                icon: const Icon(Icons.door_front_door_rounded),
                label: const Text('เยี่ยมชมห้อง'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF00F5A0),
                  side: const BorderSide(color: Color(0xFF00F5A0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.of(context).pushNamed(
                  '/friend-room',
                  arguments: {'friendUid': profileUid, 'friendName': user.displayName ?? ''},
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Privacy Section ───────────────────────────────────────────────────────

  Widget _buildPrivacySection(BuildContext context) {
    // Only the profile owner can change privacy settings.
    if (!isSelf) return const SizedBox.shrink();

    return _SectionCard(
      title: 'ความเป็นส่วนตัว',
      child: DropdownButton<PrivacyMode>(
        value: user.privacyMode,
        isExpanded: true,
        dropdownColor: _surface,
        underline: const SizedBox.shrink(),
        style: const TextStyle(color: _textWhite, fontSize: 14),
        items: const [
          DropdownMenuItem(
            value: PrivacyMode.public,
            child: Text('สาธารณะ'),
          ),
          DropdownMenuItem(
            value: PrivacyMode.friendsOnly,
            child: Text('เพื่อนเท่านั้น'),
          ),
          DropdownMenuItem(
            value: PrivacyMode.private,
            child: Text('ส่วนตัว'),
          ),
        ],
        onChanged: (mode) {
          if (mode == null) return;
          context
              .read<ProfileBloc>()
              .add(ProfileUpdateRequested(privacyMode: mode));
        },
      ),
    );
  }

  // ── Badges Section ────────────────────────────────────────────────────────

  Widget _buildBadgesSection() {
    return _SectionCard(
      title: 'เหรียญตรา',
      child: badges.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'ยังไม่มีเหรียญตรา',
                style: TextStyle(color: Color(0xFFa8c4e0), fontSize: 13),
              ),
            )
          : Wrap(
              spacing: 10,
              runSpacing: 10,
              children: badges.map((b) => BadgeChip(badge: b)).toList(),
            ),
    );
  }

  // ── Action Buttons ────────────────────────────────────────────────────────

  Widget _buildActionButtons(BuildContext context) {
    if (!isSelf) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(EditProfilePage.routeName),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _neonGreen),
                foregroundColor: _neonGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'แก้ไขโปรไฟล์',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context
                  .read<ProfileBloc>()
                  .add(const ProfileSignOutRequested()),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                foregroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'ออกจากระบบ',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}

// ── Avatar Circle ─────────────────────────────────────────────────────────────

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({this.avatarId, required this.initials});

  final String? avatarId;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _surface,
        border: Border.all(color: _neonGreen, width: 2),
      ),
      child: Center(
        child: avatarId != null
            ? Text(
                avatarId!,
                style: const TextStyle(
                  color: _neonGreen,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              )
            : Text(
                initials,
                style: const TextStyle(
                  color: _neonGreen,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

// ── Stat Chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1e3050)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: _neonGreen,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

// ── Badge Chip ────────────────────────────────────────────────────────────────

/// A 64×64 badge tile shown in the badges section.
class BadgeChip extends StatelessWidget {
  const BadgeChip({super.key, required this.badge});

  final BadgeModel badge;

  @override
  Widget build(BuildContext context) {
    final earned = badge.isEarned;
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: earned
            ? _gold.withValues(alpha: 0.08)
            : _surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: earned ? _gold : const Color(0xFF3d5a78),
          width: earned ? 1.5 : 1,
        ),
        boxShadow: earned
            ? [
                BoxShadow(
                  color: _gold.withValues(alpha: 0.25),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            badge.iconEmoji,
            style: TextStyle(
              fontSize: 28,
              color: earned ? null : const Color(0xFF3d5a78),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            badge.nameTh.isEmpty ? badge.name : badge.nameTh,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: earned ? _gold : const Color(0xFF3d5a78),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
