part of 'plaza_bloc.dart';

/// Base class for all plaza events.
abstract class PlazaEvent extends Equatable {
  const PlazaEvent();

  @override
  List<Object?> get props => [];
}

/// Starts watching plaza presence and announces initial position.
class PlazaWatchStarted extends PlazaEvent {
  const PlazaWatchStarted({
    required this.uid,
    required this.x,
    required this.y,
  });

  final String uid;
  final double x;
  final double y;

  @override
  List<Object?> get props => [uid, x, y];
}

/// User tapped a new position on the plaza map.
class PlazaPositionUpdated extends PlazaEvent {
  const PlazaPositionUpdated({required this.x, required this.y});

  final double x;
  final double y;

  @override
  List<Object?> get props => [x, y];
}

/// User has left the plaza (page disposed).
class PlazaLeft extends PlazaEvent {
  const PlazaLeft({required this.uid});

  final String uid;

  @override
  List<Object?> get props => [uid];
}
