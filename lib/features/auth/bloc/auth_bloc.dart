import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aslan_pixel/features/auth/data/models/user_model.dart';
import 'package:aslan_pixel/features/auth/data/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// BLoC responsible for all authentication flows.
///
/// Receives [AuthEvent]s, delegates to [AuthRepository], and emits
/// [AuthState]s. Business logic lives here — widgets remain pure UI.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository repository})
      : _repository = repository,
        super(const AuthInitial()) {
    on<AuthSignInWithGoogleRequested>(_onSignInWithGoogle);
    on<AuthSignInWithAppleRequested>(_onSignInWithApple);
    on<AuthSignInWithEmailRequested>(_onSignInWithEmail);
    on<AuthSignOutRequested>(_onSignOut);
  }

  final AuthRepository _repository;

  // ── Event handlers ──────────────────────────────────────────────────────────

  Future<void> _onSignInWithGoogle(
    AuthSignInWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _repository.signInWithGoogle();
      if (user != null) {
        emit(AuthSuccess(user: user));
      } else {
        // User cancelled the Google picker — go back to initial quietly.
        emit(const AuthInitial());
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(message: _mapFirebaseError(e.code)));
    } catch (e) {
      emit(const AuthFailure(message: 'เกิดข้อผิดพลาด กรุณาลองใหม่'));
    }
  }

  Future<void> _onSignInWithApple(
    AuthSignInWithAppleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _repository.signInWithApple();
      if (user != null) {
        emit(AuthSuccess(user: user));
      } else {
        // User cancelled the Apple dialog — go back to initial quietly.
        emit(const AuthInitial());
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(message: _mapFirebaseError(e.code)));
    } catch (e) {
      emit(const AuthFailure(message: 'เกิดข้อผิดพลาด กรุณาลองใหม่'));
    }
  }

  Future<void> _onSignInWithEmail(
    AuthSignInWithEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _repository.signInWithEmailPassword(
        event.email,
        event.password,
      );
      if (user != null) {
        emit(AuthSuccess(user: user));
      } else {
        emit(const AuthFailure(message: 'เกิดข้อผิดพลาด กรุณาลองใหม่'));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(message: _mapFirebaseError(e.code)));
    } catch (e) {
      emit(const AuthFailure(message: 'เกิดข้อผิดพลาด กรุณาลองใหม่'));
    }
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _repository.signOut();
      emit(const AuthSignedOut());
    } catch (e) {
      emit(const AuthFailure(message: 'ออกจากระบบไม่สำเร็จ กรุณาลองใหม่'));
    }
  }

  // ── Error mapping ───────────────────────────────────────────────────────────

  /// Maps [FirebaseAuthException] error codes to Thai user-facing messages.
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'ไม่พบบัญชีผู้ใช้นี้';
      case 'wrong-password':
      case 'invalid-credential':
        return 'รหัสผ่านไม่ถูกต้อง';
      case 'email-already-in-use':
        return 'อีเมลนี้ถูกใช้งานแล้ว';
      case 'network-request-failed':
        return 'ไม่มีการเชื่อมต่ออินเทอร์เน็ต';
      case 'too-many-requests':
        return 'พยายามเข้าสู่ระบบมากเกินไป กรุณารอสักครู่';
      case 'user-disabled':
        return 'บัญชีนี้ถูกระงับการใช้งาน';
      case 'account-exists-with-different-credential':
        return 'อีเมลนี้เชื่อมต่อกับวิธีการเข้าสู่ระบบอื่นแล้ว';
      default:
        return 'เกิดข้อผิดพลาด กรุณาลองใหม่';
    }
  }
}
