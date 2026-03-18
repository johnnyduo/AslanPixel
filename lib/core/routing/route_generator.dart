import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:page_transition/page_transition.dart';

import 'package:aslan_pixel/features/auth/view/sign_in_page.dart';
import 'package:aslan_pixel/features/auth/view/sign_up_page.dart';
import 'package:aslan_pixel/features/broker/view/broker_page.dart';
import 'package:aslan_pixel/features/home/data/repositories/ranking_repository.dart';
import 'package:aslan_pixel/features/home/view/leaderboard_page.dart';
import 'package:aslan_pixel/features/home/view/main_tabs_page.dart';
import 'package:aslan_pixel/features/inventory/view/inventory_page.dart';
import 'package:aslan_pixel/features/notifications/bloc/notification_bloc.dart';
import 'package:aslan_pixel/features/notifications/data/datasources/firestore_notification_datasource.dart';
import 'package:aslan_pixel/features/notifications/view/notification_page.dart';
import 'package:aslan_pixel/features/onboarding/view/onboarding_page.dart';
import 'package:aslan_pixel/features/pixel_art/data/models/pixel_canvas_model.dart';
import 'package:aslan_pixel/features/pixel_art/view/pixel_art_editor_page.dart';
import 'package:aslan_pixel/features/pixel_art/view/pixel_art_gallery_page.dart';
import 'package:aslan_pixel/features/profile/view/edit_profile_page.dart';
import 'package:aslan_pixel/features/profile/view/profile_page.dart';
import 'package:aslan_pixel/features/quests/view/quest_page.dart';
import 'package:aslan_pixel/features/settings/view/settings_page.dart';
import 'package:aslan_pixel/features/world/view/plaza_page.dart';
import '../utils/crash_reporter.dart';

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
          case OnboardingPage.routeName:
            return gotoPage(const OnboardingPage());
          case ProfilePage.routeName:
            return gotoRightToLeftPage(const ProfilePage());
          case EditProfilePage.routeName:
            return gotoRightToLeftPage(const EditProfilePage());
          case PixelArtGalleryPage.routeName:
            return gotoRightToLeftPage(const PixelArtGalleryPage());
          case InventoryPage.routeName:
            return gotoRightToLeftPage(const InventoryPage());
          case BrokerPage.routeName:
            return gotoRightToLeftPage(const BrokerPage());
          case PlazaPage.routeName:
            return gotoRightToLeftPage(const PlazaPage());
          case QuestPage.routeName:
            return gotoRightToLeftPage(const QuestPage());
          case SettingsPage.routeName:
            return gotoRightToLeftPage(const SettingsPage());
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
          case OnboardingPage.routeName:
            return gotoPage(const OnboardingPage());
          case ProfilePage.routeName:
            return gotoRightToLeftPage(const ProfilePage());
          case EditProfilePage.routeName:
            return gotoRightToLeftPage(const EditProfilePage());
          case PixelArtGalleryPage.routeName:
            return gotoRightToLeftPage(const PixelArtGalleryPage());
          case InventoryPage.routeName:
            return gotoRightToLeftPage(const InventoryPage());
          case BrokerPage.routeName:
            return gotoRightToLeftPage(const BrokerPage());
          case PlazaPage.routeName:
            return gotoRightToLeftPage(const PlazaPage());
          case QuestPage.routeName:
            return gotoRightToLeftPage(const QuestPage());
          case SettingsPage.routeName:
            return gotoRightToLeftPage(const SettingsPage());
          case LeaderboardPage.routeName:
            if (args is RankingRepository) {
              return gotoRightToLeftPage(
                LeaderboardPage(rankingRepository: args),
              );
            }
            return _errorRoute();
          case NotificationPage.routeName:
            if (args is String) {
              return gotoRightToLeftPage(
                BlocProvider<NotificationBloc>(
                  create: (_) => NotificationBloc(
                    repository: FirestoreNotificationDatasource(),
                  ),
                  child: NotificationPage(uid: args),
                ),
              );
            }
            return _errorRoute();
          case PixelArtEditorPage.routeName:
            if (args is PixelCanvasModel) {
              return gotoRightToLeftPage(PixelArtEditorPage(canvas: args));
            }
            return _errorRoute();
          default:
            return _errorRoute();
        }
      }
    } catch (e, stack) {
      CrashReporter.recordError(
        e,
        stack: stack,
        reason: 'Route: ${settings.name}',
      );
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
