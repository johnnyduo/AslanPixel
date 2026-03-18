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
