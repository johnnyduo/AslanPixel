import 'package:aslan_pixel/features/quests/data/models/quest_model.dart';

/// Abstract contract for quest data operations.
abstract class QuestRepository {
  /// Emits the live list of active quests for [uid].
  Stream<List<QuestModel>> watchActiveQuests(String uid);

  /// Increments quest progress by [increment].
  /// Marks the quest complete when progress >= target.
  Future<void> updateQuestProgress(
    String uid,
    String questId,
    int increment,
  );

  /// Claims the reward for a completed quest:
  ///   - Adds coins/xp to economy.
  ///   - Removes quest from the active collection.
  Future<void> claimQuestReward(String uid, String questId);
}
