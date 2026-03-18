part of 'quest_bloc.dart';

/// Base class for all quest states.
abstract class QuestState extends Equatable {
  const QuestState();

  @override
  List<Object?> get props => [];
}

/// BLoC has not started watching yet.
class QuestInitial extends QuestState {
  const QuestInitial();
}

/// Waiting for the initial snapshot.
class QuestLoading extends QuestState {
  const QuestLoading();
}

/// Live list of active quests is available.
class QuestLoaded extends QuestState {
  const QuestLoaded(this.quests);

  final List<QuestModel> quests;

  @override
  List<Object?> get props => [quests];
}

/// An error occurred during a repository operation.
class QuestError extends QuestState {
  const QuestError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// A quest reward was successfully claimed.
///
/// [unlockedItemId] is non-null when the quest's [actionType] maps to a room
/// decoration item via [kQuestRoomRewards].
class QuestRewardClaimedSuccess extends QuestState {
  const QuestRewardClaimedSuccess({
    required this.questId,
    this.unlockedItemId,
  });

  final String questId;
  final String? unlockedItemId;

  @override
  List<Object?> get props => [questId, unlockedItemId];
}
