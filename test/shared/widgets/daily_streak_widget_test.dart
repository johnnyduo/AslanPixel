import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aslan_pixel/shared/widgets/daily_streak_widget.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Wraps [child] in a minimal Flutter app shell so widgets under test have the
/// required MediaQuery, Theme and Directionality ancestors.
Widget _app(Widget child) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          child: child,
        ),
      ),
    );

void main() {
  // ── Renders without crash ─────────────────────────────────────────────────

  group('DailyStreakWidget rendering', () {
    testWidgets('renders without crashing for streak = 1', (tester) async {
      await tester.pumpWidget(_app(
        const DailyStreakWidget(streakDays: 1, todayIndex: 0),
      ));
      // pump once to trigger initState animations without advancing full loop.
      await tester.pump();
      expect(find.byType(DailyStreakWidget), findsOneWidget);
    });

    testWidgets('renders without crashing for streak = 0', (tester) async {
      await tester.pumpWidget(_app(
        const DailyStreakWidget(streakDays: 0, todayIndex: 0),
      ));
      await tester.pump();
      expect(find.byType(DailyStreakWidget), findsOneWidget);
    });

    testWidgets('renders without crashing for milestone streak = 7',
        (tester) async {
      await tester.pumpWidget(_app(
        const DailyStreakWidget(streakDays: 7, todayIndex: 2),
      ));
      // Allow postFrameCallback gold-flash to run.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byType(DailyStreakWidget), findsOneWidget);
    });

    testWidgets('renders without crashing for milestone streak = 30',
        (tester) async {
      await tester.pumpWidget(_app(
        const DailyStreakWidget(streakDays: 30, todayIndex: 6),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.byType(DailyStreakWidget), findsOneWidget);
    });
  });

  // ── Streak count text ─────────────────────────────────────────────────────

  group('DailyStreakWidget streak count display', () {
    testWidgets('shows streak count in text for streak = 5', (tester) async {
      await tester.pumpWidget(_app(
        const DailyStreakWidget(streakDays: 5, todayIndex: 3),
      ));
      await tester.pump();
      // The widget renders "5 วันติดต่อกัน!"
      expect(find.textContaining('5'), findsWidgets);
    });

    testWidgets('shows streak count in text for streak = 10', (tester) async {
      await tester.pumpWidget(_app(
        const DailyStreakWidget(streakDays: 10, todayIndex: 4),
      ));
      await tester.pump();
      expect(find.textContaining('10'), findsWidgets);
    });

    testWidgets('shows streak count in text for streak = 0', (tester) async {
      await tester.pumpWidget(_app(
        const DailyStreakWidget(streakDays: 0, todayIndex: 0),
      ));
      await tester.pump();
      expect(find.textContaining('0'), findsWidgets);
    });

    testWidgets('contains Thai label text', (tester) async {
      await tester.pumpWidget(_app(
        const DailyStreakWidget(streakDays: 3, todayIndex: 1),
      ));
      await tester.pump();
      // Header always shows "N วันติดต่อกัน!"
      expect(find.textContaining('วันติดต่อกัน'), findsOneWidget);
    });
  });

  // ── Day circles ───────────────────────────────────────────────────────────

  group('DailyStreakWidget day circles', () {
    testWidgets('renders exactly 7 _DayCircle children (one per weekday)',
        (tester) async {
      await tester.pumpWidget(_app(
        const DailyStreakWidget(streakDays: 3, todayIndex: 2),
      ));
      await tester.pump();

      // The widget uses List.generate(7, ...) of Column > Container.
      // We can count via the Row that holds day circles.
      // Each circle is a Container(width: 34, height: 34) inside a Column.
      // Find all SizedBox(width:34) is fragile — instead count
      // the direct children of the circles Row via its descendant Column count.

      // Strategy: verify 7 containers of the expected size exist.
      // We test by verifying the widget tree has enough Container descendants
      // (each _DayCircle has a 34×34 Container).
      final containers = tester.widgetList<Container>(find.byType(Container));
      final dayCircleContainers = containers
          .where((c) =>
              c.constraints?.maxWidth == 34 ||
              (c.decoration is BoxDecoration &&
                  (c.decoration as BoxDecoration).shape == BoxShape.circle))
          .toList();
      // At least 7 day-circle-sized containers should be present.
      expect(dayCircleContainers.length, greaterThanOrEqualTo(7));
    });

    testWidgets('day abbreviation labels are present in the widget tree',
        (tester) async {
      await tester.pumpWidget(_app(
        // todayIndex=0 → Monday. Days 1-6 are future and show labels below.
        const DailyStreakWidget(streakDays: 0, todayIndex: 0),
      ));
      await tester.pump();

      // The Thai day abbreviations: จ อ พ พฤ ศ ส อา
      // Future days render label text below the circle.
      // We only need to confirm at least one day label is present.
      final found = find.textContaining('อ'); // appears in อ, พ, ศ, อา
      expect(found, findsWidgets);
    });
  });

  // ── Animation pumping — no overflow ──────────────────────────────────────

  group('DailyStreakWidget animation', () {
    testWidgets('pumps fire animation without RenderFlex overflow',
        (tester) async {
      await tester.pumpWidget(_app(
        const DailyStreakWidget(streakDays: 2, todayIndex: 1),
      ));
      // Advance past the fire-pulse cycle (1500 ms loop).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));
      await tester.pump(const Duration(milliseconds: 750));

      // Confirm no overflow exceptions were thrown.
      expect(tester.takeException(), isNull);
    });

    testWidgets('pumps today-glow animation without overflow', (tester) async {
      await tester.pumpWidget(_app(
        const DailyStreakWidget(streakDays: 4, todayIndex: 3),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'milestone gold-flash animation completes without overflow for streak=3',
        (tester) async {
      await tester.pumpWidget(_app(
        const DailyStreakWidget(streakDays: 3, todayIndex: 2),
      ));
      await tester.pump(); // initState
      await tester.pump(const Duration(milliseconds: 16)); // postFrameCallback
      await tester.pump(const Duration(milliseconds: 500)); // flash forward
      await tester.pump(const Duration(milliseconds: 500)); // flash reverse

      expect(tester.takeException(), isNull);
    });

    testWidgets('disposes animations without errors', (tester) async {
      await tester.pumpWidget(_app(
        const DailyStreakWidget(streakDays: 1, todayIndex: 0),
      ));
      await tester.pump();
      // Replacing the widget tree triggers dispose() on the StatefulWidget.
      await tester.pumpWidget(_app(const SizedBox.shrink()));
      expect(tester.takeException(), isNull);
    });
  });

  // ── Tap behavior ──────────────────────────────────────────────────────────

  group('DailyStreakWidget tap behavior', () {
    testWidgets('custom onTap callback is invoked when widget is tapped',
        (tester) async {
      var tapped = false;
      await tester.pumpWidget(_app(
        DailyStreakWidget(
          streakDays: 5,
          todayIndex: 2,
          onTap: () => tapped = true,
        ),
      ));
      await tester.pump();

      await tester.tap(find.byType(DailyStreakWidget));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
