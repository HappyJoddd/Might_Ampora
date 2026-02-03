import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:might_ampora/services/api_service.dart';
import 'package:might_ampora/services/auth_storage.dart';

class FacebookAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Sign in with Facebook using Firebase Authentication
  static Future<Map<String, dynamic>> signInWithFacebook() async {
    try {
      print('🔵 Starting Facebook Sign-In...');

      // Trigger the Facebook authentication flow
      final LoginResult loginResult = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      // Check if login was successful
      if (loginResult.status != LoginStatus.success) {
        throw Exception('Facebook login failed: ${loginResult.status}');
      }

      // Get the access token
      final AccessToken? accessToken = loginResult.accessToken;
      if (accessToken == null) {
        throw Exception('Failed to get Facebook access token');
      }

      print('🔵 Facebook access token obtained');

      // Create a credential from the access token
      final OAuthCredential facebookCredential = 
          FacebookAuthProvider.credential(accessToken.tokenString);

      // Sign in to Firebase with the Facebook credential
      final UserCredential userCredential = 
          await _auth.signInWithCredential(facebookCredential);

      if (userCredential.user == null) {
        throw Exception('Failed to get user from Firebase');
      }

      final User user = userCredential.user!;
      print('🔵 Firebase user: ${user.displayName} (${user.email})');

      // Get the Firebase ID token
      final idToken = await user.getIdToken();
      
      if (idToken == null) {
        throw Exception('Failed to get Firebase ID token');
      }

      print('🔵 Firebase ID token obtained');

      // Send the ID token to your backend
      print('🔵 Sending token to backend...');
      final response = await ApiService.signInWithFacebook(idToken);

      print('🔵 Backend response: $response');

      if (response['status'] == 'success') {
        final data = response['data'];

        // Save tokens
        await AuthStorage.saveTokens(
          accessToken: data['accessToken'],
          refreshToken: data['refreshToken'],
        );

        // Save user data including userId
        if (data['user'] != null) {
          await AuthStorage.saveUserDetails(
            userId: data['user']['id'],
            name: data['user']['name'] ?? user.displayName ?? '',
            email: data['user']['email'] ?? user.email ?? '',
            phone: data['user']['phone'] ?? user.phoneNumber ?? '',
            location: data['user']['location'] ?? '',
          );
        }

        await AuthStorage.setLoggedIn(true);
        await AuthStorage.setHasRegistered(true);

        print('✅ Facebook Sign-In successful! Tokens and user data saved.');
        print('📱 User providers: ${data['user']['providers']}');
        return {'success': true, 'data': data};
      } else {
        throw Exception(response['message'] ?? 'Backend error');
      }
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth error: ${e.code} - ${e.message}');
      
      if (e.code == 'account-exists-with-different-credential') {
        throw Exception('An account already exists with the same email address but different sign-in credentials.');
      } else if (e.code == 'invalid-credential') {
        throw Exception('Invalid credentials. Please try again.');
      } else if (e.code == 'user-disabled') {
        throw Exception('This user account has been disabled.');
      }
      
      rethrow;
    } catch (e) {
      print('❌ Facebook Sign-In error: $e');
      rethrow;
    }
  }

  /// Sign out from Firebase (and Facebook)
  static Future<void> logout() async {
    await _auth.signOut();
    await AuthStorage.logout();
  }

  /// Check if user is currently signed in
  static User? getCurrentUser() {
    return _auth.currentUser;
  }
}
