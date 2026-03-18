import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  // Google OAuth
  static String get googleClientId =>
      dotenv.get('GOOGLE_CLIENT_ID', fallback: '');
  static String get googleServerClientId =>
      dotenv.get('GOOGLE_SERVER_CLIENT_ID', fallback: '');

  // Firebase
  static String get firebaseApiKey =>
      dotenv.get('FIREBASE_API_KEY', fallback: '');
  static String get firebaseAppId =>
      dotenv.get('FIREBASE_APP_ID', fallback: '');
  static String get firebaseMessagingSenderId =>
      dotenv.get('FIREBASE_MESSAGING_SENDER_ID', fallback: '');
  static String get firebaseProjectId =>
      dotenv.get('FIREBASE_PROJECT_ID', fallback: '');
  static String get firebaseAuthDomain =>
      dotenv.get('FIREBASE_AUTH_DOMAIN', fallback: '');
  static String get firebaseStorageBucket =>
      dotenv.get('FIREBASE_STORAGE_BUCKET', fallback: '');
  static String get firebaseMeasurementId =>
      dotenv.get('FIREBASE_MEASUREMENT_ID', fallback: '');

  // AI
  static String get geminiApiKey =>
      dotenv.get('GEMINI_API_KEY', fallback: '');

  // Broker
  static String get brokerEncryptionSecret =>
      dotenv.get('BROKER_ENCRYPTION_SECRET', fallback: '');

  static const _requiredVars = [
    'FIREBASE_PROJECT_ID',
    'FIREBASE_API_KEY',
    'FIREBASE_APP_ID',
  ];

  static Future<void> load({String env = 'production'}) async {
    final envFile = env == 'development' ? '.env.development' : '.env.production';
    try {
      await dotenv.load(fileName: envFile);
    } catch (_) {
      try {
        await dotenv.load(fileName: '.env');
      } catch (e2) {
        if (kDebugMode) debugPrint('[EnvConfig] No .env file found: $e2');
      }
    }
    if (kDebugMode) {
      final missing = _requiredVars
          .where((v) => dotenv.get(v, fallback: '').isEmpty)
          .toList();
      assert(missing.isEmpty,
          '[EnvConfig] Missing required env vars: ${missing.join(', ')}');
    }
  }
}
