import 'package:flutter/foundation.dart';

import '../../features/auth/data/models/user_model.dart';
import '../config/env_config.dart';
import '../../core/enums/auth_status.dart';

// ── Google OAuth helpers ──
String? get clientId => EnvConfig.googleClientId;
String? get googleServerClientId => EnvConfig.googleServerClientId;

// ── Global auth/session state ──
String? accessToken;
String? fcmToken;
bool isGuest = false;
UserModel currentUser = UserModel();

AuthStatus authStatus = AuthStatus.notdetermined;

// ── Notification badge count ──
ValueNotifier<int> notiCount = ValueNotifier<int>(0);
