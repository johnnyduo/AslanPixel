import 'package:aslan_pixel/features/home/data/models/room_item_model.dart';

/// Base class for all Room BLoC states.
abstract class RoomState {
  const RoomState();
}

/// Room BLoC has not yet received a load request.
class RoomInitial extends RoomState {
  const RoomInitial();
}

/// Room data is being fetched or a mutation is in progress.
class RoomLoading extends RoomState {
  const RoomLoading();
}

/// Room data is available and up to date.
class RoomLoaded extends RoomState {
  const RoomLoaded(this.room);
  final RoomModel room;
}

/// An error occurred while loading or mutating room data.
class RoomError extends RoomState {
  const RoomError(this.message);
  final String message;
}
