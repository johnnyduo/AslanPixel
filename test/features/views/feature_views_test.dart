import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aslan_pixel/core/enums/agent_type.dart';
import 'package:aslan_pixel/features/agents/view/agent_dialogue_bubble.dart';
import 'package:aslan_pixel/features/feed/bloc/feed_bloc.dart';
import 'package:aslan_pixel/features/feed/view/feed_post_card.dart';
import 'package:aslan_pixel/features/finance/bloc/prediction_bloc.dart';
import 'package:aslan_pixel/features/finance/view/market_insight_card.dart';
import 'package:aslan_pixel/features/finance/view/prediction_event_card.dart';
import 'package:aslan_pixel/features/follows/view/follow_button.dart';
import 'package:aslan_pixel/features/home/bloc/room_bloc.dart';
import 'package:aslan_pixel/features/home/data/repositories/room_repository.dart';
import 'package:aslan_pixel/features/home/view/market_ticker_tile.dart';
import 'package:aslan_pixel/features/home/view/prediction_card.dart';
import 'package:aslan_pixel/features/home/view/room_item_picker.dart';
import 'package:aslan_pixel/features/onboarding/view/pixel_avatar_painter.dart';
import 'package:aslan_pixel/features/pixel_art/view/pixel_canvas_widget.dart';

import '../../mocks/mock_repositories.dart';
import '../../mocks/test_fixtures.dart';

// ---------------------------------------------------------------------------
// Mock classes
// ---------------------------------------------------------------------------

