import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_service.dart';
import 'auth_storage.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: dotenv.env['WEB_CLIENT_ID'],
  );

  static Future<Map<String, dynamic>> signIn() async {
    try {
      // Sign out first to ensure clean state
      await _googleSignIn.signOut();
      
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return {'success': false, 'error': 'Google sign-in was cancelled'};
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      
      if (idToken == null) {
        return {'success': false, 'error': 'Failed to get Google ID token'};
      }

      final response = await ApiService.signInWithGoogle(idToken);
      
      if (response['success'] != true) {
        return {'success': false, 'error': response['error'] ?? 'Failed to authenticate with server'};
      }

      final data = response['data'];

      // Check if data contains the required fields
      if (data == null) {
        return {'success': false, 'error': 'Invalid server response'};
      }

      if (data['accessToken'] == null || data['refreshToken'] == null) {
        return {'success': false, 'error': 'Missing authentication tokens'};
      }

      if (data['user'] == null) {
        return {'success': false, 'error': 'Missing user data'};
      }

      // 🔹 Save tokens
      await AuthStorage.saveTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );

      // 🔹 Save user details including userId
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
      return {'success': false, 'error': 'Google sign-in error: ${e.toString()}'};
    }
  }

  static Future<void> logout() async {
    await _googleSignIn.signOut();
    await AuthStorage.logout();
  }
}
