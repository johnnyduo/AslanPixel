import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:aslan_pixel/features/follows/data/models/follow_model.dart';

/// Firestore-backed datasource for follow/unfollow operations.
///
/// Collection layout:
///   follows/{uid}/following/{targetUid}  — who uid follows
///   follows/{uid}/followers/{followerUid} — who follows uid
class FirestoreFollowDatasource {
  FirestoreFollowDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ── Collection references ──────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _followingRef(String uid) =>
      _firestore.collection('follows').doc(uid).collection('following');

  CollectionReference<Map<String, dynamic>> _followersRef(String uid) =>
      _firestore.collection('follows').doc(uid).collection('followers');

  // ── Write operations ───────────────────────────────────────────────────────

  /// Follows [targetUid] as [uid].
  /// Uses a batch write to atomically update both the following and followers
  /// sub-collections.
  Future<void> follow(String uid, String targetUid) async {
    final batch = _firestore.batch();

    // Record in uid's following list
    batch.set(
      _followingRef(uid).doc(targetUid),
      {
        'targetUid': targetUid,
        'followedAt': FieldValue.serverTimestamp(),
      },
    );

    // Record in targetUid's followers list
    batch.set(
      _followersRef(targetUid).doc(uid),
      {
        'followerUid': uid,
        'followedAt': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }

  /// Unfollows [targetUid] as [uid].
  /// Uses a batch delete to atomically remove from both sub-collections.
  Future<void> unfollow(String uid, String targetUid) async {
    final batch = _firestore.batch();

    batch.delete(_followingRef(uid).doc(targetUid));
    batch.delete(_followersRef(targetUid).doc(uid));

    await batch.commit();
  }

  // ── Read operations ────────────────────────────────────────────────────────

  /// Returns whether [uid] is currently following [targetUid].
  Future<bool> isFollowing(String uid, String targetUid) async {
    final doc = await _followingRef(uid).doc(targetUid).get();
    return doc.exists;
  }

  /// Returns a real-time stream of everyone [uid] is following,
  /// as a list of targetUid strings.
  Stream<List<String>> watchFollowing(String uid) {
    return _followingRef(uid).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => doc.data()['targetUid'] as String? ?? doc.id)
              .toList(),
        );
  }

  /// Returns a real-time stream of [FollowModel]s for everyone [uid] follows.
  Stream<List<FollowModel>> watchFollowingModels(String uid) {
    return _followingRef(uid).snapshots().map(
          (snapshot) =>
              snapshot.docs.map(FollowModel.fromFirestore).toList(),
        );
  }

  /// Returns the number of followers for [uid].
  Future<int> getFollowerCount(String uid) async {
    final snap = await _followersRef(uid).count().get();
    return snap.count ?? 0;
  }

  /// Returns the number of accounts [uid] is following.
  Future<int> getFollowingCount(String uid) async {
    final snap = await _followingRef(uid).count().get();
    return snap.count ?? 0;
  }
}
