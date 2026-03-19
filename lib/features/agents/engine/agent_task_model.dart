import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:aslan_pixel/core/enums/agent_type.dart';

enum TaskType { research, scoutMission, analysis, socialScan }

enum TaskTier { quick, basic, standard, advanced, elite }

class AgentTask {
  const AgentTask({
    required this.taskId,
    required this.agentId,
    required this.agentType,
    required this.taskType,
    required this.tier,
    required this.startedAt,
    required this.completesAt,
    required this.baseReward,
    required this.xpReward,
    required this.isSettled,
    this.actualReward,
  });

  final String taskId;
  final String agentId;
  final AgentType agentType;
  final TaskType taskType;
  final TaskTier tier;
  final DateTime startedAt;
  final DateTime completesAt;
  final int baseReward;
  final int xpReward;
  final bool isSettled;
  final int? actualReward;

  Duration get duration => completesAt.difference(startedAt);

  bool get isComplete => DateTime.now().isAfter(completesAt);

  factory AgentTask.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AgentTask(
      taskId: doc.id,
      agentId: data['agentId'] as String? ?? '',
      agentType: AgentTypeValue.fromString(data['agentType'] as String?),
      taskType: _taskTypeFromString(data['taskType'] as String?),
      tier: _tierFromString(data['tier'] as String?),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completesAt:
          (data['completesAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      baseReward: (data['baseReward'] as num?)?.toInt() ?? 0,
      xpReward: (data['xpReward'] as num?)?.toInt() ?? 0,
      isSettled: data['isSettled'] as bool? ?? false,
      actualReward: (data['actualReward'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
        'taskId': taskId,
        'agentId': agentId,
        'agentType': agentType.value,
        'taskType': _taskTypeToString(taskType),
        'tier': _tierToString(tier),
        'startedAt': Timestamp.fromDate(startedAt),
        'completesAt': Timestamp.fromDate(completesAt),
        'baseReward': baseReward,
        'xpReward': xpReward,
        'isSettled': isSettled,
        'actualReward': actualReward,
      };

  AgentTask copyWith({
    String? taskId,
    String? agentId,
    AgentType? agentType,
    TaskType? taskType,
    TaskTier? tier,
    DateTime? startedAt,
    DateTime? completesAt,
    int? baseReward,
    int? xpReward,
    bool? isSettled,
    int? actualReward,
  }) =>
      AgentTask(
        taskId: taskId ?? this.taskId,
        agentId: agentId ?? this.agentId,
        agentType: agentType ?? this.agentType,
        taskType: taskType ?? this.taskType,
        tier: tier ?? this.tier,
        startedAt: startedAt ?? this.startedAt,
        completesAt: completesAt ?? this.completesAt,
        baseReward: baseReward ?? this.baseReward,
        xpReward: xpReward ?? this.xpReward,
        isSettled: isSettled ?? this.isSettled,
        actualReward: actualReward ?? this.actualReward,
      );

  static TaskType _taskTypeFromString(String? value) {
    switch (value) {
      case 'scoutMission':
        return TaskType.scoutMission;
      case 'analysis':
        return TaskType.analysis;
      case 'socialScan':
        return TaskType.socialScan;
      default:
        return TaskType.research;
    }
  }

  static String _taskTypeToString(TaskType type) {
    switch (type) {
      case TaskType.research:
        return 'research';
      case TaskType.scoutMission:
        return 'scoutMission';
      case TaskType.analysis:
        return 'analysis';
      case TaskType.socialScan:
        return 'socialScan';
    }
  }

  static TaskTier _tierFromString(String? value) {
    switch (value) {
      case 'quick':
        return TaskTier.quick;
      case 'standard':
        return TaskTier.standard;
      case 'advanced':
        return TaskTier.advanced;
      case 'elite':
        return TaskTier.elite;
      default:
        return TaskTier.basic;
    }
  }

  static String _tierToString(TaskTier tier) {
    switch (tier) {
      case TaskTier.quick:
        return 'quick';
      case TaskTier.basic:
        return 'basic';
      case TaskTier.standard:
        return 'standard';
      case TaskTier.advanced:
        return 'advanced';
      case TaskTier.elite:
        return 'elite';
    }
  }
}
