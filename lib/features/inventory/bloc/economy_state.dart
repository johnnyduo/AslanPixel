part of 'economy_bloc.dart';

abstract class EconomyState extends Equatable {
  const EconomyState();

  @override
  List<Object?> get props => [];
}

/// Initial state — no data loaded yet.
class EconomyInitial extends EconomyState {
  const EconomyInitial();
}

/// Waiting for the first snapshot from Firestore.
class EconomyLoading extends EconomyState {
  const EconomyLoading();
}

/// Live balance is available.
///
/// [level] is computed as `xp ~/ 1000 + 1` (minimum level 1).
/// [xpForNextLevel] is always 1000 (one level = 1000 XP).
class EconomyLoaded extends EconomyState {
  const EconomyLoaded({
    required this.coins,
    required this.xp,
    required this.level,
  });

  final int coins;
  final int xp;
  final int level;

  /// XP required to reach the next level (constant: 1000).
  static const int xpForNextLevel = 1000;

  @override
  List<Object?> get props => [coins, xp, level];
}

/// Emitted once when the user's level increases.
///
/// [bonusCoins] = newLevel * 50. The BLoC emits this briefly before
/// continuing with [EconomyLoaded], so listeners can show a celebration.
class EconomyLevelUp extends EconomyState {
  const EconomyLevelUp({required this.newLevel, required this.bonusCoins});

  final int newLevel;
  final int bonusCoins;

  @override
  List<Object?> get props => [newLevel, bonusCoins];
}

/// A non-recoverable error occurred while watching or mutating the economy.
class EconomyError extends EconomyState {
  const EconomyError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
