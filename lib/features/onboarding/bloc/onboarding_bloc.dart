import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'onboarding_event.dart';
part 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        super(const OnboardingInitial()) {
    on<OnboardingAvatarSelected>(_onAvatarSelected);
    on<OnboardingMarketFocusSelected>(_onMarketFocusSelected);
    on<OnboardingRiskStyleSelected>(_onRiskStyleSelected);
    on<OnboardingUsernameChanged>(_onUsernameChanged);
    on<OnboardingCompleted>(_onCompleted);
  }

  final FirebaseFirestore _firestore;

  void _onAvatarSelected(
    OnboardingAvatarSelected event,
    Emitter<OnboardingState> emit,
  ) {
    final current = _currentProgress();
    emit(current.copyWith(avatarId: event.avatarId));
  }

  void _onMarketFocusSelected(
    OnboardingMarketFocusSelected event,
    Emitter<OnboardingState> emit,
  ) {
    final current = _currentProgress();
    emit(current.copyWith(marketFocus: event.focus));
  }

  void _onRiskStyleSelected(
    OnboardingRiskStyleSelected event,
    Emitter<OnboardingState> emit,
  ) {
    final current = _currentProgress();
    emit(current.copyWith(riskStyle: event.style));
  }

  void _onUsernameChanged(
    OnboardingUsernameChanged event,
    Emitter<OnboardingState> emit,
  ) {
    final current = _currentProgress();
    emit(current.copyWith(username: event.username));
  }

  Future<void> _onCompleted(
    OnboardingCompleted event,
    Emitter<OnboardingState> emit,
  ) async {
    final progress = _currentProgress();
    emit(const OnboardingSubmitting());

    try {
      await _firestore.collection('users').doc(event.uid).update({
        'avatarId': progress.avatarId,
        'marketFocus': progress.marketFocus,
        'riskStyle': progress.riskStyle,
        if (progress.username != null && progress.username!.isNotEmpty)
          'username': progress.username,
        'onboardingComplete': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      emit(const OnboardingDone());
    } catch (e) {
      emit(OnboardingError(e.toString()));
    }
  }

  /// Returns the current [OnboardingInProgress] state, or a blank one if
  /// we are still at [OnboardingInitial] (e.g., first selection event).
  OnboardingInProgress _currentProgress() {
    final s = state;
    if (s is OnboardingInProgress) return s;
    return const OnboardingInProgress();
  }
}
