import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:aslan_pixel/features/quests/data/models/quest_model.dart';
import 'package:aslan_pixel/features/quests/data/repositories/quest_repository.dart';
import 'package:aslan_pixel/features/quests/engine/quest_generator.dart';

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

  // ── Daily quest generation ────────────────────────────────────────────────

  /// Checks whether daily quests need to be regenerated and, if so, writes a
  /// fresh set of 3 quests to quests/{uid}/active/ and updates the
  /// users/{uid}/settings/quests document with the current server timestamp.
  Future<void> generateDailyQuestsIfNeeded(String uid) async {
    final settingsRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('quests');

    final settingsSnap = await settingsRef.get();
    DateTime? lastQuestDate;
    if (settingsSnap.exists) {
      final ts = settingsSnap.data()?['lastQuestDate'] as Timestamp?;
      lastQuestDate = ts?.toDate();
    }

    if (!QuestGenerator.needsRefresh(lastQuestDate)) return;

    final now = DateTime.now();
    final quests = QuestGenerator.generateDailyQuests(uid, now);

    final batch = _firestore.batch();

    for (final quest in quests) {
      final docRef = _activeCol(uid).doc(quest.questId);
      batch.set(docRef, quest.toMap());
    }

    batch.set(
      settingsRef,
      {'lastQuestDate': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  @override
  Future<void> ensureDailyQuestsExist(String uid) =>
      generateDailyQuestsIfNeeded(uid);

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
