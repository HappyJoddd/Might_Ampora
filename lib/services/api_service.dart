import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_storage.dart';

class ApiService {
  static const String baseUrl =
      "https://might-ampora-backend-447t.onrender.com/api/v1";

  // ============================================================
  // 🔹 TOKEN & AUTH HELPERS
  // ============================================================

  /// Handle authentication response and store tokens (defensive)
  static Future<bool> handleAuthResponse(Map<String, dynamic>? response) async {
    try {
      if (response == null) return false;
      final success = response['success'] == true;
      final data = response['data'];
      if (!success || data == null) return false;

      final access = data['accessToken'] as String?;
      final refresh = data['refreshToken'] as String?;
      if (access != null &&
          access.isNotEmpty &&
          refresh != null &&
          refresh.isNotEmpty) {
        await AuthStorage.saveTokens(
            accessToken: access, refreshToken: refresh);
        await AuthStorage.setLoggedIn(true);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> signInWithOTP({
  required String phone,
  required String name,
  required String email,
  required String location,
}) async {
  final url = Uri.parse('$baseUrl/users/otp-signup');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      "mobileNumber": phone,
      "name": name,
      "email": email,
      "location": location,
    }),
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
    final decoded = jsonDecode(response.body);
return {"success": true, "data": decoded["data"] ?? decoded};

  } else {
    return {
      "success": false,
      "error": jsonDecode(response.body)['message'] ?? "Unknown error"
    };
  }
}


  /// Refresh token and update storage if valid
  static Future<bool> refreshTokenIfNeeded() async {
    final refreshTokenValue = await AuthStorage.getRefreshToken();
    if (refreshTokenValue == null || refreshTokenValue.isEmpty) {
      await AuthStorage.clearAll();
      return false;
    }

    final response = await refreshToken(refreshTokenValue);
    final ok = await handleAuthResponse(response);
    if (!ok) await AuthStorage.clearAll();
    return ok;
  }

  // ============================================================
  // 🔹 BASIC AUTH ENDPOINTS (public)
  // ============================================================

  static Future<Map<String, dynamic>> sendOtp(String phone) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/users/request-otp"),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'mobileNumber': phone}),
          )
          .timeout(const Duration(seconds: 15));

      return _parseResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> verifyOtp(
      String phone, String otp) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/users/verify-otp"),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'mobileNumber': phone, 'otp': otp}),
          )
          .timeout(const Duration(seconds: 15));

      return _parseResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> registerUser({
    required String phone,
    required String name,
    required String email,
    required String location,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/users/otp-signup"),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'mobileNumber': phone,
              'name': name,
              'email': email,
              'location': location,
            }),
          )
          .timeout(const Duration(seconds: 15));

      return _parseResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> refreshToken(
      String refreshToken) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/users/refresh-token"),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(const Duration(seconds: 15));

      return _parseResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> logout(String? refreshToken) async {
    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        final response = await http.post(
          Uri.parse("$baseUrl/users/logout"),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refreshToken': refreshToken}),
        );
        await AuthStorage.clearAll();
        return _parseResponse(response);
      } else {
        await AuthStorage.clearAll();
        return {'success': true, 'message': 'Logged out locally'};
      }
    } catch (e) {
      await AuthStorage.clearAll();
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============================================================
  // 🔹 GENERIC API CLIENT FOR AUTHENTICATED REQUESTS
  // ============================================================

  static final _client = http.Client();
  static Completer<bool>? _refreshCompleter;

  /// Send GET request with token and auto-refresh
  static Future<Map<String, dynamic>> get(String path) async {
    final uri = Uri.parse("$baseUrl$path");
    return _sendWithAuth(() => _client.get(uri));
  }

  /// Send POST request with token and auto-refresh
  static Future<Map<String, dynamic>> post(String path,
      {Map<String, dynamic>? body}) async {
    final uri = Uri.parse("$baseUrl$path");
    return _sendWithAuth(() => _client.post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body ?? {})));
  }

  /// Handles token injection, 401 retry once, and refresh-lock
  static Future<Map<String, dynamic>> _sendWithAuth(
      Future<http.Response> Function() requestFunc) async {
    try {
      final token = await AuthStorage.getAccessToken();
      final response = await requestFunc().then((res) async {
        if (res.statusCode != 401) return res;

        // If unauthorized -> try to refresh once
        final refreshed = await _attemptRefresh();
        if (!refreshed) return res;

        // Retry once after refresh
        final newToken = await AuthStorage.getAccessToken();
        if (newToken == null) return res;

        // Retry the same request but with updated header
        final headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $newToken',
        };
        final uri = res.request?.url;
        if (uri == null) return res;

        // Retry same HTTP method
        switch (res.request?.method) {
          case 'POST':
            return await _client.post(uri,
                headers: headers, body: (res.request as dynamic).body);
          case 'PUT':
            return await _client.put(uri,
                headers: headers, body: (res.request as dynamic).body);
          case 'DELETE':
            return await _client.delete(uri, headers: headers);
          default:
            return await _client.get(uri, headers: headers);
        }
      });

      return _parseResponse(response);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Prevents multiple refreshes at once (refresh-lock)
  static Future<bool> _attemptRefresh() async {
    if (_refreshCompleter != null) return _refreshCompleter!.future;

    _refreshCompleter = Completer<bool>();
    try {
      final refreshToken = await AuthStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await AuthStorage.clearAll();
        _refreshCompleter!.complete(false);
        _refreshCompleter = null;
        return false;
      }

      final res = await refreshTokenIfNeeded();
      _refreshCompleter!.complete(res);
      _refreshCompleter = null;
      return res;
    } catch (e) {
      await AuthStorage.clearAll();
      _refreshCompleter!.complete(false);
      _refreshCompleter = null;
      return false;
    }
  }

  // ============================================================
  // 🔹 RESPONSE PARSER
  // ============================================================

  static Map<String, dynamic> _parseResponse(http.Response response) {
    try {
      final body =
          response.body.isNotEmpty ? jsonDecode(response.body) : null;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (body is Map<String, dynamic>) {
          return {
            'success': true,
            'data': body['data'] ?? body,
            'message': body['message'] ?? 'Success',
          };
        }
        return {'success': true, 'data': body};
      } else {
        final errorMessage = (body is Map<String, dynamic>)
            ? (body['error'] ??
                body['message'] ??
                body['msg'] ??
                'Request failed (${response.statusCode})')
            : 'Unexpected error (${response.statusCode})';
        return {'success': false, 'error': errorMessage};
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to parse server response: $e',
      };
    }
  }
}
