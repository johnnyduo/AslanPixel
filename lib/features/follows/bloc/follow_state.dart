part of 'follow_bloc.dart';

/// Base class for all FollowBloc states.
sealed class FollowState extends Equatable {
  const FollowState();

  @override
  List<Object?> get props => [];
}

/// Before any check has been issued.
final class FollowInitial extends FollowState {
  const FollowInitial();
}

/// An operation (check or toggle) is in progress.
final class FollowLoading extends FollowState {
  const FollowLoading();
}

/// Follow status and counts are available.
final class FollowLoaded extends FollowState {
  const FollowLoaded({
    required this.isFollowing,
    required this.followerCount,
    required this.followingCount,
  });

  final bool isFollowing;
  final int followerCount;
  final int followingCount;

  /// Returns a copy with optional overrides.
  FollowLoaded copyWith({
    bool? isFollowing,
    int? followerCount,
    int? followingCount,
  }) {
    return FollowLoaded(
      isFollowing: isFollowing ?? this.isFollowing,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
    );
  }

  @override
  List<Object?> get props => [isFollowing, followerCount, followingCount];
}

/// An error occurred.
final class FollowError extends FollowState {
  const FollowError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
