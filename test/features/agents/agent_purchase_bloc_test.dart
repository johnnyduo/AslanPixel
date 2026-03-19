import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aslan_pixel/core/enums/agent_type.dart';
import 'package:aslan_pixel/features/agents/bloc/agent_bloc.dart';
import 'package:aslan_pixel/features/agents/data/models/agent_model.dart';
import 'package:aslan_pixel/features/inventory/data/repositories/economy_repository.dart';
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

  group('AgentPurchaseRequested', () {
    blocTest<AgentBloc, AgentState>(
      'emits AgentPurchaseSuccess on successful purchase',
      build: build,
      setUp: () {
        when(() => repo.getAgent(any(), any()))
            .thenAnswer((_) async => null);
        when(
          () => repo.purchaseAgent(
            uid: any(named: 'uid'),
            type: any(named: 'type'),
            price: any(named: 'price'),
          ),
        ).thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(
        const AgentPurchaseRequested(
          agentType: AgentType.scout,
          uid: 'uid_01',
          price: 200,
        ),
      ),
      expect: () => [
        isA<AgentPurchaseSuccess>()
            .having((s) => s.agentType, 'agentType', AgentType.scout),
      ],
      verify: (_) {
        verify(
          () => repo.purchaseAgent(
            uid: 'uid_01',
            type: AgentType.scout,
            price: 200,
          ),
        ).called(1);
      },
    );

    blocTest<AgentBloc, AgentState>(
      'emits AgentPurchaseError when agent already owned',
      build: build,
      setUp: () {
        when(() => repo.getAgent(any(), any())).thenAnswer(
          (_) async => const AgentModel(
            agentId: 'agent_scout_01',
            type: AgentType.scout,
            level: 1,
            xp: 0,
            status: AgentStatus.idle,
          ),
        );
      },
      act: (bloc) => bloc.add(
        const AgentPurchaseRequested(
          agentType: AgentType.scout,
          uid: 'uid_01',
          price: 200,
        ),
      ),
      expect: () => [
        isA<AgentPurchaseError>(),
      ],
    );

    blocTest<AgentBloc, AgentState>(
      'emits AgentPurchaseError with insufficient coins',
      build: build,
      setUp: () {
        when(() => repo.getAgent(any(), any()))
            .thenAnswer((_) async => null);
        when(
          () => repo.purchaseAgent(
            uid: any(named: 'uid'),
            type: any(named: 'type'),
            price: any(named: 'price'),
          ),
        ).thenThrow(const InsufficientCoinsException(100, 200));
      },
      act: (bloc) => bloc.add(
        const AgentPurchaseRequested(
          agentType: AgentType.scout,
          uid: 'uid_01',
          price: 200,
        ),
      ),
      expect: () => [
        isA<AgentPurchaseError>(),
      ],
    );

    blocTest<AgentBloc, AgentState>(
      'emits AgentPurchaseSuccess for free agent (price 0)',
      build: build,
      setUp: () {
        when(() => repo.getAgent(any(), any()))
            .thenAnswer((_) async => null);
        when(
          () => repo.purchaseAgent(
            uid: any(named: 'uid'),
            type: any(named: 'type'),
            price: any(named: 'price'),
          ),
        ).thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(
        const AgentPurchaseRequested(
          agentType: AgentType.analyst,
          uid: 'uid_01',
          price: 0,
        ),
      ),
      expect: () => [
        isA<AgentPurchaseSuccess>()
            .having((s) => s.agentType, 'agentType', AgentType.analyst),
      ],
    );
  });
}
