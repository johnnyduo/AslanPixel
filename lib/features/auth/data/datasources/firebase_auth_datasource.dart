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
/// Handles Google Sign-In, Apple Sign-In, email/password auth,
/// and keeps a Firestore user document in sync after every sign-in.
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
      return await _syncAndBuildUserModel(userCredential);
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
    return await _syncAndBuildUserModel(userCredential);
  }

  @override
  Future<void> signOut() async {
    await Future.wait([
      GoogleSignIn.instance.signOut(),
      _auth.signOut(),
    ]);
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

  // ── Private helpers ─────────────────────────────────────────────────────────

  /// Writes / merges the user document to Firestore and returns a [UserModel].
  Future<UserModel?> _syncAndBuildUserModel(
    UserCredential credential, {
    String? overrideDisplayName,
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
