import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:aslan_pixel/features/auth/data/models/user_model.dart';
import 'package:aslan_pixel/features/auth/data/repositories/auth_repository.dart';

/// Firebase-backed implementation of [AuthRepository].
/// Handles Google Sign-In, Apple Sign-In, email/password auth, guest auth,
/// email verification, account deletion, and guest-to-email linking.
/// Keeps a Firestore user document in sync after every sign-in.
class FirebaseAuthDatasource implements AuthRepository {
  FirebaseAuthDatasource({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Initialize Google Sign-In (call once at startup).
  /// serverClientId is optional — set for server-side token verification.
  Future<void> initGoogleSignIn({String? serverClientId}) async {
    await GoogleSignIn.instance.initialize(serverClientId: serverClientId);
  }

  // ── Public interface ────────────────────────────────────────────────────────

  @override
  Future<UserModel?> signInWithGoogle() async {
    try {
      // Trigger the Google authentication flow (v7 singleton API).
      final googleAccount = await GoogleSignIn.instance.authenticate();
      // v7: authentication only exposes idToken; accessToken is in authorization.
      final idToken = googleAccount.authentication.idToken;
      final credential = GoogleAuthProvider.credential(idToken: idToken);

      final userCredential = await _auth.signInWithCredential(credential);
      return await _syncAndBuildUserModel(
        userCredential,
        provider: 'google',
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      debugPrint('[FirebaseAuthDatasource] Google sign-in error: $e');
      rethrow;
    } catch (e) {
      debugPrint('[FirebaseAuthDatasource] Google sign-in error: $e');
      rethrow;
    }
  }

  @override
  Future<UserModel?> signInWithApple() async {
    try {
      // Generate a cryptographically-secure nonce for the Apple ID request.
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);

      // Apple only provides the name on the very first authorization.
      final givenName = appleCredential.givenName;
      final familyName = appleCredential.familyName;
      final fullName = (givenName != null || familyName != null)
          ? '${givenName ?? ''} ${familyName ?? ''}'.trim()
          : null;

      return await _syncAndBuildUserModel(
        userCredential,
        overrideDisplayName: fullName,
        provider: 'apple',
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null; // user cancelled
      debugPrint('[FirebaseAuthDatasource] Apple sign-in error: $e');
      rethrow;
    } catch (e) {
      debugPrint('[FirebaseAuthDatasource] Apple sign-in error: $e');
      rethrow;
    }
  }

  @override
  Future<UserModel?> signInWithEmailPassword(
      String email, String password) async {
    // Throws FirebaseAuthException — let callers (BLoC) handle error codes.
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return await _syncAndBuildUserModel(
      userCredential,
      provider: 'email',
    );
  }

  @override
  Future<UserModel?> signUpWithEmail(
      String email, String password, String displayName) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Update Firebase Auth profile with the chosen display name.
    await userCredential.user?.updateDisplayName(displayName);

    // Send email verification automatically after sign-up.
    await userCredential.user?.sendEmailVerification();

    return await _syncAndBuildUserModel(
      userCredential,
      overrideDisplayName: displayName,
      provider: 'email',
    );
  }

  @override
  Future<UserModel?> signInAsGuest() async {
    final userCredential = await _auth.signInAnonymously();
    return await _syncAndBuildUserModel(
      userCredential,
      overrideDisplayName: 'ผู้เยี่ยมชม',
      provider: 'anonymous',
    );
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('ไม่มีผู้ใช้ที่ลงชื่อเข้าใช้อยู่');
    await user.sendEmailVerification();
  }

  @override
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      GoogleSignIn.instance.signOut(),
      _auth.signOut(),
    ]);
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('ไม่มีผู้ใช้ที่ลงชื่อเข้าใช้อยู่');

    final uid = user.uid;

    // Delete Firestore user data first (economy sub-collections, then user doc).
    final userRef = _firestore.collection('users').doc(uid);

    // Delete economy/balance sub-document.
    try {
      await userRef.collection('economy').doc('balance').delete();
    } catch (_) {
      // Ignore if sub-doc doesn't exist.
    }

