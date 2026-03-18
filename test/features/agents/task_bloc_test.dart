import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aslan_pixel/core/enums/agent_type.dart';
import 'package:aslan_pixel/features/agents/bloc/task_bloc.dart';
import 'package:aslan_pixel/features/agents/engine/agent_task_model.dart';
import '../../mocks/mock_repositories.dart';
import '../../mocks/test_fixtures.dart';

void main() {
  late MockAgentTaskRepository repo;

  setUpAll(() {
    registerFallbackValue(kPendingTask());
  });

  setUp(() {
    repo = MockAgentTaskRepository();
  });

  TaskBloc build() => TaskBloc(repository: repo);

  group('TaskBloc — initial state', () {
    test('initial state is TaskInitial', () {
      expect(build().state, isA<TaskInitial>());
    });
  });

  // ── TaskWatchStarted ───────────────────────────────────────────────────────

  group('TaskWatchStarted', () {
    blocTest<TaskBloc, TaskState>(
      'emits [Loading, Loaded] with tasks from stream',
      build: build,
      setUp: () {
        when(() => repo.watchPendingTasks('uid_01'))
            .thenAnswer((_) => Stream.value([kPendingTask()]));
      },
      act: (bloc) => bloc.add(const TaskWatchStarted('uid_01')),
      expect: () => [
        isA<TaskLoading>(),
        isA<TaskLoaded>().having((s) => s.tasks.length, 'count', 1),
      ],
      verify: (_) =>
          verify(() => repo.watchPendingTasks('uid_01')).called(1),
    );

    blocTest<TaskBloc, TaskState>(
      'emits [Loading, Loaded] with empty list when no tasks',
      build: build,
      setUp: () {
        when(() => repo.watchPendingTasks(any()))
            .thenAnswer((_) => Stream.value(<AgentTask>[]));
      },
      act: (bloc) => bloc.add(const TaskWatchStarted('uid_01')),
      expect: () => [
        isA<TaskLoading>(),
        isA<TaskLoaded>().having((s) => s.tasks, 'tasks', isEmpty),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'emits [Loading, Error] when stream throws',
      build: build,
      setUp: () {
        when(() => repo.watchPendingTasks(any()))
            .thenAnswer((_) => Stream.error(Exception('Firestore error')));
      },
      act: (bloc) => bloc.add(const TaskWatchStarted('uid_01')),
      expect: () => [isA<TaskLoading>(), isA<TaskError>()],
    );

    blocTest<TaskBloc, TaskState>(
      'second call with same uid does not re-subscribe',
      build: build,
      setUp: () {
        when(() => repo.watchPendingTasks(any()))
            .thenAnswer((_) => Stream.value([kPendingTask()]));
      },
      act: (bloc) async {
        bloc.add(const TaskWatchStarted('uid_01'));
        await Future.delayed(Duration.zero);
        bloc.add(const TaskWatchStarted('uid_01'));
      },
      verify: (_) =>
          verify(() => repo.watchPendingTasks('uid_01')).called(1),
    );

    blocTest<TaskBloc, TaskState>(
      'emits multiple Loaded states on multiple stream events',
      build: build,
      setUp: () {
        when(() => repo.watchPendingTasks(any())).thenAnswer(
          (_) => Stream.fromIterable([
            [kPendingTask()],
            [kPendingTask(), kSettledTask()],
          ]),
        );
      },
      act: (bloc) => bloc.add(const TaskWatchStarted('uid_01')),
      expect: () => [
        isA<TaskLoading>(),
        isA<TaskLoaded>().having((s) => s.tasks.length, 'count', 1),
        isA<TaskLoaded>().having((s) => s.tasks.length, 'count', 2),
      ],
    );
  });

  // ── TaskCreated ────────────────────────────────────────────────────────────

  group('TaskCreated', () {
    blocTest<TaskBloc, TaskState>(
      'calls repository saveTask with correct uid',
      build: build,
      setUp: () {
        when(() => repo.watchPendingTasks(any()))
            .thenAnswer((_) => Stream.value([kPendingTask()]));
        when(() => repo.saveTask(any(), any()))
            .thenAnswer((_) async {});
      },
      act: (bloc) async {
        bloc.add(const TaskWatchStarted('uid_01'));
        await Future.delayed(Duration.zero);
        bloc.add(TaskCreated(
          uid: 'uid_01',
          agentId: kAnalystAgent.agentId,
          agentType: AgentType.analyst,
          taskType: TaskType.research,
          tier: TaskTier.basic,
          agentLevel: kAnalystAgent.level,
        ));
      },
      verify: (_) =>
          verify(() => repo.saveTask('uid_01', any())).called(1),
    );

    blocTest<TaskBloc, TaskState>(
      'emits TaskCreating before saving',
      build: build,
      setUp: () {
        when(() => repo.watchPendingTasks(any()))
            .thenAnswer((_) => Stream.value([kPendingTask()]));
        when(() => repo.saveTask(any(), any()))
            .thenAnswer((_) async {});
      },
      act: (bloc) async {
        bloc.add(const TaskWatchStarted('uid_01'));
        await Future.delayed(Duration.zero);
        bloc.add(TaskCreated(
          uid: 'uid_01',
          agentId: kAnalystAgent.agentId,
          agentType: AgentType.analyst,
          taskType: TaskType.research,
          tier: TaskTier.basic,
          agentLevel: 1,
        ));
        await Future.delayed(Duration.zero);
      },
      expect: () => [
        isA<TaskLoading>(),
        isA<TaskLoaded>(),
        isA<TaskCreating>(),
        // After createTask, bloc resets _watchedUid and re-subscribes
        isA<TaskLoading>(),
        isA<TaskLoaded>(),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'emits TaskError when saveTask throws',
      build: build,
      setUp: () {
        when(() => repo.watchPendingTasks(any()))
            .thenAnswer((_) => Stream.value([kPendingTask()]));
        when(() => repo.saveTask(any(), any()))
            .thenThrow(Exception('save failed'));
      },
      act: (bloc) async {
        bloc.add(const TaskWatchStarted('uid_01'));
        await Future.delayed(Duration.zero);
        bloc.add(TaskCreated(
          uid: 'uid_01',
          agentId: kAnalystAgent.agentId,
          agentType: AgentType.analyst,
          taskType: TaskType.research,
          tier: TaskTier.basic,
          agentLevel: kAnalystAgent.level,
        ));
      },
      expect: () => [
        isA<TaskLoading>(),
        isA<TaskLoaded>(),
        isA<TaskCreating>(),
        isA<TaskError>(),
      ],
    );
  });

  // ── TasksSettled ───────────────────────────────────────────────────────────

  group('TasksSettled', () {
    blocTest<TaskBloc, TaskState>(
      'calls repository settleTask for completed tasks',
      build: build,
      setUp: () {
        when(() => repo.watchPendingTasks(any()))
            .thenAnswer((_) => Stream.value([kCompletedTask()]));
        when(() => repo.settleTask(any(), any(), any()))
            .thenAnswer((_) async {});
      },
      act: (bloc) async {
        bloc.add(const TaskWatchStarted('uid_01'));
        await Future.delayed(Duration.zero);
        bloc.add(const TasksSettled('uid_01'));
      },
      verify: (_) =>
          verify(() => repo.settleTask('uid_01', any(), any())).called(1),
    );

    blocTest<TaskBloc, TaskState>(
      'does nothing when state is not TaskLoaded',
      build: build,
      act: (bloc) => bloc.add(const TasksSettled('uid_01')),
      expect: () => [],
    );

    blocTest<TaskBloc, TaskState>(
      'emits TaskError when settleTask throws',
      build: build,
      setUp: () {
        when(() => repo.watchPendingTasks(any()))
            .thenAnswer((_) => Stream.value([kCompletedTask()]));
        when(() => repo.settleTask(any(), any(), any()))
            .thenThrow(Exception('settle failed'));
      },
      act: (bloc) async {
        bloc.add(const TaskWatchStarted('uid_01'));
        await Future.delayed(Duration.zero);
        bloc.add(const TasksSettled('uid_01'));
      },
      expect: () => [
        isA<TaskLoading>(),
        isA<TaskLoaded>(),
        isA<TaskError>(),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'all tasks result in TaskLoaded after settlement attempt',
      build: build,
      setUp: () {
        // Task with far future completesAt so it won't be settled
        final futureTask = AgentTask(
          taskId: 'task_future',
          agentId: 'agent_001',
          agentType: AgentType.analyst,
          taskType: TaskType.research,
          tier: TaskTier.basic,
          startedAt: DateTime.now(),
          completesAt: DateTime.now().add(const Duration(hours: 99)),
          baseReward: 10,
          xpReward: 5,
          isSettled: false,
          actualReward: null,
        );
        when(() => repo.watchPendingTasks(any()))
            .thenAnswer((_) => Stream.value([futureTask]));
        when(() => repo.settleTask(any(), any(), any()))
            .thenAnswer((_) async {});
      },
      act: (bloc) async {
        bloc.add(const TaskWatchStarted('uid_01'));
        await Future.delayed(Duration.zero);
        bloc.add(const TasksSettled('uid_01'));
      },
      expect: () => [
        isA<TaskLoading>(),
        isA<TaskLoaded>(),
        // No 3rd emit: bloc emits TaskLoaded(settled) but equatable
        // prevents duplicate state emission when nothing changed
      ],
      verify: (_) =>
          verifyNever(() => repo.settleTask(any(), any(), any())),
    );
  });

  // ── State equality ─────────────────────────────────────────────────────────

  group('State equality', () {
    test('TaskInitial == TaskInitial', () {
      expect(const TaskInitial(), equals(const TaskInitial()));
    });

    test('TaskLoading == TaskLoading', () {
      expect(const TaskLoading(), equals(const TaskLoading()));
    });

    test('TaskLoaded with same task reference has same props', () {
      final task = kPendingTask();
      final state1 = TaskLoaded([task]);
      final state2 = TaskLoaded([task]);
      expect(state1.tasks, equals(state2.tasks));
    });

    test('TaskCreating == TaskCreating', () {
      expect(const TaskCreating(), equals(const TaskCreating()));
    });

    test('TaskError with same message are equal', () {
      expect(
        const TaskError('error'),
        equals(const TaskError('error')),
      );
    });
  });
}
