part of 'profile_bloc.dart';

/// Base class for all ProfileBloc states.
sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any load has been requested.
final class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

/// Profile data is being fetched.
final class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

/// Profile and badges are available.
final class ProfileLoaded extends ProfileState {
  const ProfileLoaded({required this.user, required this.badges});

  final UserModel user;
  final List<BadgeModel> badges;

  @override
  List<Object?> get props => [user, badges];
}

/// An update is being written to Firestore.
final class ProfileUpdating extends ProfileState {
  const ProfileUpdating({required this.user});

  final UserModel user;

  @override
  List<Object?> get props => [user];
}

/// An error occurred while loading or updating.
final class ProfileError extends ProfileState {
  const ProfileError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// The user has been successfully signed out.
final class ProfileSignedOut extends ProfileState {
  const ProfileSignedOut();
}
