import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single following relationship.
///
/// Stored at: follows/{uid}/following/{targetUid}
class FollowModel {
  const FollowModel({
    required this.targetUid,
    required this.followedAt,
  });

  final String targetUid;
  final DateTime followedAt;

  factory FollowModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FollowModel(
      targetUid: data['targetUid'] as String? ?? doc.id,
      followedAt:
          (data['followedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'targetUid': targetUid,
        'followedAt': Timestamp.fromDate(followedAt),
      };
}
