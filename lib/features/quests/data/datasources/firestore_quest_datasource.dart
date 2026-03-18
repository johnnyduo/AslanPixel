import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:aslan_pixel/features/quests/data/models/quest_model.dart';
import 'package:aslan_pixel/features/quests/data/repositories/quest_repository.dart';

/// Firestore implementation of [QuestRepository].
///
/// Active quests: quests/{uid}/active/{questId}
/// History:       quests/{uid}/history/{questId}
class FirestoreQuestDatasource implements QuestRepository {
  FirestoreQuestDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _activeCol(String uid) =>
      _firestore.collection('quests').doc(uid).collection('active');

  CollectionReference<Map<String, dynamic>> _historyCol(String uid) =>
      _firestore.collection('quests').doc(uid).collection('history');

  // ── QuestRepository ────────────────────────────────────────────────────────

  @override
  Stream<List<QuestModel>> watchActiveQuests(String uid) {
    return _activeCol(uid)
        .snapshots()
        .map((snap) => snap.docs.map(QuestModel.fromFirestore).toList());
  }

  @override
  Future<void> updateQuestProgress(
    String uid,
    String questId,
    int increment,
  ) async {
    final docRef = _activeCol(uid).doc(questId);

    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(docRef);
      if (!snap.exists) return;

      final current = QuestModel.fromFirestore(snap);
      final newProgress = current.progress + increment;
      final isComplete = newProgress >= current.target;

      txn.update(docRef, {
        'progress': newProgress,
        'completed': isComplete,
      });

      if (isComplete) {
        // Write a history record so completed quests can be reviewed.
        final histRef = _historyCol(uid).doc(questId);
        txn.set(histRef, {
          ...current.toMap(),
          'progress': newProgress,
          'completed': true,
          'completedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  @override
  Future<void> claimQuestReward(String uid, String questId) async {
    final docRef = _activeCol(uid).doc(questId);
    final economyRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('economy')
        .doc('balance');

    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(docRef);
      if (!snap.exists) return;

      final quest = QuestModel.fromFirestore(snap);
      if (!quest.isComplete) return;

      final coins = quest.reward['coins'] as int? ?? 0;
      final xp = quest.reward['xp'] as int? ?? 0;

      // Credit economy balance.
      txn.set(
        economyRef,
        {
          'coins': FieldValue.increment(coins),
          'xp': FieldValue.increment(xp),
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // Remove from active.
      txn.delete(docRef);
    });
  }
}
