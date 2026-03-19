import 'package:aslan_pixel/features/finance/bloc/prediction_bloc.dart';
import 'package:aslan_pixel/features/finance/bloc/prediction_event.dart';
import 'package:aslan_pixel/features/finance/bloc/prediction_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/mock_repositories.dart';

void main() {
  late MockPredictionRepository mockRepository;

  setUp(() {
    mockRepository = MockPredictionRepository();
  });

  group('PredictionBloc vote events', () {
    group('PredictionVotesLoaded', () {
      blocTest<PredictionBloc, PredictionState>(
        'emits PredictionVotesData on success',
        build: () {
          when(() => mockRepository.loadVotes(
                eventId: any(named: 'eventId'),
                uid: any(named: 'uid'),
              )).thenAnswer((_) async => (
                bullCount: 42,
                bearCount: 18,
                myVote: 'bull',
              ));
          return PredictionBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(const PredictionVotesLoaded(
          eventId: 'event_123',
          uid: 'user_abc',
        )),
        expect: () => [
          const PredictionVotesData(
            eventId: 'event_123',
            bullCount: 42,
            bearCount: 18,
            myVote: 'bull',
          ),
        ],
        verify: (_) {
          verify(() => mockRepository.loadVotes(
                eventId: 'event_123',
                uid: 'user_abc',
              )).called(1);
        },
      );

      blocTest<PredictionBloc, PredictionState>(
        'emits PredictionVotesData with null myVote when user has not voted',
        build: () {
          when(() => mockRepository.loadVotes(
                eventId: any(named: 'eventId'),
                uid: any(named: 'uid'),
              )).thenAnswer((_) async => (
                bullCount: 10,
                bearCount: 5,
                myVote: null,
              ));
          return PredictionBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(const PredictionVotesLoaded(
          eventId: 'event_456',
          uid: 'user_xyz',
        )),
        expect: () => [
          const PredictionVotesData(
            eventId: 'event_456',
            bullCount: 10,
            bearCount: 5,
            myVote: null,
          ),
        ],
      );

      blocTest<PredictionBloc, PredictionState>(
        'emits PredictionError when loadVotes throws',
        build: () {
          when(() => mockRepository.loadVotes(
                eventId: any(named: 'eventId'),
                uid: any(named: 'uid'),
              )).thenThrow(Exception('Network error'));
          return PredictionBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(const PredictionVotesLoaded(
          eventId: 'event_fail',
          uid: 'user_err',
        )),
        expect: () => [
          isA<PredictionError>().having(
            (s) => s.message,
            'message',
            contains('Network error'),
          ),
        ],
      );
    });

    group('PredictionVoteCasted', () {
      blocTest<PredictionBloc, PredictionState>(
        'emits PredictionVoteCastedSuccess on success',
        build: () {
          when(() => mockRepository.castVote(
                eventId: any(named: 'eventId'),
                uid: any(named: 'uid'),
                side: any(named: 'side'),
              )).thenAnswer((_) async {});
          when(() => mockRepository.enterPrediction(
                eventId: any(named: 'eventId'),
                uid: any(named: 'uid'),
                selectedOptionId: any(named: 'selectedOptionId'),
                coinStaked: any(named: 'coinStaked'),
              )).thenAnswer((_) async {});
          return PredictionBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(const PredictionVoteCasted(
          eventId: 'event_123',
          uid: 'user_abc',
          side: 'bull',
          selectedOptionId: 'option_up',
          coinStaked: 50,
        )),
        expect: () => [
          const PredictionVoteCastedSuccess(side: 'bull'),
        ],
        verify: (_) {
          verify(() => mockRepository.castVote(
                eventId: 'event_123',
                uid: 'user_abc',
                side: 'bull',
              )).called(1);
          verify(() => mockRepository.enterPrediction(
                eventId: 'event_123',
                uid: 'user_abc',
                selectedOptionId: 'option_up',
                coinStaked: 50,
              )).called(1);
        },
      );

      blocTest<PredictionBloc, PredictionState>(
        'emits PredictionVoteCastedSuccess with bear side',
        build: () {
          when(() => mockRepository.castVote(
                eventId: any(named: 'eventId'),
                uid: any(named: 'uid'),
                side: any(named: 'side'),
              )).thenAnswer((_) async {});
          when(() => mockRepository.enterPrediction(
                eventId: any(named: 'eventId'),
                uid: any(named: 'uid'),
                selectedOptionId: any(named: 'selectedOptionId'),
                coinStaked: any(named: 'coinStaked'),
              )).thenAnswer((_) async {});
          return PredictionBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(const PredictionVoteCasted(
          eventId: 'event_789',
          uid: 'user_def',
          side: 'bear',
          selectedOptionId: 'option_down',
          coinStaked: 100,
        )),
        expect: () => [
          const PredictionVoteCastedSuccess(side: 'bear'),
        ],
      );

      blocTest<PredictionBloc, PredictionState>(
        'emits PredictionVoteCastError when castVote throws',
        build: () {
          when(() => mockRepository.castVote(
                eventId: any(named: 'eventId'),
                uid: any(named: 'uid'),
                side: any(named: 'side'),
              )).thenThrow(Exception('Insufficient coins'));
          return PredictionBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(const PredictionVoteCasted(
          eventId: 'event_fail',
          uid: 'user_broke',
          side: 'bull',
          selectedOptionId: 'option_up',
          coinStaked: 9999,
        )),
        expect: () => [
          isA<PredictionVoteCastError>().having(
            (s) => s.message,
            'message',
            contains('Insufficient coins'),
          ),
        ],
      );

      blocTest<PredictionBloc, PredictionState>(
        'emits PredictionVoteCastError when enterPrediction throws',
        build: () {
          when(() => mockRepository.castVote(
                eventId: any(named: 'eventId'),
                uid: any(named: 'uid'),
                side: any(named: 'side'),
              )).thenAnswer((_) async {});
          when(() => mockRepository.enterPrediction(
                eventId: any(named: 'eventId'),
                uid: any(named: 'uid'),
                selectedOptionId: any(named: 'selectedOptionId'),
                coinStaked: any(named: 'coinStaked'),
              )).thenThrow(Exception('Event closed'));
          return PredictionBloc(repository: mockRepository);
        },
        act: (bloc) => bloc.add(const PredictionVoteCasted(
          eventId: 'event_closed',
          uid: 'user_late',
          side: 'bear',
          selectedOptionId: 'option_down',
          coinStaked: 25,
        )),
        expect: () => [
          isA<PredictionVoteCastError>().having(
            (s) => s.message,
            'message',
            contains('Event closed'),
          ),
        ],
      );
    });
  });
}
