import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:aslan_pixel/features/feed/data/models/feed_post_model.dart';
import 'package:aslan_pixel/features/feed/data/repositories/feed_repository.dart';
import 'package:aslan_pixel/features/follows/data/repositories/follow_repository.dart';

part 'feed_event.dart';
part 'feed_state.dart';

/// BLoC responsible for managing the social feed.
class FeedBloc extends Bloc<FeedEvent, FeedState> {
  FeedBloc(this._repository, {this.followRepository})
      : super(const FeedInitial()) {
    on<FeedWatchStarted>(_onWatchStarted);
    on<FeedPostCreated>(_onPostCreated);
    on<FeedReactionAdded>(_onReactionAdded);
    on<FeedLoadMoreRequested>(_onLoadMore);
    on<FeedFilterToggled>(_onFilterToggled);
  }

  final FeedRepository _repository;
  final FollowRepository? followRepository;

  Future<void> _onWatchStarted(
    FeedWatchStarted event,
    Emitter<FeedState> emit,
  ) async {
    emit(const FeedLoading());
    await emit.forEach<List<FeedPostModel>>(
      _repository.watchFeed(),
      onData: FeedLoaded.new,
      onError: (_, __) => const FeedError('ไม่สามารถโหลดฟีดได้ กรุณาลองใหม่'),
    );
  }

  Future<void> _onPostCreated(
    FeedPostCreated event,
    Emitter<FeedState> emit,
  ) async {
    try {
      await _repository.createPost(
        authorUid: event.authorUid,
        content: event.content,
        contentTh: event.contentTh,
      );
      // Stream auto-updates — no manual state change needed.
    } catch (_) {
      // Swallow silently; UI can handle retry if desired.
    }
  }

  Future<void> _onReactionAdded(
    FeedReactionAdded event,
    Emitter<FeedState> emit,
  ) async {
    try {
      await _repository.addReaction(event.postId, event.emoji, event.uid);
    } catch (_) {
      // Swallow silently; stream will reflect actual state.
    }
  }

  Future<void> _onLoadMore(
    FeedLoadMoreRequested event,
    Emitter<FeedState> emit,
  ) async {
    final current = state;
    if (current is! FeedLoaded ||
        !current.hasMore ||
        current.isLoadingMore) {
      return;
    }

    emit(current.copyWith(isLoadingMore: true));
    try {
      final lastPost = current.posts.last;
      final morePosts = await _repository.fetchFeedPage(
        limit: 20,
        startAfter: lastPost.createdAt,
      );
      emit(current.copyWith(
        posts: [...current.posts, ...morePosts],
        hasMore: morePosts.length >= 20,
        isLoadingMore: false,
      ));
    } catch (_) {
      emit(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onFilterToggled(
    FeedFilterToggled event,
    Emitter<FeedState> emit,
  ) async {
    final current = state;
    if (current is! FeedLoaded) return;

    if (!event.showFollowedOnly) {
      emit(current.copyWith(showFollowedOnly: false));
      return;
    }

    // Fetch following UIDs if we don't have them yet
    if (current.followingUids.isEmpty && followRepository != null) {
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
        final uids = await followRepository!.watchFollowing(uid).first;
        emit(current.copyWith(
          showFollowedOnly: true,
          followingUids: uids,
        ));
      } catch (_) {
        emit(current.copyWith(showFollowedOnly: true));
      }
    } else {
      emit(current.copyWith(showFollowedOnly: true));
    }
  }
}
