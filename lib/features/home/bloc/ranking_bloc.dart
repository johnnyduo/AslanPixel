import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aslan_pixel/features/home/data/models/ranking_entry_model.dart';
import 'package:aslan_pixel/features/home/data/repositories/ranking_repository.dart';

part 'ranking_event.dart';
part 'ranking_state.dart';

/// BLoC that watches a leaderboard period and exposes the current user's rank.
///
/// Emits [RankingLoaded] on every Firestore snapshot.
/// The current user's position is derived from the list — no extra query needed
/// as long as they are within the top-50 fetched by [RankingRepository].
class RankingBloc extends Bloc<RankingEvent, RankingState> {
  RankingBloc(this._repository) : super(const RankingInitial()) {
    on<RankingWatchStarted>(_onWatchStarted);
    on<RankingPeriodChanged>(_onPeriodChanged);
  }

  final RankingRepository _repository;

  // Tracks the currently watched (uid, period) pair so we don't re-subscribe
  // unnecessarily.
  String? _watchedUid;
  String? _watchedPeriod;

  Future<void> _onWatchStarted(
    RankingWatchStarted event,
    Emitter<RankingState> emit,
  ) async {
    if (_watchedUid == event.uid && _watchedPeriod == event.period) return;

    _watchedUid = event.uid;
    _watchedPeriod = event.period;

    emit(const RankingLoading());

    await emit.forEach<List<RankingEntryModel>>(
      _repository.watchLeaderboard(event.period, limit: 50),
      onData: (entries) {
        final myRank = _findMyRank(entries, event.uid);
        return RankingLoaded(
          entries: entries,
          myRank: myRank,
          period: event.period,
        );
      },
      onError: (error, _) => RankingError(error.toString()),
    );
  }

  Future<void> _onPeriodChanged(
    RankingPeriodChanged event,
    Emitter<RankingState> emit,
  ) async {
    // Reset watched state so _onWatchStarted doesn't short-circuit.
    _watchedUid = null;
    _watchedPeriod = null;

    add(RankingWatchStarted(uid: event.uid, period: event.period));
  }

  /// Returns the 1-based rank of [uid] within [entries], or null if absent.
  int? _findMyRank(List<RankingEntryModel> entries, String uid) {
    final index = entries.indexWhere((e) => e.uid == uid);
    return index == -1 ? null : index + 1;
  }
}
