import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/enums/agent_type.dart';
import '../../../inventory/data/repositories/economy_repository.dart';
import '../models/agent_model.dart';
import '../repositories/agent_repository.dart';

class FirestoreAgentDatasource implements AgentRepository {
  FirestoreAgentDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _agentsCollection(String uid) =>
      _firestore.collection('users').doc(uid).collection('agents');

  @override
  Stream<List<AgentModel>> watchAgents(String uid) {
    return _agentsCollection(uid).snapshots().map(
          (snapshot) =>
              snapshot.docs.map(AgentModel.fromFirestore).toList(),
        );
  }

  @override
  Future<AgentModel?> getAgent(String uid, AgentType type) async {
    final snapshot = await _agentsCollection(uid)
        .where('type', isEqualTo: type.value)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return AgentModel.fromFirestore(snapshot.docs.first);
  }

  @override
  Future<void> updateAgentStatus(
    String uid,
    String agentId,
    AgentStatus status,
  ) async {
    await _agentsCollection(uid).doc(agentId).update({
      'status': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> clearActiveTask(String uid, String agentId) async {
    await _agentsCollection(uid).doc(agentId).update({
      'activeTaskId': FieldValue.delete(),
      'taskCompletesAt': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> levelUpAgent(String uid, String agentId) async {
    final docRef = _agentsCollection(uid).doc(agentId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final current = AgentModel.fromFirestore(snapshot);
      final newLevel = (current.level + 1).clamp(1, 10);

      transaction.update(docRef, {
        'level': newLevel,
        'xp': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> purchaseAgent({
    required String uid,
    required AgentType type,
    required int price,
  }) async {
    final balRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('economy')
        .doc('balance');
    final agentRef = _agentsCollection(uid).doc(type.value);

    await _firestore.runTransaction((txn) async {
      // Check if agent already exists
      final agentSnap = await txn.get(agentRef);
      if (agentSnap.exists) {
        throw AgentAlreadyOwnedException(type);
      }

      // Deduct coins (skip for free agents)
      if (price > 0) {
        final balSnap = await txn.get(balRef);
        final currentCoins = balSnap.exists
            ? (balSnap.data()?['coins'] as int? ?? 0)
            : 0;
        if (currentCoins < price) {
          throw InsufficientCoinsException(currentCoins, price);
        }
        txn.set(
          balRef,
          {
            'coins': FieldValue.increment(-price),
            'lastUpdated': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      // Create agent document
      txn.set(agentRef, {
        'type': type.value,
        'level': 1,
        'xp': 0,
        'status': AgentStatus.idle.value,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}

/// Thrown when the player already owns the requested agent.
class AgentAlreadyOwnedException implements Exception {
  const AgentAlreadyOwnedException(this.type);
  final AgentType type;

  @override
  String toString() => 'AgentAlreadyOwnedException: ${type.value} already owned';
}
