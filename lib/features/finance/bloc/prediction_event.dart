import 'package:equatable/equatable.dart';

abstract class PredictionEvent extends Equatable {
  const PredictionEvent();

  @override
  List<Object?> get props => [];
}

/// Start watching open prediction events from Firestore.
class PredictionWatchStarted extends PredictionEvent {
  const PredictionWatchStarted();
}

/// Enter a prediction event by staking coins on an option.
class PredictionEventEntered extends PredictionEvent {
  const PredictionEventEntered({
    required this.eventId,
    required this.uid,
    required this.selectedOptionId,
    required this.coinStaked,
  });

  final String eventId;
  final String uid;
  final String selectedOptionId;
  final int coinStaked;

  @override
  List<Object?> get props => [eventId, uid, selectedOptionId, coinStaked];
}

/// Start watching the current user's prediction entries.
class PredictionMyEntriesWatchStarted extends PredictionEvent {
  const PredictionMyEntriesWatchStarted(this.uid);

  final String uid;

  @override
  List<Object?> get props => [uid];
}
