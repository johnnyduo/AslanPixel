import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user's real-time presence in the Public Plaza.
class PlazaPresenceModel {
  const PlazaPresenceModel({
    required this.uid,
    this.avatarId,
    this.displayName,
    required this.x,
    required this.y,
    required this.lastSeen,
  });

  final String uid;
  final String? avatarId;
  final String? displayName;

  /// Normalised X position [0.0 – 1.0] relative to the plaza canvas width.
  final double x;

  /// Normalised Y position [0.0 – 1.0] relative to the plaza canvas height.
  final double y;

  final DateTime lastSeen;

  factory PlazaPresenceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final pos = data['position'] as Map<String, dynamic>? ?? {};
    return PlazaPresenceModel(
      uid: doc.id,
      avatarId: data['avatarId'] as String?,
      displayName: data['displayName'] as String?,
      x: (pos['x'] as num?)?.toDouble() ?? 0.5,
      y: (pos['y'] as num?)?.toDouble() ?? 0.5,
      lastSeen:
          (data['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'avatarId': avatarId,
        'displayName': displayName,
        'position': {'x': x, 'y': y},
        'lastSeen': Timestamp.fromDate(lastSeen),
      };

  PlazaPresenceModel copyWith({
    String? uid,
    Object? avatarId = _sentinel,
    Object? displayName = _sentinel,
    double? x,
    double? y,
    DateTime? lastSeen,
  }) =>
      PlazaPresenceModel(
        uid: uid ?? this.uid,
        avatarId: avatarId == _sentinel ? this.avatarId : avatarId as String?,
        displayName:
            displayName == _sentinel ? this.displayName : displayName as String?,
        x: x ?? this.x,
        y: y ?? this.y,
        lastSeen: lastSeen ?? this.lastSeen,
      );
}

const Object _sentinel = Object();
