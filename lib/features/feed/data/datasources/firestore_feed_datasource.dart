import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:aslan_pixel/features/feed/data/models/feed_post_model.dart';
import 'package:aslan_pixel/features/feed/data/repositories/feed_repository.dart';

/// Firestore-backed implementation of [FeedRepository].
class FirestoreFeedDatasource implements FeedRepository {
  FirestoreFeedDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('feedPosts');

  @override
  Stream<List<FeedPostModel>> watchFeed({int limit = 20}) {
    return _collection
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(FeedPostModel.fromFirestore)
              .toList(),
        );
  }

  @override
  Future<void> createPost({
    required String authorUid,
    required String content,
    String? contentTh,
    Map<String, dynamic> metadata = const {},
  }) async {
    await _collection.add({
      'type': 'user',
      'authorUid': authorUid,
      'content': content,
      'contentTh': contentTh,
      'metadata': metadata,
      'createdAt': FieldValue.serverTimestamp(),
      'reactions': <String, int>{},
    });
  }

  @override
  Future<List<FeedPostModel>> fetchFeedPage({
    int limit = 20,
    DateTime? startAfter,
  }) async {
    var query = _collection
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (startAfter != null) {
      query = query.startAfter([Timestamp.fromDate(startAfter)]);
    }
    final snap = await query.get();
    return snap.docs.map(FeedPostModel.fromFirestore).toList();
  }

  @override
  Future<void> addReaction(String postId, String emoji, String uid) async {
    final docRef = _collection.doc(postId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;
      final data = snapshot.data() ?? {};
      final reactions = Map<String, dynamic>.from(
        data['reactions'] as Map<String, dynamic>? ?? {},
      );
      final current = (reactions[emoji] as num?)?.toInt() ?? 0;
      reactions[emoji] = current + 1;
      transaction.update(docRef, {'reactions': reactions});
    });
  }
}
