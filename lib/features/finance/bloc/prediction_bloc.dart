import 'dart:async';

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
  }

  final PredictionRepository _repository;
  StreamSubscription<List<PredictionEventModel>>? _eventsSubscription;
  StreamSubscription<List<PredictionEntryModel>>? _entriesSubscription;

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  Future<void> _onWatchStarted(
    PredictionWatchStarted event,
    Emitter<PredictionState> emit,
  ) async {
    emit(const PredictionLoading());
    await _eventsSubscription?.cancel();

    _eventsSubscription = _repository.watchOpenEvents().listen(
      (events) {
        final current = state;
        if (current is PredictionLoaded) {
          emit(current.copyWith(events: events));
        } else {
          emit(PredictionLoaded(events: events));
        }
      },
      onError: (Object error) {
        emit(PredictionError(error.toString()));
      },
    );
  }

  Future<void> _onMyEntriesWatchStarted(
    PredictionMyEntriesWatchStarted event,
    Emitter<PredictionState> emit,
  ) async {
    await _entriesSubscription?.cancel();

    _entriesSubscription = _repository.watchMyEntries(event.uid).listen(
      (entries) {
        final current = state;
        if (current is PredictionLoaded) {
          emit(current.copyWith(myEntries: entries));
        }
      },
      onError: (Object error) {
        emit(PredictionError(error.toString()));
      },
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

  @override
  Future<void> close() {
    _eventsSubscription?.cancel();
    _entriesSubscription?.cancel();
    return super.close();
  }
}
