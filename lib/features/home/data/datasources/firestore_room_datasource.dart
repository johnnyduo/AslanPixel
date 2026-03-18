import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:aslan_pixel/features/home/data/models/room_item_model.dart';
import 'package:aslan_pixel/features/home/data/repositories/room_repository.dart';

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
