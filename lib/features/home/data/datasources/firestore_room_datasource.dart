import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:aslan_pixel/features/home/data/models/room_item_model.dart';
import 'package:aslan_pixel/features/home/data/repositories/room_repository.dart';
import 'package:aslan_pixel/features/inventory/data/repositories/economy_repository.dart';

/// Firestore implementation of [RoomRepository].
///
/// Document path: rooms/{uid}
class FirestoreRoomDatasource implements RoomRepository {
  FirestoreRoomDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection('rooms').doc(uid);

  // ── RoomRepository ────────────────────────────────────────────────────────

  @override
  Future<RoomModel?> getRoom(String uid) async {
    final snap = await _doc(uid).get();
    if (!snap.exists) return null;
    return RoomModel.fromFirestore(snap);
  }

  @override
  Future<void> saveRoom(String uid, RoomModel room) async {
    await _doc(uid).set(room.toMap(), SetOptions(merge: true));
  }

  @override
  Stream<RoomModel?> watchRoom(String uid) {
    return _doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return RoomModel.fromFirestore(snap);
    });
  }

  @override
  Future<void> placeItem(String uid, RoomItem item) async {
    final ref = _doc(uid);

    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(ref);

      List<Map<String, dynamic>> currentItems;
      if (snap.exists) {
        final data = snap.data() ?? {};
        currentItems = List<Map<String, dynamic>>.from(
          (data['items'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>(),
        );
      } else {
        currentItems = [];
      }

      // Guard: slot must be unoccupied.
      final slotTaken = currentItems.any(
        (m) => m['slotX'] == item.slotX && m['slotY'] == item.slotY,
      );
      if (slotTaken) {
        throw StateError(
          'Slot (${item.slotX}, ${item.slotY}) is already occupied.',
        );
      }

      currentItems.add(item.toMap());

      txn.set(
        ref,
        {
          'items': currentItems,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  @override
  Future<void> removeItem(String uid, String itemId) async {
    final ref = _doc(uid);

    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) return;

      final data = snap.data() ?? {};
      final currentItems = List<Map<String, dynamic>>.from(
        (data['items'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>(),
      );

      final filtered =
          currentItems.where((m) => m['itemId'] != itemId).toList();

      txn.update(ref, {
        'items': filtered,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<List<RoomItem>> getFriendRoom(String friendUid) async {
    final snap = await _doc(friendUid).get();
    if (!snap.exists) return [];
    final data = snap.data() ?? {};
    final rawItems = data['items'] as List<dynamic>? ?? [];
    return rawItems
        .map((e) => RoomItem.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // ── Theme Shop ──────────────────────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>> _balanceRef(String uid) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('economy')
          .doc('balance');

  @override
  Future<void> purchaseTheme({
    required String uid,
    required String themeId,
    required int price,
  }) async {
    final roomRef = _doc(uid);
    final balRef = _balanceRef(uid);
    final txLogRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('economy')
        .doc('balance')
        .collection('transactions')
        .doc();

    await _firestore.runTransaction((txn) async {
      // 1. Read current balance.
      final balSnap = await txn.get(balRef);
      final currentCoins = balSnap.exists
          ? (balSnap.data()?['coins'] as int? ?? 0)
          : 0;

      if (currentCoins < price) {
        throw InsufficientCoinsException(currentCoins, price);
      }

      // 2. Read current room doc for owned themes.
      final roomSnap = await txn.get(roomRef);
      final roomData = roomSnap.data() ?? {};
      final ownedThemes = List<String>.from(
        roomData['ownedThemes'] as List<dynamic>? ?? <String>['starter'],
      );

      if (ownedThemes.contains(themeId)) {
        throw StateError('Theme "$themeId" is already owned.');
      }

      // 3. Deduct coins.
      txn.set(
        balRef,
        {
          'coins': FieldValue.increment(-price),
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // 4. Log the transaction.
      txn.set(txLogRef, {
        'type': 'debit',
        'amount': price,
        'reason': 'room_theme_purchase:$themeId',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 5. Add theme to owned list.
      ownedThemes.add(themeId);
      txn.set(
        roomRef,
        {
          'ownedThemes': ownedThemes,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  @override
  Future<void> setActiveTheme({
    required String uid,
    required String themeId,
  }) async {
    final roomRef = _doc(uid);

    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(roomRef);
      final data = snap.data() ?? {};
      final ownedThemes = List<String>.from(
        data['ownedThemes'] as List<dynamic>? ?? <String>['starter'],
      );

      if (!ownedThemes.contains(themeId)) {
        throw StateError('Theme "$themeId" is not owned — cannot activate.');
      }

      txn.set(
        roomRef,
        {
          'activeTheme': themeId,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  @override
  Future<List<String>> getOwnedThemes(String uid) async {
    final snap = await _doc(uid).get();
    if (!snap.exists) return ['starter'];
    final data = snap.data() ?? {};
    return List<String>.from(
      data['ownedThemes'] as List<dynamic>? ?? <String>['starter'],
    );
  }

  @override
  Future<String> getActiveTheme(String uid) async {
    final snap = await _doc(uid).get();
    if (!snap.exists) return 'starter';
    final data = snap.data() ?? {};
    return data['activeTheme'] as String? ?? 'starter';
  }

  @override
  Future<void> unlockItem(String uid, String itemId) async {
    final ref = _doc(uid);

    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(ref);
      if (!snap.exists) return;

      final data = snap.data() ?? {};
      final currentItems = List<Map<String, dynamic>>.from(
        (data['items'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>(),
      );

      final index = currentItems.indexWhere((m) => m['itemId'] == itemId);
      if (index == -1) return;

      currentItems[index] = {
        ...currentItems[index],
        'isUnlocked': true,
      };

      txn.update(ref, {
        'items': currentItems,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