    // Delete the user document itself.
    try {
      await userRef.delete();
    } catch (_) {
      // Ignore if doc doesn't exist.
    }

    // Delete the Firebase Auth account.
    await user.delete();
  }

  @override
  Future<UserModel?> linkGuestToEmail(String email, String password) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('ไม่มีผู้ใช้ที่ลงชื่อเข้าใช้อยู่');
    if (!user.isAnonymous) {
      throw Exception('บัญชีนี้ไม่ใช่บัญชีผู้เยี่ยมชม');
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    final userCredential = await user.linkWithCredential(credential);

    // Update Firestore user doc with new email and provider.
    final uid = user.uid;
    await _firestore.collection('users').doc(uid).update({
      'email': email,
      'provider': 'email',
      'lastLoginAt': FieldValue.serverTimestamp(),
    });

    return await _fetchOrBuildUserModel(userCredential.user ?? user);
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return await _fetchOrBuildUserModel(firebaseUser);
    });
  }

  @override
  UserModel? get currentUser {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    return UserModel(
      uid: firebaseUser.uid,
      displayName: firebaseUser.displayName,
      email: firebaseUser.email,
      photoUrl: firebaseUser.photoURL,
    );
  }

  @override
  bool get isGuest => _auth.currentUser?.isAnonymous ?? false;

  // ── Private helpers ─────────────────────────────────────────────────────────

  /// Writes / merges the user document to Firestore and returns a [UserModel].
  /// Also initialises the economy balance document for new users via a
  /// Firestore transaction (coins/xp writes ONLY via transactions).
  Future<UserModel?> _syncAndBuildUserModel(
    UserCredential credential, {
    String? overrideDisplayName,
    String provider = 'email',
  }) async {
    final firebaseUser = credential.user;
    if (firebaseUser == null) return null;

    final uid = firebaseUser.uid;
    final ref = _firestore.collection('users').doc(uid);

    // Strip Apple private relay emails — they are not usable for display.
    String? email = firebaseUser.email;
    if (email != null && email.endsWith('@privaterelay.appleid.com')) {
      email = null;
    }

    final displayName = overrideDisplayName?.isNotEmpty == true
        ? overrideDisplayName
        : firebaseUser.displayName;

    // Build the data to write/merge into Firestore.
    final Map<String, dynamic> data = {
      'email': email,
      'photoUrl': firebaseUser.photoURL,
      'provider': provider,
      'lastLoginAt': FieldValue.serverTimestamp(),
      if (displayName != null && displayName.isNotEmpty)
        'displayName': displayName,
    };

    final docSnapshot = await ref.get();
    if (!docSnapshot.exists) {
      // New user: set initial document with createdAt.
      await ref.set({
        ...data,
        'displayName': displayName ??
            (email != null ? email.split('@').first : 'User'),
        'role': 'user',
        'privacyMode': 'public',
        'onboardingComplete': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Initialise economy balance via Firestore transaction (rule: economy
      // writes ONLY via transactions).
      final balanceRef = ref.collection('economy').doc('balance');
      await _firestore.runTransaction((txn) async {
        txn.set(balanceRef, {
          'coins': 100,
          'xp': 0,
          'streakDays': 0,
          'lastActiveAt': FieldValue.serverTimestamp(),
        });
      });
    } else {
      // Existing user: merge changes without overwriting protected fields.
      await ref.set(data, SetOptions(merge: true));
    }

    return await _fetchOrBuildUserModel(firebaseUser);
  }

  /// Fetches the Firestore user document and builds a [UserModel].
  /// Falls back to constructing from [User] if Firestore fetch fails.
  Future<UserModel> _fetchOrBuildUserModel(User firebaseUser) async {
    try {
      final doc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('[FirebaseAuthDatasource] Firestore fetch error: $e');
    }

    // Fallback — minimal model from Firebase Auth data.
    return UserModel(
      uid: firebaseUser.uid,
      displayName: firebaseUser.displayName,
      email: firebaseUser.email,
      photoUrl: firebaseUser.photoURL,
    );
  }

  /// Generates a cryptographically-secure random nonce string.
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Returns the SHA-256 hex digest of [input].
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
