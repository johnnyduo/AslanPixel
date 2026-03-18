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
  });

  final String? avatarId;
  final String? marketFocus;
  final String? riskStyle;

  OnboardingInProgress copyWith({
    String? avatarId,
    String? marketFocus,
    String? riskStyle,
  }) =>
      OnboardingInProgress(
        avatarId: avatarId ?? this.avatarId,
        marketFocus: marketFocus ?? this.marketFocus,
        riskStyle: riskStyle ?? this.riskStyle,
      );

  @override
  List<Object?> get props => [avatarId, marketFocus, riskStyle];
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
