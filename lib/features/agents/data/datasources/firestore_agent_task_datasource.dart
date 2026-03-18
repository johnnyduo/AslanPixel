import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:aslan_pixel/features/agents/data/repositories/agent_task_repository.dart';
import 'package:aslan_pixel/features/agents/engine/agent_task_model.dart';

/// Firestore implementation of [AgentTaskRepository].
///
/// Layout:
///   agentTasks/{uid}/tasks/{taskId}
///   users/{uid}/economy/balance  — coins + xp credited on settlement
class FirestoreAgentTaskDatasource implements AgentTaskRepository {
  FirestoreAgentTaskDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _tasksCol(String uid) =>
      _firestore.collection('agentTasks').doc(uid).collection('tasks');

  DocumentReference<Map<String, dynamic>> _economyDoc(String uid) =>
      _firestore.collection('users').doc(uid).collection('economy').doc('balance');

  // ── AgentTaskRepository ───────────────────────────────────────────────────

  @override
  Future<void> saveTask(String uid, AgentTask task) async {
    await _tasksCol(uid).doc(task.taskId).set(task.toMap());
  }

  @override
  Stream<List<AgentTask>> watchPendingTasks(String uid) {
    return _tasksCol(uid)
        .where('isSettled', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.map(AgentTask.fromFirestore).toList());
  }

  @override
  Future<void> settleTask(String uid, String taskId, int actualReward) async {
    final taskRef = _tasksCol(uid).doc(taskId);
    final economyRef = _economyDoc(uid);

    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(taskRef);
      if (!snap.exists) return;

      final task = AgentTask.fromFirestore(snap);
      if (task.isSettled) return;

      txn.update(taskRef, {
        'isSettled': true,
        'actualReward': actualReward,
        'settledAt': FieldValue.serverTimestamp(),
      });

      txn.set(
        economyRef,
        {
          'coins': FieldValue.increment(actualReward),
          'xp': FieldValue.increment(task.xpReward),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  @override
  Future<void> clearSettledTasks(String uid) async {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));

    final snap = await _tasksCol(uid)
        .where('isSettled', isEqualTo: true)
        .where('settledAt', isLessThan: Timestamp.fromDate(cutoff))
        .get();

    if (snap.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
