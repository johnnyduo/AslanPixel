import 'package:aslan_pixel/core/enums/privacy_mode.dart';
import 'package:aslan_pixel/features/auth/data/models/user_model.dart';
import 'package:aslan_pixel/features/profile/data/models/badge_model.dart';

/// Abstract contract for all profile-related data operations.
abstract class ProfileRepository {
  /// Fetch the user document from Firestore for [uid].
  Future<UserModel?> getProfile(String uid);

  /// Update mutable profile fields for [uid].
  /// Only non-null parameters are written.
  Future<void> updateProfile(
    String uid, {
    String? displayName,
    String? avatarId,
    PrivacyMode? privacyMode,
    String? marketFocus,
    String? riskStyle,
  });

  /// Realtime stream of the badge sub-collection for [uid].
  Stream<List<BadgeModel>> watchBadges(String uid);

  /// Sign out from Firebase Auth (and Google if applicable).
  Future<void> signOut();
}
