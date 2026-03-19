import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aslan_pixel/core/enums/agent_type.dart';
import 'package:aslan_pixel/features/home/bloc/pixel_world_bloc.dart';
import '../../../mocks/mock_repositories.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(AgentType.analyst);
  });

  late MockAiService aiService;

  setUp(() {
    aiService = MockAiService();
  });

  PixelWorldBloc build() => PixelWorldBloc(aiService: aiService);

  // ── Initial state ─────────────────────────────────────────────────────────

  group('PixelWorldBloc initial state', () {
    test('starts as PixelWorldInitial', () {
      expect(build().state, isA<PixelWorldInitial>());
    });
  });

  // ── PixelWorldStarted ─────────────────────────────────────────────────────

  group('PixelWorldStarted', () {
    blocTest<PixelWorldBloc, PixelWorldState>(
      'emits [PixelWorldLoading, PixelWorldLoaded] with default idle statuses',
      build: build,
      act: (bloc) => bloc.add(const PixelWorldStarted()),
      expect: () => [
        isA<PixelWorldLoading>(),
        isA<PixelWorldLoaded>()
            .having(
              (s) => s.agentStatuses[AgentType.analyst],
              'analyst status',
              AgentStatus.idle,
            )
            .having(
              (s) => s.agentStatuses[AgentType.scout],
              'scout status',
              AgentStatus.idle,
            ),
      ],
    );

    blocTest<PixelWorldBloc, PixelWorldState>(
      'loaded state has entries for all four agent types',
      build: build,
      act: (bloc) => bloc.add(const PixelWorldStarted()),
      expect: () => [
        isA<PixelWorldLoading>(),
        isA<PixelWorldLoaded>()
            .having((s) => s.agentStatuses.length, 'agent count', 4),
      ],
    );
  });

  // ── PixelWorldRoomLoaded ──────────────────────────────────────────────────

  group('PixelWorldRoomLoaded', () {
    blocTest<PixelWorldBloc, PixelWorldState>(
      'emits PixelWorldLoaded with parsed statuses from roomData',
      build: build,
      act: (bloc) => bloc.add(const PixelWorldRoomLoaded({
        'agentStatuses': {
          'analyst': 'working',
          'scout': 'returning',
        },
      })),
      expect: () => [
        isA<PixelWorldLoaded>()
            .having(
              (s) => s.agentStatuses[AgentType.analyst],
              'analyst',
              AgentStatus.working,
            )
            .having(
              (s) => s.agentStatuses[AgentType.scout],
              'scout',
              AgentStatus.returning,
            )
            .having(
              (s) => s.agentStatuses[AgentType.risk],
              'risk defaults to idle',
              AgentStatus.idle,
            ),
      ],
    );

    blocTest<PixelWorldBloc, PixelWorldState>(
      'defaults all agents to idle when agentStatuses key is absent',
      build: build,
      act: (bloc) => bloc.add(const PixelWorldRoomLoaded({})),
      expect: () => [
        isA<PixelWorldLoaded>().having(
          (s) =>
              s.agentStatuses.values.every((st) => st == AgentStatus.idle),
          'all idle',
          isTrue,
        ),
      ],
    );
  });

  // ── PixelWorldAgentTapped ─────────────────────────────────────────────────

  group('PixelWorldAgentTapped', () {
    blocTest<PixelWorldBloc, PixelWorldState>(
      'emits PixelWorldDialogueLoaded with AI-generated text',
      build: build,
      setUp: () {
        when(() => aiService.generateAgentDialogue(
              agentType: any(named: 'agentType'),
              agentStatus: any(named: 'agentStatus'),
              context: any(named: 'context'),
            )).thenAnswer((_) async => 'ตลาดดูดีมากวันนี้!');
      },
      act: (bloc) =>
          bloc.add(const PixelWorldAgentTapped(AgentType.analyst)),
      expect: () => [
        isA<PixelWorldDialogueLoaded>()
            .having((s) => s.agentType, 'agentType', AgentType.analyst)
            .having((s) => s.text, 'text', 'ตลาดดูดีมากวันนี้!'),
      ],
    );

    blocTest<PixelWorldBloc, PixelWorldState>(
      'emits dialogue with empty text when AI service returns empty string',
      build: build,
      setUp: () {
        when(() => aiService.generateAgentDialogue(
              agentType: any(named: 'agentType'),
              agentStatus: any(named: 'agentStatus'),
              context: any(named: 'context'),
            )).thenAnswer((_) async => '');
      },
      act: (bloc) => bloc.add(const PixelWorldAgentTapped(AgentType.scout)),
      expect: () => [
        isA<PixelWorldDialogueLoaded>()
            .having((s) => s.text, 'text', ''),
      ],
    );
  });
}
