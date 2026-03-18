import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an achievement badge that a user can earn.
/// Stored under users/{uid}/badges/{badgeId}.
class BadgeModel {
  const BadgeModel({
    required this.badgeId,
    required this.name,
    required this.nameTh,
    required this.description,
    required this.descriptionTh,
    required this.iconEmoji,
    required this.category,
    this.earnedAt,
    this.isEarned = false,
  });

  final String badgeId;
  final String name;
  final String nameTh;
  final String description;
  final String descriptionTh;
  final String iconEmoji;

  /// One of: trading | social | game | special
  final String category;

  final DateTime? earnedAt;
  final bool isEarned;

  factory BadgeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BadgeModel(
      badgeId: doc.id,
      name: data['name'] as String? ?? '',
      nameTh: data['nameTh'] as String? ?? '',
      description: data['description'] as String? ?? '',
      descriptionTh: data['descriptionTh'] as String? ?? '',
      iconEmoji: data['iconEmoji'] as String? ?? '🏅',
      category: data['category'] as String? ?? 'special',
      earnedAt: (data['earnedAt'] as Timestamp?)?.toDate(),
      isEarned: data['isEarned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'nameTh': nameTh,
        'description': description,
        'descriptionTh': descriptionTh,
        'iconEmoji': iconEmoji,
        'category': category,
        'earnedAt': earnedAt != null ? Timestamp.fromDate(earnedAt!) : null,
        'isEarned': isEarned,
      };

  BadgeModel copyWith({
    String? badgeId,
    String? name,
    String? nameTh,
    String? description,
    String? descriptionTh,
    String? iconEmoji,
    String? category,
    DateTime? earnedAt,
    bool? isEarned,
  }) =>
      BadgeModel(
        badgeId: badgeId ?? this.badgeId,
        name: name ?? this.name,
        nameTh: nameTh ?? this.nameTh,
        description: description ?? this.description,
        descriptionTh: descriptionTh ?? this.descriptionTh,
        iconEmoji: iconEmoji ?? this.iconEmoji,
        category: category ?? this.category,
        earnedAt: earnedAt ?? this.earnedAt,
        isEarned: isEarned ?? this.isEarned,
      );
}
