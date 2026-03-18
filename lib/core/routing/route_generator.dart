import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

import '../../features/auth/view/sign_in_page.dart';
import '../../features/auth/view/sign_up_page.dart';
import '../../features/home/view/main_tabs_page.dart';
import '../utils/crash_reporter.dart';

// TODO: add ProfilePage when implemented
// import '../../features/profile/view/profile_page.dart';

class RouteGenerator {
  static PageTransition gotoPage(
    Widget page, {
    PageTransitionType type = PageTransitionType.fade,
  }) {
    return PageTransition(
      isIos: true,
      child: page,
      type: type,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 100),
    );
  }

  static PageTransition gotoRightToLeftPage(Widget page) {
    return PageTransition(
      child: page,
      type: PageTransitionType.rightToLeft,
    );
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;
    try {
      if (args == null) {
        switch (settings.name) {
          case SignInPage.routeName:
            return gotoPage(const SignInPage());
          case SignUpPage.routeName:
            return gotoRightToLeftPage(const SignUpPage());
          case MainTabsPage.routeName:
            return gotoPage(const MainTabsPage());
          // TODO: ProfilePage.routeName → '/profile'
          default:
            return _errorRoute();
        }
      } else {
        switch (settings.name) {
          case SignInPage.routeName:
            return gotoPage(const SignInPage());
          case SignUpPage.routeName:
            return gotoRightToLeftPage(const SignUpPage());
          case MainTabsPage.routeName:
            if (args is int) {
              return gotoPage(MainTabsPage(tabIndex: args));
            }
            return gotoPage(const MainTabsPage());
          default:
            return _errorRoute();
        }
      }
    } catch (e, stack) {
      CrashReporter.recordError(e, stack: stack, reason: 'Route: ${settings.name}');
      return _errorRoute();
    }
  }

  // Error/fallback route
  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) {
        return const Scaffold(
          appBar: null,
          body: Center(child: Text('Please wait...')),
        );
      },
    );
  }
}
