import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aslan_pixel/features/home/bloc/room_event.dart';
import 'package:aslan_pixel/features/home/bloc/room_state.dart';
import 'package:aslan_pixel/features/home/data/models/room_item_model.dart';
import 'package:aslan_pixel/features/home/data/repositories/room_repository.dart';

/// BLoC that manages the user's pixel room state.
class RoomBloc extends Bloc<RoomEvent, RoomState> {
  RoomBloc({required RoomRepository repository})
      : _repository = repository,
        super(const RoomInitial()) {
    on<RoomLoadRequested>(_onLoadRequested);
    on<RoomItemPlaced>(_onItemPlaced);
    on<RoomItemRemoved>(_onItemRemoved);
  }

  final RoomRepository _repository;
  StreamSubscription<RoomModel?>? _roomSub;

  // ── Handlers ──────────────────────────────────────────────────────────────

  Future<void> _onLoadRequested(
    RoomLoadRequested event,
    Emitter<RoomState> emit,
  ) async {
    emit(const RoomLoading());

    // Cancel any previous subscription before starting a new one.
    await _roomSub?.cancel();

    // If the room does not exist yet, create a starter room first.
    final existing = await _repository.getRoom(event.uid);
    if (existing == null) {
      final starter = RoomModel.starter(event.uid);
      await _repository.saveRoom(event.uid, starter);
    }

    // Stream real-time updates.
    await emit.forEach<RoomModel?>(
      _repository.watchRoom(event.uid),
      onData: (room) =>
          room != null ? RoomLoaded(room) : const RoomLoading(),
      onError: (error, _) => RoomError(error.toString()),
    );
  }

  Future<void> _onItemPlaced(
    RoomItemPlaced event,
    Emitter<RoomState> emit,
  ) async {
    try {
      await _repository.placeItem(event.uid, event.item);
      // The stream subscription will emit the updated RoomLoaded state
      // automatically once Firestore confirms the write.
    } catch (e) {
      emit(RoomError(e.toString()));
    }
  }

  Future<void> _onItemRemoved(
    RoomItemRemoved event,
    Emitter<RoomState> emit,
  ) async {
    try {
      await _repository.removeItem(event.uid, event.itemId);
    } catch (e) {
      emit(RoomError(e.toString()));
    }
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  Future<void> close() async {
    await _roomSub?.cancel();
    return super.close();
  }
}
