import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:aslan_pixel/core/enums/privacy_mode.dart';
import 'package:aslan_pixel/features/auth/data/models/user_model.dart';
import 'package:aslan_pixel/features/profile/data/models/badge_model.dart';
import 'package:aslan_pixel/features/profile/data/repositories/profile_repository.dart';

/// Firestore-backed implementation of [ProfileRepository].
class FirestoreProfileDatasource implements ProfileRepository {
  FirestoreProfileDatasource({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  // ── ProfileRepository ──────────────────────────────────────────────────────

  @override
  Future<UserModel?> getProfile(String uid) async {
    final doc = await _userDoc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  @override
  Future<void> updateProfile(
    String uid, {
    String? displayName,
    String? avatarId,
    PrivacyMode? privacyMode,
    String? marketFocus,
    String? riskStyle,
  }) async {
    final Map<String, dynamic> data = {};
    if (displayName != null) data['displayName'] = displayName;
    if (avatarId != null) data['avatarId'] = avatarId;
    if (privacyMode != null) data['privacyMode'] = privacyMode.value;
    if (marketFocus != null) data['marketFocus'] = marketFocus;
    if (riskStyle != null) data['riskStyle'] = riskStyle;
    if (data.isEmpty) return;
    await _userDoc(uid).update(data);
  }

  @override
  Stream<List<BadgeModel>> watchBadges(String uid) {
    return _userDoc(uid)
        .collection('badges')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(BadgeModel.fromFirestore).toList());
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      GoogleSignIn.instance.signOut(),
      _auth.signOut(),
    ]);
  }
}
