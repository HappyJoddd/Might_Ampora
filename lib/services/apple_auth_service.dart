import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'api_service.dart';
import 'auth_storage.dart';

class AppleAuthService {
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Returns true only on iOS / macOS — hides the button on Android / web.
  static bool get isAvailable => Platform.isIOS || Platform.isMacOS;

  /// Full Apple Sign-In flow:
  /// 1. Native Apple credential
  /// 2. Firebase Auth sign-in
  /// 3. Send Firebase ID token to our backend
  /// 4. Store tokens locally
  static Future<Map<String, dynamic>> signIn() async {
    try {
      // ---------- Step 1: Get Apple credential ----------
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // ---------- Step 2: Sign in to Firebase ----------
      final oAuthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(oAuthCredential);

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return {'success': false, 'error': 'Firebase sign-in failed'};
      }

      // ---------- Step 3: Get Firebase ID token ----------
      final idToken = await firebaseUser.getIdToken();
      if (idToken == null) {
        return {'success': false, 'error': 'Failed to get Firebase ID token'};
      }

      // Apple only returns the name on the FIRST sign-in, so capture it.
      final fullName = _buildFullName(appleCredential);

      // ---------- Step 4: Authenticate with our backend ----------
      final response = await ApiService.signInWithApple(
        idToken: idToken,
        name: fullName,
      );

      if (response['success'] != true) {
        return {
          'success': false,
          'error': response['error'] ?? 'Failed to authenticate with server'
        };
      }

      final data = response['data'];
      if (data == null ||
          data['accessToken'] == null ||
          data['refreshToken'] == null ||
          data['user'] == null) {
        return {'success': false, 'error': 'Invalid server response'};
      }

      // ---------- Step 5: Persist tokens & user data ----------
      await AuthStorage.saveTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );

      await AuthStorage.saveUserDetails(
        userId: data['user']['id'],
        name: data['user']['name'],
        email: data['user']['email'],
        phone: data['user']['phone'] ?? '',
      );

      await AuthStorage.setLoggedIn(true);
      await AuthStorage.setHasRegistered(true);

      return {'success': true};
    } catch (e) {
      return {
        'success': false,
        'error': 'Apple sign-in error: ${e.toString()}'
      };
    }
  }

  /// Sign out from Firebase.
  static Future<void> logout() async {
    await _firebaseAuth.signOut();
    await AuthStorage.logout();
  }

  // ─── helpers ────────────────────────────────────────────────
  static String? _buildFullName(AuthorizationCredentialAppleID cred) {
    final parts = <String>[];
    if (cred.givenName != null && cred.givenName!.isNotEmpty) {
      parts.add(cred.givenName!);
    }
    if (cred.familyName != null && cred.familyName!.isNotEmpty) {
      parts.add(cred.familyName!);
    }
    return parts.isEmpty ? null : parts.join(' ');
  }
}
