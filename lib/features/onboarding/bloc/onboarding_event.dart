part of 'onboarding_bloc.dart';

abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

class OnboardingAvatarSelected extends OnboardingEvent {
  const OnboardingAvatarSelected(this.avatarId);

  final String avatarId;

  @override
  List<Object?> get props => [avatarId];
}

class OnboardingMarketFocusSelected extends OnboardingEvent {
  const OnboardingMarketFocusSelected(this.focus);

  /// One of: crypto | fx | stocks | mixed
  final String focus;

  @override
  List<Object?> get props => [focus];
}

class OnboardingRiskStyleSelected extends OnboardingEvent {
  const OnboardingRiskStyleSelected(this.style);

  /// One of: calm | balanced | bold
  final String style;

  @override
  List<Object?> get props => [style];
}

class OnboardingCompleted extends OnboardingEvent {
  const OnboardingCompleted(this.uid);

  final String uid;

  @override
  List<Object?> get props => [uid];
}
