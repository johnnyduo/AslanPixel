import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:aslan_pixel/features/notifications/data/models/notification_model.dart';
import 'package:aslan_pixel/features/notifications/data/repositories/notification_repository.dart';

/// Firestore implementation of [NotificationRepository].
///
/// Layout: notifications/{uid}/{notifId}
class FirestoreNotificationDatasource implements NotificationRepository {
  FirestoreNotificationDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  int _cachedUnreadCount = 0;

  CollectionReference<Map<String, dynamic>> _notifCol(String uid) =>
      _firestore.collection('notifications').doc(uid).collection('items');

  // ── NotificationRepository ────────────────────────────────────────────────

  @override
  Stream<List<NotificationModel>> watchNotifications(
    String uid, {
    int limit = 30,
  }) {
    return _notifCol(uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
      final notifications =
          snap.docs.map(NotificationModel.fromFirestore).toList();
      _cachedUnreadCount = notifications.where((n) => !n.isRead).length;
      return notifications;
    });
  }

  @override
  Future<void> markAsRead(String uid, String notifId) async {
    await _notifCol(uid).doc(notifId).update({'isRead': true});
  }

  @override
  Future<void> markAllAsRead(String uid) async {
    final snap =
        await _notifCol(uid).where('isRead', isEqualTo: false).get();

    if (snap.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  @override
  int get unreadCount => _cachedUnreadCount;
}
