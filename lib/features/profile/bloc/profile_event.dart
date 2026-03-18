part of 'profile_bloc.dart';

/// Base class for all ProfileBloc events.
sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Request to load the profile and start the badge stream for [uid].
final class ProfileLoadRequested extends ProfileEvent {
  const ProfileLoadRequested(this.uid);

  final String uid;

  @override
  List<Object?> get props => [uid];
}

/// Request to update one or more profile fields.
final class ProfileUpdateRequested extends ProfileEvent {
  const ProfileUpdateRequested({
    this.displayName,
    this.avatarId,
    this.privacyMode,
    this.marketFocus,
    this.riskStyle,
  });

  final String? displayName;
  final String? avatarId;
  final PrivacyMode? privacyMode;
  final String? marketFocus;
  final String? riskStyle;

  @override
  List<Object?> get props =>
      [displayName, avatarId, privacyMode, marketFocus, riskStyle];
}

/// Request to sign out the current user.
final class ProfileSignOutRequested extends ProfileEvent {
  const ProfileSignOutRequested();
}
