import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single post in the social feed.
///
/// [type] is one of: system | user | achievement | prediction | ranking
class FeedPostModel {
  const FeedPostModel({
    required this.postId,
    required this.type,
    this.authorUid,
    required this.content,
    this.contentTh,
    required this.metadata,
    required this.createdAt,
    required this.reactions,
  });

  final String postId;
  final String type;
  final String? authorUid;
  final String content;
  final String? contentTh;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  /// Maps emoji string → reaction count, e.g. {"❤️": 3, "🔥": 1}
  final Map<String, int> reactions;

  factory FeedPostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawReactions = data['reactions'] as Map<String, dynamic>? ?? {};
    return FeedPostModel(
      postId: doc.id,
      type: data['type'] as String? ?? 'user',
      authorUid: data['authorUid'] as String?,
      content: data['content'] as String? ?? '',
      contentTh: data['contentTh'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reactions: rawReactions.map(
        (k, v) => MapEntry(k, (v as num).toInt()),
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type,
        'authorUid': authorUid,
        'content': content,
        'contentTh': contentTh,
        'metadata': metadata,
        'createdAt': Timestamp.fromDate(createdAt),
        'reactions': reactions,
      };

  FeedPostModel copyWith({
    String? postId,
    String? type,
    Object? authorUid = _sentinel,
    String? content,
    Object? contentTh = _sentinel,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    Map<String, int>? reactions,
  }) =>
      FeedPostModel(
        postId: postId ?? this.postId,
        type: type ?? this.type,
        authorUid: authorUid == _sentinel ? this.authorUid : authorUid as String?,
        content: content ?? this.content,
        contentTh: contentTh == _sentinel ? this.contentTh : contentTh as String?,
        metadata: metadata ?? this.metadata,
        createdAt: createdAt ?? this.createdAt,
        reactions: reactions ?? this.reactions,
      );
}

// Sentinel object for nullable copyWith parameters.
const Object _sentinel = Object();
