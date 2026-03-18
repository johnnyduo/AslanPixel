import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aslan_pixel/core/utils/time_utils.dart';
import 'package:aslan_pixel/features/notifications/bloc/notification_bloc.dart';
import 'package:aslan_pixel/features/notifications/data/models/notification_model.dart';
import 'package:aslan_pixel/shared/widgets/empty_state_widget.dart';

// ── Palette ────────────────────────────────────────────────────────────────
const _kBackground = Color(0xFF0a1628);
const _kSurface = Color(0xFF162040);
const _kBorder = Color(0xFF1e3050);
const _kNeonGreen = Color(0xFF00f5a0);
const _kTextPrimary = Color(0xFFe8f4ff);
const _kTextSecondary = Color(0xFFa8c4e0);
const _kTextDisabled = Color(0xFF3d5a78);
const _kGold = Color(0xFFf5c518);
const _kCyan = Color(0xFF4fc3f7);

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key, required this.uid});

  static const routeName = '/notifications';

  final String uid;

  @override
  Widget build(BuildContext context) {
    // NotificationBloc is provided by the parent DI layer.
    // Trigger the watch as soon as the page is built.
    context.read<NotificationBloc>().add(NotificationWatchStarted(uid));
    return _NotificationView(uid: uid);
  }
}

class _NotificationView extends StatelessWidget {
  const _NotificationView({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        foregroundColor: _kTextPrimary,
        elevation: 0,
        title: const Text(
          'การแจ้งเตือน',
          style: TextStyle(
            color: _kTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kBorder),
        ),
        actions: [
          TextButton(
            onPressed: () {
              context
                  .read<NotificationBloc>()
                  .add(NotificationAllMarkedRead(uid));
            },
            child: const Text(
              'อ่านทั้งหมด',
              style: TextStyle(
                color: _kNeonGreen,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading || state is NotificationInitial) {
            return const Center(
              child: CircularProgressIndicator(
                color: _kNeonGreen,
                strokeWidth: 2,
              ),
            );
          }

          if (state is NotificationError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Color(0xFFff4d4f), fontSize: 14),
                textAlign: TextAlign.center,
              ),
            );
          }

          if (state is NotificationLoaded) {
            if (state.notifications.isEmpty) {
              return const EmptyStateWidget(
                emoji: '🔔',
                titleTh: 'ยังไม่มีการแจ้งเตือน',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.notifications.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: _kBorder, height: 1),
              itemBuilder: (context, index) {
                final notif = state.notifications[index];
                return _NotificationTile(
                  notification: notif,
                  onTap: () {
                    if (!notif.isRead) {
                      context.read<NotificationBloc>().add(
                            NotificationMarkedRead(
                              notifId: notif.notifId,
                              uid: uid,
                            ),
                          );
                    }
                  },
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  final NotificationModel notification;
  final VoidCallback onTap;

  IconData _typeIcon() {
    switch (notification.type) {
      case 'quest_complete':
        return Icons.star_rounded;
      case 'prediction_settled':
        return Icons.bar_chart_rounded;
      case 'agent_returned':
        return Icons.smart_toy_rounded;
      case 'social':
        return Icons.people_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _typeColor() {
    switch (notification.type) {
      case 'quest_complete':
        return _kGold;
      case 'prediction_settled':
        return _kNeonGreen;
      case 'agent_returned':
        return _kCyan;
      case 'social':
        return const Color(0xFF7b2fff);
      default:
        return _kTextDisabled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      splashColor: _kNeonGreen.withValues(alpha: 0.05),
      highlightColor: _kNeonGreen.withValues(alpha: 0.03),
      child: Container(
        color: isUnread
            ? _kSurface.withValues(alpha: 0.6)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leading icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _typeColor().withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _typeIcon(),
                color: _typeColor(),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.titleTh,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _kTextPrimary,
                      fontSize: 14,
                      fontWeight: isUnread ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.bodyTh,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _kTextSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Trailing: time + unread dot
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  TimeUtils.timeAgoTh(notification.createdAt),
                  style: const TextStyle(
                    color: _kTextDisabled,
                    fontSize: 11,
                  ),
                ),
                if (isUnread) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: _kNeonGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
