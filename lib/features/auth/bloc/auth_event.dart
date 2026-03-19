part of 'auth_bloc.dart';

/// Base class for all authentication events.
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Fired when the user taps the Google sign-in button.
class AuthSignInWithGoogleRequested extends AuthEvent {
  const AuthSignInWithGoogleRequested();
}

/// Fired when the user taps the Apple sign-in button.
class AuthSignInWithAppleRequested extends AuthEvent {
  const AuthSignInWithAppleRequested();
}

/// Fired when the user submits the email + password form.
class AuthSignInWithEmailRequested extends AuthEvent {
  const AuthSignInWithEmailRequested({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// Fired when the user submits the sign-up form.
class AuthSignUpWithEmailRequested extends AuthEvent {
  const AuthSignUpWithEmailRequested({
    required this.email,
    required this.password,
    required this.displayName,
  });

  final String email;
  final String password;
  final String displayName;

  @override
  List<Object?> get props => [email, password, displayName];
}

/// Fired when the user taps the guest sign-in button.
class AuthSignInAsGuestRequested extends AuthEvent {
  const AuthSignInAsGuestRequested();
}

/// Fired when the user taps the sign-out button.
class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// Fired when the user requests account deletion.
class AuthDeleteAccountRequested extends AuthEvent {
  const AuthDeleteAccountRequested();
}

/// Fired when a guest user wants to link to email + password.
class AuthLinkGuestAccountRequested extends AuthEvent {
  const AuthLinkGuestAccountRequested({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// Fired to send email verification to the current user.
class AuthSendEmailVerificationRequested extends AuthEvent {
  const AuthSendEmailVerificationRequested();
}

/// Fired to check if the current user's email is verified.
class AuthCheckEmailVerificationRequested extends AuthEvent {
  const AuthCheckEmailVerificationRequested();
}
