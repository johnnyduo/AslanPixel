import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:aslan_pixel/features/world/data/models/plaza_presence_model.dart';
import 'package:aslan_pixel/features/world/data/repositories/plaza_repository.dart';

/// Firestore-backed implementation of [PlazaRepository].
///
/// Collection layout: plazaPresence/{uid}
class FirestorePlazaDatasource implements PlazaRepository {
  FirestorePlazaDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('plazaPresence');

  @override
  Stream<List<PlazaPresenceModel>> watchPresence({int limit = 50}) {
    return _collection
        .orderBy('lastSeen', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(PlazaPresenceModel.fromFirestore)
              .toList(),
        );
  }

  @override
  Future<void> updateMyPresence({
    required String uid,
    required double x,
    required double y,
    String? avatarId,
    String? displayName,
  }) async {
    await _collection.doc(uid).set(
      {
        'uid': uid,
        if (avatarId != null) 'avatarId': avatarId,
        if (displayName != null) 'displayName': displayName,
        'position': {'x': x, 'y': y},
        'lastSeen': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> removeMyPresence(String uid) async {
    await _collection.doc(uid).delete();
  }
}
