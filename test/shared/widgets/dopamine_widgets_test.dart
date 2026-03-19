import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aslan_pixel/core/utils/haptic_service.dart';
import 'package:aslan_pixel/features/profile/data/models/badge_model.dart';
import 'package:aslan_pixel/shared/widgets/achievement_unlock_popup.dart';
import 'package:aslan_pixel/shared/widgets/combo_indicator.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

BadgeModel _testBadge() => BadgeModel(
      badgeId: 'first_mission',
      name: 'First Mission',
      nameTh: 'ภารกิจแรก',
      description: 'Complete your first agent task',
      descriptionTh: 'ทำภารกิจตัวแทนครั้งแรก',
      iconEmoji: '🎯',
      category: 'game',
      isEarned: true,
      earnedAt: DateTime(2026, 3, 18),
    );

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  // ── AchievementUnlockPopup ────────────────────────────────────────────────

  group('AchievementUnlockPopup', () {
    testWidgets('renders badge emoji, name, and description', (tester) async {
      final badge = _testBadge();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              // Show popup via a button tap to ensure Overlay is available.
              return ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => AchievementUnlockPopup(badge: badge),
                  );
                },
                child: const Text('Show'),
              );
            },
          ),
        ),
      ));

      // Tap button to trigger dialog.
      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Badge emoji should be visible.
      expect(find.text('🎯'), findsOneWidget);

      // Badge name in Thai.
      expect(find.text('ภารกิจแรก'), findsOneWidget);

      // Badge description in Thai.
      expect(find.text('ทำภารกิจตัวแทนครั้งแรก'), findsOneWidget);
    });

    testWidgets('shows dismiss button with correct text', (tester) async {
      final badge = _testBadge();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => AchievementUnlockPopup(badge: badge),
                  );
                },
                child: const Text('Show'),
              );
            },
          ),
        ),
      ));

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Dismiss button text: เยี่ยม!
      expect(find.text('\u0e40\u0e22\u0e35\u0e48\u0e22\u0e21!'), findsOneWidget);
    });

    testWidgets('shows category chip', (tester) async {
      final badge = _testBadge();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => AchievementUnlockPopup(badge: badge),
                  );
                },
                child: const Text('Show'),
              );
            },
          ),
        ),
      ));

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Category chip for 'game'.
      expect(find.text('Game'), findsOneWidget);
    });
  });

  // ── ComboIndicator ────────────────────────────────────────────────────────

  group('ComboIndicator', () {
    testWidgets('renders multiplier text', (tester) async {
      await tester.pumpWidget(
        _wrap(const ComboIndicator(streakDays: 5, multiplier: 1.5)),
      );

      expect(find.text('x1.5'), findsOneWidget);
    });

    testWidgets('shows fire emoji when streakDays > 0', (tester) async {
      await tester.pumpWidget(
        _wrap(const ComboIndicator(streakDays: 3, multiplier: 1.3)),
      );

      expect(find.text('\u{1F525}'), findsOneWidget);
    });

    testWidgets('hidden when streakDays is 0', (tester) async {
      await tester.pumpWidget(
        _wrap(const ComboIndicator(streakDays: 0, multiplier: 1.0)),
      );

      // Should render SizedBox.shrink — no fire emoji, no multiplier text.
      expect(find.text('\u{1F525}'), findsNothing);
      expect(find.text('x1.0'), findsNothing);
    });

    testWidgets('renders x1.0 when streakDays > 0 but multiplier is 1.0',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const ComboIndicator(streakDays: 1, multiplier: 1.0)),
      );

      expect(find.text('x1.0'), findsOneWidget);
    });
  });

  // ── HapticService ─────────────────────────────────────────────────────────

  group('HapticService', () {
    // Set up a mock method channel so haptic calls don't crash in tests.
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        SystemChannels.platform,
        (methodCall) async => null,
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    test('lightTap completes without error', () async {
      await expectLater(HapticService.lightTap(), completes);
    });

    test('mediumTap completes without error', () async {
      await expectLater(HapticService.mediumTap(), completes);
    });

    test('heavyTap completes without error', () async {
      await expectLater(HapticService.heavyTap(), completes);
    });

    test('selectionTick completes without error', () async {
      await expectLater(HapticService.selectionTick(), completes);
    });

    test('successPattern completes without error', () async {
      await expectLater(HapticService.successPattern(), completes);
    });

    test('coinCollect completes without error', () async {
      await expectLater(HapticService.coinCollect(), completes);
    });
  });
}
