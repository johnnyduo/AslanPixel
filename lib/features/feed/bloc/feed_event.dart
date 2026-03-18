part of 'feed_bloc.dart';

/// Base class for all feed events.
abstract class FeedEvent extends Equatable {
  const FeedEvent();

  @override
  List<Object?> get props => [];
}

/// Starts the real-time feed subscription.
class FeedWatchStarted extends FeedEvent {
  const FeedWatchStarted();
}

/// Requests creation of a new post.
class FeedPostCreated extends FeedEvent {
  const FeedPostCreated({
    required this.authorUid,
    required this.content,
    this.contentTh,
  });

  final String authorUid;
  final String content;
  final String? contentTh;

  @override
  List<Object?> get props => [authorUid, content, contentTh];
}

/// Requests adding/incrementing a reaction on a post.
class FeedReactionAdded extends FeedEvent {
  const FeedReactionAdded({
    required this.postId,
    required this.emoji,
    required this.uid,
  });

  final String postId;
  final String emoji;
  final String uid;

  @override
  List<Object?> get props => [postId, emoji, uid];
}
