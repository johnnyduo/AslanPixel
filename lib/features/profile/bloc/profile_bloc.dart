import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aslan_pixel/core/enums/privacy_mode.dart';
import 'package:aslan_pixel/features/auth/data/models/user_model.dart';
import 'package:aslan_pixel/features/profile/data/models/badge_model.dart';
import 'package:aslan_pixel/features/profile/data/repositories/profile_repository.dart';

part 'profile_event.dart';
part 'profile_state.dart';

/// Manages profile loading, editing, badge streaming, and sign-out.
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc(this._repository) : super(const ProfileInitial()) {
    on<ProfileLoadRequested>(_onLoadRequested);
    on<ProfileUpdateRequested>(_onUpdateRequested);
    on<ProfileSignOutRequested>(_onSignOutRequested);
  }

  final ProfileRepository _repository;

  // Keeps track of the last known uid for reload after update.
  String _currentUid = '';

  Future<void> _onLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    _currentUid = event.uid;
    emit(const ProfileLoading());
    try {
      final user = await _repository.getProfile(event.uid);
      if (user == null) {
        emit(const ProfileError('ไม่พบข้อมูลผู้ใช้'));
        return;
      }
      // Stream badges; emit ProfileLoaded on every badge update.
      await emit.forEach<List<BadgeModel>>(
        _repository.watchBadges(event.uid),
        onData: (badges) => ProfileLoaded(user: user, badges: badges),
        onError: (_, __) =>
            const ProfileError('ไม่สามารถโหลดเหรียญตราได้'),
      );
    } catch (_) {
      emit(const ProfileError('เกิดข้อผิดพลาด กรุณาลองใหม่'));
    }
  }

  Future<void> _onUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<ProfileState> emit,
  ) async {
    final current = state;
    if (current is! ProfileLoaded) return;

    emit(ProfileUpdating(user: current.user));
    try {
      await _repository.updateProfile(
        _currentUid,
        displayName: event.displayName,
        avatarId: event.avatarId,
        privacyMode: event.privacyMode,
        marketFocus: event.marketFocus,
        riskStyle: event.riskStyle,
      );
      // Reload fresh data after update.
      add(ProfileLoadRequested(_currentUid));
    } catch (_) {
      emit(const ProfileError('บันทึกข้อมูลไม่สำเร็จ กรุณาลองใหม่'));
    }
  }

  Future<void> _onSignOutRequested(
    ProfileSignOutRequested event,
    Emitter<ProfileState> emit,
  ) async {
    try {
      await _repository.signOut();
      emit(const ProfileSignedOut());
    } catch (_) {
      emit(const ProfileError('ออกจากระบบไม่สำเร็จ'));
    }
  }
}
