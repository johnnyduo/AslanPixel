import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aslan_pixel/core/utils/local_notification_service.dart';
import 'package:aslan_pixel/features/quests/data/models/quest_model.dart';
import 'package:aslan_pixel/features/quests/data/repositories/quest_repository.dart';
import 'package:aslan_pixel/features/quests/engine/quest_room_rewards.dart';

part 'quest_event.dart';
part 'quest_state.dart';

/// BLoC for the quest system.
///
/// Manages a live-updated quest list and reward claims.
class QuestBloc extends Bloc<QuestEvent, QuestState> {
  QuestBloc({required QuestRepository repository})
      : _repository = repository,
        super(const QuestInitial()) {
    on<QuestWatchStarted>(_onWatchStarted);
    on<QuestProgressUpdated>(_onProgressUpdated);
    on<QuestRewardClaimed>(_onRewardClaimed);
  }

  final QuestRepository _repository;
  StreamSubscription<List<QuestModel>>? _questSub;
  String _watchedUid = '';

  // ── Handlers ───────────────────────────────────────────────────────────────

  Future<void> _onWatchStarted(
    QuestWatchStarted event,
    Emitter<QuestState> emit,
  ) async {
    if (_watchedUid == event.uid) return;
    _watchedUid = event.uid;

    emit(const QuestLoading());

    // Auto-generate daily quests before starting the stream.
    try {
      await _repository.ensureDailyQuestsExist(event.uid);
    } catch (_) {
      // Non-fatal — proceed to watch even if generation fails.
    }

    await _questSub?.cancel();
    await emit.forEach<List<QuestModel>>(
      _repository.watchActiveQuests(event.uid),
      onData: QuestLoaded.new,
      onError: (e, _) => QuestError(e.toString()),
    );
  }

  Future<void> _onProgressUpdated(
    QuestProgressUpdated event,
    Emitter<QuestState> emit,
  ) async {
    if (_watchedUid.isEmpty) return;
    try {
      await _repository.updateQuestProgress(
        _watchedUid,
        event.questId,
        event.increment,
      );
    } catch (e) {
      emit(QuestError(e.toString()));
    }
  }

  Future<void> _onRewardClaimed(
    QuestRewardClaimed event,
    Emitter<QuestState> emit,
  ) async {
    // Capture the quest's actionType and reward from the current loaded state
    // before claiming (the document is deleted by claimQuestReward).
    String? actionType;
    String questTitle = '';
    int rewardCoins = 0;
    final current = state;
    if (current is QuestLoaded) {
      final match = current.quests
          .where((q) => q.questId == event.questId)
          .toList();
      if (match.isNotEmpty) {
        actionType = match.first.actionType;
        questTitle = match.first.objectiveTh.isNotEmpty
            ? match.first.objectiveTh
            : match.first.objective;
        rewardCoins = (match.first.reward['coins'] as num?)?.toInt() ?? 0;
      }
    }

    try {
      await _repository.claimQuestReward(event.uid, event.questId);
      if (questTitle.isNotEmpty) {
        unawaited(LocalNotificationService.instance.showQuestComplete(
          questTitle,
          rewardCoins,
        ));
      }
      final unlockedItemId =
          actionType != null ? kQuestRoomRewards[actionType] : null;
      emit(QuestRewardClaimedSuccess(
        questId: event.questId,
        unlockedItemId: unlockedItemId,
      ));
    } catch (e) {
      emit(QuestError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _questSub?.cancel();
    return super.close();
  }
}
