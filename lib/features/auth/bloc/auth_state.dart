part of 'auth_bloc.dart';

/// Base class for all authentication states.
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any auth action has been taken.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Auth operation is in progress (show a loader).
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Authentication succeeded — carries the signed-in user.
class AuthSuccess extends AuthState {
  const AuthSuccess({required this.user});

  final UserModel user;

  @override
  List<Object?> get props => [user.uid];
}

/// Authentication failed — carries a human-readable message.
class AuthFailure extends AuthState {
  const AuthFailure({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

/// User has successfully signed out — return to the sign-in screen.
class AuthSignedOut extends AuthState {
  const AuthSignedOut();
}

/// Email verification has been sent.
class AuthEmailVerificationSent extends AuthState {
  const AuthEmailVerificationSent();
}

/// User's account has been deleted.
class AuthAccountDeleted extends AuthState {
  const AuthAccountDeleted();
}

/// Guest account has been linked to email credentials.
class AuthGuestLinked extends AuthState {
  const AuthGuestLinked({required this.user});

  final UserModel user;

  @override
  List<Object?> get props => [user.uid];
}

/// Email verification check result.
class AuthEmailVerificationChecked extends AuthState {
  const AuthEmailVerificationChecked({required this.isVerified});

  final bool isVerified;

  @override
  List<Object?> get props => [isVerified];
}
