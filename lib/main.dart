import 'dart:async';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';

import 'firebase_options.dart';
import 'core/app/app_bloc.dart';
import 'core/config/app_colors.dart';
import 'core/config/env_config.dart';
import 'core/config/theme_provider.dart';
import 'core/routing/route.dart';
import 'core/routing/route_generator.dart';
import 'core/utils/fcm_service.dart';
import 'core/utils/globals.dart';

bool _isLikelyNetworkError(Object error) {
  final message = error.toString();
  return message.contains('SocketException') ||
      message.contains('WebSocketChannelException') ||
      message.contains('Failed host lookup') ||
      message.contains('TimeoutException') ||
      message.contains('Connection reset by peer') ||
      message.contains('Connection refused');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use bundled fonts — prevent runtime HTTP fetch (SSL failures on some devices)
  GoogleFonts.config.allowRuntimeFetching = false;

  _setupGlobalErrorHandlers();

  // Load environment variables
  await EnvConfig.load(env: kDebugMode ? 'development' : 'production');

  await _initializeFirebaseCore();

  runApp(const MyApp());
  unawaited(setConfig());
}

void _setupGlobalErrorHandlers() {
  // Global Flutter error handler → Crashlytics
  // Network reachability/DNS failures are noisy and should be non-fatal.
  FlutterError.onError = (details) {
    if (_isLikelyNetworkError(details.exception)) {
      debugPrint(
        '[Main] Ignored transient network FlutterError: ${details.exception}',
      );
      return;
    }
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };

  // Global async/platform error handler → Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    if (_isLikelyNetworkError(error)) {
      debugPrint('[Main] Ignored transient network async error: $error');
      return true;
    }
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}

Future<void> _initializeFirebaseCore() async {
  if (Firebase.apps.isNotEmpty) return;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('[Main] Firebase init error: $e');
  }
}

Future<void> setConfig() async {
  Intl.defaultLocale = 'th';
  initializeDateFormatting('th', null);

  // Phase 2: ALL init in parallel (maximum speed)
  try {
    await Future.wait(<Future>[
      // Firebase services
      appBloc.setCrashlytics(),
      appBloc.setPerformance(),
      // Remote Config (network — may be slow)
      _initRemoteConfig(),
      // Auth listener (instant — just attaches stream)
      appBloc.requestCheckSignin(),
    ]).timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('[Main] Startup timeout (continuing): $e');
  }

  // Phase 3: Non-blocking post-init (fire-and-forget)
  unawaited(appBloc.preloadCaches());
  unawaited(FcmService().initialize());

  if (!kIsWeb) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }
}

/// Initialize Remote Config with fail-open defaults.
Future<void> _initRemoteConfig() async {
  try {
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 8),
        minimumFetchInterval:
            kDebugMode ? Duration.zero : const Duration(hours: 1),
      ),
    );
    await remoteConfig.setDefaults(const {
      'pixel_world_enabled': true,
      'social_feed_enabled': true,
      'broker_connect_enabled': false,
    });
    await remoteConfig.fetchAndActivate();
  } catch (e) {
    debugPrint('[Main] Remote Config error: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // ignore: library_private_types_in_public_api
  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('th');
  ThemeMode _themeMode = ThemeMode.dark; // Aslan Pixel is dark-first

  @override
  void initState() {
    super.initState();
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    final mode = await ThemeProvider.loadThemeMode();
    if (mounted && mode != _themeMode) {
      setState(() => _themeMode = mode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppColors(
      scheme: _resolveColorScheme(context),
      child: Sizer(
        builder: (context, orientation, deviceType) {
          return GetMaterialApp(
            title: 'Aslan Pixel',
            debugShowCheckedModeBanner: false,
            themeMode: _themeMode,
            onGenerateRoute: RouteGenerator.generateRoute,
            navigatorKey: Globals.navigatorKey,
            scaffoldMessengerKey: Globals.scaffoldMessengerKey,
            locale: _locale,
            supportedLocales: const [
              Locale('th'),
              Locale('en'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(1.0)),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const RootPage(isGuest: true),
          );
        },
      ),
    );
  }

  /// Change the app locale at runtime
  void changeLanguage(Locale newLocale) {
    setState(() {
      _locale = newLocale;
      Intl.defaultLocale = newLocale.languageCode;
      initializeDateFormatting(newLocale.languageCode, null);
    });
    Get.updateLocale(newLocale);
  }

  /// Change the app theme mode at runtime
  void changeTheme(ThemeMode mode) {
    if (mode == _themeMode) return;
    setState(() => _themeMode = mode);
    ThemeProvider.saveThemeMode(mode);
  }

  /// Current theme mode for external access
  ThemeMode get themeMode => _themeMode;

  /// Resolve the AppColorScheme based on theme mode.
  /// For ThemeMode.system, follows the platform brightness.
  AppColorScheme _resolveColorScheme(BuildContext context) {
    if (_themeMode == ThemeMode.dark) return AppColorScheme.dark;
    if (_themeMode == ThemeMode.light) return AppColorScheme.light;
    // ThemeMode.system — follow platform
    final brightness = MediaQuery.platformBrightnessOf(context);
    return brightness == Brightness.dark
        ? AppColorScheme.dark
        : AppColorScheme.light;
  }
}
