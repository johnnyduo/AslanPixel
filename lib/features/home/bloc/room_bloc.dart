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
    on<RoomItemUnlocked>(_onItemUnlocked);
    on<FriendRoomVisitRequested>(_onFriendVisit);
    on<RoomThemePurchaseRequested>(_onThemePurchase);
    on<RoomThemeChanged>(_onThemeChanged);
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

  Future<void> _onItemUnlocked(
    RoomItemUnlocked event,
    Emitter<RoomState> emit,
  ) async {
    try {
      final current = state;
      if (current is! RoomLoaded) return;

      final existingIndex = current.room.items
          .indexWhere((i) => i.itemId == event.itemId);

      if (existingIndex == -1) {
        // Item does not exist yet — place it at the default slot.
        await _repository.placeItem(
          event.uid,
          RoomItem(
            itemId: event.itemId,
            type: RoomItemType.decoration,
            assetKey: event.itemId,
            slotX: 0,
            slotY: 0,
            isUnlocked: true,
          ),
        );
      } else if (!current.room.items[existingIndex].isUnlocked) {
        // Item exists but is locked — unlock it.
        await _repository.unlockItem(event.uid, event.itemId);
      }
      // If already unlocked, nothing to do.
    } catch (e) {
      emit(RoomError(e.toString()));
    }
  }

  Future<void> _onFriendVisit(
    FriendRoomVisitRequested event,
    Emitter<RoomState> emit,
  ) async {
    emit(const RoomLoading());
    try {
      final items = await _repository.getFriendRoom(event.friendUid);
      emit(FriendRoomLoaded(event.friendUid, items));
    } catch (e) {
      emit(RoomError(e.toString()));
    }
  }

  Future<void> _onThemePurchase(
    RoomThemePurchaseRequested event,
    Emitter<RoomState> emit,
  ) async {
    try {
      await _repository.purchaseTheme(
        uid: event.uid,
        themeId: event.themeId,
        price: event.price,
      );
      emit(RoomThemePurchaseSuccess(event.themeId));
    } catch (e) {
      emit(RoomThemePurchaseFailure(e.toString()));
    }
  }

  Future<void> _onThemeChanged(
    RoomThemeChanged event,
    Emitter<RoomState> emit,
  ) async {
    try {
      await _repository.setActiveTheme(
        uid: event.uid,
        themeId: event.themeId,
      );
      emit(RoomThemeChangeSuccess(event.themeId));
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
