import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aslan_pixel/features/auth/bloc/auth_bloc.dart';
import 'package:aslan_pixel/features/auth/data/models/user_model.dart';
import '../../mocks/mock_repositories.dart';
import '../../mocks/test_fixtures.dart';

/// Comprehensive auth tests covering all sign-in methods, sign-up,
/// sign-out, account deletion, guest linking, and email verification.
void main() {
  late MockAuthRepository repo;

  setUp(() {
    repo = MockAuthRepository();
  });

  AuthBloc build() => AuthBloc(repository: repo);

  group('AuthBloc -- initial state', () {
    test('initial state is AuthInitial', () {
      expect(build().state, isA<AuthInitial>());
    });
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
      act: (bloc) => bloc.add(
        const AuthSignInWithEmailRequested(email: email, password: password),
      ),
      expect: () => [isA<AuthLoading>(), isA<AuthSuccess>()],
      verify: (_) =>
          verify(() => repo.signInWithEmailPassword(email, password)).called(1),
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Failure] when null returned',
      build: build,
      setUp: () {
        when(() => repo.signInWithEmailPassword(email, password))
            .thenAnswer((_) async => null);
      },
      act: (bloc) => bloc.add(
        const AuthSignInWithEmailRequested(email: email, password: password),
      ),
      expect: () => [isA<AuthLoading>(), isA<AuthFailure>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Failure] on exception',
      build: build,
      setUp: () {
        when(() => repo.signInWithEmailPassword(email, password))
            .thenThrow(Exception('wrong-password'));
      },
      act: (bloc) => bloc.add(
        const AuthSignInWithEmailRequested(email: email, password: password),
      ),
      expect: () => [isA<AuthLoading>(), isA<AuthFailure>()],
    );
  });

  // ── Google Sign-In ─────────────────────────────────────────────────────────

  group('AuthSignInWithGoogleRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Success] on successful Google sign-in',
      build: build,
      setUp: () {
        when(() => repo.signInWithGoogle()).thenAnswer((_) async => kUser);
      },
      act: (bloc) => bloc.add(const AuthSignInWithGoogleRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthSuccess>()],
      verify: (_) => verify(() => repo.signInWithGoogle()).called(1),
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Initial] when user cancels (null)',
      build: build,
      setUp: () {
        when(() => repo.signInWithGoogle()).thenAnswer((_) async => null);
      },
      act: (bloc) => bloc.add(const AuthSignInWithGoogleRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthInitial>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Failure] on exception',
      build: build,
      setUp: () {
        when(() => repo.signInWithGoogle())
            .thenThrow(Exception('network error'));
      },
      act: (bloc) => bloc.add(const AuthSignInWithGoogleRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthFailure>()],
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
      act: (bloc) => bloc.add(const AuthSignInWithAppleRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthSuccess>()],
      verify: (_) => verify(() => repo.signInWithApple()).called(1),
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Initial] when cancelled (null)',
      build: build,
      setUp: () {
        when(() => repo.signInWithApple()).thenAnswer((_) async => null);
      },
      act: (bloc) => bloc.add(const AuthSignInWithAppleRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthInitial>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Failure] on exception',
      build: build,
      setUp: () {
        when(() => repo.signInWithApple()).thenThrow(Exception('Apple error'));
      },
      act: (bloc) => bloc.add(const AuthSignInWithAppleRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthFailure>()],
    );
  });

  // ── Guest Sign-In ──────────────────────────────────────────────────────────

  group('AuthSignInAsGuestRequested', () {
    const kGuestUser = UserModel(
      uid: 'uid_guest_01',
      displayName: 'ผู้เยี่ยมชม',
      email: null,
      photoUrl: null,
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Success] on successful guest sign-in',
      build: build,
      setUp: () {
        when(() => repo.signInAsGuest()).thenAnswer((_) async => kGuestUser);
      },
      act: (bloc) => bloc.add(const AuthSignInAsGuestRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthSuccess>()],
      verify: (_) => verify(() => repo.signInAsGuest()).called(1),
    );

    blocTest<AuthBloc, AuthState>(
      'AuthSuccess carries guest user model',
      build: build,
      setUp: () {
        when(() => repo.signInAsGuest()).thenAnswer((_) async => kGuestUser);
      },
      act: (bloc) => bloc.add(const AuthSignInAsGuestRequested()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthSuccess>().having(
          (s) => s.user.displayName,
          'displayName',
          'ผู้เยี่ยมชม',
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Failure] when null returned',
      build: build,
      setUp: () {
        when(() => repo.signInAsGuest()).thenAnswer((_) async => null);
      },
      act: (bloc) => bloc.add(const AuthSignInAsGuestRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthFailure>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Failure] on exception',
      build: build,
      setUp: () {
        when(() => repo.signInAsGuest()).thenThrow(Exception('auth error'));
      },
      act: (bloc) => bloc.add(const AuthSignInAsGuestRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthFailure>()],
    );
  });

  // ── Email Sign-Up ──────────────────────────────────────────────────────────

  group('AuthSignUpWithEmailRequested', () {
    const email = 'new@aslanpixel.com';
    const password = 'securePass123';
    const displayName = 'New User';

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Success] on successful sign-up',
      build: build,
      setUp: () {
        when(() => repo.signUpWithEmail(email, password, displayName))
            .thenAnswer((_) async => kUserOnboarding);
      },
      act: (bloc) => bloc.add(const AuthSignUpWithEmailRequested(
        email: email,
        password: password,
        displayName: displayName,
      )),
      expect: () => [isA<AuthLoading>(), isA<AuthSuccess>()],
      verify: (_) => verify(
        () => repo.signUpWithEmail(email, password, displayName),
      ).called(1),
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Failure] when null returned',
      build: build,
      setUp: () {
        when(() => repo.signUpWithEmail(email, password, displayName))
            .thenAnswer((_) async => null);
      },
      act: (bloc) => bloc.add(const AuthSignUpWithEmailRequested(
        email: email,
        password: password,
        displayName: displayName,
      )),
      expect: () => [isA<AuthLoading>(), isA<AuthFailure>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Failure] on email-already-in-use error',
      build: build,
      setUp: () {
        when(() => repo.signUpWithEmail(email, password, displayName))
            .thenThrow(Exception('email-already-in-use'));
      },
      act: (bloc) => bloc.add(const AuthSignUpWithEmailRequested(
        email: email,
        password: password,
        displayName: displayName,
      )),
      expect: () => [isA<AuthLoading>(), isA<AuthFailure>()],
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
      act: (bloc) => bloc.add(const AuthSignOutRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthSignedOut>()],
      verify: (_) => verify(() => repo.signOut()).called(1),
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Failure] when sign-out throws',
      build: build,
      setUp: () {
        when(() => repo.signOut()).thenThrow(Exception('sign out failed'));
      },
      act: (bloc) => bloc.add(const AuthSignOutRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthFailure>()],
    );
  });

  // ── Account Deletion ───────────────────────────────────────────────────────

  group('AuthDeleteAccountRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, AccountDeleted] on successful deletion',
      build: build,
      setUp: () {
        when(() => repo.deleteAccount()).thenAnswer((_) async {});
      },
      act: (bloc) => bloc.add(const AuthDeleteAccountRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthAccountDeleted>()],
      verify: (_) => verify(() => repo.deleteAccount()).called(1),
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Failure] on deletion error',
      build: build,
      setUp: () {
        when(() => repo.deleteAccount())
            .thenThrow(Exception('delete failed'));
      },
      act: (bloc) => bloc.add(const AuthDeleteAccountRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthFailure>()],
    );
  });

  // ── Guest Account Linking ──────────────────────────────────────────────────

  group('AuthLinkGuestAccountRequested', () {
    const email = 'upgrade@aslanpixel.com';
    const password = 'newPass123';

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, GuestLinked] on successful linking',
      build: build,
      setUp: () {
        when(() => repo.linkGuestToEmail(email, password))
            .thenAnswer((_) async => kUser);
      },
      act: (bloc) => bloc.add(const AuthLinkGuestAccountRequested(
        email: email,
        password: password,
      )),
      expect: () => [isA<AuthLoading>(), isA<AuthGuestLinked>()],
      verify: (_) =>
          verify(() => repo.linkGuestToEmail(email, password)).called(1),
    );

    blocTest<AuthBloc, AuthState>(
      'AuthGuestLinked carries correct user model',
      build: build,
      setUp: () {
        when(() => repo.linkGuestToEmail(email, password))
            .thenAnswer((_) async => kUser);
      },
      act: (bloc) => bloc.add(const AuthLinkGuestAccountRequested(
        email: email,
        password: password,
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthGuestLinked>().having(
          (s) => s.user.uid,
          'uid',
          kUser.uid,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Failure] when null returned',
      build: build,
      setUp: () {
        when(() => repo.linkGuestToEmail(email, password))
            .thenAnswer((_) async => null);
      },
      act: (bloc) => bloc.add(const AuthLinkGuestAccountRequested(
        email: email,
        password: password,
      )),
      expect: () => [isA<AuthLoading>(), isA<AuthFailure>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Failure] on exception',
      build: build,
      setUp: () {
        when(() => repo.linkGuestToEmail(email, password))
            .thenThrow(Exception('credential-already-in-use'));
      },
      act: (bloc) => bloc.add(const AuthLinkGuestAccountRequested(
        email: email,
        password: password,
      )),
      expect: () => [isA<AuthLoading>(), isA<AuthFailure>()],
    );
  });

  // ── Email Verification ─────────────────────────────────────────────────────

  group('AuthSendEmailVerificationRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, EmailVerificationSent] on success',
      build: build,
      setUp: () {
        when(() => repo.sendEmailVerification()).thenAnswer((_) async {});
      },
      act: (bloc) =>
          bloc.add(const AuthSendEmailVerificationRequested()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthEmailVerificationSent>(),
      ],
      verify: (_) =>
          verify(() => repo.sendEmailVerification()).called(1),
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Failure] on exception',
      build: build,
      setUp: () {
        when(() => repo.sendEmailVerification())
            .thenThrow(Exception('send failed'));
      },
      act: (bloc) =>
          bloc.add(const AuthSendEmailVerificationRequested()),
      expect: () => [isA<AuthLoading>(), isA<AuthFailure>()],
    );
  });

  group('AuthCheckEmailVerificationRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [EmailVerificationChecked(true)] when verified',
      build: build,
      setUp: () {
        when(() => repo.isEmailVerified()).thenAnswer((_) async => true);
      },
      act: (bloc) =>
          bloc.add(const AuthCheckEmailVerificationRequested()),
      expect: () => [
        isA<AuthEmailVerificationChecked>().having(
          (s) => s.isVerified,
          'isVerified',
          true,
        ),
      ],
      verify: (_) =>
          verify(() => repo.isEmailVerified()).called(1),
    );

    blocTest<AuthBloc, AuthState>(
      'emits [EmailVerificationChecked(false)] when not verified',
      build: build,
      setUp: () {
        when(() => repo.isEmailVerified()).thenAnswer((_) async => false);
      },
      act: (bloc) =>
          bloc.add(const AuthCheckEmailVerificationRequested()),
      expect: () => [
        isA<AuthEmailVerificationChecked>().having(
          (s) => s.isVerified,
          'isVerified',
          false,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [Failure] on exception',
      build: build,
      setUp: () {
        when(() => repo.isEmailVerified())
            .thenThrow(Exception('check failed'));
      },
      act: (bloc) =>
          bloc.add(const AuthCheckEmailVerificationRequested()),
      expect: () => [isA<AuthFailure>()],
    );
  });

  // ── State equality ─────────────────────────────────────────────────────────

  group('State equality', () {
    test('AuthInitial == AuthInitial', () {
      expect(const AuthInitial(), equals(const AuthInitial()));
    });

    test('AuthLoading == AuthLoading', () {
      expect(const AuthLoading(), equals(const AuthLoading()));
    });

    test('AuthSuccess with same user are equal', () {
      expect(
        const AuthSuccess(user: kUser),
        equals(const AuthSuccess(user: kUser)),
      );
    });

    test('AuthFailure with same message are equal', () {
      expect(
        const AuthFailure(message: 'error'),
        equals(const AuthFailure(message: 'error')),
      );
    });

    test('AuthSignedOut == AuthSignedOut', () {
      expect(const AuthSignedOut(), equals(const AuthSignedOut()));
    });

    test('AuthAccountDeleted == AuthAccountDeleted', () {
      expect(const AuthAccountDeleted(), equals(const AuthAccountDeleted()));
    });

    test('AuthEmailVerificationSent == AuthEmailVerificationSent', () {
      expect(
        const AuthEmailVerificationSent(),
        equals(const AuthEmailVerificationSent()),
      );
    });

    test('AuthGuestLinked with same user are equal', () {
      expect(
        const AuthGuestLinked(user: kUser),
        equals(const AuthGuestLinked(user: kUser)),
      );
    });

    test('AuthEmailVerificationChecked with same value are equal', () {
      expect(
        const AuthEmailVerificationChecked(isVerified: true),
        equals(const AuthEmailVerificationChecked(isVerified: true)),
      );
    });
  });

  // ── Event equality ─────────────────────────────────────────────────────────

  group('Event equality', () {
    test('AuthSignInWithEmailRequested props', () {
      const e1 = AuthSignInWithEmailRequested(
        email: 'a@b.com',
        password: '12345678',
      );
      const e2 = AuthSignInWithEmailRequested(
        email: 'a@b.com',
        password: '12345678',
      );
      expect(e1, equals(e2));
    });

    test('AuthSignUpWithEmailRequested props', () {
      const e1 = AuthSignUpWithEmailRequested(
        email: 'a@b.com',
        password: '12345678',
        displayName: 'Test',
      );
      const e2 = AuthSignUpWithEmailRequested(
        email: 'a@b.com',
        password: '12345678',
        displayName: 'Test',
      );
      expect(e1, equals(e2));
    });

    test('AuthLinkGuestAccountRequested props', () {
      const e1 = AuthLinkGuestAccountRequested(
        email: 'a@b.com',
        password: '12345678',
      );
      const e2 = AuthLinkGuestAccountRequested(
        email: 'a@b.com',
        password: '12345678',
      );
      expect(e1, equals(e2));
    });

    test('AuthSignInWithGoogleRequested has empty props', () {
      expect(
        const AuthSignInWithGoogleRequested().props,
        isEmpty,
      );
    });

    test('AuthSignInWithAppleRequested has empty props', () {
      expect(
        const AuthSignInWithAppleRequested().props,
        isEmpty,
      );
    });

    test('AuthSignInAsGuestRequested has empty props', () {
      expect(
        const AuthSignInAsGuestRequested().props,
        isEmpty,
      );
    });
  });
}
