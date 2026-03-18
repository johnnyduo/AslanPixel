part of 'economy_bloc.dart';

abstract class EconomyEvent extends Equatable {
  const EconomyEvent();

  @override
  List<Object?> get props => [];
}

/// Start streaming the live economy balance for [uid].
class EconomyWatchStarted extends EconomyEvent {
  const EconomyWatchStarted(this.uid);

  final String uid;

  @override
  List<Object?> get props => [uid];
}

/// Add [amount] coins to [uid]'s balance, logging [reason].
class EconomyCoinsAdded extends EconomyEvent {
  const EconomyCoinsAdded({
    required this.uid,
    required this.amount,
    required this.reason,
  });

  final String uid;
  final int amount;
  final String reason;

  @override
  List<Object?> get props => [uid, amount, reason];
}

/// Deduct [amount] coins from [uid]'s balance, logging [reason].
/// Throws [InsufficientCoinsException] if balance is insufficient.
class EconomyCoinsDeducted extends EconomyEvent {
  const EconomyCoinsDeducted({
    required this.uid,
    required this.amount,
    required this.reason,
  });

  final String uid;
  final int amount;
  final String reason;

  @override
  List<Object?> get props => [uid, amount, reason];
}
