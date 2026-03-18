import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/enums/agent_type.dart';

enum AgentStatus { idle, working, returning, celebrating, fail }

extension AgentStatusValue on AgentStatus {
  String get value {
    switch (this) {
      case AgentStatus.idle:
        return 'idle';
      case AgentStatus.working:
        return 'working';
      case AgentStatus.returning:
        return 'returning';
      case AgentStatus.celebrating:
        return 'celebrating';
      case AgentStatus.fail:
        return 'fail';
    }
  }

  static AgentStatus fromString(String? v) {
    switch (v) {
      case 'working':
        return AgentStatus.working;
      case 'returning':
        return AgentStatus.returning;
      case 'celebrating':
        return AgentStatus.celebrating;
      case 'fail':
        return AgentStatus.fail;
      default:
        return AgentStatus.idle;
    }
  }
}

class AgentModel {
  const AgentModel({
    required this.agentId,
    required this.type,
    required this.level,
    required this.xp,
    required this.status,
    this.activeTaskId,
    this.taskCompletesAt,
    this.personalityKey,
  });

  final String agentId;
  final AgentType type;
  final int level;
  final int xp;
  final AgentStatus status;
  final String? activeTaskId;
  final DateTime? taskCompletesAt;
  final String? personalityKey;

  factory AgentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AgentModel(
      agentId: doc.id,
      type: AgentTypeValue.fromString(data['type'] as String?),
      level: (data['level'] as num?)?.toInt() ?? 1,
      xp: (data['xp'] as num?)?.toInt() ?? 0,
      status: AgentStatusValue.fromString(data['status'] as String?),
      activeTaskId: data['activeTaskId'] as String?,
      taskCompletesAt: (data['taskCompletesAt'] as Timestamp?)?.toDate(),
      personalityKey: data['personalityKey'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'agentId': agentId,
        'type': type.value,
        'level': level,
        'xp': xp,
        'status': status.value,
        'activeTaskId': activeTaskId,
        'taskCompletesAt':
            taskCompletesAt != null ? Timestamp.fromDate(taskCompletesAt!) : null,
        'personalityKey': personalityKey,
      };

  AgentModel copyWith({
    String? agentId,
    AgentType? type,
    int? level,
    int? xp,
    AgentStatus? status,
    String? activeTaskId,
    DateTime? taskCompletesAt,
    String? personalityKey,
  }) =>
      AgentModel(
        agentId: agentId ?? this.agentId,
        type: type ?? this.type,
        level: level ?? this.level,
        xp: xp ?? this.xp,
        status: status ?? this.status,
        activeTaskId: activeTaskId ?? this.activeTaskId,
        taskCompletesAt: taskCompletesAt ?? this.taskCompletesAt,
        personalityKey: personalityKey ?? this.personalityKey,
      );
}
