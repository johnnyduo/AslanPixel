part of 'feed_bloc.dart';

/// Base class for all feed states.
abstract class FeedState extends Equatable {
  const FeedState();

  @override
  List<Object?> get props => [];
}

/// Feed has not yet been loaded.
class FeedInitial extends FeedState {
  const FeedInitial();
}

/// Feed is loading for the first time.
class FeedLoading extends FeedState {
  const FeedLoading();
}

/// Feed data is available.
class FeedLoaded extends FeedState {
  const FeedLoaded(
    this.posts, {
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  final List<FeedPostModel> posts;
  final bool hasMore;
  final bool isLoadingMore;

  FeedLoaded copyWith({
    List<FeedPostModel>? posts,
    bool? hasMore,
    bool? isLoadingMore,
  }) =>
      FeedLoaded(
        posts ?? this.posts,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );

  @override
  List<Object?> get props => [posts, hasMore, isLoadingMore];
}

/// An error occurred while loading or updating the feed.
class FeedError extends FeedState {
  const FeedError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
