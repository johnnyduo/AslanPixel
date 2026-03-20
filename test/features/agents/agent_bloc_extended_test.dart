import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aslan_pixel/core/enums/agent_type.dart';
import 'package:aslan_pixel/features/agents/bloc/agent_bloc.dart';
import 'package:aslan_pixel/features/agents/data/models/agent_model.dart';
import '../../mocks/mock_repositories.dart';

void main() {
  late MockAgentRepository repo;

  setUpAll(() {
    registerFallbackValue(AgentStatus.idle);
    registerFallbackValue(AgentType.analyst);
  });

  setUp(() {
    repo = MockAgentRepository();
  });

  AgentBloc build() => AgentBloc(repository: repo);

  // ══════════════════════════════════════════════════════════════════════════
  // AgentLevelUpRequested
  // ══════════════════════════════════════════════════════════════════════════

  group('AgentLevelUpRequested', () {
    blocTest<AgentBloc, AgentState>(
      'emits AgentLevelUpSuccess on successful level-up',
      build: build,
      setUp: () {
        when(() => repo.levelUpAgent(any(), any()))
            .thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(const AgentLevelUpRequested(
        uid: 'uid_01',
        agentId: 'agent_analyst_01',
      )),
      expect: () => [
        isA<AgentLevelUpSuccess>()
            .having((s) => s.agentId, 'agentId', 'agent_analyst_01'),
      ],
      verify: (_) =>
          verify(() => repo.levelUpAgent('uid_01', 'agent_analyst_01'))
              .called(1),
    );

    blocTest<AgentBloc, AgentState>(
      'emits AgentError when level-up throws',
      build: build,
      setUp: () {
        when(() => repo.levelUpAgent(any(), any()))
            .thenThrow(Exception('Insufficient XP'));
      },
      act: (bloc) => bloc.add(const AgentLevelUpRequested(
        uid: 'uid_01',
        agentId: 'agent_analyst_01',
      )),
      expect: () => [
        isA<AgentError>(),
      ],
    );

    blocTest<AgentBloc, AgentState>(
      'passes correct uid and agentId to repository',
      build: build,
      setUp: () {
        when(() => repo.levelUpAgent(any(), any()))
            .thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(const AgentLevelUpRequested(
        uid: 'uid_42',
        agentId: 'agent_scout_99',
      )),
      verify: (_) =>
          verify(() => repo.levelUpAgent('uid_42', 'agent_scout_99'))
              .called(1),
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // AgentTaskCompleted
  // ══════════════════════════════════════════════════════════════════════════

  group('AgentTaskCompleted', () {
    blocTest<AgentBloc, AgentState>(
      'calls repository status transitions: returning -> celebrating -> idle + clearActiveTask',
      build: build,
      setUp: () {
        when(() => repo.updateAgentStatus(any(), any(), any()))
            .thenAnswer((_) async {});
        when(() => repo.clearActiveTask(any(), any()))
            .thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(const AgentTaskCompleted(
        uid: 'uid_01',
        agentId: 'agent_analyst_01',
        coinsEarned: 50,
      )),
      wait: const Duration(seconds: 4),
      verify: (_) {
        verify(() => repo.updateAgentStatus(
              'uid_01',
              'agent_analyst_01',
              AgentStatus.returning,
            )).called(1);
        verify(() => repo.updateAgentStatus(
              'uid_01',
              'agent_analyst_01',
              AgentStatus.celebrating,
            )).called(1);
        verify(() => repo.updateAgentStatus(
              'uid_01',
              'agent_analyst_01',
              AgentStatus.idle,
            )).called(1);
        verify(() => repo.clearActiveTask('uid_01', 'agent_analyst_01'))
            .called(1);
      },
    );

    blocTest<AgentBloc, AgentState>(
      'emits AgentError when status update throws',
      build: build,
      setUp: () {
        when(() => repo.updateAgentStatus(any(), any(), any()))
            .thenThrow(Exception('Firestore offline'));
      },
      act: (bloc) => bloc.add(const AgentTaskCompleted(
        uid: 'uid_01',
        agentId: 'agent_analyst_01',
        coinsEarned: 25,
      )),
      expect: () => [
        isA<AgentError>(),
      ],
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // State equality for new states
  // ══════════════════════════════════════════════════════════════════════════

  group('State equality — extended', () {
    test('AgentLevelUpSuccess with same agentId are equal', () {
      expect(
        const AgentLevelUpSuccess('agent_01'),
        equals(const AgentLevelUpSuccess('agent_01')),
      );
    });

    test('AgentLevelUpSuccess with different agentId are not equal', () {
      expect(
        const AgentLevelUpSuccess('agent_01'),
        isNot(equals(const AgentLevelUpSuccess('agent_02'))),
      );
    });

    test('AgentPurchaseSuccess with same type are equal', () {
      expect(
        const AgentPurchaseSuccess(AgentType.scout),
        equals(const AgentPurchaseSuccess(AgentType.scout)),
      );
    });

    test('AgentPurchaseSuccess with different type are not equal', () {
      expect(
        const AgentPurchaseSuccess(AgentType.scout),
        isNot(equals(const AgentPurchaseSuccess(AgentType.analyst))),
      );
    });

    test('AgentPurchaseError with same message are equal', () {
      expect(
        const AgentPurchaseError('already owned'),
        equals(const AgentPurchaseError('already owned')),
      );
    });

    test('AgentPurchaseError with different message are not equal', () {
      expect(
        const AgentPurchaseError('already owned'),
        isNot(equals(const AgentPurchaseError('insufficient coins'))),
      );
    });
  });
}
