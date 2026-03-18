import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aslan_pixel/features/feed/data/models/feed_post_model.dart';
import 'package:aslan_pixel/features/feed/data/repositories/feed_repository.dart';

part 'feed_event.dart';
part 'feed_state.dart';

/// BLoC responsible for managing the social feed.
class FeedBloc extends Bloc<FeedEvent, FeedState> {
  FeedBloc(this._repository) : super(const FeedInitial()) {
    on<FeedWatchStarted>(_onWatchStarted);
    on<FeedPostCreated>(_onPostCreated);
    on<FeedReactionAdded>(_onReactionAdded);
  }

  final FeedRepository _repository;

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
}
