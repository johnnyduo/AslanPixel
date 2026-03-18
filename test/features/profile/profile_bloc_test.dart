import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aslan_pixel/features/profile/bloc/profile_bloc.dart';
import 'package:aslan_pixel/features/profile/data/models/badge_model.dart';
import '../../mocks/mock_repositories.dart';
import '../../mocks/test_fixtures.dart';

void main() {
  late MockProfileRepository repo;

  setUp(() {
    repo = MockProfileRepository();
  });

  ProfileBloc build() => ProfileBloc(repo);

  group('ProfileBloc — initial state', () {
    test('initial state is ProfileInitial', () {
      expect(build().state, isA<ProfileInitial>());
    });
  });

  // ── ProfileLoadRequested ───────────────────────────────────────────────────

  group('ProfileLoadRequested', () {
    blocTest<ProfileBloc, ProfileState>(
      'emits [Loading, Loaded] with user and badges',
      build: build,
      setUp: () {
        when(() => repo.getProfile(kUser.uid!))
            .thenAnswer((_) async => kUser);
        when(() => repo.watchBadges(kUser.uid!))
            .thenAnswer((_) => Stream.value([kBadge()]));
      },
      act: (bloc) => bloc.add(ProfileLoadRequested(kUser.uid!)),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileLoaded>()
            .having((s) => s.user.uid, 'uid', kUser.uid)
            .having((s) => s.badges.length, 'badges count', 1),
      ],
      verify: (_) {
        verify(() => repo.getProfile(kUser.uid!)).called(1);
        verify(() => repo.watchBadges(kUser.uid!)).called(1);
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [Loading, Loaded] with empty badges list',
      build: build,
      setUp: () {
        when(() => repo.getProfile(any()))
            .thenAnswer((_) async => kUser);
        when(() => repo.watchBadges(any()))
            .thenAnswer((_) => Stream.value(<BadgeModel>[]));
      },
      act: (bloc) => bloc.add(ProfileLoadRequested(kUser.uid!)),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileLoaded>()
            .having((s) => s.badges, 'badges', isEmpty),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [Loading, Error] when getProfile returns null',
      build: build,
      setUp: () {
        when(() => repo.getProfile(any()))
            .thenAnswer((_) async => null);
      },
      act: (bloc) => bloc.add(ProfileLoadRequested(kUser.uid!)),
      expect: () => [isA<ProfileLoading>(), isA<ProfileError>()],
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [Loading, Error] when getProfile throws',
      build: build,
      setUp: () {
        when(() => repo.getProfile(any()))
            .thenThrow(Exception('user not found'));
      },
      act: (bloc) => bloc.add(ProfileLoadRequested(kUser.uid!)),
      expect: () => [isA<ProfileLoading>(), isA<ProfileError>()],
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [Loading, Error] when badges stream throws',
      build: build,
      setUp: () {
        when(() => repo.getProfile(any()))
            .thenAnswer((_) async => kUser);
        when(() => repo.watchBadges(any()))
            .thenAnswer((_) => Stream.error(Exception('badges error')));
      },
      act: (bloc) => bloc.add(ProfileLoadRequested(kUser.uid!)),
      expect: () => [isA<ProfileLoading>(), isA<ProfileError>()],
    );

    blocTest<ProfileBloc, ProfileState>(
      'multiple badge stream events re-emit Loaded',
      build: build,
      setUp: () {
        when(() => repo.getProfile(any()))
            .thenAnswer((_) async => kUser);
        when(() => repo.watchBadges(any())).thenAnswer(
          (_) => Stream.fromIterable([
            [kBadge(isEarned: false)],
            [kBadge(isEarned: true)],
          ]),
        );
      },
      act: (bloc) => bloc.add(ProfileLoadRequested(kUser.uid!)),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileLoaded>().having(
            (s) => s.badges.first.isEarned, 'isEarned', false),
        isA<ProfileLoaded>().having(
            (s) => s.badges.first.isEarned, 'isEarned', true),
      ],
    );
  });

  // ── ProfileUpdateRequested ─────────────────────────────────────────────────

  group('ProfileUpdateRequested', () {
    blocTest<ProfileBloc, ProfileState>(
      'calls repository updateProfile with correct args',
      build: build,
      setUp: () {
        when(() => repo.getProfile(any()))
            .thenAnswer((_) async => kUser);
        when(() => repo.watchBadges(any()))
            .thenAnswer((_) => Stream.value([kBadge()]));
        when(() => repo.updateProfile(any(), displayName: any(named: 'displayName')))
            .thenAnswer((_) async {});
      },
      act: (bloc) async {
        bloc.add(ProfileLoadRequested(kUser.uid!));
        await Future.delayed(Duration.zero);
        bloc.add(ProfileUpdateRequested(displayName: 'New Name'));
      },
      verify: (_) => verify(
        () => repo.updateProfile(kUser.uid!, displayName: 'New Name'),
      ).called(1),
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [Updating, Loading, Loaded] on successful update',
      build: build,
      setUp: () {
        when(() => repo.getProfile(any()))
            .thenAnswer((_) async => kUser);
        when(() => repo.watchBadges(any()))
            .thenAnswer((_) => Stream.value([kBadge()]));
        when(() => repo.updateProfile(any(),
              displayName: any(named: 'displayName')))
            .thenAnswer((_) async {});
      },
      act: (bloc) async {
        bloc.add(ProfileLoadRequested(kUser.uid!));
        await Future.delayed(Duration.zero);
        bloc.add(ProfileUpdateRequested(displayName: 'New Name'));
      },
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileLoaded>(),
        isA<ProfileUpdating>(),
        isA<ProfileLoading>(), // re-loads after update
        isA<ProfileLoaded>(),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits ProfileError when updateProfile throws',
      build: build,
      setUp: () {
        when(() => repo.getProfile(any()))
            .thenAnswer((_) async => kUser);
        when(() => repo.watchBadges(any()))
            .thenAnswer((_) => Stream.value([kBadge()]));
        when(() => repo.updateProfile(any(),
              displayName: any(named: 'displayName')))
            .thenThrow(Exception('update failed'));
      },
      act: (bloc) async {
        bloc.add(ProfileLoadRequested(kUser.uid!));
        await Future.delayed(Duration.zero);
        bloc.add(ProfileUpdateRequested(displayName: 'New Name'));
      },
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileLoaded>(),
        isA<ProfileUpdating>(),
        isA<ProfileError>(),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'does nothing when no profile is loaded yet',
      build: build,
      act: (bloc) => bloc.add(ProfileUpdateRequested(displayName: 'X')),
      expect: () => [],
    );
  });

  // ── ProfileSignOutRequested ────────────────────────────────────────────────

  group('ProfileSignOutRequested', () {
    blocTest<ProfileBloc, ProfileState>(
      'emits ProfileSignedOut on successful sign-out',
      build: build,
      setUp: () {
        when(() => repo.signOut()).thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(ProfileSignOutRequested()),
      expect: () => [isA<ProfileSignedOut>()],
      verify: (_) => verify(() => repo.signOut()).called(1),
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits ProfileError when signOut throws',
      build: build,
      setUp: () {
        when(() => repo.signOut())
            .thenThrow(Exception('sign out failed'));
      },
      act: (bloc) => bloc.add(ProfileSignOutRequested()),
      expect: () => [isA<ProfileError>()],
    );
  });

  // ── State equality ─────────────────────────────────────────────────────────

  group('State equality', () {
    test('ProfileInitial == ProfileInitial', () {
      expect(const ProfileInitial(), equals(const ProfileInitial()));
    });

    test('ProfileLoading == ProfileLoading', () {
      expect(const ProfileLoading(), equals(const ProfileLoading()));
    });

    test('ProfileLoaded with same references has same props', () {
      final badge = kBadge();
      final s1 = ProfileLoaded(user: kUser, badges: [badge]);
      final s2 = ProfileLoaded(user: kUser, badges: [badge]);
      expect(s1.user, equals(s2.user));
      expect(s1.badges, equals(s2.badges));
    });

    test('ProfileUpdating with same user are equal', () {
      expect(
        ProfileUpdating(user: kUser),
        equals(ProfileUpdating(user: kUser)),
      );
    });

    test('ProfileError with same message are equal', () {
      expect(
        const ProfileError('error'),
        equals(const ProfileError('error')),
      );
    });

    test('ProfileSignedOut == ProfileSignedOut', () {
      expect(const ProfileSignedOut(), equals(const ProfileSignedOut()));
    });
  });
}
