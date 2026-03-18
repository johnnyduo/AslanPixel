import 'package:equatable/equatable.dart';
import 'package:aslan_pixel/features/finance/data/models/prediction_entry_model.dart';
import 'package:aslan_pixel/features/finance/data/models/prediction_event_model.dart';

abstract class PredictionState extends Equatable {
  const PredictionState();

  @override
  List<Object?> get props => [];
}

class PredictionInitial extends PredictionState {
  const PredictionInitial();
}

class PredictionLoading extends PredictionState {
  const PredictionLoading();
}

class PredictionLoaded extends PredictionState {
  const PredictionLoaded({
    required this.events,
    this.myEntries = const [],
  });

  final List<PredictionEventModel> events;
  final List<PredictionEntryModel> myEntries;

  PredictionLoaded copyWith({
    List<PredictionEventModel>? events,
    List<PredictionEntryModel>? myEntries,
  }) {
    return PredictionLoaded(
      events: events ?? this.events,
      myEntries: myEntries ?? this.myEntries,
    );
  }

  @override
  List<Object?> get props => [events, myEntries];
}

class PredictionEntering extends PredictionState {
  const PredictionEntering();
}

class PredictionEntered extends PredictionState {
  const PredictionEntered();
}

class PredictionError extends PredictionState {
  const PredictionError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
