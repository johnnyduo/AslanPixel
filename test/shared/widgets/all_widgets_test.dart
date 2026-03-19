// ignore_for_file: avoid_redundant_argument_values

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aslan_pixel/core/config/app_colors.dart';
import 'package:aslan_pixel/shared/widgets/animated_coin_counter.dart';
import 'package:aslan_pixel/shared/widgets/coin_badge_widget.dart';
import 'package:aslan_pixel/shared/widgets/empty_state_widget.dart';
import 'package:aslan_pixel/shared/widgets/pixel_error_widget.dart';
import 'package:aslan_pixel/shared/widgets/loader/loader_widget.dart';
import 'package:aslan_pixel/shared/widgets/sparkline_chart.dart';
import 'package:aslan_pixel/shared/widgets/confetti_overlay.dart';
import 'package:aslan_pixel/shared/widgets/floating_reward_text.dart';
import 'package:aslan_pixel/shared/widgets/xp_progress_bar.dart';
import 'package:aslan_pixel/shared/widgets/ready_to_collect_badge.dart';
import 'package:aslan_pixel/shared/widgets/field/custom_text_field.dart';
import 'package:aslan_pixel/shared/widgets/appbar/pixel_appbar.dart';
import 'package:aslan_pixel/shared/widgets/chart/animated_sparkline.dart';
import 'package:aslan_pixel/shared/widgets/chart/market_mini_chart.dart';
import 'package:aslan_pixel/shared/widgets/chart/portfolio_pnl_chart.dart';
import 'package:aslan_pixel/shared/widgets/reward_popup.dart';
import 'package:aslan_pixel/shared/widgets/streak_warning_banner.dart';
import 'package:aslan_pixel/shared/widgets/notification_bell.dart';

// ── Test helper ──────────────────────────────────────────────────────────────

/// Wraps [child] in a dark-themed MaterialApp with AppColors InheritedWidget,
/// matching the Aslan Pixel production setup.
Widget buildTestWidget(Widget child) {
  return AppColors(
    scheme: AppColorScheme.dark,
    child: MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(body: child),
    ),
  );
}

/// Same as [buildTestWidget] but wraps in an Overlay so overlay-dependent
/// widgets (ConfettiOverlay, FloatingRewardText) can be tested.
Widget buildTestWidgetWithOverlay(Widget child) {
  return AppColors(
    scheme: AppColorScheme.dark,
    child: MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: Overlay(
          initialEntries: [
            OverlayEntry(builder: (_) => child),
          ],
        ),
      ),
    ),
  );
}

