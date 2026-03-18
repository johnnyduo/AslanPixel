import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:aslan_pixel/features/home/data/models/ranking_entry_model.dart';
import 'package:aslan_pixel/features/home/data/repositories/ranking_repository.dart';

/// Firestore implementation of [RankingRepository].
///
/// Collection path: rankings/{period}/entries/{uid}
class FirestoreRankingDatasource implements RankingRepository {
  FirestoreRankingDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _entriesCol(String period) =>
      _firestore.collection('rankings').doc(period).collection('entries');

  // ── RankingRepository ─────────────────────────────────────────────────────

  @override
  Stream<List<RankingEntryModel>> watchLeaderboard(
    String period, {
    int limit = 20,
  }) {
    return _entriesCol(period)
        .orderBy('score', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(RankingEntryModel.fromFirestore)
              .toList(),
        );
  }

  @override
  Future<RankingEntryModel?> getMyRank(String uid, String period) async {
    final snap = await _entriesCol(period).doc(uid).get();
    if (!snap.exists) return null;
    return RankingEntryModel.fromFirestore(snap);
  }
}
