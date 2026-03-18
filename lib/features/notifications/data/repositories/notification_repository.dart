import 'package:aslan_pixel/features/notifications/data/models/notification_model.dart';

/// Abstract contract for notification persistence and observation.
abstract class NotificationRepository {
  /// Stream of the latest [limit] notifications for [uid], ordered newest-first.
  Stream<List<NotificationModel>> watchNotifications(
    String uid, {
    int limit = 30,
  });

  /// Marks a single notification as read.
  Future<void> markAsRead(String uid, String notifId);

  /// Marks every unread notification as read in a single batch.
  Future<void> markAllAsRead(String uid);

  /// Count of unread notifications computed from the most recent stream event.
  int get unreadCount;
}
