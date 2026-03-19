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

  /// Sets [isUnlocked] to true on the item with [itemId] in [uid]'s room.
  ///
  /// No-ops silently if the item does not exist.
  Future<void> unlockItem(String uid, String itemId);

  /// Fetch a friend's room for read-only visit.
  Future<List<RoomItem>> getFriendRoom(String friendUid);

  /// Purchases a room theme for [uid], deducting [price] coins atomically.
  ///
  /// Throws [InsufficientCoinsException] if the user does not have enough coins.
  /// Throws [StateError] if the theme is already owned.
  Future<void> purchaseTheme({
    required String uid,
    required String themeId,
    required int price,
  });

  /// Sets the active room theme for [uid].
  ///
  /// Throws [StateError] if the theme is not owned.
  Future<void> setActiveTheme({
    required String uid,
    required String themeId,
  });

  /// Returns the list of theme IDs owned by [uid].
  Future<List<String>> getOwnedThemes(String uid);

  /// Returns the currently active theme ID for [uid], or `'starter'` if unset.
  Future<String> getActiveTheme(String uid);
}
