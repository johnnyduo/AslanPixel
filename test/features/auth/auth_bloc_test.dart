import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aslan_pixel/features/auth/bloc/auth_bloc.dart';
import '../../mocks/mock_repositories.dart';
import '../../mocks/test_fixtures.dart';

void main() {
  late MockAuthRepository repo;

  setUp(() {
    repo = MockAuthRepository();
  });

  AuthBloc build() => AuthBloc(repository: repo);

  group('AuthBloc — initial state', () {
    test('initial state is AuthInitial', () {
      expect(build().state, isA<AuthInitial>());
    });
  });

  // ── Google Sign-In ─────────────────────────────────────────────────────────

  group('AuthSignInWithGoogleRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Success] on successful Google sign-in',
      build: build,
      setUp: () {
        when(() => repo.signInWithGoogle()).thenAnswer((_) async => kUser);
      },
      act: (bloc) => bloc.add(AuthSignInWithGoogleRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthSuccess>()],
      verify: (_) => verify(() => repo.signInWithGoogle()).called(1),
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Success] with correct user model',
      build: build,
      setUp: () {
        when(() => repo.signInWithGoogle()).thenAnswer((_) async => kUser);
      },
      act: (bloc) => bloc.add(AuthSignInWithGoogleRequested()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthSuccess>().having((s) => s.user.uid, 'uid', kUser.uid),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Initial] when user cancels Google sign-in (null return)',
      build: build,
      setUp: () {
        when(() => repo.signInWithGoogle()).thenAnswer((_) async => null);
      },
      act: (bloc) => bloc.add(AuthSignInWithGoogleRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthInitial>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Failure] on Google sign-in exception',
      build: build,
      setUp: () {
        when(() => repo.signInWithGoogle())
            .thenThrow(Exception('network error'));
      },
      act: (bloc) => bloc.add(AuthSignInWithGoogleRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthFailure>()],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthFailure contains non-empty message on error',
      build: build,
      setUp: () {
        when(() => repo.signInWithGoogle())
            .thenThrow(Exception('something went wrong'));
      },
      act: (bloc) => bloc.add(AuthSignInWithGoogleRequested()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthFailure>().having(
            (s) => s.message, 'message', isNotEmpty),
      ],
    );
  });

  // ── Apple Sign-In ──────────────────────────────────────────────────────────

  group('AuthSignInWithAppleRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Success] on successful Apple sign-in',
      build: build,
      setUp: () {
        when(() => repo.signInWithApple()).thenAnswer((_) async => kUser);
      },
      act: (bloc) => bloc.add(AuthSignInWithAppleRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthSuccess>()],
      verify: (_) => verify(() => repo.signInWithApple()).called(1),
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Initial] when Apple sign-in returns null (cancelled)',
      build: build,
      setUp: () {
        when(() => repo.signInWithApple()).thenAnswer((_) async => null);
      },
      act: (bloc) => bloc.add(AuthSignInWithAppleRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthInitial>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Failure] on Apple sign-in error',
      build: build,
      setUp: () {
        when(() => repo.signInWithApple()).thenThrow(Exception('Apple error'));
      },
      act: (bloc) => bloc.add(AuthSignInWithAppleRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthFailure>()],
    );
  });

  // ── Email Sign-In ──────────────────────────────────────────────────────────

  group('AuthSignInWithEmailRequested', () {
    const email = 'test@aslanpixel.com';
    const password = 'password123';

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Success] on valid credentials',
      build: build,
      setUp: () {
        when(() => repo.signInWithEmailPassword(email, password))
            .thenAnswer((_) async => kUser);
      },
      act: (bloc) =>
          bloc.add(AuthSignInWithEmailRequested(email: email, password: password)),
      expect: () => [isA<AuthLoading>(), isA<AuthSuccess>()],
      verify: (_) =>
          verify(() => repo.signInWithEmailPassword(email, password)).called(1),
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Failure] on wrong-password Firebase error',
      build: build,
      setUp: () {
        when(() => repo.signInWithEmailPassword(email, password))
            .thenThrow(Exception('wrong-password'));
      },
      act: (bloc) =>
          bloc.add(AuthSignInWithEmailRequested(email: email, password: password)),
      expect: () => [isA<AuthLoading>(), isA<AuthFailure>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Failure] on user-not-found error',
      build: build,
      setUp: () {
        when(() => repo.signInWithEmailPassword(email, password))
            .thenThrow(Exception('user-not-found'));
      },
      act: (bloc) =>
          bloc.add(AuthSignInWithEmailRequested(email: email, password: password)),
      expect: () => [isA<AuthLoading>(), isA<AuthFailure>()],
    );

    blocTest<AuthBloc, AuthState>(
      'passes correct email and password to repository',
      build: build,
      setUp: () {
        when(() => repo.signInWithEmailPassword(any(), any()))
            .thenAnswer((_) async => kUser);
      },
      act: (bloc) => bloc.add(
        AuthSignInWithEmailRequested(email: email, password: password),
      ),
      verify: (_) =>
          verify(() => repo.signInWithEmailPassword(email, password)).called(1),
    );
  });

  // ── Sign Out ───────────────────────────────────────────────────────────────

  group('AuthSignOutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, SignedOut] on successful sign-out',
      build: build,
      setUp: () {
        when(() => repo.signOut()).thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(AuthSignOutRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthSignedOut>()],
      verify: (_) => verify(() => repo.signOut()).called(1),
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Failure] when sign-out throws',
      build: build,
      setUp: () {
        when(() => repo.signOut()).thenThrow(Exception('sign out failed'));
      },
      act: (bloc) => bloc.add(AuthSignOutRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthFailure>()],
    );
  });

  // ── State equality ─────────────────────────────────────────────────────────

  group('State equality', () {
    test('AuthInitial == AuthInitial', () {
      expect(AuthInitial(), equals(AuthInitial()));
    });

    test('AuthLoading == AuthLoading', () {
      expect(AuthLoading(), equals(AuthLoading()));
    });

    test('AuthSuccess with same user are equal', () {
      expect(AuthSuccess(user: kUser), equals(AuthSuccess(user: kUser)));
    });

    test('AuthFailure with same message are equal', () {
      expect(
        AuthFailure(message: 'error'),
        equals(AuthFailure(message: 'error')),
      );
    });

    test('AuthSignedOut == AuthSignedOut', () {
      expect(AuthSignedOut(), equals(AuthSignedOut()));
    });
  });
}
