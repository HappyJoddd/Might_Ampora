import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'auth_storage.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  static Future<bool> signIn() async {
    try {
      // Sign out first to ensure clean state
      await _googleSignIn.signOut();
      
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print("Google Sign-In cancelled by user");
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      
      if (idToken == null) {
        print("Failed to get ID token");
        return false;
      }

      print("ID Token obtained, calling backend...");
      final response = await ApiService.signInWithGoogle(idToken);

      print("Backend response: $response");
      
      if (response['success'] != true) {
        print("Backend error: ${response['error']}");
        return false;
      }

      final data = response['data'];
      print("Data from backend: $data");

      // Check if data contains the required fields
      if (data == null) {
        print("Error: No data in response");
        return false;
      }

      if (data['accessToken'] == null || data['refreshToken'] == null) {
        print("Error: Missing tokens in response. AccessToken: ${data['accessToken']}, RefreshToken: ${data['refreshToken']}");
        return false;
      }

      if (data['user'] == null) {
        print("Error: No user data in response");
        return false;
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
      print("✅ Google Sign-In successful! Tokens and user data saved.");
      print('📱 User providers: ${data['user']['providers']}');
      return true;
    } catch (e) {
      print("Google Sign-In error: $e");
      return false;
    }
  }

  static Future<void> logout() async {
    await _googleSignIn.signOut();
    await AuthStorage.logout();
  }
}
