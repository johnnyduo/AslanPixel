import 'package:cloud_firestore/cloud_firestore.dart';

/// A single quest (daily, weekly, or achievement) stored under
/// quests/{uid}/active/{questId}.
class QuestModel {
  const QuestModel({
    required this.questId,
    required this.type,
    required this.objective,
    required this.objectiveTh,
    required this.reward,
    required this.progress,
    required this.target,
    required this.completed,
    this.expiresAt,
  });

  final String questId;

  /// 'daily' | 'weekly' | 'achievement'
  final String type;

  final String objective;

  /// Thai-language description.
  final String objectiveTh;

  /// Reward map — keys: coins (int), xp (int), itemId (String?).
  final Map<String, dynamic> reward;

  final DateTime? expiresAt;

  /// Current completion progress.
  final int progress;

  /// Target value to complete the quest.
  final int target;

  final bool completed;

  // ── Computed ────────────────────────────────────────────────────────────────

  bool get isComplete => progress >= target;

  // ── Factory ─────────────────────────────────────────────────────────────────

  factory QuestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return QuestModel(
      questId: doc.id,
      type: data['type'] as String? ?? 'daily',
      objective: data['objective'] as String? ?? '',
      objectiveTh: data['objectiveTh'] as String? ?? '',
      reward: (data['reward'] as Map<String, dynamic>?) ?? {},
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      progress: data['progress'] as int? ?? 0,
      target: data['target'] as int? ?? 1,
      completed: data['completed'] as bool? ?? false,
    );
  }

  // ── Serialisation ────────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'type': type,
        'objective': objective,
        'objectiveTh': objectiveTh,
        'reward': reward,
        'expiresAt':
            expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
        'progress': progress,
        'target': target,
        'completed': completed,
      };

  // ── copyWith ─────────────────────────────────────────────────────────────────

  QuestModel copyWith({
    String? questId,
    String? type,
    String? objective,
    String? objectiveTh,
    Map<String, dynamic>? reward,
    DateTime? expiresAt,
    int? progress,
    int? target,
    bool? completed,
  }) =>
      QuestModel(
        questId: questId ?? this.questId,
        type: type ?? this.type,
        objective: objective ?? this.objective,
        objectiveTh: objectiveTh ?? this.objectiveTh,
        reward: reward ?? this.reward,
        expiresAt: expiresAt ?? this.expiresAt,
        progress: progress ?? this.progress,
        target: target ?? this.target,
        completed: completed ?? this.completed,
      );
}
