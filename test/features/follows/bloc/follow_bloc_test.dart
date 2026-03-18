import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aslan_pixel/features/follows/bloc/follow_bloc.dart';
import 'package:aslan_pixel/features/follows/data/repositories/follow_repository.dart';

// ── Mock ─────────────────────────────────────────────────────────────────────

class MockFollowRepository extends Mock implements FollowRepository {}

void main() {
  late MockFollowRepository repo;

  const kUid = 'uid_test_01';
  const kTargetUid = 'uid_test_02';

  setUp(() {
    repo = MockFollowRepository();
  });

  FollowBloc build() => FollowBloc(repo);

  // ── Initial state ─────────────────────────────────────────────────────────

  group('FollowBloc initial state', () {
    test('starts as FollowInitial', () {
      expect(build().state, isA<FollowInitial>());
    });
  });

  // ── FollowCheckRequested ──────────────────────────────────────────────────

  group('FollowCheckRequested', () {
    blocTest<FollowBloc, FollowState>(
      'emits [FollowLoading, FollowLoaded(isFollowing: false)] when not following',
      build: build,
      setUp: () {
        when(() => repo.isFollowing(kUid, kTargetUid))
            .thenAnswer((_) async => false);
        when(() => repo.getFollowerCount(kTargetUid))
            .thenAnswer((_) async => 10);
        when(() => repo.getFollowingCount(kTargetUid))
            .thenAnswer((_) async => 5);
      },
      act: (bloc) => bloc.add(
        const FollowCheckRequested(uid: kUid, targetUid: kTargetUid),
      ),
      expect: () => [
        isA<FollowLoading>(),
        isA<FollowLoaded>()
            .having((s) => s.isFollowing, 'isFollowing', false)
            .having((s) => s.followerCount, 'followerCount', 10)
            .having((s) => s.followingCount, 'followingCount', 5),
      ],
    );

    blocTest<FollowBloc, FollowState>(
      'emits [FollowLoading, FollowLoaded(isFollowing: true)] when already following',
      build: build,
      setUp: () {
        when(() => repo.isFollowing(kUid, kTargetUid))
            .thenAnswer((_) async => true);
        when(() => repo.getFollowerCount(kTargetUid))
            .thenAnswer((_) async => 42);
        when(() => repo.getFollowingCount(kTargetUid))
            .thenAnswer((_) async => 7);
      },
      act: (bloc) => bloc.add(
        const FollowCheckRequested(uid: kUid, targetUid: kTargetUid),
      ),
      expect: () => [
        isA<FollowLoading>(),
        isA<FollowLoaded>()
            .having((s) => s.isFollowing, 'isFollowing', true)
            .having((s) => s.followerCount, 'followerCount', 42),
      ],
    );

    blocTest<FollowBloc, FollowState>(
      'emits [FollowLoading, FollowError] when repository throws',
      build: build,
      setUp: () {
        when(() => repo.isFollowing(any(), any()))
            .thenThrow(Exception('network error'));
      },
      act: (bloc) => bloc.add(
        const FollowCheckRequested(uid: kUid, targetUid: kTargetUid),
      ),
      expect: () => [isA<FollowLoading>(), isA<FollowError>()],
    );
  });

  // ── FollowToggled — optimistic updates ────────────────────────────────────

  group('FollowToggled', () {
    blocTest<FollowBloc, FollowState>(
      'when not following: calls follow(), emits optimistic FollowLoaded(isFollowing: true)',
      build: build,
      seed: () => const FollowLoaded(
        isFollowing: false,
        followerCount: 10,
        followingCount: 3,
      ),
      setUp: () {
        when(() => repo.follow(kUid, kTargetUid))
            .thenAnswer((_) async {});
        // Authoritative count differs from optimistic (+2 not +1, race condition)
        // so equatable does not deduplicate the two FollowLoaded emissions.
        when(() => repo.getFollowerCount(kTargetUid))
            .thenAnswer((_) async => 12);
        when(() => repo.getFollowingCount(kTargetUid))
            .thenAnswer((_) async => 3);
      },
      act: (bloc) =>
          bloc.add(const FollowToggled(uid: kUid, targetUid: kTargetUid)),
      expect: () => [
        // Optimistic update: +1 follower, isFollowing flips to true
        isA<FollowLoaded>()
            .having((s) => s.isFollowing, 'isFollowing', true)
            .having((s) => s.followerCount, 'followerCount', 11),
        // Authoritative refresh from Firestore — different (higher) count
        isA<FollowLoaded>()
            .having((s) => s.isFollowing, 'isFollowing', true)
            .having((s) => s.followerCount, 'followerCount', 12),
      ],
      verify: (_) =>
          verify(() => repo.follow(kUid, kTargetUid)).called(1),
    );

    blocTest<FollowBloc, FollowState>(
      'when already following: calls unfollow(), emits optimistic FollowLoaded(isFollowing: false)',
      build: build,
      seed: () => const FollowLoaded(
        isFollowing: true,
        followerCount: 20,
        followingCount: 5,
      ),
      setUp: () {
        when(() => repo.unfollow(kUid, kTargetUid))
            .thenAnswer((_) async {});
        // Authoritative count differs from optimistic so states are not deduplicated.
        when(() => repo.getFollowerCount(kTargetUid))
            .thenAnswer((_) async => 18);
        when(() => repo.getFollowingCount(kTargetUid))
            .thenAnswer((_) async => 5);
      },
      act: (bloc) =>
          bloc.add(const FollowToggled(uid: kUid, targetUid: kTargetUid)),
      expect: () => [
        // Optimistic update: -1 follower, isFollowing flips to false
        isA<FollowLoaded>()
            .having((s) => s.isFollowing, 'isFollowing', false)
            .having((s) => s.followerCount, 'followerCount', 19),
        // Authoritative refresh — count corrected to 18
        isA<FollowLoaded>()
            .having((s) => s.isFollowing, 'isFollowing', false)
            .having((s) => s.followerCount, 'followerCount', 18),
      ],
      verify: (_) =>
          verify(() => repo.unfollow(kUid, kTargetUid)).called(1),
    );

    blocTest<FollowBloc, FollowState>(
      'reverts optimistic update and emits FollowError when follow() throws',
      build: build,
      seed: () => const FollowLoaded(
        isFollowing: false,
        followerCount: 10,
        followingCount: 3,
      ),
      setUp: () {
        when(() => repo.follow(any(), any()))
            .thenThrow(Exception('permission denied'));
      },
      act: (bloc) =>
          bloc.add(const FollowToggled(uid: kUid, targetUid: kTargetUid)),
      expect: () => [
        // Optimistic flip to true
        isA<FollowLoaded>().having((s) => s.isFollowing, 'isFollowing', true),
        // Revert to original state
        isA<FollowLoaded>().having((s) => s.isFollowing, 'isFollowing', false),
        // Error state
        isA<FollowError>(),
      ],
    );

    blocTest<FollowBloc, FollowState>(
      'followerCount cannot go below 0 when optimistic unfollow from 0 followers',
      build: build,
      seed: () => const FollowLoaded(
        isFollowing: true,
        followerCount: 0,
        followingCount: 0,
      ),
      setUp: () {
        when(() => repo.unfollow(any(), any())).thenAnswer((_) async {});
        // Authoritative followingCount differs (1) so the second state is not
        // deduplicated by equatable and both emissions are observable.
        when(() => repo.getFollowerCount(any())).thenAnswer((_) async => 0);
        when(() => repo.getFollowingCount(any())).thenAnswer((_) async => 1);
      },
      act: (bloc) =>
          bloc.add(const FollowToggled(uid: kUid, targetUid: kTargetUid)),
      expect: () => [
        // Optimistic: clamp at 0 — followerCount must NOT go to -1
        isA<FollowLoaded>()
            .having((s) => s.followerCount, 'followerCount', 0)
            .having((s) => s.isFollowing, 'isFollowing', false),
        // Authoritative refresh — followingCount updated to 1
        isA<FollowLoaded>()
            .having((s) => s.followerCount, 'followerCount', 0)
            .having((s) => s.followingCount, 'followingCount', 1),
      ],
    );
  });

  // ── FollowCountsRequested ─────────────────────────────────────────────────

  group('FollowCountsRequested', () {
    blocTest<FollowBloc, FollowState>(
      'updates follower and following counts in FollowLoaded state',
      build: build,
      seed: () => const FollowLoaded(
        isFollowing: true,
        followerCount: 5,
        followingCount: 2,
      ),
      setUp: () {
        when(() => repo.getFollowerCount(kTargetUid))
            .thenAnswer((_) async => 7);
        when(() => repo.getFollowingCount(kTargetUid))
            .thenAnswer((_) async => 3);
      },
      act: (bloc) =>
          bloc.add(const FollowCountsRequested(targetUid: kTargetUid)),
      expect: () => [
        isA<FollowLoaded>()
            .having((s) => s.followerCount, 'followerCount', 7)
            .having((s) => s.followingCount, 'followingCount', 3)
            .having((s) => s.isFollowing, 'isFollowing', true),
      ],
    );

    blocTest<FollowBloc, FollowState>(
      'emits FollowError when getFollowerCount throws',
      build: build,
      setUp: () {
        when(() => repo.getFollowerCount(any()))
            .thenThrow(Exception('network error'));
      },
      act: (bloc) =>
          bloc.add(const FollowCountsRequested(targetUid: kTargetUid)),
      expect: () => [isA<FollowError>()],
    );
  });
}
