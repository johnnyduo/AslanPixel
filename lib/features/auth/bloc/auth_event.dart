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

/// Fired when the user taps the sign-out button.
class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}
