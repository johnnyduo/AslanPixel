import 'package:cloud_firestore/cloud_firestore.dart';

/// Economy balance for a single user.
///
/// Document path: users/{uid}/economy/balance
class EconomyModel {
  const EconomyModel({
    required this.coins,
    required this.xp,
    required this.unlockPoints,
    required this.lastUpdated,
  });

  final int coins;
  final int xp;

  /// Points used to unlock cosmetics / game features.
  final int unlockPoints;

  final DateTime lastUpdated;

  // ── Computed ────────────────────────────────────────────────────────────────

  /// Simple level formula: every 1000 XP = 1 level (floor), starting at 1.
  int get level => (xp ~/ 1000) + 1;

  // ── Factory ─────────────────────────────────────────────────────────────────

  factory EconomyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return EconomyModel(
      coins: data['coins'] as int? ?? 0,
      xp: data['xp'] as int? ?? 0,
      unlockPoints: data['unlockPoints'] as int? ?? 0,
      lastUpdated:
          (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // ── Serialisation ────────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'coins': coins,
        'xp': xp,
        'unlockPoints': unlockPoints,
        'lastUpdated': Timestamp.fromDate(lastUpdated),
      };

  // ── copyWith ─────────────────────────────────────────────────────────────────

  EconomyModel copyWith({
    int? coins,
    int? xp,
    int? unlockPoints,
    DateTime? lastUpdated,
  }) =>
      EconomyModel(
        coins: coins ?? this.coins,
        xp: xp ?? this.xp,
        unlockPoints: unlockPoints ?? this.unlockPoints,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );
}
