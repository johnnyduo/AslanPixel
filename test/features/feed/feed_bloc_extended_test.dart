import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aslan_pixel/features/feed/bloc/feed_bloc.dart';
import '../../mocks/mock_repositories.dart';
import '../../mocks/test_fixtures.dart';

void main() {
  late MockFeedRepository repo;

  setUp(() {
    repo = MockFeedRepository();
  });

  FeedBloc build() => FeedBloc(repo);

  // ══════════════════════════════════════════════════════════════════════════
  // FeedFilterToggled
  // ══════════════════════════════════════════════════════════════════════════

  group('FeedFilterToggled', () {
    final posts = [
      kFeedPost(postId: 'post_001'),
      kFeedPost(postId: 'post_002').copyWith(authorUid: 'uid_other'),
    ];

    blocTest<FeedBloc, FeedState>(
      'setting showFollowedOnly=true emits FeedLoaded with showFollowedOnly=true',
      build: build,
      seed: () => FeedLoaded(posts),
      act: (bloc) =>
          bloc.add(const FeedFilterToggled(showFollowedOnly: true)),
      expect: () => [
        isA<FeedLoaded>()
            .having(
                (s) => s.showFollowedOnly, 'showFollowedOnly', true),
      ],
    );

    blocTest<FeedBloc, FeedState>(
      'setting showFollowedOnly=false emits FeedLoaded with showFollowedOnly=false',
      build: build,
      seed: () => FeedLoaded(posts, showFollowedOnly: true),
      act: (bloc) =>
          bloc.add(const FeedFilterToggled(showFollowedOnly: false)),
      expect: () => [
        isA<FeedLoaded>()
            .having(
                (s) => s.showFollowedOnly, 'showFollowedOnly', false),
      ],
    );

    blocTest<FeedBloc, FeedState>(
      'does nothing when state is not FeedLoaded',
      build: build,
      act: (bloc) =>
          bloc.add(const FeedFilterToggled(showFollowedOnly: true)),
      expect: () => <FeedState>[],
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // FeedLoaded — filteredPosts
  // ══════════════════════════════════════════════════════════════════════════

  group('FeedLoaded — filteredPosts', () {
    test('returns all posts when showFollowedOnly is false', () {
      final posts = [
        kFeedPost(postId: 'p1'),
        kFeedPost(postId: 'p2').copyWith(authorUid: 'other'),
      ];
      final state = FeedLoaded(posts, showFollowedOnly: false);
      expect(state.filteredPosts.length, 2);
    });

    test('returns all posts when showFollowedOnly is true but followingUids is empty',
        () {
      final posts = [
        kFeedPost(postId: 'p1'),
        kFeedPost(postId: 'p2').copyWith(authorUid: 'other'),
      ];
      final state =
          FeedLoaded(posts, showFollowedOnly: true, followingUids: const []);
      expect(state.filteredPosts.length, 2);
    });

    test('filters to only followed users when showFollowedOnly + followingUids',
        () {
      final posts = [
        kFeedPost(postId: 'p1'), // authorUid = 'uid_test_01'
        kFeedPost(postId: 'p2').copyWith(authorUid: 'other'),
        kFeedPost(postId: 'p3').copyWith(authorUid: 'uid_test_01'),
      ];
      final state = FeedLoaded(
        posts,
        showFollowedOnly: true,
        followingUids: const ['uid_test_01'],
      );
      expect(state.filteredPosts.length, 2);
      expect(
        state.filteredPosts.every((p) => p.authorUid == 'uid_test_01'),
        true,
      );
    });

    test('filteredPosts returns empty list when no posts match', () {
      final posts = [
        kFeedPost(postId: 'p1').copyWith(authorUid: 'unknown'),
      ];
      final state = FeedLoaded(
        posts,
        showFollowedOnly: true,
        followingUids: const ['uid_test_01'],
      );
      expect(state.filteredPosts, isEmpty);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // FeedLoaded — copyWith
  // ══════════════════════════════════════════════════════════════════════════

  group('FeedLoaded — copyWith', () {
    test('copyWith no args preserves all fields', () {
      final posts = [kFeedPost()];
      final state = FeedLoaded(
        posts,
        hasMore: false,
        isLoadingMore: true,
        showFollowedOnly: true,
        followingUids: const ['uid_01'],
      );
      final copied = state.copyWith();
      expect(copied.posts, state.posts);
      expect(copied.hasMore, state.hasMore);
      expect(copied.isLoadingMore, state.isLoadingMore);
      expect(copied.showFollowedOnly, state.showFollowedOnly);
      expect(copied.followingUids, state.followingUids);
    });

    test('copyWith replaces only specified fields', () {
      final posts = [kFeedPost()];
      final state = FeedLoaded(posts, hasMore: true, isLoadingMore: false);
      final copied = state.copyWith(hasMore: false, isLoadingMore: true);
      expect(copied.hasMore, false);
      expect(copied.isLoadingMore, true);
      expect(copied.posts, state.posts);
    });

    test('copyWith can update followingUids', () {
      final state = FeedLoaded([kFeedPost()]);
      final copied = state.copyWith(
        followingUids: const ['uid_01', 'uid_02'],
        showFollowedOnly: true,
      );
      expect(copied.followingUids, ['uid_01', 'uid_02']);
      expect(copied.showFollowedOnly, true);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // FeedPostModel — copyWith
  // ══════════════════════════════════════════════════════════════════════════

  group('FeedPostModel — copyWith', () {
    test('copies all fields when no arguments provided', () {
      final post = kFeedPost();
      final copied = post.copyWith();
      expect(copied.postId, post.postId);
      expect(copied.type, post.type);
      expect(copied.authorUid, post.authorUid);
      expect(copied.content, post.content);
      expect(copied.contentTh, post.contentTh);
      expect(copied.metadata, post.metadata);
      expect(copied.createdAt, post.createdAt);
      expect(copied.reactions, post.reactions);
    });

    test('replaces specified fields', () {
      final post = kFeedPost();
      final copied = post.copyWith(
        postId: 'new_id',
        type: 'system',
        content: 'New content',
      );
      expect(copied.postId, 'new_id');
      expect(copied.type, 'system');
      expect(copied.content, 'New content');
      expect(copied.authorUid, post.authorUid);
    });

    test('can set authorUid to null via sentinel', () {
      final post = kFeedPost();
      expect(post.authorUid, isNotNull);
      final copied = post.copyWith(authorUid: null);
      expect(copied.authorUid, isNull);
    });

    test('can set contentTh to null via sentinel', () {
      final post = kFeedPost();
      expect(post.contentTh, isNotNull);
      final copied = post.copyWith(contentTh: null);
      expect(copied.contentTh, isNull);
    });
  });
}
