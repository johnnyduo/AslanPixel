import 'package:aslan_pixel/features/follows/data/datasources/firestore_follow_datasource.dart';
import 'package:aslan_pixel/features/follows/data/models/follow_model.dart';
import 'package:aslan_pixel/features/follows/data/repositories/follow_repository.dart';

/// Concrete [FollowRepository] backed by [FirestoreFollowDatasource].
class FollowRepositoryImpl implements FollowRepository {
  const FollowRepositoryImpl(this._datasource);

  final FirestoreFollowDatasource _datasource;

  @override
  Future<void> follow(String uid, String targetUid) =>
      _datasource.follow(uid, targetUid);

  @override
  Future<void> unfollow(String uid, String targetUid) =>
      _datasource.unfollow(uid, targetUid);

  @override
  Future<bool> isFollowing(String uid, String targetUid) =>
      _datasource.isFollowing(uid, targetUid);

  @override
  Stream<List<String>> watchFollowing(String uid) =>
      _datasource.watchFollowing(uid);

  @override
  Stream<List<FollowModel>> watchFollowingModels(String uid) =>
      _datasource.watchFollowingModels(uid);

  @override
  Future<int> getFollowerCount(String uid) =>
      _datasource.getFollowerCount(uid);

  @override
  Future<int> getFollowingCount(String uid) =>
      _datasource.getFollowingCount(uid);
}
