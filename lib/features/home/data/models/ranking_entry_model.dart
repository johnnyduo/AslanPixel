import 'package:cloud_firestore/cloud_firestore.dart';

/// A single entry in a leaderboard period document.
///
/// Stored at: rankings/{period}/entries/{uid}
class RankingEntryModel {
  const RankingEntryModel({
    required this.uid,
    required this.score,
    required this.rank,
    required this.category,
    this.displayName,
    this.avatarId,
  });

  /// The user's uid — also the Firestore document ID.
  final String uid;

  /// Optional display name (may be null if the user has not set one).
  final String? displayName;

  /// Optional avatar asset ID.
  final String? avatarId;

  /// Numeric score used to order the leaderboard.
  final int score;

  /// Pre-computed rank position (1-based).
  final int rank;

  /// 'weekly' or 'alltime'.
  final String category;

  // ── Factory ───────────────────────────────────────────────────────────────

  factory RankingEntryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return RankingEntryModel(
      uid: doc.id,
      displayName: data['displayName'] as String?,
      avatarId: data['avatarId'] as String?,
      score: data['score'] as int? ?? 0,
      rank: data['rank'] as int? ?? 0,
      category: data['category'] as String? ?? 'weekly',
    );
  }

  // ── Serialisation ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'displayName': displayName,
        'avatarId': avatarId,
        'score': score,
        'rank': rank,
        'category': category,
      };

  // ── copyWith ──────────────────────────────────────────────────────────────

  RankingEntryModel copyWith({
    String? uid,
    String? displayName,
    String? avatarId,
    int? score,
    int? rank,
    String? category,
  }) =>
      RankingEntryModel(
        uid: uid ?? this.uid,
        displayName: displayName ?? this.displayName,
        avatarId: avatarId ?? this.avatarId,
        score: score ?? this.score,
        rank: rank ?? this.rank,
        category: category ?? this.category,
      );
}
