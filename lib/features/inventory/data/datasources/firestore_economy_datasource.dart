import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:aslan_pixel/features/inventory/data/models/economy_model.dart';
import 'package:aslan_pixel/features/inventory/data/repositories/economy_repository.dart';

/// Firestore implementation of [EconomyRepository].
///
/// Balance document:     users/{uid}/economy/balance
/// Transaction log:      users/{uid}/economy/transactions/{auto-id}
class FirestoreEconomyDatasource implements EconomyRepository {
  FirestoreEconomyDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _balanceRef(String uid) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('economy')
          .doc('balance');

  CollectionReference<Map<String, dynamic>> _txCol(String uid) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('economy')
          .doc('balance')
          .collection('transactions');

  // ── EconomyRepository ──────────────────────────────────────────────────────

  @override
  Stream<EconomyModel> watchEconomy(String uid) {
    return _balanceRef(uid).snapshots().map((snap) {
      if (!snap.exists) {
        return EconomyModel(
          coins: 0,
          xp: 0,
          unlockPoints: 0,
          lastUpdated: DateTime.now(),
        );
      }
      return EconomyModel.fromFirestore(snap);
    });
  }

  @override
  Future<void> addCoins(String uid, int amount, String reason) async {
    final balRef = _balanceRef(uid);
    final txRef = _txCol(uid).doc();

    await _firestore.runTransaction((txn) async {
      txn.set(
        balRef,
        {
          'coins': FieldValue.increment(amount),
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      txn.set(txRef, {
        'type': 'credit',
        'amount': amount,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> deductCoins(String uid, int amount, String reason) async {
    final balRef = _balanceRef(uid);
    final txRef = _txCol(uid).doc();

    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(balRef);
      final current = snap.exists
          ? (snap.data()?['coins'] as int? ?? 0)
          : 0;

      if (current < amount) {
        throw InsufficientCoinsException(current, amount);
      }

      txn.set(
        balRef,
        {
          'coins': FieldValue.increment(-amount),
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      txn.set(txRef, {
        'type': 'debit',
        'amount': amount,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> addXp(String uid, int amount) async {
    await _firestore.runTransaction((txn) async {
      final ref = _balanceRef(uid);
      txn.set(
        ref,
        {
          'xp': FieldValue.increment(amount),
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }
}
