import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:page_transition/page_transition.dart';

import 'package:aslan_pixel/core/enums/agent_type.dart';
import 'package:aslan_pixel/features/auth/bloc/auth_bloc.dart';
import 'package:aslan_pixel/features/auth/data/datasources/firebase_auth_datasource.dart';
import 'package:aslan_pixel/features/auth/view/forgot_password_page.dart';
import 'package:aslan_pixel/features/auth/view/sign_in_page.dart';
import 'package:aslan_pixel/features/auth/view/sign_up_page.dart';
import 'package:aslan_pixel/features/broker/view/broker_page.dart';
import 'package:aslan_pixel/features/broker/view/manual_order_page.dart';
import 'package:aslan_pixel/features/feed/view/feed_page.dart';
import 'package:aslan_pixel/features/finance/view/crypto_page.dart';
import 'package:aslan_pixel/features/finance/view/finance_page.dart';
import 'package:aslan_pixel/features/home/bloc/ranking_bloc.dart';
import 'package:aslan_pixel/features/home/data/datasources/firestore_ranking_datasource.dart';
import 'package:aslan_pixel/features/home/view/friend_room_page.dart';
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
import 'package:aslan_pixel/features/settings/view/account_deletion_page.dart';
import 'package:aslan_pixel/features/settings/view/legal_page.dart';
import 'package:aslan_pixel/features/settings/view/notification_settings_page.dart';
import 'package:aslan_pixel/features/settings/view/settings_page.dart';
import 'package:aslan_pixel/features/agents/view/agent_shop_page.dart';
import 'package:aslan_pixel/features/home/view/room_3d_page.dart';
import 'package:aslan_pixel/features/home/view/model_showcase_page.dart';
import 'package:aslan_pixel/features/home/view/room_theme_shop_page.dart';
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
          case ForgotPasswordPage.routeName:
            return gotoRightToLeftPage(const ForgotPasswordPage());
          case SignInPage.routeName:
            return gotoPage(_withAuthBloc(const SignInPage()));
          case SignUpPage.routeName:
            return gotoRightToLeftPage(_withAuthBloc(const SignUpPage()));
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
          case NotificationSettingsPage.routeName:
            return gotoRightToLeftPage(const NotificationSettingsPage());
          case FeedPage.routeName:
            return gotoRightToLeftPage(const FeedPage());
          case FinancePage.routeName:
            return gotoRightToLeftPage(const FinancePage());
          case CryptoPage.routeName:
            return gotoRightToLeftPage(const CryptoPage());
          case ManualOrderPage.routeName:
            return gotoRightToLeftPage(const ManualOrderPage());
          case AgentShopPage.routeName:
            return gotoRightToLeftPage(const AgentShopPage());
          case RoomThemeShopPage.routeName:
            return gotoRightToLeftPage(const RoomThemeShopPage());
          case Room3DPage.routeName:
            return gotoRightToLeftPage(const Room3DPage());
          case ModelShowcasePage.routeName:
            return gotoRightToLeftPage(const ModelShowcasePage());
          case AccountDeletionPage.routeName:
            return gotoRightToLeftPage(const AccountDeletionPage());
          case LegalPage.privacyPolicyRouteName:
            return gotoRightToLeftPage(LegalPage.privacyPolicy());
          case LegalPage.termsOfServiceRouteName:
            return gotoRightToLeftPage(LegalPage.termsOfService());
          // Routes below require arguments — return error route when args are
          // missing so the app surfaces a meaningful fallback instead of an
          // unhandled exception from a null-argument dereference.
          case FriendRoomPage.routeName:
          case NotificationPage.routeName:
          case LeaderboardPage.routeName:
          case PixelArtEditorPage.routeName:
            return _errorRoute();
          default:
            return _errorRoute();
        }
      } else {
        switch (settings.name) {
          case ForgotPasswordPage.routeName:
            return gotoRightToLeftPage(const ForgotPasswordPage());
          case SignInPage.routeName:
            return gotoPage(_withAuthBloc(const SignInPage()));
          case SignUpPage.routeName:
            return gotoRightToLeftPage(_withAuthBloc(const SignUpPage()));
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
          case NotificationSettingsPage.routeName:
            return gotoRightToLeftPage(const NotificationSettingsPage());
          case FeedPage.routeName:
            return gotoRightToLeftPage(const FeedPage());
          case FinancePage.routeName:
            return gotoRightToLeftPage(const FinancePage());
          case CryptoPage.routeName:
            return gotoRightToLeftPage(const CryptoPage());
          case ManualOrderPage.routeName:
            return gotoRightToLeftPage(const ManualOrderPage());
          case AgentShopPage.routeName:
            return gotoRightToLeftPage(const AgentShopPage());
          case RoomThemeShopPage.routeName:
            return gotoRightToLeftPage(const RoomThemeShopPage());
          case Room3DPage.routeName:
            if (args is AgentType) {
              return gotoRightToLeftPage(Room3DPage(agentType: args));
            }
            return gotoRightToLeftPage(const Room3DPage());
          case ModelShowcasePage.routeName:
            return gotoRightToLeftPage(const ModelShowcasePage());
          case AccountDeletionPage.routeName:
            return gotoRightToLeftPage(const AccountDeletionPage());
          case LegalPage.privacyPolicyRouteName:
            return gotoRightToLeftPage(LegalPage.privacyPolicy());
          case LegalPage.termsOfServiceRouteName:
            return gotoRightToLeftPage(LegalPage.termsOfService());
          case FriendRoomPage.routeName:
            if (args is Map<String, String>) {
              return gotoRightToLeftPage(
                FriendRoomPage(
                  friendUid: args['friendUid'] ?? '',
                  friendName: args['friendName'] ?? '',
                ),
              );
            }
            return _errorRoute();
          case LeaderboardPage.routeName:
            if (args is String && args.isNotEmpty) {
              return gotoRightToLeftPage(
                BlocProvider<RankingBloc>(
                  create: (_) => RankingBloc(FirestoreRankingDatasource())
                    ..add(RankingWatchStarted(uid: args, period: 'weekly')),
                  child: LeaderboardPage(uid: args),
                ),
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

  // Wrap auth pages with AuthBloc
  static Widget _withAuthBloc(Widget child) {
    return BlocProvider<AuthBloc>(
      create: (_) => AuthBloc(repository: FirebaseAuthDatasource()),
      child: child,
    );
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
