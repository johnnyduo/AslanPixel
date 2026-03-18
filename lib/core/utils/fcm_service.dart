import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:aslan_pixel/core/utils/globals.dart';

/// Singleton service that wraps Firebase Cloud Messaging setup.
///
/// Call [initialize] once at app start (fire-and-forget via `unawaited`).
/// Call [saveTokenToFirestore] after the user signs in to persist the token.
class FcmService {
  static final FcmService _instance = FcmService._();
  factory FcmService() => _instance;
  FcmService._();

  Future<void> initialize() async {
    // Request permission (iOS prompts user; Android 13+ respects this)
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[FCM] Authorization status: ${settings.authorizationStatus}');

    // Retrieve and cache the device token
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      debugPrint('[FCM] Token: ${token.substring(0, 20)}...');
      Globals.fcmToken = token;
    }

    // Handle messages that arrive while the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] Foreground message: ${message.notification?.title}');
      // TODO: Phase production — show in-app notification banner
    });

    // Handle notification tap when app was in background / terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] App opened from notification: ${message.data}');
      // TODO: Phase production — navigate based on message.data['route']
    });
  }

  /// Persists the current FCM token to Firestore under the authenticated user.
  ///
  /// Call this immediately after successful sign-in.
  Future<void> saveTokenToFirestore(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('fcm')
          .set(
            {
              'token': token,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
    } catch (e) {
      debugPrint('[FCM] saveTokenToFirestore error: $e');
    }
  }
}
