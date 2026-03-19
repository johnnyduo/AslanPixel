import 'package:flutter/material.dart';

import 'package:aslan_pixel/features/notifications/data/datasources/firestore_notification_datasource.dart';
import 'package:aslan_pixel/features/notifications/data/models/notification_model.dart';
import 'package:aslan_pixel/shared/widgets/pixel_icon.dart';

/// AppBar action that shows a bell icon with an unread-count badge.
///
/// Streams the latest notification from Firestore to derive the unread count.
/// Taps navigate to `/notifications`.
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key, required this.uid});

  final String uid;

  static const String _routeName = '/notifications';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NotificationModel>>(
      stream: FirestoreNotificationDatasource().watchNotifications(uid, limit: 30),
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? const [];
        final unreadCount = notifications.where((n) => !n.isRead).length;

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const PixelIcon(
                PixelIcon.bell,
                size: 24,
                color: Color(0xFFe8f4ff),
              ),
              onPressed: () =>
                  Navigator.of(context).pushNamed(_routeName),
              tooltip: 'การแจ้งเตือน',
            ),
            if (unreadCount > 0)
              Positioned(
                top: 6,
                right: 6,
                child: _UnreadBadge(count: unreadCount),
              ),
          ],
        );
      },
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 9 ? '9+' : '$count';
    return Container(
      width: 16,
      height: 16,
      decoration: const BoxDecoration(
        color: Color(0xFFff4d4f),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          height: 1.0,
        ),
      ),
    );
  }
}
