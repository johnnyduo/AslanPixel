import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aslan_pixel/features/finance/bloc/prediction_event.dart';
import 'package:aslan_pixel/features/finance/bloc/prediction_state.dart';
import 'package:aslan_pixel/features/finance/data/models/prediction_entry_model.dart';
import 'package:aslan_pixel/features/finance/data/models/prediction_event_model.dart';
import 'package:aslan_pixel/features/finance/data/repositories/prediction_repository.dart';

class PredictionBloc extends Bloc<PredictionEvent, PredictionState> {
  PredictionBloc({required PredictionRepository repository})
      : _repository = repository,
        super(const PredictionInitial()) {
    on<PredictionWatchStarted>(_onWatchStarted);
    on<PredictionMyEntriesWatchStarted>(_onMyEntriesWatchStarted);
    on<PredictionEventEntered>(_onEventEntered);
    on<PredictionVotesLoaded>(_onVotesLoaded);
    on<PredictionVoteCasted>(_onVoteCasted);
  }

  final PredictionRepository _repository;

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  Future<void> _onWatchStarted(
    PredictionWatchStarted event,
    Emitter<PredictionState> emit,
  ) async {
    emit(const PredictionLoading());
    await emit.forEach<List<PredictionEventModel>>(
      _repository.watchOpenEvents(),
      onData: (events) {
        final current = state;
        if (current is PredictionLoaded) {
          return current.copyWith(events: events);
        }
        return PredictionLoaded(events: events);
      },
      onError: (error, _) => PredictionError(error.toString()),
    );
  }

  Future<void> _onMyEntriesWatchStarted(
    PredictionMyEntriesWatchStarted event,
    Emitter<PredictionState> emit,
  ) async {
    await emit.forEach<List<PredictionEntryModel>>(
      _repository.watchMyEntries(event.uid),
      onData: (entries) {
        final current = state;
        if (current is PredictionLoaded) {
          return current.copyWith(myEntries: entries);
        }
        return state;
      },
      onError: (error, _) => PredictionError(error.toString()),
    );
  }

  Future<void> _onEventEntered(
    PredictionEventEntered event,
    Emitter<PredictionState> emit,
  ) async {
    emit(const PredictionEntering());
    try {
      await _repository.enterPrediction(
        eventId: event.eventId,
        uid: event.uid,
        selectedOptionId: event.selectedOptionId,
        coinStaked: event.coinStaked,
      );
      emit(const PredictionEntered());
    } catch (e) {
      emit(PredictionError(e.toString()));
    }
  }

  Future<void> _onVotesLoaded(
    PredictionVotesLoaded event,
    Emitter<PredictionState> emit,
  ) async {
    try {
      final result = await _repository.loadVotes(
        eventId: event.eventId,
        uid: event.uid,
      );
      emit(PredictionVotesData(
        eventId: event.eventId,
        bullCount: result.bullCount,
        bearCount: result.bearCount,
        myVote: result.myVote,
      ));
    } catch (e) {
      emit(PredictionError(e.toString()));
    }
  }

  Future<void> _onVoteCasted(
    PredictionVoteCasted event,
    Emitter<PredictionState> emit,
  ) async {
    try {
      await _repository.castVote(
        eventId: event.eventId,
        uid: event.uid,
        side: event.side,
      );
      // Also enter the prediction (staking coins)
      await _repository.enterPrediction(
        eventId: event.eventId,
        uid: event.uid,
        selectedOptionId: event.selectedOptionId,
        coinStaked: event.coinStaked,
      );
      emit(PredictionVoteCastedSuccess(side: event.side));
    } catch (e) {
      emit(PredictionVoteCastError(e.toString()));
    }
  }

  // emit.forEach handles subscription lifecycle automatically.
}
