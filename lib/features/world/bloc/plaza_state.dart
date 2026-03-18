part of 'plaza_bloc.dart';

/// Base class for all plaza states.
abstract class PlazaState extends Equatable {
  const PlazaState();

  @override
  List<Object?> get props => [];
}

/// Plaza has not yet loaded.
class PlazaInitial extends PlazaState {
  const PlazaInitial();
}

/// Plaza is fetching first snapshot.
class PlazaLoading extends PlazaState {
  const PlazaLoading();
}

/// Plaza presence data is available.
class PlazaLoaded extends PlazaState {
  const PlazaLoaded(this.presences);

  final List<PlazaPresenceModel> presences;

  @override
  List<Object?> get props => [presences];
}

/// An error occurred.
class PlazaError extends PlazaState {
  const PlazaError(this.msg);

  final String msg;

  @override
  List<Object?> get props => [msg];
}
