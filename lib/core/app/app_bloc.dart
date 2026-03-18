import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/constant.dart';
import '../enums/auth_status.dart';
import '../utils/crash_reporter.dart';
import '../utils/globals.dart';

class AppBloc {
  /// Subscription for Firebase auth state changes — must be cancelled to prevent memory leak
  StreamSubscription<User?>? _authStateSubscription;

  /// Set to true before manual logout to prevent auto-logout guard from competing.
  static bool isManualLogout = false;

  /// Prevents double-triggering of force sign-out
  bool _isForceSigningOut = false;

  // Setup Crashlytics collection
  setCrashlytics() async {
    try {
      if (kDebugMode) {
        await FirebaseCrashlytics.instance
            .setCrashlyticsCollectionEnabled(false)
            .timeout(const Duration(seconds: 5));
      } else {
        await FirebaseCrashlytics.instance
            .setCrashlyticsCollectionEnabled(true)
            .timeout(const Duration(seconds: 5));
      }
    } catch (e) {
      debugPrint('[AppBloc] setCrashlytics failed: $e');
    }
  }

  // Setup Performance Monitoring collection
  setPerformance() async {
    try {
      if (kDebugMode) {
        await FirebasePerformance.instance
            .setPerformanceCollectionEnabled(false)
            .timeout(const Duration(seconds: 5));
      } else {
        await FirebasePerformance.instance
            .setPerformanceCollectionEnabled(true)
            .timeout(const Duration(seconds: 5));
      }
    } catch (e) {
      debugPrint('[AppBloc] setPerformance failed: $e');
    }
  }

  // Setup status bar style
  setStatusBarColor() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  // Listen to Firebase Auth state changes and update global authStatus
  requestCheckSignin() async {
    // Cancel any existing subscription to prevent memory leaks
    await _authStateSubscription?.cancel();

    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (User? user) {
        if (user == null) {
          authStatus = AuthStatus.notloggedin;
          isGuest = true;
        } else {
          authStatus = AuthStatus.loggedin;
          if (user.isAnonymous == true) {
            isGuest = true;
          } else {
            isGuest = false;
          }
        }
      },
      onError: (error) {
        debugPrint('[AppBloc] authStateChanges error (no GMS?): $error');
        authStatus = AuthStatus.notloggedin;
      },
    );
  }

  /// Stub: preload caches for faster UX on home page.
  /// Will be populated in Phase 2 when data services are implemented.
  preloadCaches() async {
    // TODO: Phase 2 — preload pixel world state, portfolio data, social feed
    debugPrint('[AppBloc] preloadCaches — stub (Phase 1)');
  }

  void _navigateToSignIn() {
    final nav = Globals.navigatorKey.currentState;
    if (nav != null) {
      nav.pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  /// Force sign-out when account is detected as deleted or session is invalid.
  Future<void> forceSignOut() async {
    if (_isForceSigningOut) return;
    _isForceSigningOut = true;

    CrashReporter.log('Account session invalid — forcing sign out');

    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('[AppBloc] Force sign out error: $e');
    }

    accessToken = null;
    authStatus = AuthStatus.notloggedin;
    isGuest = true;

    _isForceSigningOut = false;
    isManualLogout = false;

    _navigateToSignIn();
  }

  /// Clean up resources — call when app is terminating
  Future<void> dispose() async {
    await _authStateSubscription?.cancel();
    _authStateSubscription = null;
  }
}

/// Global AppBloc instance — single instance for app lifetime
final AppBloc appBloc = AppBloc();
