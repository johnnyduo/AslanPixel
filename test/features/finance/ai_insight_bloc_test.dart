import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aslan_pixel/features/finance/bloc/ai_insight_bloc.dart';
import 'package:aslan_pixel/features/finance/bloc/ai_insight_event.dart';
import 'package:aslan_pixel/features/finance/bloc/ai_insight_state.dart';
import 'package:aslan_pixel/features/finance/data/models/ai_insight_model.dart';
import '../../mocks/mock_repositories.dart';
import '../../mocks/test_fixtures.dart';

// ── AiInsightBloc requires both AIService + AiInsightRepository ──────────────
// We build with both mocks to match the constructor.

void main() {
  late MockAiInsightRepository repo;
  late MockAiService aiService;

  setUp(() {
    repo = MockAiInsightRepository();
    aiService = MockAiService();
  });

  AiInsightBloc build() =>
      AiInsightBloc(aiService: aiService, repository: repo);

  group('AiInsightBloc — initial state', () {
    test('initial state is AiInsightInitial', () {
      expect(build().state, isA<AiInsightInitial>());
    });
  });

  // ── AiInsightWatchStarted ──────────────────────────────────────────────────

  // AiInsightWatchStarted uses emit.forEach — no Loading emitted before stream data.
  group('AiInsightWatchStarted', () {
    blocTest<AiInsightBloc, AiInsightState>(
      'emits [Loaded] with insights from stream',
      build: build,
      setUp: () {
        when(() => repo.watchInsights('uid_01'))
            .thenAnswer((_) => Stream.value([kAiInsight()]));
      },
      act: (bloc) => bloc.add(const AiInsightWatchStarted('uid_01')),
      expect: () => [
        isA<AiInsightLoaded>()
            .having((s) => s.insights.length, 'count', 1),
      ],
      verify: (_) =>
          verify(() => repo.watchInsights('uid_01')).called(1),
    );

    blocTest<AiInsightBloc, AiInsightState>(
      'emits [Loaded] with empty list when no insights',
      build: build,
      setUp: () {
        when(() => repo.watchInsights(any()))
            .thenAnswer((_) => Stream.value(<AiInsightModel>[]));
      },
      act: (bloc) => bloc.add(const AiInsightWatchStarted('uid_01')),
      expect: () => [
        isA<AiInsightLoaded>()
            .having((s) => s.insights, 'insights', isEmpty),
      ],
    );

    blocTest<AiInsightBloc, AiInsightState>(
      'emits [Error] when stream throws',
      build: build,
      setUp: () {
        when(() => repo.watchInsights(any()))
            .thenAnswer((_) => Stream.error(Exception('Firestore error')));
      },
      act: (bloc) => bloc.add(const AiInsightWatchStarted('uid_01')),
      expect: () => [isA<AiInsightError>()],
    );

    blocTest<AiInsightBloc, AiInsightState>(
      'emits multiple Loaded states on stream updates',
      build: build,
      setUp: () {
        when(() => repo.watchInsights(any())).thenAnswer(
          (_) => Stream.fromIterable([
            [kAiInsight()],
            [kAiInsight(), kAiInsight(expired: true)],
          ]),
        );
      },
      act: (bloc) => bloc.add(const AiInsightWatchStarted('uid_01')),
      expect: () => [
        isA<AiInsightLoaded>().having((s) => s.insights.length, 'count', 1),
        isA<AiInsightLoaded>().having((s) => s.insights.length, 'count', 2),
      ],
    );
  });

  // ── AiInsightRequested — cache hit ─────────────────────────────────────────

  group('AiInsightRequested — cache hit', () {
    blocTest<AiInsightBloc, AiInsightState>(
      'emits [Loading, Loaded] from cache without calling AI service',
      build: build,
      setUp: () {
        when(() => repo.getLatestInsight('uid_01', 'market_summary'))
            .thenAnswer((_) async => kAiInsight());
      },
      act: (bloc) => bloc.add(const AiInsightRequested(
        uid: 'uid_01',
        type: 'market_summary',
        context: 'PTT,BBL',
      )),
      expect: () => [
        isA<AiInsightLoading>(),
        isA<AiInsightLoaded>(),
      ],
      verify: (_) {
        verify(() => repo.getLatestInsight('uid_01', 'market_summary'))
            .called(1);
        verifyNever(() => aiService.generateMarketSummary(
              symbols: any(named: 'symbols'),
              context: any(named: 'context'),
            ));
      },
    );

    blocTest<AiInsightBloc, AiInsightState>(
      'loaded insight from cache has correct content',
      build: build,
      setUp: () {
        when(() => repo.getLatestInsight(any(), any()))
            .thenAnswer((_) async => kAiInsight());
      },
      act: (bloc) => bloc.add(const AiInsightRequested(
        uid: 'uid_01',
        type: 'market_summary',
        context: '',
      )),
      expect: () => [
        isA<AiInsightLoading>(),
        isA<AiInsightLoaded>().having(
          (s) => s.insights.first.content,
          'content',
          isNotEmpty,
        ),
      ],
    );
  });

  // ── AiInsightRequested — cache miss (AI service errors) ───────────────────
  // Note: cache-miss success path requires Firebase.initializeApp() because
  // the bloc uses FirebaseFirestore.instance.collection('_').doc().id to
  // generate the insight ID. These tests cover the error path instead, which
  // short-circuits before the Firebase call.

  group('AiInsightRequested — cache miss error path', () {
    blocTest<AiInsightBloc, AiInsightState>(
      'emits [Loading, Error] when AI service throws',
      build: build,
      setUp: () {
        when(() => repo.getLatestInsight(any(), any()))
            .thenAnswer((_) async => null);
        when(() => aiService.generateMarketSummary(
              symbols: any(named: 'symbols'),
              context: any(named: 'context'),
            )).thenThrow(Exception('API quota exceeded'));
      },
      act: (bloc) => bloc.add(const AiInsightRequested(
        uid: 'uid_01',
        type: 'market_summary',
        context: 'PTT',
      )),
      expect: () => [isA<AiInsightLoading>(), isA<AiInsightError>()],
    );

    blocTest<AiInsightBloc, AiInsightState>(
      'AiInsightError message is non-empty on AI service error',
      build: build,
      setUp: () {
        when(() => repo.getLatestInsight(any(), any()))
            .thenAnswer((_) async => null);
        when(() => aiService.generateMarketSummary(
              symbols: any(named: 'symbols'),
              context: any(named: 'context'),
            )).thenThrow(Exception('quota exceeded'));
      },
      act: (bloc) => bloc.add(const AiInsightRequested(
        uid: 'uid_01',
        type: 'market_summary',
        context: 'PTT',
      )),
      expect: () => [
        isA<AiInsightLoading>(),
        isA<AiInsightError>()
            .having((s) => s.message, 'message', isNotEmpty),
      ],
    );
  });

  // ── State equality ─────────────────────────────────────────────────────────

  group('State equality', () {
    test('AiInsightInitial == AiInsightInitial', () {
      expect(const AiInsightInitial(), equals(const AiInsightInitial()));
    });

    test('AiInsightLoading == AiInsightLoading', () {
      expect(const AiInsightLoading(), equals(const AiInsightLoading()));
    });

    test('AiInsightLoaded with same insights are equal', () {
      expect(
        AiInsightLoaded([kAiInsight()]),
        equals(AiInsightLoaded([kAiInsight()])),
      );
    });

    test('AiInsightError with same message are equal', () {
      expect(
        const AiInsightError('error'),
        equals(const AiInsightError('error')),
      );
    });
  });
}
