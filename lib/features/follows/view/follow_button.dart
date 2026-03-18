import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aslan_pixel/features/follows/bloc/follow_bloc.dart';
import 'package:aslan_pixel/features/follows/data/datasources/firestore_follow_datasource.dart';
import 'package:aslan_pixel/features/follows/data/repositories/follow_repository_impl.dart';

// ── Colour constants (matches profile palette) ─────────────────────────────
const Color _neonGreen = Color(0xFF00f5a0);
const Color _navy = Color(0xFF0a1628);
const Color _surface = Color(0xFF0F2040);
const Color _textSecondary = Color(0xFFa8c4e0);

/// A self-contained widget that shows a Follow / Unfollow button and follower
/// count for [targetUid], driven by its own [FollowBloc].
///
/// Pass [uid] as the currently signed-in user and [targetUid] as the profile
/// being viewed.  When [uid] equals [targetUid] the button is hidden (you
/// cannot follow yourself).
///
/// Usage (wrap the call site with a BlocProvider, or let this widget own it):
/// ```dart
/// FollowButton(uid: currentUid, targetUid: profileUid)
/// ```
class FollowButton extends StatelessWidget {
  const FollowButton({
    super.key,
    required this.uid,
    required this.targetUid,
  });

  final String uid;
  final String targetUid;

  @override
  Widget build(BuildContext context) {
    // Do not show a follow button on your own profile.
    if (uid.isEmpty || uid == targetUid) return const SizedBox.shrink();

    return BlocProvider(
      create: (_) => FollowBloc(
        FollowRepositoryImpl(FirestoreFollowDatasource()),
      )..add(FollowCheckRequested(uid: uid, targetUid: targetUid)),
      child: _FollowButtonView(uid: uid, targetUid: targetUid),
    );
  }
}

class _FollowButtonView extends StatelessWidget {
  const _FollowButtonView({required this.uid, required this.targetUid});

  final String uid;
  final String targetUid;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FollowBloc, FollowState>(
      listener: (context, state) {
        if (state is FollowError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'เกิดข้อผิดพลาด: ${state.message}',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is FollowInitial || state is FollowLoading) {
          return _buildLoadingState();
        }

        if (state is FollowLoaded) {
          return _buildLoadedState(context, state);
        }

        // Error fallback — show a retry button.
        return _buildErrorState(context);
      },
    );
  }

  // ── Loading ───────────────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 40,
          child: OutlinedButton(
            onPressed: null,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _neonGreen.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              minimumSize: const Size(120, 40),
            ),
            child: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: _neonGreen,
                strokeWidth: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Loaded ────────────────────────────────────────────────────────────────

  Widget _buildLoadedState(BuildContext context, FollowLoaded state) {
    final isFollowing = state.isFollowing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Follow / Unfollow button
        SizedBox(
          height: 40,
          child: isFollowing
              ? OutlinedButton.icon(
                  onPressed: () => context
                      .read<FollowBloc>()
                      .add(FollowToggled(uid: uid, targetUid: targetUid)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _neonGreen.withValues(alpha: 0.6),
                    ),
                    foregroundColor: _neonGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    minimumSize: const Size(120, 40),
                  ),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text(
                    'ติดตามแล้ว',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: () => context
                      .read<FollowBloc>()
                      .add(FollowToggled(uid: uid, targetUid: targetUid)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _neonGreen,
                    foregroundColor: _navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    minimumSize: const Size(120, 40),
                  ),
                  icon: const Icon(Icons.person_add_outlined, size: 16),
                  label: const Text(
                    'ติดตาม',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
        ),

        const SizedBox(height: 8),

        // Follower / Following counts row
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CountLabel(
              count: state.followerCount,
              label: 'ผู้ติดตาม',
            ),
            Container(
              width: 1,
              height: 24,
              color: _surface,
              margin: const EdgeInsets.symmetric(horizontal: 12),
            ),
            _CountLabel(
              count: state.followingCount,
              label: 'กำลังติดตาม',
            ),
          ],
        ),
      ],
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────────

  Widget _buildErrorState(BuildContext context) {
    return TextButton.icon(
      onPressed: () => context
          .read<FollowBloc>()
          .add(FollowCheckRequested(uid: uid, targetUid: targetUid)),
      icon: const Icon(Icons.refresh, size: 16, color: _textSecondary),
      label: const Text(
        'ลองใหม่',
        style: TextStyle(color: _textSecondary, fontSize: 13),
      ),
    );
  }
}

// ── Count Label ───────────────────────────────────────────────────────────────

class _CountLabel extends StatelessWidget {
  const _CountLabel({required this.count, required this.label});

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _format(count),
          style: const TextStyle(
            color: _neonGreen,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: _textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  String _format(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}
