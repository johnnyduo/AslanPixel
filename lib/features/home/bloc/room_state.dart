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

/// A friend's room has been loaded for read-only visit.
class FriendRoomLoaded extends RoomState {
  const FriendRoomLoaded(this.friendUid, this.items);
  final String friendUid;
  final List<RoomItem> items;
}

/// A room theme was successfully purchased.
class RoomThemePurchaseSuccess extends RoomState {
  const RoomThemePurchaseSuccess(this.themeId);
  final String themeId;
}

/// The active room theme was successfully changed.
class RoomThemeChangeSuccess extends RoomState {
  const RoomThemeChangeSuccess(this.themeId);
  final String themeId;
}

/// A room theme purchase failed (e.g. insufficient coins).
class RoomThemePurchaseFailure extends RoomState {
  const RoomThemePurchaseFailure(this.message);
  final String message;
}

/// An error occurred while loading or mutating room data.
class RoomError extends RoomState {
  const RoomError(this.message);
  final String message;
}
