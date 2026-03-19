import 'package:aslan_pixel/features/home/data/models/room_item_model.dart';

/// Base class for all Room BLoC events.
abstract class RoomEvent {
  const RoomEvent();
}

/// Request to load (and watch) the room for [uid].
class RoomLoadRequested extends RoomEvent {
  const RoomLoadRequested(this.uid);
  final String uid;
}

/// Request to place [item] in the room owned by [uid].
class RoomItemPlaced extends RoomEvent {
  const RoomItemPlaced({required this.uid, required this.item});
  final String uid;
  final RoomItem item;
}

/// Request to remove the item identified by [itemId] from [uid]'s room.
class RoomItemRemoved extends RoomEvent {
  const RoomItemRemoved({required this.uid, required this.itemId});
  final String uid;
  final String itemId;
}

/// Request to unlock the room item [itemId] for [uid].
///
/// If the item does not yet exist in the room it is placed at the default
/// position (slotX: 0, slotY: 0) and marked as unlocked.
/// If it already exists but is locked, its [isUnlocked] flag is set to true.
class RoomItemUnlocked extends RoomEvent {
  const RoomItemUnlocked({required this.uid, required this.itemId});
  final String uid;
  final String itemId;
}

/// Request to visit a friend's room in read-only mode.
class FriendRoomVisitRequested extends RoomEvent {
  const FriendRoomVisitRequested(this.friendUid);
  final String friendUid;
}

/// Request to purchase a room theme for [uid].
///
/// Deducts [price] coins via Firestore transaction and records the theme
/// in the user's owned themes collection.
class RoomThemePurchaseRequested extends RoomEvent {
  const RoomThemePurchaseRequested({
    required this.themeId,
    required this.uid,
    required this.price,
  });

  final String themeId;
  final String uid;
  final int price;
}

/// Request to change the active room theme for [uid].
///
/// The theme must already be owned.
class RoomThemeChanged extends RoomEvent {
  const RoomThemeChanged({
    required this.themeId,
    required this.uid,
  });

  final String themeId;
  final String uid;
}
