part of 'quest_bloc.dart';

/// Base class for all quest-related events.
abstract class QuestEvent extends Equatable {
  const QuestEvent();

  @override
  List<Object?> get props => [];
}

/// Begin watching the active quest list for [uid].
class QuestWatchStarted extends QuestEvent {
  const QuestWatchStarted(this.uid);

  final String uid;

  @override
  List<Object?> get props => [uid];
}

/// Increment progress on [questId] by [increment].
class QuestProgressUpdated extends QuestEvent {
  const QuestProgressUpdated({
    required this.questId,
    required this.increment,
  });

  final String questId;
  final int increment;

  @override
  List<Object?> get props => [questId, increment];
}

/// Claim reward for a completed quest.
class QuestRewardClaimed extends QuestEvent {
  const QuestRewardClaimed({
    required this.questId,
    required this.uid,
  });

  final String questId;
  final String uid;

  @override
  List<Object?> get props => [questId, uid];
}
