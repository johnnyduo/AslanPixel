import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../config/constant.dart';
import '../enums/auth_status.dart';
import '../../features/auth/view/sign_in_page.dart';
import '../../features/home/view/main_tabs_page.dart';

class RootPage extends StatefulWidget {
  const RootPage({
    super.key,
    this.tabIndex,
    this.isGuest,
  });

  final int? tabIndex;
  final bool? isGuest;

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  StreamSubscription<User?>? _authSub;
  Timer? _safetyTimer;

  @override
  void initState() {
    super.initState();
    // Listen to auth state changes so we rebuild when authStatus is set
    _authSub = FirebaseAuth.instance.authStateChanges().listen((_) {
      _safetyTimer?.cancel();
      if (mounted) setState(() {});
    });

    // Safety net: if auth state never resolves (e.g. Huawei without GMS),
    // force to guest/login screen after 5 seconds to prevent white screen hang.
    _safetyTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && authStatus == AuthStatus.notdetermined) {
        debugPrint('[RootPage] Auth timeout — forcing notloggedin (Huawei/no-GMS?)');
        authStatus = AuthStatus.notloggedin;
        isGuest = true;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _safetyTimer?.cancel();
    super.dispose();
  }

  Widget _buildWaitingScreen() {
    if (authStatus == AuthStatus.notloggedin) {
      return const SignInPage();
    } else if (authStatus == AuthStatus.loggedin) {
      return const MainTabsPage();
    } else {
      // Show a loading indicator instead of blank white screen
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (authStatus) {
      case AuthStatus.notdetermined:
        return _buildWaitingScreen();
      case AuthStatus.notloggedin:
        return _buildWaitingScreen();
      case AuthStatus.loggedin:
        if (accessToken != null) {
          return MainTabsPage(tabIndex: widget.tabIndex ?? 0);
        } else {
          return _buildWaitingScreen();
        }
      default:
        return _buildWaitingScreen();
    }
  }
}
