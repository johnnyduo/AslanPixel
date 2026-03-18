import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:aslan_pixel/features/follows/data/models/follow_model.dart';
import 'package:aslan_pixel/features/follows/data/repositories/follow_repository.dart';

/// Firestore-backed implementation of [FollowRepository].
///
/// Collection layout: follows/{uid}/following/{targetUid}
class FirestoreFollowDatasource implements FollowRepository {
  FirestoreFollowDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _followingRef(String uid) =>
      _firestore.collection('follows').doc(uid).collection('following');

  @override
  Future<void> follow(String uid, String targetUid) async {
    await _followingRef(uid).doc(targetUid).set({
      'targetUid': targetUid,
      'followedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> unfollow(String uid, String targetUid) async {
    await _followingRef(uid).doc(targetUid).delete();
  }

  @override
  Future<bool> isFollowing(String uid, String targetUid) async {
    final doc = await _followingRef(uid).doc(targetUid).get();
    return doc.exists;
  }

  @override
  Stream<List<FollowModel>> watchFollowing(String uid) {
    return _followingRef(uid).snapshots().map(
          (snapshot) =>
              snapshot.docs.map(FollowModel.fromFirestore).toList(),
        );
  }
}
