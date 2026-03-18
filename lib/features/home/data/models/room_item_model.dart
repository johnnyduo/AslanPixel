import 'package:cloud_firestore/cloud_firestore.dart';

/// The category of a room decoration item.
enum RoomItemType { floor, furniture, decoration, plant, chest }

/// A single item placed inside a user's pixel room.
class RoomItem {
  const RoomItem({
    required this.itemId,
    required this.type,
    required this.assetKey,
    required this.slotX,
    required this.slotY,
    required this.isUnlocked,
  });

  /// Unique identifier for this item instance (usually equals [assetKey]).
  final String itemId;

  /// Category used to drive sprite sheet selection.
  final RoomItemType type;

  /// Sprite key used by the Flame asset loader (e.g. 'desk_01', 'plant_02').
  final String assetKey;

  /// Horizontal grid position (0–7).
  final int slotX;

  /// Vertical grid position (0–7).
  final int slotY;

  /// Whether this item has been unlocked by the user.
  final bool isUnlocked;

  // ── Factory ───────────────────────────────────────────────────────────────

  factory RoomItem.fromMap(Map<String, dynamic> map) {
    return RoomItem(
      itemId: map['itemId'] as String? ?? '',
      type: _typeFromString(map['type'] as String? ?? 'furniture'),
      assetKey: map['assetKey'] as String? ?? '',
      slotX: map['slotX'] as int? ?? 0,
      slotY: map['slotY'] as int? ?? 0,
      isUnlocked: map['isUnlocked'] as bool? ?? false,
    );
  }

  // ── Serialisation ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'itemId': itemId,
        'type': type.name,
        'assetKey': assetKey,
        'slotX': slotX,
        'slotY': slotY,
        'isUnlocked': isUnlocked,
      };

  // ── copyWith ──────────────────────────────────────────────────────────────

  RoomItem copyWith({
    String? itemId,
    RoomItemType? type,
    String? assetKey,
    int? slotX,
    int? slotY,
    bool? isUnlocked,
  }) =>
      RoomItem(
        itemId: itemId ?? this.itemId,
        type: type ?? this.type,
        assetKey: assetKey ?? this.assetKey,
        slotX: slotX ?? this.slotX,
        slotY: slotY ?? this.slotY,
        isUnlocked: isUnlocked ?? this.isUnlocked,
      );

  // ── Internal ──────────────────────────────────────────────────────────────

  static RoomItemType _typeFromString(String value) {
    return RoomItemType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RoomItemType.furniture,
    );
  }
}

/// The full room document stored at rooms/{uid}.
class RoomModel {
  const RoomModel({
    required this.uid,
    required this.layoutVersion,
    required this.items,
    required this.updatedAt,
  });

  final String uid;

  /// Incremented whenever the layout schema changes.
  final int layoutVersion;

  /// All items currently placed in the room.
  final List<RoomItem> items;

  final DateTime updatedAt;

  // ── Factory ───────────────────────────────────────────────────────────────

  factory RoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawItems = data['items'] as List<dynamic>? ?? [];
    return RoomModel(
      uid: doc.id,
      layoutVersion: data['layoutVersion'] as int? ?? 1,
      items: rawItems
          .map((e) => RoomItem.fromMap(e as Map<String, dynamic>))
          .toList(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // ── Starter room ──────────────────────────────────────────────────────────

  /// Returns a default room with desk, plant, and chest at fixed positions.
  static RoomModel starter(String uid) => RoomModel(
        uid: uid,
        layoutVersion: 1,
        items: const [
          RoomItem(
            itemId: 'desk_01',
            type: RoomItemType.furniture,
            assetKey: 'desk_01',
            slotX: 3,
            slotY: 2,
            isUnlocked: true,
          ),
          RoomItem(
            itemId: 'plant_01',
            type: RoomItemType.plant,
            assetKey: 'plant_01',
            slotX: 6,
            slotY: 1,
            isUnlocked: true,
          ),
          RoomItem(
            itemId: 'chest_01',
            type: RoomItemType.chest,
            assetKey: 'chest_01',
            slotX: 1,
            slotY: 5,
            isUnlocked: true,
          ),
        ],
        updatedAt: DateTime.now(),
      );

  // ── Serialisation ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'layoutVersion': layoutVersion,
        'items': items.map((i) => i.toMap()).toList(),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  // ── copyWith ──────────────────────────────────────────────────────────────

  RoomModel copyWith({
    String? uid,
    int? layoutVersion,
    List<RoomItem>? items,
    DateTime? updatedAt,
  }) =>
      RoomModel(
        uid: uid ?? this.uid,
        layoutVersion: layoutVersion ?? this.layoutVersion,
        items: items ?? this.items,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