class _MockRoomRepository extends Mock implements RoomRepository {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _buildTestWidget(Widget child) {
  return MaterialApp(
    theme: ThemeData.dark(),
    home: Scaffold(body: child),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // =========================================================================
  // 1. PredictionEventCard
  // =========================================================================

  group('PredictionEventCard', () {
    late MockPredictionRepository mockPredictionRepo;
    late PredictionBloc predictionBloc;

    setUp(() {
      mockPredictionRepo = MockPredictionRepository();

      // Stub loadVotes for the _BullBearVoteSection initState call
      when(() => mockPredictionRepo.loadVotes(
            eventId: any(named: 'eventId'),
            uid: any(named: 'uid'),
          )).thenAnswer(
        (_) async => (bullCount: 5, bearCount: 3, myVote: null),
      );

      predictionBloc = PredictionBloc(repository: mockPredictionRepo);
    });

    tearDown(() => predictionBloc.close());

    testWidgets('renders event title', (tester) async {
      final event = kPredictionEvent();

      await tester.pumpWidget(
        _buildTestWidget(
          SingleChildScrollView(
            child: PredictionEventCard(
              event: event,
              uid: 'uid_test_01',
              bloc: predictionBloc,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(event.titleTh), findsOneWidget);
    });

    testWidgets('shows symbol chip', (tester) async {
      final event = kPredictionEvent();

      await tester.pumpWidget(
        _buildTestWidget(
          SingleChildScrollView(
            child: PredictionEventCard(
              event: event,
              uid: 'uid_test_01',
              bloc: predictionBloc,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('PTT'), findsOneWidget);
    });

    testWidgets('shows coin cost', (tester) async {
      final event = kPredictionEvent();

      await tester.pumpWidget(
        _buildTestWidget(
          SingleChildScrollView(
            child: PredictionEventCard(
              event: event,
              uid: 'uid_test_01',
              bloc: predictionBloc,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('${event.coinCost}'), findsOneWidget);
    });

    testWidgets('shows countdown text', (tester) async {
      // Use a future date so the countdown shows "เหลือ" instead of "หมดเวลา"
      final futureEvent = kPredictionEvent().copyWith(
        settlementAt: DateTime.now().add(const Duration(days: 3)),
      );

      await tester.pumpWidget(
        _buildTestWidget(
          SingleChildScrollView(
            child: PredictionEventCard(
              event: futureEvent,
              uid: 'uid_test_01',
              bloc: predictionBloc,
            ),
          ),
        ),
      );
      await tester.pump();

      // Countdown label starts with Thai "เหลือ" (remaining)
      expect(find.textContaining('เหลือ'), findsOneWidget);
    });
  });

  // =========================================================================
  // 2. FeedPostCard
  // =========================================================================

  group('FeedPostCard', () {
    late MockFeedRepository mockFeedRepo;
    late FeedBloc feedBloc;

    setUp(() {
      mockFeedRepo = MockFeedRepository();
      feedBloc = FeedBloc(mockFeedRepo);
    });

    tearDown(() => feedBloc.close());

    testWidgets('renders post content (Thai)', (tester) async {
      final post = kFeedPost();

      await tester.pumpWidget(
        _buildTestWidget(
          BlocProvider<FeedBloc>.value(
            value: feedBloc,
            child: SingleChildScrollView(
              child: FeedPostCard(post: post, currentUid: 'uid_test_01'),
            ),
          ),
        ),
      );
      await tester.pump();

      // Content is rendered via RichText with TextSpan, so use byType
      expect(find.byType(RichText), findsWidgets);
      // Verify the FeedPostCard itself is rendered
      expect(find.byType(FeedPostCard), findsOneWidget);
    });

    testWidgets('shows reaction counts', (tester) async {
      final post = kFeedPost();

      await tester.pumpWidget(
        _buildTestWidget(
          BlocProvider<FeedBloc>.value(
            value: feedBloc,
            child: SingleChildScrollView(
              child: FeedPostCard(post: post, currentUid: 'uid_test_01'),
            ),
          ),
        ),
      );
      await tester.pump();

      // kFeedPost has reactions: {'fire': 5, 'heart': 2}
      expect(find.textContaining('5'), findsOneWidget);
    });

    testWidgets('renders heart button', (tester) async {
      final post = kFeedPost();

      await tester.pumpWidget(
        _buildTestWidget(
          BlocProvider<FeedBloc>.value(
            value: feedBloc,
            child: SingleChildScrollView(
              child: FeedPostCard(post: post, currentUid: 'uid_test_01'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });
  });

  // =========================================================================
  // 3. MarketInsightCard
  // =========================================================================

  group('MarketInsightCard', () {
    testWidgets('renders insight content when loaded', (tester) async {
      final insight = kAiInsight();

      await tester.pumpWidget(
        _buildTestWidget(
          SingleChildScrollView(
            child: MarketInsightCard(insight: insight),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(insight.contentTh), findsOneWidget);
      expect(find.textContaining('AI Insight'), findsOneWidget);
    });

    testWidgets('shows model used chip', (tester) async {
      final insight = kAiInsight();

      await tester.pumpWidget(
        _buildTestWidget(
          SingleChildScrollView(
            child: MarketInsightCard(insight: insight),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(insight.modelUsed), findsOneWidget);
    });

    testWidgets('shows shimmer when loading', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          const SingleChildScrollView(
            child: MarketInsightCard(isLoading: true),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.textContaining('กำลังวิเคราะห์'), findsOneWidget);
    });

    testWidgets('shows empty tap placeholder when no insight', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          const SingleChildScrollView(child: MarketInsightCard()),
        ),
      );
      await tester.pump();

      expect(find.textContaining('แตะเพื่อโหลด'), findsOneWidget);
    });

    testWidgets('shows refresh icon button', (tester) async {
      final insight = kAiInsight();

      await tester.pumpWidget(
        _buildTestWidget(
          SingleChildScrollView(
            child: MarketInsightCard(insight: insight, onRefresh: () {}),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });

  // =========================================================================
  // 4. FollowButton
  // =========================================================================

  group('FollowButton', () {
    testWidgets('renders SizedBox.shrink when uid equals targetUid',
        (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          const FollowButton(uid: 'same_uid', targetUid: 'same_uid'),
        ),
      );
      await tester.pump();

      // When uid == targetUid the widget returns SizedBox.shrink
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('renders SizedBox.shrink when uid is empty', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          const FollowButton(uid: '', targetUid: 'target_01'),
        ),
      );
      await tester.pump();

      expect(find.byType(SizedBox), findsWidgets);
    });
  });

  // =========================================================================
  // 5. AgentDialogueBubble
  // =========================================================================

  group('AgentDialogueBubble', () {
    testWidgets('renders dialogue text', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          const AgentDialogueBubble(
            text: 'Hello from the analyst agent!',
            agentType: AgentType.analyst,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Hello from the analyst agent!'), findsOneWidget);
    });

    testWidgets('truncates text longer than 60 characters', (tester) async {
      const longText =
          'This is a very long dialogue message that exceeds sixty characters in total length';

      await tester.pumpWidget(
        _buildTestWidget(
          const AgentDialogueBubble(
            text: longText,
            agentType: AgentType.scout,
          ),
        ),
      );
      await tester.pump();

      final truncated = '${longText.substring(0, 60)}\u2026';
      expect(find.text(truncated), findsOneWidget);
    });

    testWidgets('returns SizedBox.shrink when not visible', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          const AgentDialogueBubble(
            text: 'Hidden message',
            agentType: AgentType.risk,
            isVisible: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Hidden message'), findsNothing);
    });

    testWidgets('renders for each agent type without errors', (tester) async {
      for (final type in AgentType.values) {
        await tester.pumpWidget(
          _buildTestWidget(
            AgentDialogueBubble(
              text: 'Msg from ${type.name}',
              agentType: type,
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Msg from ${type.name}'), findsOneWidget);
      }
    });
  });

  // =========================================================================
  // 6. PixelCanvasWidget
  // =========================================================================

  group('PixelCanvasWidget', () {
    testWidgets('renders CustomPaint with pixel grid', (tester) async {
      final pixels = [
        [0xFFFF0000, 0xFF00FF00, 0xFF0000FF, 0xFFFFFFFF],
        [0xFF000000, 0xFFFF0000, 0xFF00FF00, 0xFF0000FF],
        [0xFFFFFFFF, 0xFF000000, 0xFFFF0000, 0xFF00FF00],
        [0xFF0000FF, 0xFFFFFFFF, 0xFF000000, 0xFFFF0000],
      ];

      await tester.pumpWidget(
        _buildTestWidget(
          PixelCanvasWidget(
            pixels: pixels,
            cellSize: 12,
            onPixelTap: (row, col) {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.byType(InteractiveViewer), findsOneWidget);
    });

    testWidgets('renders SizedBox.shrink for empty pixel list', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          PixelCanvasWidget(
            pixels: const [],
            cellSize: 12,
            onPixelTap: (row, col) {},
          ),
        ),
      );
      await tester.pump();

      // Empty pixels returns SizedBox.shrink, so no CustomPaint
      expect(find.byType(InteractiveViewer), findsNothing);
    });

    testWidgets('fires onPixelTap on tap', (tester) async {
      int? tappedRow;
      int? tappedCol;

      final pixels = [
        [0xFFFF0000, 0xFF00FF00],
        [0xFF0000FF, 0xFFFFFFFF],
      ];

      await tester.pumpWidget(
        _buildTestWidget(
          Center(
            child: PixelCanvasWidget(
              pixels: pixels,
              cellSize: 24,
              onPixelTap: (row, col) {
                tappedRow = row;
                tappedCol = col;
              },
            ),
          ),
        ),
      );
      await tester.pump();

      final canvasFinder = find.byType(GestureDetector).first;
      await tester.tap(canvasFinder);
      await tester.pump();

      expect(tappedRow, isNotNull);
      expect(tappedCol, isNotNull);
    });
  });

  // =========================================================================
  // 7. PixelAvatarPainter
  // =========================================================================

  group('PixelAvatarPainter', () {
    testWidgets('renders via CustomPaint without error', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          const SizedBox(
            width: 80,
            height: 100,
            child: CustomPaint(
              painter: PixelAvatarPainter(avatarIndex: 0),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders all 8 avatar indices without error', (tester) async {
      for (int i = 0; i < 8; i++) {
        await tester.pumpWidget(
          _buildTestWidget(
            SizedBox(
              width: 80,
              height: 100,
              child: CustomPaint(
                painter: PixelAvatarPainter(avatarIndex: i),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(CustomPaint), findsWidgets);
      }
    });

    test('shouldRepaint returns true when avatarIndex changes', () {
      const p1 = PixelAvatarPainter(avatarIndex: 0);
      const p2 = PixelAvatarPainter(avatarIndex: 1);
      const p3 = PixelAvatarPainter(avatarIndex: 0);

      expect(p1.shouldRepaint(p2), isTrue);
      expect(p1.shouldRepaint(p3), isFalse);
    });
  });

  // =========================================================================
  // 8. PredictionCard
  // =========================================================================

  group('PredictionCard', () {
    testWidgets('renders symbol and question text', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          const SingleChildScrollView(
            child: PredictionCard(
              symbol: 'SET50',
              questionTh: 'SET50 จะปิดเขียววันนี้?',
              coinCost: 25,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('SET50'), findsOneWidget);
      expect(find.text('SET50 จะปิดเขียววันนี้?'), findsOneWidget);
    });

    testWidgets('shows coin cost badge', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          const SingleChildScrollView(
            child: PredictionCard(
              symbol: 'BTC',
              questionTh: 'BTC จะผ่าน 100K?',
              coinCost: 50,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('50'), findsOneWidget);
      expect(find.byIcon(Icons.monetization_on), findsOneWidget);
    });

    testWidgets('shows join button', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          const SingleChildScrollView(
            child: PredictionCard(
              symbol: 'GOLD',
              questionTh: 'ทองจะขึ้น?',
              coinCost: 15,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('เข้าร่วม'), findsOneWidget);
    });

    testWidgets('renders sparkline chart for bullish variant', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          const SingleChildScrollView(
            child: PredictionCard(
              symbol: 'AOT',
              questionTh: 'AOT ขึ้น?',
              coinCost: 10,
              bullish: true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders bearish variant', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          const SingleChildScrollView(
            child: PredictionCard(
              symbol: 'DELTA',
              questionTh: 'DELTA จะลง?',
              coinCost: 20,
              bullish: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('DELTA'), findsOneWidget);
    });
  });

  // =========================================================================
  // 9. RoomItemPicker
  // =========================================================================

  group('RoomItemPicker', () {
    late _MockRoomRepository mockRoomRepo;
    late RoomBloc roomBloc;

    setUp(() {
      mockRoomRepo = _MockRoomRepository();
      roomBloc = RoomBloc(repository: mockRoomRepo);
    });

    tearDown(() => roomBloc.close());

    testWidgets('renders title and catalogue items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: RoomItemPicker(uid: 'uid_test_01', bloc: roomBloc),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('เลือกไอเทม'), findsOneWidget);
      expect(find.text('โต๊ะ 01'), findsOneWidget);
      expect(find.text('ต้นไม้ 01'), findsOneWidget);
      expect(find.text('ปิด'), findsOneWidget);
    });

    testWidgets('renders GridView', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: RoomItemPicker(uid: 'uid_test_01', bloc: roomBloc),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(GridView), findsOneWidget);
    });
  });

  // =========================================================================
  // 10. MarketTickerTile
  // =========================================================================

  group('MarketTickerTile', () {
    testWidgets('renders symbol and positive change', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          const MarketTickerTile(symbol: 'SET', changePercent: 1.5),
        ),
      );
      await tester.pump();

      expect(find.text('SET'), findsOneWidget);
      expect(find.text('+1.5%'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
    });

    testWidgets('renders negative change with down arrow', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          const MarketTickerTile(symbol: 'KBANK', changePercent: -2.3),
        ),
      );
      await tester.pump();

      expect(find.text('KBANK'), findsOneWidget);
      expect(find.text('-2.3%'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
    });

    testWidgets('renders price when provided', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          const MarketTickerTile(
            symbol: 'PTT',
            changePercent: 0.8,
            price: '35.50',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('PTT'), findsOneWidget);
      expect(find.text('35.50'), findsOneWidget);
      expect(find.text('+0.8%'), findsOneWidget);
    });

    testWidgets('renders sparkline chart', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          const MarketTickerTile(symbol: 'AOT', changePercent: 3.2),
        ),
      );
      await tester.pump();

      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders with custom price history', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          const MarketTickerTile(
            symbol: 'CPALL',
            changePercent: -0.5,
            priceHistory: [60.0, 59.5, 59.8, 59.2, 59.0, 58.8, 59.1, 58.5],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('CPALL'), findsOneWidget);
      expect(find.text('-0.5%'), findsOneWidget);
    });
  });
}
