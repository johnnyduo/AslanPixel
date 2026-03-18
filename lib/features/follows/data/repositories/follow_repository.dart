import 'package:aslan_pixel/features/follows/data/models/follow_model.dart';

/// Abstract interface for follow/unfollow operations.
abstract class FollowRepository {
  /// Follows [targetUid] as [uid].
  Future<void> follow(String uid, String targetUid);

  /// Unfollows [targetUid] as [uid].
  Future<void> unfollow(String uid, String targetUid);

  /// Returns whether [uid] is currently following [targetUid].
  Future<bool> isFollowing(String uid, String targetUid);

  /// Returns a real-time stream of everyone [uid] is following (as UIDs).
  Stream<List<String>> watchFollowing(String uid);

  /// Returns a real-time stream of [FollowModel]s for everyone [uid] follows.
  Stream<List<FollowModel>> watchFollowingModels(String uid);

  /// Returns the number of followers [uid] has.
  Future<int> getFollowerCount(String uid);

  /// Returns the number of accounts [uid] is following.
  Future<int> getFollowingCount(String uid);
}
