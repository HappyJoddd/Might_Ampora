import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static const _storage = FlutterSecureStorage();

  // 🔑 Storage keys
  static const _keyAccessToken = 'accessToken';
  static const _keyRefreshToken = 'refreshToken';
  static const _keyIsLoggedIn = 'isLoggedIn';
  static const _keyUserName = 'userName';
  static const _keyUserEmail = 'userEmail';
  static const _keyUserPhone = 'userPhone';
  static const _keyUserLocation = 'userLocation';
  static const _keyHasRegistered = 'hasRegistered'; // 🆕 NEW

  // ==============================================================
  // 🟢 TOKEN MANAGEMENT
  // ==============================================================

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
    await _storage.write(key: _keyIsLoggedIn, value: 'true');
  }

  static Future<void> saveUserToken(String token) async {
    await _storage.write(key: _keyAccessToken, value: token);
  }

  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _keyRefreshToken, value: token);
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  // ==============================================================
  // 🟠 LOGIN STATE MANAGEMENT
  // ==============================================================

  static Future<void> setLoggedIn(bool value) async {
    await _storage.write(key: _keyIsLoggedIn, value: value.toString());
  }

  static Future<bool> isLoggedIn() async {
    final value = await _storage.read(key: _keyIsLoggedIn);
    return value == 'true';
  }

  // ==============================================================
  // 🟣 REGISTRATION STATE MANAGEMENT (NEW)
  // ==============================================================

  /// Marks whether the user has ever registered (used by SplashController)
  static Future<void> setHasRegistered(bool value) async {
    await _storage.write(key: _keyHasRegistered, value: value.toString());
  }

  /// Returns true if the user has registered before
  static Future<bool> hasRegisteredUser() async {
    final value = await _storage.read(key: _keyHasRegistered);
    return value == 'true';
  }

  // ==============================================================
  // 🔵 USER DETAILS
  // ==============================================================

static Future<void> saveUserDetails({
  String? name,
  String? email,
  String? phone,
  String? location,
}) async {
  bool hasAnyDetail = false;

  if (name != null && name.isNotEmpty) {
    await _storage.write(key: _keyUserName, value: name);
    hasAnyDetail = true;
  }
  if (email != null && email.isNotEmpty) {
    await _storage.write(key: _keyUserEmail, value: email);
    hasAnyDetail = true;
  }
  if (phone != null && phone.isNotEmpty) {
    await _storage.write(key: _keyUserPhone, value: phone);
    hasAnyDetail = true;
  }
  if (location != null && location.isNotEmpty) {
    await _storage.write(key: _keyUserLocation, value: location);
    hasAnyDetail = true;
  }

  // ✅ Automatically mark user as registered once they’ve provided details
  if (hasAnyDetail) {
    await setHasRegistered(true);
  }
}

  static Future<Map<String, String?>> getUserDetails() async {
    final name = await _storage.read(key: _keyUserName);
    final email = await _storage.read(key: _keyUserEmail);
    final phone = await _storage.read(key: _keyUserPhone);
    final location = await _storage.read(key: _keyUserLocation);
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'location': location,
    };
  }

  static Future<String?> getUserNumber() async {
    return await _storage.read(key: _keyUserPhone);
  }

  // ==============================================================
  // 🔴 CLEARING & LOGOUT
  // ==============================================================

  /// Clears everything completely
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Logs user out safely but keeps `hasRegistered` so OTP flow works
  static Future<void> logout() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.write(key: _keyIsLoggedIn, value: 'false');

    // Keep registration info so user goes to OTP next time
    await _storage.write(key: _keyHasRegistered, value: 'true');
  }
}
