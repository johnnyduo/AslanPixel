import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aslan_pixel/features/follows/data/repositories/follow_repository.dart';

part 'follow_event.dart';
part 'follow_state.dart';

/// Manages follow/unfollow state for a single target user.
///
/// Typical lifecycle:
///   1. Dispatch [FollowCheckRequested] when the profile screen opens.
///   2. Dispatch [FollowToggled] when the user taps the follow button.
///   3. Dispatch [FollowCountsRequested] to refresh counts independently.
class FollowBloc extends Bloc<FollowEvent, FollowState> {
  FollowBloc(this._repository) : super(const FollowInitial()) {
    on<FollowCheckRequested>(_onCheckRequested);
    on<FollowToggled>(_onToggled);
    on<FollowCountsRequested>(_onCountsRequested);
  }

  final FollowRepository _repository;

  // ── Handlers ──────────────────────────────────────────────────────────────

  Future<void> _onCheckRequested(
    FollowCheckRequested event,
    Emitter<FollowState> emit,
  ) async {
    emit(const FollowLoading());
    try {
      final isFollowing =
          await _repository.isFollowing(event.uid, event.targetUid);
      final followerCount =
          await _repository.getFollowerCount(event.targetUid);
      final followingCount =
          await _repository.getFollowingCount(event.targetUid);
      emit(FollowLoaded(
        isFollowing: isFollowing,
        followerCount: followerCount,
        followingCount: followingCount,
      ));
    } catch (e) {
      emit(FollowError(e.toString()));
    }
  }

  Future<void> _onToggled(
    FollowToggled event,
    Emitter<FollowState> emit,
  ) async {
    final current = state;

    // Optimistic update: flip isFollowing immediately and adjust count.
    if (current is FollowLoaded) {
      final nowFollowing = !current.isFollowing;
      final delta = nowFollowing ? 1 : -1;
      emit(current.copyWith(
        isFollowing: nowFollowing,
        followerCount: (current.followerCount + delta).clamp(0, 999999),
      ));

      try {
        if (nowFollowing) {
          await _repository.follow(event.uid, event.targetUid);
        } else {
          await _repository.unfollow(event.uid, event.targetUid);
        }
        // Refresh authoritative counts from Firestore after write.
        final followerCount =
            await _repository.getFollowerCount(event.targetUid);
        final followingCount =
            await _repository.getFollowingCount(event.targetUid);
        final latest = state;
        if (latest is FollowLoaded) {
          emit(latest.copyWith(
            followerCount: followerCount,
            followingCount: followingCount,
          ));
        }
      } catch (e) {
        // Revert optimistic update on error.
        emit(current);
        emit(FollowError(e.toString()));
      }
    } else {
      // No existing state — do a full check+write.
      emit(const FollowLoading());
      try {
        final isNowFollowing =
            await _repository.isFollowing(event.uid, event.targetUid);
        if (isNowFollowing) {
          await _repository.unfollow(event.uid, event.targetUid);
        } else {
          await _repository.follow(event.uid, event.targetUid);
        }
        final isFollowing =
            await _repository.isFollowing(event.uid, event.targetUid);
        final followerCount =
            await _repository.getFollowerCount(event.targetUid);
        final followingCount =
            await _repository.getFollowingCount(event.targetUid);
        emit(FollowLoaded(
          isFollowing: isFollowing,
          followerCount: followerCount,
          followingCount: followingCount,
        ));
      } catch (e) {
        emit(FollowError(e.toString()));
      }
    }
  }

  Future<void> _onCountsRequested(
    FollowCountsRequested event,
    Emitter<FollowState> emit,
  ) async {
    try {
      final followerCount =
          await _repository.getFollowerCount(event.targetUid);
      final followingCount =
          await _repository.getFollowingCount(event.targetUid);
      final current = state;
      if (current is FollowLoaded) {
        emit(current.copyWith(
          followerCount: followerCount,
          followingCount: followingCount,
        ));
      } else {
        emit(FollowLoaded(
          isFollowing: false,
          followerCount: followerCount,
          followingCount: followingCount,
        ));
      }
    } catch (e) {
      emit(FollowError(e.toString()));
    }
  }
}
