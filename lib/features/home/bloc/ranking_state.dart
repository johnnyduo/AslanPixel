part of 'ranking_bloc.dart';

/// Base class for all ranking states.
abstract class RankingState extends Equatable {
  const RankingState();

  @override
  List<Object?> get props => [];
}

/// No watch started yet.
class RankingInitial extends RankingState {
  const RankingInitial();
}

/// Fetching leaderboard data.
class RankingLoading extends RankingState {
  const RankingLoading();
}

/// Leaderboard data successfully loaded.
class RankingLoaded extends RankingState {
  const RankingLoaded({
    required this.entries,
    required this.myRank,
    required this.period,
  });

  /// Top-50 entries ordered by score descending.
  final List<RankingEntryModel> entries;

  /// The current user's 1-based rank, or null if they are not in the list.
  final int? myRank;

  /// 'weekly' or 'alltime'.
  final String period;

  @override
  List<Object?> get props => [entries, myRank, period];
}

/// An error occurred while fetching or watching the leaderboard.
class RankingError extends RankingState {
  const RankingError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