void main() {
  // ════════════════════════════════════════════════════════════════════════════
  // 1. AnimatedCoinCounter
  // ════════════════════════════════════════════════════════════════════════════
  group('AnimatedCoinCounter', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const AnimatedCoinCounter(toAmount: 500)),
      );
      await tester.pump();
      expect(find.byType(AnimatedCoinCounter), findsOneWidget);
    });

    testWidgets('shows coin icon by default', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const AnimatedCoinCounter(toAmount: 100)),
      );
      await tester.pump();
      expect(find.byIcon(Icons.monetization_on_rounded), findsOneWidget);
    });

    testWidgets('hides icon when showIcon is false', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AnimatedCoinCounter(toAmount: 100, showIcon: false),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.monetization_on_rounded), findsNothing);
    });

    testWidgets('shows target amount after animation completes', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const AnimatedCoinCounter(toAmount: 1234)),
      );
      await tester.pumpAndSettle();
      expect(find.text('1234'), findsOneWidget);
    });

    testWidgets('animates from fromAmount to toAmount', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AnimatedCoinCounter(fromAmount: 0, toAmount: 100),
        ),
      );
      // At t=0 we should see '0'
      expect(find.text('0'), findsOneWidget);
      // After settling we should see '100'
      await tester.pumpAndSettle();
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('uses TweenAnimationBuilder', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const AnimatedCoinCounter(toAmount: 50)),
      );
      await tester.pump();
      expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 2. CoinBadgeWidget
  // ════════════════════════════════════════════════════════════════════════════
  group('CoinBadgeWidget', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const CoinBadgeWidget(amount: 250)),
      );
      await tester.pump();
      expect(find.byType(CoinBadgeWidget), findsOneWidget);
    });

    testWidgets('shows coin icon', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const CoinBadgeWidget(amount: 99)),
      );
      await tester.pump();
      expect(find.byIcon(Icons.monetization_on), findsOneWidget);
    });

    testWidgets('shows formatted coin amount', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const CoinBadgeWidget(amount: 5000)),
      );
      await tester.pump();
      expect(find.text('5000'), findsOneWidget);
    });

    testWidgets('shows zero amount', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const CoinBadgeWidget(amount: 0)),
      );
      await tester.pump();
      expect(find.text('0'), findsOneWidget);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 3. EmptyStateWidget
  // ════════════════════════════════════════════════════════════════════════════
  group('EmptyStateWidget', () {
    testWidgets('renders emoji and title', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const EmptyStateWidget(
            emoji: '📭',
            titleTh: 'ไม่มีข้อมูล',
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(EmptyStateWidget), findsOneWidget);
      expect(find.text('📭'), findsOneWidget);
      expect(find.text('ไม่มีข้อมูล'), findsOneWidget);
    });

    testWidgets('shows subtitle when provided', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const EmptyStateWidget(
            emoji: '🔍',
            titleTh: 'ไม่พบผลลัพธ์',
            subtitleTh: 'ลองค้นหาใหม่',
          ),
        ),
      );
      await tester.pump();
      expect(find.text('ลองค้นหาใหม่'), findsOneWidget);
    });

    testWidgets('hides subtitle when null', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const EmptyStateWidget(
            emoji: '🔍',
            titleTh: 'ไม่พบผลลัพธ์',
          ),
        ),
      );
      await tester.pump();
      expect(find.text('ลองค้นหาใหม่'), findsNothing);
    });

    testWidgets('shows action button when both onAction and actionLabelTh provided',
        (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildTestWidget(
          EmptyStateWidget(
            emoji: '➕',
            titleTh: 'เริ่มต้น',
            actionLabelTh: 'เพิ่มใหม่',
            onAction: () => tapped = true,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.text('เพิ่มใหม่'), findsOneWidget);

      await tester.tap(find.byType(OutlinedButton));
      expect(tapped, isTrue);
    });

    testWidgets('hides action button when onAction is null', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const EmptyStateWidget(
            emoji: '📭',
            titleTh: 'ว่างเปล่า',
            actionLabelTh: 'ลอง',
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('hides action button when actionLabelTh is null', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          EmptyStateWidget(
            emoji: '📭',
            titleTh: 'ว่างเปล่า',
            onAction: () {},
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(OutlinedButton), findsNothing);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 4. PixelErrorWidget
  // ════════════════════════════════════════════════════════════════════════════
  group('PixelErrorWidget', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const PixelErrorWidget(message: 'Something went wrong')),
      );
      await tester.pump();
      expect(find.byType(PixelErrorWidget), findsOneWidget);
    });

    testWidgets('shows error icon', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const PixelErrorWidget(message: 'Error!')),
      );
      await tester.pump();
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows error message', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const PixelErrorWidget(message: 'Network error occurred'),
        ),
      );
      await tester.pump();
      expect(find.text('Network error occurred'), findsOneWidget);
    });

    testWidgets('shows retry button when onRetry provided', (tester) async {
      bool retried = false;
      await tester.pumpWidget(
        buildTestWidget(
          PixelErrorWidget(
            message: 'Failed',
            onRetry: () => retried = true,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.text('ลองใหม่'), findsOneWidget);

      await tester.tap(find.byType(OutlinedButton));
      expect(retried, isTrue);
    });

    testWidgets('hides retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const PixelErrorWidget(message: 'Failed')),
      );
      await tester.pump();
      expect(find.byType(OutlinedButton), findsNothing);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 5. LoaderWidget / LoaderOverlay / LoaderInline
  // ════════════════════════════════════════════════════════════════════════════
  group('LoaderWidget', () {
    testWidgets('renders spinner', (tester) async {
      await tester.pumpWidget(buildTestWidget(const LoaderWidget()));
      await tester.pump();
      expect(find.byType(LoaderWidget), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows message when provided', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const LoaderWidget(message: 'กำลังโหลด...')),
      );
      await tester.pump();
      expect(find.text('กำลังโหลด...'), findsOneWidget);
    });

    testWidgets('hides message when null', (tester) async {
      await tester.pumpWidget(buildTestWidget(const LoaderWidget()));
      await tester.pump();
      expect(find.byType(Text), findsNothing);
    });
  });

  group('LoaderOverlay', () {
    testWidgets('renders with transparency and spinner', (tester) async {
      await tester.pumpWidget(buildTestWidget(const LoaderOverlay()));
      await tester.pump();
      expect(find.byType(LoaderOverlay), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('LoaderInline', () {
    testWidgets('renders small spinner', (tester) async {
      await tester.pumpWidget(buildTestWidget(const LoaderInline()));
      await tester.pump();
      expect(find.byType(LoaderInline), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('respects custom size', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const LoaderInline(size: 30)),
      );
      await tester.pump();
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, 30);
      expect(sizedBox.height, 30);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 6. SparklineChart
  // ════════════════════════════════════════════════════════════════════════════
  group('SparklineChart', () {
    testWidgets('renders with data', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const SparklineChart(values: [1.0, 3.0, 2.0, 5.0, 4.0]),
        ),
      );
      await tester.pump();
      expect(find.byType(SparklineChart), findsOneWidget);
      // CustomPaint is a descendant of SparklineChart
      expect(
        find.descendant(
          of: find.byType(SparklineChart),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });

    testWidgets('handles empty data gracefully', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const SparklineChart(values: [])),
      );
      await tester.pump();
      expect(find.byType(SparklineChart), findsOneWidget);
      // Empty data returns a SizedBox, no CustomPaint descendant
      expect(
        find.descendant(
          of: find.byType(SparklineChart),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
    });

    testWidgets('handles single value', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const SparklineChart(values: [42.0])),
      );
      await tester.pump();
      expect(find.byType(SparklineChart), findsOneWidget);
    });

    testWidgets('respects custom dimensions', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const SparklineChart(
            values: [1.0, 2.0, 3.0],
            width: 200,
            height: 80,
          ),
        ),
      );
      await tester.pump();
      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(SparklineChart),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(customPaint.size, const Size(200, 80));
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 7. ConfettiOverlay
  // ════════════════════════════════════════════════════════════════════════════
  group('ConfettiOverlay', () {
    testWidgets('renders via burst and completes animation', (tester) async {
      await tester.pumpWidget(
        buildTestWidgetWithOverlay(
          Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ConfettiOverlay.burst(context);
              });
              return const SizedBox.expand();
            },
          ),
        ),
      );

      // Trigger the post-frame callback
      await tester.pump();
      expect(find.byType(ConfettiOverlay), findsOneWidget);

      // Pump past the 1500ms animation duration + extra frame
      await tester.pump(const Duration(milliseconds: 1501));
      await tester.pump();

      // After onDone, overlay entry is removed
      expect(find.byType(ConfettiOverlay), findsNothing);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 8. FloatingRewardText
  // ════════════════════════════════════════════════════════════════════════════
  group('FloatingRewardText', () {
    testWidgets('shows amount text and completes animation', (tester) async {
      await tester.pumpWidget(
        buildTestWidgetWithOverlay(
          Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                FloatingRewardText.show(context, 500);
              });
              return const SizedBox.expand();
            },
          ),
        ),
      );

      // Trigger the post-frame callback
      await tester.pump();
      expect(find.byType(FloatingRewardText), findsOneWidget);
      expect(find.textContaining('+500'), findsOneWidget);

      // Pump past the 1200ms animation + extra frame
      await tester.pump(const Duration(milliseconds: 1201));
      await tester.pump();

      // After animation completes, the overlay entry is removed
      expect(find.byType(FloatingRewardText), findsNothing);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 9. XpProgressBar
  // ════════════════════════════════════════════════════════════════════════════
  group('XpProgressBar', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const XpProgressBar(level: 5, currentXp: 400, maxXp: 1000),
        ),
      );
      await tester.pump();
      expect(find.byType(XpProgressBar), findsOneWidget);
      // Dispose cleanly by pumping past animations
      await tester.pumpAndSettle();
    });

    testWidgets('shows level number', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const XpProgressBar(level: 7, currentXp: 200, maxXp: 500),
        ),
      );
      await tester.pump();
      expect(find.textContaining('7'), findsWidgets);
      await tester.pumpAndSettle();
    });

    testWidgets('shows next level indicator', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const XpProgressBar(level: 3, currentXp: 300, maxXp: 1000),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Lv 4'), findsWidgets);
      await tester.pumpAndSettle();
    });

    testWidgets('shows XP remaining text', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const XpProgressBar(level: 1, currentXp: 200, maxXp: 1000),
        ),
      );
      await tester.pump();
      expect(find.text('800 XP'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('handles zero maxXp gracefully', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const XpProgressBar(level: 1, currentXp: 0, maxXp: 0),
        ),
      );
      await tester.pump();
      expect(find.byType(XpProgressBar), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 10. ReadyToCollectBadge
  // ════════════════════════════════════════════════════════════════════════════
  group('ReadyToCollectBadge', () {
    // ReadyToCollectBadge has a repeating AnimationController, so we cannot
    // use pumpAndSettle. Instead, pump one frame and verify, then dispose
    // the widget tree by pumping a replacement widget.

    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          ReadyToCollectBadge(count: 1, onTap: () {}),
        ),
      );
      await tester.pump();
      expect(find.byType(ReadyToCollectBadge), findsOneWidget);
      // Replace to dispose the repeating animation
      await tester.pumpWidget(buildTestWidget(const SizedBox()));
    });

    testWidgets('shows single reward label for count=1', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          ReadyToCollectBadge(count: 1, onTap: () {}),
        ),
      );
      await tester.pump();
      expect(find.textContaining('พร้อมเก็บ'), findsOneWidget);
      await tester.pumpWidget(buildTestWidget(const SizedBox()));
    });

    testWidgets('shows count for multiple rewards', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          ReadyToCollectBadge(count: 5, onTap: () {}),
        ),
      );
      await tester.pump();
      expect(find.textContaining('5'), findsOneWidget);
      expect(find.textContaining('รางวัล'), findsOneWidget);
      await tester.pumpWidget(buildTestWidget(const SizedBox()));
    });

    testWidgets('fires onTap callback', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildTestWidget(
          ReadyToCollectBadge(count: 2, onTap: () => tapped = true),
        ),
      );
      await tester.pump();
      await tester.tap(find.byType(GestureDetector).first);
      expect(tapped, isTrue);
      await tester.pumpWidget(buildTestWidget(const SizedBox()));
    });

    testWidgets('has pulsing scale transform', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          ReadyToCollectBadge(count: 3, onTap: () {}),
        ),
      );
      await tester.pump();
      // Verify that a Transform exists as a descendant of ReadyToCollectBadge
      expect(
        find.descendant(
          of: find.byType(ReadyToCollectBadge),
          matching: find.byType(Transform),
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(buildTestWidget(const SizedBox()));
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 11. CustomTextField
  // ════════════════════════════════════════════════════════════════════════════
  group('CustomTextField', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          CustomTextField(controller: TextEditingController()),
        ),
      );
      await tester.pump();
      expect(find.byType(CustomTextField), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('shows hint text', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          CustomTextField(
            controller: TextEditingController(),
            hint: 'Enter name',
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Enter name'), findsOneWidget);
    });

    testWidgets('accepts text input', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        buildTestWidget(
          CustomTextField(controller: controller),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextFormField), 'Hello world');
      expect(controller.text, 'Hello world');
    });

    testWidgets('calls onChanged callback', (tester) async {
      String? changedValue;
      await tester.pumpWidget(
        buildTestWidget(
          CustomTextField(
            controller: TextEditingController(),
            onChanged: (val) => changedValue = val,
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextFormField), 'test');
      expect(changedValue, 'test');
    });

    testWidgets('supports obscureText without crashing', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          CustomTextField(
            controller: TextEditingController(),
            obscureText: true,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('can be disabled', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          CustomTextField(
            controller: TextEditingController(),
            isEnable: false,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CustomTextField), findsOneWidget);
      final textField = tester.widget<TextFormField>(find.byType(TextFormField));
      expect(textField.enabled, isFalse);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 12. PixelAppBar
  // ════════════════════════════════════════════════════════════════════════════
  group('PixelAppBar', () {
    testWidgets('renders title text', (tester) async {
      await tester.pumpWidget(
        AppColors(
          scheme: AppColorScheme.dark,
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              appBar: PixelAppBar(title: 'Test Page'),
              body: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(PixelAppBar), findsOneWidget);
      expect(find.textContaining('Test Page'), findsOneWidget);
    });

    testWidgets('shows back button by default', (tester) async {
      await tester.pumpWidget(
        AppColors(
          scheme: AppColorScheme.dark,
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              appBar: PixelAppBar(title: 'Back Test'),
              body: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    });

    testWidgets('hides back button when showBackButton is false', (tester) async {
      await tester.pumpWidget(
        AppColors(
          scheme: AppColorScheme.dark,
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              appBar: PixelAppBar(title: 'No Back', showBackButton: false),
              body: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);
    });

    testWidgets('renders action widgets', (tester) async {
      await tester.pumpWidget(
        AppColors(
          scheme: AppColorScheme.dark,
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              appBar: PixelAppBar(
                title: 'Actions',
                showBackButton: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {},
                  ),
                ],
              ),
              body: const SizedBox(),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('preferredSize is correct', (tester) async {
      // ignore: prefer_const_constructors
      final appBar = PixelAppBar(title: 'Size Test');
      expect(appBar.preferredSize.height, kToolbarHeight + 24);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 13. AnimatedSparkline
  // ════════════════════════════════════════════════════════════════════════════
  group('AnimatedSparkline', () {
    testWidgets('renders CustomPaint with data', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AnimatedSparkline(values: [1.0, 2.0, 3.0, 4.0, 5.0]),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AnimatedSparkline), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AnimatedSparkline),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });

    testWidgets('handles empty data', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const AnimatedSparkline(values: [])),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AnimatedSparkline), findsOneWidget);
    });

    testWidgets('handles constant values (range = 0)', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AnimatedSparkline(values: [5.0, 5.0, 5.0]),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AnimatedSparkline), findsOneWidget);
    });

    testWidgets('animates on mount', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AnimatedSparkline(values: [1.0, 3.0, 2.0]),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.byType(AnimatedSparkline), findsOneWidget);
    });

    testWidgets('respects custom height', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const AnimatedSparkline(values: [1.0, 2.0], height: 100),
        ),
      );
      await tester.pumpAndSettle();
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.height, 100);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 14. MarketMiniChart
  // ════════════════════════════════════════════════════════════════════════════
  group('MarketMiniChart', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const MarketMiniChart(
            symbol: 'PTT',
            changePercent: 1.34,
            history: [100, 101, 99, 103, 105],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MarketMiniChart), findsOneWidget);
    });

    testWidgets('shows symbol text', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const MarketMiniChart(
            symbol: 'DELTA',
            changePercent: 2.5,
            history: [10, 12, 11, 13],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('DELTA'), findsOneWidget);
    });

    testWidgets('shows positive change percentage with + sign', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const MarketMiniChart(
            symbol: 'AOT',
            changePercent: 3.14,
            history: [50, 55, 53],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('+3.14%'), findsOneWidget);
    });

    testWidgets('shows negative change percentage', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const MarketMiniChart(
            symbol: 'BANPU',
            changePercent: -2.50,
            history: [80, 75, 78],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('-2.50%'), findsOneWidget);
    });

    testWidgets('shows zero change as positive', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const MarketMiniChart(
            symbol: 'CPALL',
            changePercent: 0.0,
            history: [50, 50],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('+0.00%'), findsOneWidget);
    });

    testWidgets('contains AnimatedSparkline', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const MarketMiniChart(
            symbol: 'SCB',
            changePercent: 0.5,
            history: [100, 101, 102],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AnimatedSparkline), findsOneWidget);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 15. PortfolioPnlChart
  // ════════════════════════════════════════════════════════════════════════════
  group('PortfolioPnlChart', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const PortfolioPnlChart(
            pnlHistory: [100, 105, 103, 110],
            totalPnl: 250.50,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PortfolioPnlChart), findsOneWidget);
    });

    testWidgets('shows positive PnL with + sign', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const PortfolioPnlChart(
            pnlHistory: [100, 110],
            totalPnl: 150.75,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('+150.75'), findsOneWidget);
    });

    testWidgets('shows negative PnL', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const PortfolioPnlChart(
            pnlHistory: [100, 90],
            totalPnl: -42.30,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('-42.30'), findsOneWidget);
    });

    testWidgets('shows up arrow for profit', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const PortfolioPnlChart(
            pnlHistory: [100, 110],
            totalPnl: 10.0,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_drop_up_rounded), findsOneWidget);
    });

    testWidgets('shows down arrow for loss', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const PortfolioPnlChart(
            pnlHistory: [100, 90],
            totalPnl: -10.0,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_drop_down_rounded), findsOneWidget);
    });

    testWidgets('renders period selector chips', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const PortfolioPnlChart(
            pnlHistory: [100, 105, 103],
            totalPnl: 5.0,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('7 วัน'), findsOneWidget);
      expect(find.text('30 วัน'), findsOneWidget);
      expect(find.text('ทั้งหมด'), findsOneWidget);
    });

    testWidgets('tapping period chip changes selection', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          PortfolioPnlChart(
            pnlHistory: List<double>.filled(35, 100.0),
            totalPnl: 0.0,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "30 วัน" chip
      await tester.tap(find.text('30 วัน'));
      await tester.pumpAndSettle();
      expect(find.byType(PortfolioPnlChart), findsOneWidget);
    });

    testWidgets('handles empty pnlHistory (uses mock data)', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const PortfolioPnlChart(
            pnlHistory: [],
            totalPnl: 0.0,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PortfolioPnlChart), findsOneWidget);
      expect(find.byType(AnimatedSparkline), findsOneWidget);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 16. RewardPopup
  // ════════════════════════════════════════════════════════════════════════════
  group('RewardPopup', () {
    // RewardPopup has a repeating AnimationController (_rainController)
    // and a 300ms delayed Future. We must pump past the delay and then
    // dispose the widget tree by replacing it, to avoid pending timer errors.

    Future<void> pumpRewardAndDispose(
      WidgetTester tester,
      Widget popup,
    ) async {
      await tester.pumpWidget(
        AppColors(
          scheme: AppColorScheme.dark,
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(body: popup),
          ),
        ),
      );
      // Pump past the 300ms delayed XP bar future
      await tester.pump(const Duration(milliseconds: 350));
    }

    Future<void> disposeReward(WidgetTester tester) async {
      await tester.pumpWidget(
        AppColors(
          scheme: AppColorScheme.dark,
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const Scaffold(body: SizedBox()),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('renders without crashing', (tester) async {
      await pumpRewardAndDispose(
        tester,
        const RewardPopup(coins: 250, xp: 120),
      );
      expect(find.byType(RewardPopup), findsOneWidget);
      await disposeReward(tester);
    });

    testWidgets('shows trophy icon', (tester) async {
      await pumpRewardAndDispose(
        tester,
        const RewardPopup(coins: 100, xp: 50),
      );
      expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
      await disposeReward(tester);
    });

    testWidgets('shows task complete title', (tester) async {
      await pumpRewardAndDispose(
        tester,
        const RewardPopup(coins: 100, xp: 50),
      );
      expect(find.text('ภารกิจสำเร็จ!'), findsOneWidget);
      await disposeReward(tester);
    });

    testWidgets('shows claim button', (tester) async {
      await pumpRewardAndDispose(
        tester,
        const RewardPopup(coins: 100, xp: 50),
      );
      expect(find.text('รับรางวัล!'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      await disposeReward(tester);
    });

    testWidgets('shows streak banner when streakDays > 0', (tester) async {
      await pumpRewardAndDispose(
        tester,
        const RewardPopup(coins: 100, xp: 50, streakDays: 3),
      );
      expect(find.textContaining('3 วันติดต่อกัน'), findsOneWidget);
      await disposeReward(tester);
    });

    testWidgets('hides streak banner when streakDays is 0', (tester) async {
      await pumpRewardAndDispose(
        tester,
        const RewardPopup(coins: 100, xp: 50, streakDays: 0),
      );
      expect(find.textContaining('วันติดต่อกัน'), findsNothing);
      await disposeReward(tester);
    });

    testWidgets('contains AnimatedCoinCounter', (tester) async {
      await pumpRewardAndDispose(
        tester,
        const RewardPopup(coins: 500, xp: 100),
      );
      expect(find.byType(AnimatedCoinCounter), findsOneWidget);
      await disposeReward(tester);
    });

    testWidgets('shows XP label', (tester) async {
      await pumpRewardAndDispose(
        tester,
        const RewardPopup(coins: 100, xp: 200),
      );
      expect(find.text('+200 XP'), findsOneWidget);
      await disposeReward(tester);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 17. StreakWarningBanner (async — depends on SharedPreferences)
  // ════════════════════════════════════════════════════════════════════════════
  group('StreakWarningBanner', () {
    testWidgets('renders as SizedBox.shrink when no streak data (default)',
        (tester) async {
      // Without setting up SharedPreferences, the banner won't show
      // (last_login_date is null => first launch => no warning)
      await tester.pumpWidget(
        buildTestWidget(const StreakWarningBanner(streakDays: 5)),
      );
      await tester.pump();
      expect(find.byType(StreakWarningBanner), findsOneWidget);
    });

    testWidgets('renders widget type correctly', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(const StreakWarningBanner(streakDays: 3)),
      );
      await tester.pump();
      expect(find.byType(StreakWarningBanner), findsOneWidget);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 18. NotificationBell — depends on Firestore
  // ════════════════════════════════════════════════════════════════════════════
  // NotificationBell directly creates a FirestoreNotificationDatasource
  // and streams from Firestore, so it cannot be widget-tested without Firebase
  // Emulator. We verify construction only.
  group('NotificationBell', () {
    test('can be instantiated', () {
      // ignore: prefer_const_constructors
      final bell = NotificationBell(uid: 'test-uid');
      expect(bell.uid, 'test-uid');
    });
  });
}
