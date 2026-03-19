import 'package:aslan_pixel/features/auth/data/models/user_model.dart';

/// Abstract contract for all authentication operations.
/// Implementations live in datasources/ and may be swapped for testing.
abstract class AuthRepository {
  /// Sign in via Google OAuth → Firebase credential.
  /// Returns [UserModel] on success, null if the user cancels.
  Future<UserModel?> signInWithGoogle();

  /// Sign in via Apple ID → Firebase credential.
  /// Returns [UserModel] on success, null if the user cancels.
  Future<UserModel?> signInWithApple();

  /// Sign in with email + password through Firebase Auth.
  /// Throws [FirebaseAuthException] on failure so the BLoC can map
  /// error codes to human-readable messages.
  Future<UserModel?> signInWithEmailPassword(String email, String password);

  /// Create a new account with email + password + display name.
  Future<UserModel?> signUpWithEmail(
      String email, String password, String displayName);

  /// Sign in anonymously as a guest.
  Future<UserModel?> signInAsGuest();

  /// Send email verification to the current user.
  Future<void> sendEmailVerification();

  /// Check whether the current user's email is verified.
  Future<bool> isEmailVerified();

  /// Send a password-reset email.
  Future<void> sendPasswordResetEmail(String email);

  /// Sign out from both the social provider and Firebase Auth.
  Future<void> signOut();

  /// Delete the current user account and all associated Firestore data.
  Future<void> deleteAccount();

  /// Link an anonymous (guest) account to email + password credentials.
  /// Preserves all existing data (coins, agents, quests, room).
  Future<UserModel?> linkGuestToEmail(String email, String password);

  /// Emits the current [UserModel] whenever the auth state changes.
  /// Emits null when the user signs out.
  Stream<UserModel?> get authStateChanges;

  /// Returns the currently signed-in [UserModel], or null if not signed in.
  UserModel? get currentUser;

  /// Whether the current user is an anonymous guest.
  bool get isGuest;
}
