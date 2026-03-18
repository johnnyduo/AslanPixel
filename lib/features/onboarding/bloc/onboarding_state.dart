part of 'onboarding_bloc.dart';

abstract class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object?> get props => [];
}

class OnboardingInitial extends OnboardingState {
  const OnboardingInitial();
}

class OnboardingInProgress extends OnboardingState {
  const OnboardingInProgress({
    this.avatarId,
    this.marketFocus,
    this.riskStyle,
    this.username,
  });

  final String? avatarId;
  final String? marketFocus;
  final String? riskStyle;
  final String? username;

  OnboardingInProgress copyWith({
    String? avatarId,
    String? marketFocus,
    String? riskStyle,
    String? username,
  }) =>
      OnboardingInProgress(
        avatarId: avatarId ?? this.avatarId,
        marketFocus: marketFocus ?? this.marketFocus,
        riskStyle: riskStyle ?? this.riskStyle,
        username: username ?? this.username,
      );

  @override
  List<Object?> get props => [avatarId, marketFocus, riskStyle, username];
}

class OnboardingSubmitting extends OnboardingState {
  const OnboardingSubmitting();
}

class OnboardingDone extends OnboardingState {
  const OnboardingDone();
}

class OnboardingError extends OnboardingState {
  const OnboardingError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
