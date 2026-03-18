import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aslan_pixel/features/world/data/models/plaza_presence_model.dart';
import 'package:aslan_pixel/features/world/data/repositories/plaza_repository.dart';

part 'plaza_event.dart';
part 'plaza_state.dart';

/// BLoC managing real-time presence in the Public Plaza.
///
/// Position updates are debounced (3 s) to avoid Firestore write storms.
class PlazaBloc extends Bloc<PlazaEvent, PlazaState> {
  PlazaBloc(this._repository) : super(const PlazaInitial()) {
    on<PlazaWatchStarted>(_onWatchStarted);
    on<PlazaPositionUpdated>(_onPositionUpdated);
    on<PlazaLeft>(_onLeft);
  }

  final PlazaRepository _repository;

  String? _currentUid;
  double _currentX = 0.5;
  double _currentY = 0.5;
  Timer? _debounceTimer;

  // ── Event handlers ─────────────────────────────────────────────────────────

  Future<void> _onWatchStarted(
    PlazaWatchStarted event,
    Emitter<PlazaState> emit,
  ) async {
    _currentUid = event.uid;
    _currentX = event.x;
    _currentY = event.y;

    // Announce arrival immediately.
    await _repository.updateMyPresence(
      uid: event.uid,
      x: event.x,
      y: event.y,
    );

    emit(const PlazaLoading());
    await emit.forEach<List<PlazaPresenceModel>>(
      _repository.watchPresence(),
      onData: PlazaLoaded.new,
      onError: (_, __) => const PlazaError('ไม่สามารถโหลด Plaza ได้'),
    );
  }

  Future<void> _onPositionUpdated(
    PlazaPositionUpdated event,
    Emitter<PlazaState> emit,
  ) async {
    _currentX = event.x;
    _currentY = event.y;

    // Debounce Firestore writes to 3 seconds.
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 3), () {
      if (_currentUid != null) {
        _repository.updateMyPresence(
          uid: _currentUid!,
          x: _currentX,
          y: _currentY,
        );
      }
    });
  }

  Future<void> _onLeft(
    PlazaLeft event,
    Emitter<PlazaState> emit,
  ) async {
    _debounceTimer?.cancel();
    await _repository.removeMyPresence(event.uid);
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    if (_currentUid != null) {
      _repository.removeMyPresence(_currentUid!);
    }
    return super.close();
  }
}
