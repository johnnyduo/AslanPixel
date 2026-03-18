import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aslan_pixel/features/quests/data/models/quest_model.dart';
import 'package:aslan_pixel/features/quests/data/repositories/quest_repository.dart';

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
    try {
      await _repository.claimQuestReward(event.uid, event.questId);
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
