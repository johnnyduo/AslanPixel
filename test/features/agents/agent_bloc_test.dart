import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aslan_pixel/features/agents/bloc/agent_bloc.dart';
import 'package:aslan_pixel/features/agents/data/models/agent_model.dart';
import '../../mocks/mock_repositories.dart';
import '../../mocks/test_fixtures.dart';

void main() {
  late MockAgentRepository repo;

  setUpAll(() {
    registerFallbackValue(AgentStatus.idle);
  });

  setUp(() {
    repo = MockAgentRepository();
  });

  AgentBloc build() => AgentBloc(repository: repo);

  group('AgentBloc — initial state', () {
    test('initial state is AgentInitial', () {
      expect(build().state, isA<AgentInitial>());
    });
  });

  // ── AgentWatchStarted ─────────────────────────────────────────────────────

  group('AgentWatchStarted', () {
    final agents = [kAnalystAgent, kScoutAgent];

    blocTest<AgentBloc, AgentState>(
      'emits [Loading, Loaded] with agents from stream',
      build: build,
      setUp: () {
        when(() => repo.watchAgents('uid_01'))
            .thenAnswer((_) => Stream.value(agents));
      },
      act: (bloc) => bloc.add(AgentWatchStarted('uid_01')),
      expect: () => [
        isA<AgentLoading>(),
        isA<AgentLoaded>().having((s) => s.agents, 'agents', agents),
      ],
      verify: (_) => verify(() => repo.watchAgents('uid_01')).called(1),
    );

    blocTest<AgentBloc, AgentState>(
      'emits [Loading, Loaded] with empty list when no agents',
      build: build,
      setUp: () {
        when(() => repo.watchAgents(any()))
            .thenAnswer((_) => Stream.value(<AgentModel>[]));
      },
      act: (bloc) => bloc.add(AgentWatchStarted('uid_01')),
      expect: () => [
        isA<AgentLoading>(),
        isA<AgentLoaded>().having((s) => s.agents, 'agents', isEmpty),
      ],
    );

    blocTest<AgentBloc, AgentState>(
      'emits [Loading, Error] when stream throws',
      build: build,
      setUp: () {
        when(() => repo.watchAgents(any()))
            .thenAnswer((_) => Stream.error(Exception('Firestore error')));
      },
      act: (bloc) => bloc.add(AgentWatchStarted('uid_01')),
      expect: () => [isA<AgentLoading>(), isA<AgentError>()],
    );

    blocTest<AgentBloc, AgentState>(
      'emits multiple Loaded states on multiple stream events',
      build: build,
      setUp: () {
        when(() => repo.watchAgents(any())).thenAnswer(
          (_) => Stream.fromIterable([
            [kAnalystAgent],
            [kAnalystAgent, kScoutAgent],
          ]),
        );
      },
      act: (bloc) => bloc.add(AgentWatchStarted('uid_01')),
      expect: () => [
        isA<AgentLoading>(),
        isA<AgentLoaded>()
            .having((s) => s.agents.length, 'count', 1),
        isA<AgentLoaded>()
            .having((s) => s.agents.length, 'count', 2),
      ],
    );
  });

  // ── AgentStatusUpdated ────────────────────────────────────────────────────

  group('AgentStatusUpdated', () {
    blocTest<AgentBloc, AgentState>(
      'calls repository updateAgentStatus with correct args',
      build: build,
      setUp: () {
        when(() => repo.watchAgents(any()))
            .thenAnswer((_) => Stream.value([kAnalystAgent]));
        when(() => repo.updateAgentStatus(any(), any(), any()))
            .thenAnswer((_) async {});
      },
      act: (bloc) async {
        bloc.add(AgentWatchStarted('uid_01'));
        await Future.delayed(Duration.zero);
        bloc.add(AgentStatusUpdated(
          agentId: kAnalystAgent.agentId,
          status: AgentStatus.working,
        ));
      },
      verify: (_) => verify(
        () => repo.updateAgentStatus(
          'uid_01',
          kAnalystAgent.agentId,
          AgentStatus.working,
        ),
      ).called(1),
    );

    blocTest<AgentBloc, AgentState>(
      'emits AgentError when updateAgentStatus throws',
      build: build,
      setUp: () {
        when(() => repo.watchAgents(any()))
            .thenAnswer((_) => Stream.value([kAnalystAgent]));
        when(() => repo.updateAgentStatus(any(), any(), any()))
            .thenThrow(Exception('update failed'));
      },
      act: (bloc) async {
        bloc.add(AgentWatchStarted('uid_01'));
        await Future.delayed(Duration.zero);
        bloc.add(AgentStatusUpdated(
          agentId: kAnalystAgent.agentId,
          status: AgentStatus.working,
        ));
      },
      expect: () => [
        isA<AgentLoading>(),
        isA<AgentLoaded>(),
        isA<AgentError>(),
      ],
    );
  });

  // ── AgentLoaded state equality ─────────────────────────────────────────────

  group('State equality', () {
    test('AgentInitial == AgentInitial', () {
      expect(AgentInitial(), equals(AgentInitial()));
    });

    test('AgentLoaded with same agents are equal', () {
      expect(
        const AgentLoaded([kAnalystAgent]),
        equals(const AgentLoaded([kAnalystAgent])),
      );
    });

    test('AgentError with same message are equal', () {
      expect(
        const AgentError('error'),
        equals(const AgentError('error')),
      );
    });
  });
}
