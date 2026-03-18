import 'package:aslan_pixel/features/feed/data/models/feed_post_model.dart';

/// Abstract interface for all feed data operations.
abstract class FeedRepository {
  /// Returns a real-time stream of the latest [limit] feed posts.
  Stream<List<FeedPostModel>> watchFeed({int limit = 20});

  /// Creates a new user post in the feed.
  Future<void> createPost({
    required String authorUid,
    required String content,
    String? contentTh,
    Map<String, dynamic> metadata,
  });

  /// Increments the reaction count for [emoji] on post [postId] by [uid].
  Future<void> addReaction(String postId, String emoji, String uid);
}
