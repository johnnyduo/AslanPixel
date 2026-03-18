import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aslan_pixel/features/inventory/data/datasources/firestore_economy_datasource.dart';
import 'package:aslan_pixel/features/inventory/data/models/economy_model.dart';
import 'package:aslan_pixel/features/inventory/data/repositories/economy_repository.dart';

part 'economy_event.dart';
part 'economy_state.dart';

/// BLoC that manages the live coin/XP balance for the signed-in user.
///
/// - Use [EconomyWatchStarted] to begin the Firestore stream.
/// - Use [EconomyCoinsAdded] / [EconomyCoinsDeducted] to mutate the balance
///   via Firestore transactions (never direct sets).
class EconomyBloc extends Bloc<EconomyEvent, EconomyState> {
  EconomyBloc({EconomyRepository? repository})
      : _repository = repository ?? FirestoreEconomyDatasource(),
        super(const EconomyInitial()) {
    on<EconomyWatchStarted>(_onWatchStarted);
    on<EconomyCoinsAdded>(_onCoinsAdded);
    on<EconomyCoinsDeducted>(_onCoinsDeducted);
  }

  final EconomyRepository _repository;
  String? _watchedUid;

  // ── Handlers ───────────────────────────────────────────────────────────────

  Future<void> _onWatchStarted(
    EconomyWatchStarted event,
    Emitter<EconomyState> emit,
  ) async {
    // Avoid re-subscribing when already watching the same uid.
    if (_watchedUid == event.uid) return;
    _watchedUid = event.uid;

    emit(const EconomyLoading());

    await emit.forEach<EconomyModel>(
      _repository.watchEconomy(event.uid),
      onData: (model) => EconomyLoaded(
        coins: model.coins,
        xp: model.xp,
        level: model.level,
      ),
      onError: (error, _) => EconomyError(error.toString()),
    );
  }

  Future<void> _onCoinsAdded(
    EconomyCoinsAdded event,
    Emitter<EconomyState> emit,
  ) async {
    try {
      await _repository.addCoins(event.uid, event.amount, event.reason);
    } catch (e) {
      debugPrint('[EconomyBloc] addCoins error: $e');
      emit(EconomyError(e.toString()));
    }
  }

  Future<void> _onCoinsDeducted(
    EconomyCoinsDeducted event,
    Emitter<EconomyState> emit,
  ) async {
    try {
      await _repository.deductCoins(event.uid, event.amount, event.reason);
    } catch (e) {
      debugPrint('[EconomyBloc] deductCoins error: $e');
      emit(EconomyError(e.toString()));
    }
  }
}
