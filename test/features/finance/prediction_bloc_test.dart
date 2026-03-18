import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aslan_pixel/features/finance/bloc/prediction_bloc.dart';
import 'package:aslan_pixel/features/finance/bloc/prediction_event.dart';
import 'package:aslan_pixel/features/finance/bloc/prediction_state.dart';
import '../../mocks/mock_repositories.dart';
import '../../mocks/test_fixtures.dart';

// NOTE: PredictionBloc uses Stream.listen() instead of emit.forEach,
// which causes BLoC's debug assertion "emit after handler completed".
// These tests are limited to state and repository verification only.

void main() {
  late MockPredictionRepository repo;

  setUp(() {
    repo = MockPredictionRepository();
  });

  PredictionBloc build() => PredictionBloc(repository: repo);

  group('PredictionBloc — initial state', () {
    test('initial state is PredictionInitial', () {
      expect(build().state, isA<PredictionInitial>());
    });
  });

  // ── PredictionWatchStarted ─────────────────────────────────────────────────

  group('PredictionWatchStarted', () {
    test('calls repository watchOpenEvents', () async {
      when(() => repo.watchOpenEvents())
          .thenAnswer((_) => const Stream.empty());
      final bloc = build();
      bloc.add(const PredictionWatchStarted());
      await Future.delayed(Duration.zero);
      verify(() => repo.watchOpenEvents()).called(1);
      await bloc.close();
    });

    test('emits PredictionLoading immediately', () async {
      when(() => repo.watchOpenEvents())
          .thenAnswer((_) => const Stream.empty());
      final bloc = build();
      bloc.add(const PredictionWatchStarted());
      await Future.delayed(Duration.zero);
      expect(bloc.state, isA<PredictionLoading>());
      await bloc.close();
    });
  });

  // ── PredictionEventEntered ─────────────────────────────────────────────────

  group('PredictionEventEntered', () {
    test('calls repository enterPrediction with correct args', () async {
      // Don't add PredictionWatchStarted to avoid listen() assertion.
      // enterPrediction is independent of the watch subscription.
      when(() => repo.enterPrediction(
            eventId: any(named: 'eventId'),
            uid: any(named: 'uid'),
            selectedOptionId: any(named: 'selectedOptionId'),
            coinStaked: any(named: 'coinStaked'),
          )).thenAnswer((_) async {});

      final bloc = build();
      bloc.add(PredictionEventEntered(
        eventId: kPredictionEvent().eventId,
        uid: kUser.uid!,
        selectedOptionId: 'yes',
        coinStaked: 10,
      ));
      await Future.delayed(Duration.zero);

      verify(() => repo.enterPrediction(
            eventId: kPredictionEvent().eventId,
            uid: kUser.uid!,
            selectedOptionId: 'yes',
            coinStaked: 10,
          )).called(1);

      await bloc.close();
    });
  });

  // ── PredictionLoaded state ─────────────────────────────────────────────────

  group('PredictionLoaded', () {
    test('copyWith updates events', () {
      final state = PredictionLoaded(events: [kPredictionEvent()]);
      final updated = state.copyWith(events: []);
      expect(updated.events, isEmpty);
      expect(updated.myEntries, isEmpty);
    });

    test('copyWith updates myEntries', () {
      final state = PredictionLoaded(events: [kPredictionEvent()]);
      final updated = state.copyWith(myEntries: [kPredictionEntry()]);
      expect(updated.myEntries.length, 1);
      expect(updated.events.length, 1);
    });

    test('copyWith without args preserves all fields', () {
      final entry = kPredictionEntry();
      final event = kPredictionEvent();
      final state = PredictionLoaded(events: [event], myEntries: [entry]);
      final copy = state.copyWith();
      expect(copy.events, equals(state.events));
      expect(copy.myEntries, equals(state.myEntries));
    });
  });

  // ── State equality ─────────────────────────────────────────────────────────

  group('State equality', () {
    test('PredictionInitial == PredictionInitial', () {
      expect(const PredictionInitial(), equals(const PredictionInitial()));
    });

    test('PredictionLoading == PredictionLoading', () {
      expect(const PredictionLoading(), equals(const PredictionLoading()));
    });

    test('PredictionLoaded with same events reference are equal', () {
      final event = kPredictionEvent();
      expect(
        PredictionLoaded(events: [event]),
        equals(PredictionLoaded(events: [event])),
      );
    });

    test('PredictionLoaded default myEntries is empty', () {
      expect(
        PredictionLoaded(events: []).myEntries,
        isEmpty,
      );
    });

    test('PredictionEntering == PredictionEntering', () {
      expect(const PredictionEntering(), equals(const PredictionEntering()));
    });

    test('PredictionEntered == PredictionEntered', () {
      expect(const PredictionEntered(), equals(const PredictionEntered()));
    });

    test('PredictionError with same message are equal', () {
      expect(
        const PredictionError('error'),
        equals(const PredictionError('error')),
      );
    });
  });
}
