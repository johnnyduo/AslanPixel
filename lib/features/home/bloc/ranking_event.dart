part of 'ranking_bloc.dart';

/// Base class for all ranking events.
abstract class RankingEvent extends Equatable {
  const RankingEvent();

  @override
  List<Object?> get props => [];
}

/// Start watching the leaderboard for [uid] and [period].
///
/// [period] is 'weekly' or 'alltime'.
class RankingWatchStarted extends RankingEvent {
  const RankingWatchStarted({required this.uid, required this.period});

  final String uid;
  final String period;

  @override
  List<Object?> get props => [uid, period];
}

/// Switch to a different period tab — re-watch with new period.
class RankingPeriodChanged extends RankingEvent {
  const RankingPeriodChanged({required this.uid, required this.period});

  final String uid;
  final String period;

  @override
  List<Object?> get props => [uid, period];
}
