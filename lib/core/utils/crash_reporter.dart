import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

/// Centralized error reporting utility.
///
/// Wraps Firebase Crashlytics + Performance in safe, concise APIs.
/// All methods are no-throw — safe to call anywhere without try-catch.
/// Lazily checks if Crashlytics is available on first use; skips if not
/// (e.g. in tests where the Crashlytics plugin isn't fully initialized).
class CrashReporter {
  CrashReporter._();

  // Lazy-initialized Crashlytics instance. Null = not available.
  static FirebaseCrashlytics? _crashlytics;
  static bool _crashlyticsChecked = false;

  /// Safely get FirebaseCrashlytics, or null if unavailable.
  /// Caches result — plugin assertion fires at most once.
  static FirebaseCrashlytics? get _instance {
    if (!_crashlyticsChecked) {
      _crashlyticsChecked = true;
      try {
        final c = FirebaseCrashlytics.instance;
        // Force delegate init to verify plugin is fully usable
        c.isCrashlyticsCollectionEnabled;
        _crashlytics = c;
      } catch (_) {
        _crashlytics = null;
      }
    }
    return _crashlytics;
  }

  /// Record a non-fatal error to Crashlytics.
  /// Use for unexpected errors that shouldn't crash the app but need tracking.
  static void recordError(Object error, {StackTrace? stack, String? reason}) {
    try {
      _instance?.recordError(
        error,
        stack ?? StackTrace.current,
        reason: reason,
      );
    } catch (_) {}
    if (kDebugMode) debugPrint('[CrashReporter] ${reason ?? 'error'}: $error');
  }

  /// Log a breadcrumb message for crash timeline.
  /// Use at key user actions: navigation, API calls, auth transitions.
  static void log(String message) {
    try {
      _instance?.log(message);
    } catch (_) {}
    if (kDebugMode) debugPrint('[Breadcrumb] $message');
  }

  /// Set a custom key-value pair on crash reports.
  /// Use for user context: auth state, active screen, user role.
  static void setKey(String key, Object value) {
    try {
      _instance?.setCustomKey(key, value);
    } catch (_) {}
  }

  /// Set multiple custom keys at once.
  static void setKeys(Map<String, Object> keys) {
    for (final entry in keys.entries) {
      setKey(entry.key, entry.value);
    }
  }

  /// Set the Crashlytics user identifier.
  static void setUserId(String uid) {
    try {
      _instance?.setUserIdentifier(uid);
    } catch (_) {}
  }

  /// Start a Performance Monitoring trace.
  /// Returns null if Performance is unavailable (safe to use with ?.).
  static Trace? startTrace(String name) {
    try {
      final trace = FirebasePerformance.instance.newTrace(name);
      trace.start();
      return trace;
    } catch (_) {
      return null;
    }
  }

  /// Stop a trace safely (handles null).
  static void stopTrace(Trace? trace, {Map<String, String>? attributes}) {
    if (trace == null) return;
    try {
      attributes?.forEach((k, v) => trace.putAttribute(k, v));
      trace.stop();
    } catch (_) {}
  }
}
