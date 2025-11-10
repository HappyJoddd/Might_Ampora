import 'package:get/get.dart';
import 'package:might_ampora/Routes/routes_name.dart';
import 'package:might_ampora/services/auth_storage.dart';
import 'package:might_ampora/services/api_service.dart';

class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 3)); // Splash screen delay

    final isLoggedIn = await AuthStorage.isLoggedIn();

    // 🟢 1️⃣ Already logged in → Home
    if (isLoggedIn) {
      Get.offAllNamed(RouteName.home);
      return;
    }

    // 🟡 2️⃣ Try to refresh tokens (if present)
    final accessToken = await AuthStorage.getAccessToken();
    final refreshToken = await AuthStorage.getRefreshToken();

    if (accessToken != null && refreshToken != null) {
      final refreshed = await ApiService.refreshTokenIfNeeded();
      if (refreshed) {
        Get.offAllNamed(RouteName.home);
        return;
      }
    }

    // 🔵 3️⃣ Check if user has registered before (returning user)
    final hasRegistered = await AuthStorage.hasRegisteredUser();

    if (hasRegistered) {
      // Old user who logged out → Go directly to OTP
      Get.offAllNamed(RouteName.otp);
    } else {
      // New user (no account or registration info) → Start fresh
      Get.offAllNamed(RouteName.login);
    }
  }
}
