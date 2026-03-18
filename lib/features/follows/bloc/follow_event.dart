part of 'follow_bloc.dart';

/// Base class for all FollowBloc events.
sealed class FollowEvent extends Equatable {
  const FollowEvent();

  @override
  List<Object?> get props => [];
}

/// Check whether [uid] is following [targetUid] and load counts.
final class FollowCheckRequested extends FollowEvent {
  const FollowCheckRequested({required this.uid, required this.targetUid});

  final String uid;
  final String targetUid;

  @override
  List<Object?> get props => [uid, targetUid];
}

/// Toggle follow state: follow if not following, unfollow if already following.
final class FollowToggled extends FollowEvent {
  const FollowToggled({required this.uid, required this.targetUid});

  final String uid;
  final String targetUid;

  @override
  List<Object?> get props => [uid, targetUid];
}

/// Load follower and following counts for [targetUid].
final class FollowCountsRequested extends FollowEvent {
  const FollowCountsRequested({required this.targetUid});

  final String targetUid;

  @override
  List<Object?> get props => [targetUid];
}
