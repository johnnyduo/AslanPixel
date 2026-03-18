import 'package:aslan_pixel/features/home/data/models/room_item_model.dart';

/// Abstract contract for room data operations.
abstract class RoomRepository {
  /// Fetches the room document for [uid], or null if it does not exist yet.
  Future<RoomModel?> getRoom(String uid);

  /// Persists [room] to the backing store (merge strategy).
  Future<void> saveRoom(String uid, RoomModel room);

  /// Emits real-time updates for the room owned by [uid].
  Stream<RoomModel?> watchRoom(String uid);

  /// Places [item] in the room. Throws [StateError] if the target slot is
  /// already occupied by another item.
  Future<void> placeItem(String uid, RoomItem item);

  /// Removes the item with [itemId] from the room.
  Future<void> removeItem(String uid, String itemId);
}
