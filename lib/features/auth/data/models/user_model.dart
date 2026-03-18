import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/enums/user_role.dart';
import '../../../../core/enums/privacy_mode.dart';

/// Core user model stored in Firestore users/{uid}
class UserModel {
  final String? uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final String? avatarId;
  final UserRoleType role;
  final PrivacyMode privacyMode;
  final String? marketFocus;   // crypto | fx | stocks | mixed
  final String? riskStyle;     // calm | balanced | bold
  final bool onboardingComplete;
  final DateTime? createdAt;

  const UserModel({
    this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
    this.avatarId,
    this.role = UserRoleType.user,
    this.privacyMode = PrivacyMode.public,
    this.marketFocus,
    this.riskStyle,
    this.onboardingComplete = false,
    this.createdAt,
  });

  bool get isEmpty => uid == null || uid!.isEmpty;
  bool get isNotEmpty => !isEmpty;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      displayName: data['displayName'] as String?,
      email: data['email'] as String?,
      photoUrl: data['photoUrl'] as String?,
      avatarId: data['avatarId'] as String?,
      role: UserRoleTypeValue.fromString(data['role'] as String?),
      privacyMode: PrivacyModeValue.fromString(data['privacyMode'] as String?),
      marketFocus: data['marketFocus'] as String?,
      riskStyle: data['riskStyle'] as String?,
      onboardingComplete: data['onboardingComplete'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'email': email,
        'photoUrl': photoUrl,
        'avatarId': avatarId,
        'role': role.value,
        'privacyMode': privacyMode.value,
        'marketFocus': marketFocus,
        'riskStyle': riskStyle,
        'onboardingComplete': onboardingComplete,
        'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      };

  UserModel copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? photoUrl,
    String? avatarId,
    UserRoleType? role,
    PrivacyMode? privacyMode,
    String? marketFocus,
    String? riskStyle,
    bool? onboardingComplete,
    DateTime? createdAt,
  }) =>
      UserModel(
        uid: uid ?? this.uid,
        displayName: displayName ?? this.displayName,
        email: email ?? this.email,
        photoUrl: photoUrl ?? this.photoUrl,
        avatarId: avatarId ?? this.avatarId,
        role: role ?? this.role,
        privacyMode: privacyMode ?? this.privacyMode,
        marketFocus: marketFocus ?? this.marketFocus,
        riskStyle: riskStyle ?? this.riskStyle,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        createdAt: createdAt ?? this.createdAt,
      );
}
