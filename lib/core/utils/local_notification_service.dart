import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;

class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();
  factory LocalNotificationService() => instance;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  Future<void> showTaskComplete(String agentName, int coinsEarned) async {
    if (!_initialized) return;
    await _plugin.show(
      1001,
      'ภารกิจเสร็จสิ้น! 🎉',
      '$agentName ได้รับ $coinsEarned เหรียญ',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_complete', 'Task Complete',
          channelDescription: 'Agent task completion notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> showQuestComplete(String questTitle, int coinsEarned) async {
    if (!_initialized) return;
    await _plugin.show(
      1002,
      'Quest สำเร็จ! ✨',
      '$questTitle +$coinsEarned เหรียญ',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'quest_complete', 'Quest Complete',
          channelDescription: 'Quest completion notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
