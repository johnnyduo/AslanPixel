import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aslan_pixel/features/feed/bloc/feed_bloc.dart';
import 'package:aslan_pixel/features/feed/data/models/feed_post_model.dart';
import '../../mocks/mock_repositories.dart';
import '../../mocks/test_fixtures.dart';

void main() {
  late MockFeedRepository repo;

  setUp(() {
    repo = MockFeedRepository();
  });

  FeedBloc build() => FeedBloc(repo);

  group('FeedBloc — initial state', () {
    test('initial state is FeedInitial', () {
      expect(build().state, isA<FeedInitial>());
    });
  });

  // ── FeedWatchStarted ───────────────────────────────────────────────────────

  group('FeedWatchStarted', () {
    blocTest<FeedBloc, FeedState>(
      'emits [Loading, Loaded] with posts from stream',
      build: build,
      setUp: () {
        when(() => repo.watchFeed())
            .thenAnswer((_) => Stream.value([kFeedPost()]));
      },
      act: (bloc) => bloc.add(const FeedWatchStarted()),
      expect: () => [
        isA<FeedLoading>(),
        isA<FeedLoaded>().having((s) => s.posts.length, 'count', 1),
      ],
      verify: (_) => verify(() => repo.watchFeed()).called(1),
    );

    blocTest<FeedBloc, FeedState>(
      'emits [Loading, Loaded] with empty list when no posts',
      build: build,
      setUp: () {
        when(() => repo.watchFeed())
            .thenAnswer((_) => Stream.value(<FeedPostModel>[]));
      },
      act: (bloc) => bloc.add(const FeedWatchStarted()),
      expect: () => [
        isA<FeedLoading>(),
        isA<FeedLoaded>().having((s) => s.posts, 'posts', isEmpty),
      ],
    );

    blocTest<FeedBloc, FeedState>(
      'emits [Loading, Error] when stream throws',
      build: build,
      setUp: () {
        when(() => repo.watchFeed())
            .thenAnswer((_) => Stream.error(Exception('Firestore error')));
      },
      act: (bloc) => bloc.add(const FeedWatchStarted()),
      expect: () => [isA<FeedLoading>(), isA<FeedError>()],
    );

    blocTest<FeedBloc, FeedState>(
      'emits multiple Loaded states on stream updates',
      build: build,
      setUp: () {
        when(() => repo.watchFeed()).thenAnswer(
          (_) => Stream.fromIterable([
            [kFeedPost(postId: 'post_001')],
            [kFeedPost(postId: 'post_001'), kFeedPost(postId: 'post_002')],
          ]),
        );
      },
      act: (bloc) => bloc.add(const FeedWatchStarted()),
      expect: () => [
        isA<FeedLoading>(),
        isA<FeedLoaded>().having((s) => s.posts.length, 'count', 1),
        isA<FeedLoaded>().having((s) => s.posts.length, 'count', 2),
      ],
    );
  });

  // ── FeedPostCreated ────────────────────────────────────────────────────────

  group('FeedPostCreated', () {
    blocTest<FeedBloc, FeedState>(
      'calls repository createPost with correct args',
      build: build,
      setUp: () {
        when(() => repo.watchFeed())
            .thenAnswer((_) => Stream.value([kFeedPost()]));
        when(() => repo.createPost(
              authorUid: any(named: 'authorUid'),
              content: any(named: 'content'),
              contentTh: any(named: 'contentTh'),
            )).thenAnswer((_) async {});
      },
      act: (bloc) async {
        bloc.add(const FeedWatchStarted());
        await Future.delayed(Duration.zero);
        bloc.add(const FeedPostCreated(
          authorUid: 'uid_test_01',
          content: 'Market looks bullish!',
          contentTh: 'ตลาดดูกระทิง!',
        ));
      },
      verify: (_) => verify(
        () => repo.createPost(
          authorUid: 'uid_test_01',
          content: 'Market looks bullish!',
          contentTh: 'ตลาดดูกระทิง!',
        ),
      ).called(1),
    );

    blocTest<FeedBloc, FeedState>(
      'calls repository createPost without Thai content',
      build: build,
      setUp: () {
        when(() => repo.watchFeed())
            .thenAnswer((_) => Stream.value([kFeedPost()]));
        when(() => repo.createPost(
              authorUid: any(named: 'authorUid'),
              content: any(named: 'content'),
              contentTh: any(named: 'contentTh'),
            )).thenAnswer((_) async {});
      },
      act: (bloc) async {
        bloc.add(const FeedWatchStarted());
        await Future.delayed(Duration.zero);
        bloc.add(const FeedPostCreated(
          authorUid: 'uid_test_01',
          content: 'Market looks bullish!',
        ));
      },
      verify: (_) => verify(
        () => repo.createPost(
          authorUid: 'uid_test_01',
          content: 'Market looks bullish!',
          contentTh: null,
        ),
      ).called(1),
    );

    // FeedBloc swallows post errors silently (no FeedError emitted)
    blocTest<FeedBloc, FeedState>(
      'does not emit FeedError when createPost throws (silent fail)',
      build: build,
      setUp: () {
        when(() => repo.watchFeed())
            .thenAnswer((_) => Stream.value([kFeedPost()]));
        when(() => repo.createPost(
              authorUid: any(named: 'authorUid'),
              content: any(named: 'content'),
              contentTh: any(named: 'contentTh'),
            )).thenThrow(Exception('post failed'));
      },
      act: (bloc) async {
        bloc.add(const FeedWatchStarted());
        await Future.delayed(Duration.zero);
        bloc.add(const FeedPostCreated(
          authorUid: 'uid_test_01',
          content: 'test',
        ));
      },
      expect: () => [
        isA<FeedLoading>(),
        isA<FeedLoaded>(),
        // no FeedError — bloc swallows createPost errors
      ],
    );
  });

  // ── FeedReactionAdded ──────────────────────────────────────────────────────

  group('FeedReactionAdded', () {
    blocTest<FeedBloc, FeedState>(
      'calls repository addReaction with correct args',
      build: build,
      setUp: () {
        when(() => repo.watchFeed())
            .thenAnswer((_) => Stream.value([kFeedPost()]));
        when(() => repo.addReaction(any(), any(), any()))
            .thenAnswer((_) async {});
      },
      act: (bloc) async {
        bloc.add(const FeedWatchStarted());
        await Future.delayed(Duration.zero);
        bloc.add(FeedReactionAdded(
          postId: kFeedPost().postId,
          emoji: '🔥',
          uid: kUser.uid!,
        ));
      },
      verify: (_) => verify(
        () => repo.addReaction(kFeedPost().postId, '🔥', kUser.uid!),
      ).called(1),
    );

    blocTest<FeedBloc, FeedState>(
      'does not emit FeedError when addReaction throws (silent fail)',
      build: build,
      setUp: () {
        when(() => repo.watchFeed())
            .thenAnswer((_) => Stream.value([kFeedPost()]));
        when(() => repo.addReaction(any(), any(), any()))
            .thenThrow(Exception('reaction failed'));
      },
      act: (bloc) async {
        bloc.add(const FeedWatchStarted());
        await Future.delayed(Duration.zero);
        bloc.add(FeedReactionAdded(
          postId: kFeedPost().postId,
          emoji: '🔥',
          uid: kUser.uid!,
        ));
      },
      expect: () => [
        isA<FeedLoading>(),
        isA<FeedLoaded>(),
        // no FeedError — bloc swallows reaction errors
      ],
    );
  });

  // ── State equality ─────────────────────────────────────────────────────────

  group('State equality', () {
    test('FeedInitial == FeedInitial', () {
      expect(const FeedInitial(), equals(const FeedInitial()));
    });

    test('FeedLoading == FeedLoading', () {
      expect(const FeedLoading(), equals(const FeedLoading()));
    });

    test('FeedLoaded with same post reference has same posts', () {
      final post = kFeedPost();
      expect(FeedLoaded([post]).posts, equals(FeedLoaded([post]).posts));
    });

    test('FeedError with same message are equal', () {
      expect(
        const FeedError('error'),
        equals(const FeedError('error')),
      );
    });
  });
}
