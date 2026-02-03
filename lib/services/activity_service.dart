import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_storage.dart';

class ActivityService {
  static final String baseUrl = dotenv.env['BACKEND_URL'] ?? 
    "https://might-ampora-backend-p4tz.onrender.com/api/v1";

  /// Save daily activity to backend
  static Future<bool> saveDailyActivity({
    required String userId,
    required int steps,
    required double drivenKm,
    required double savedCO2,
    String? date, // Optional, defaults to today on backend
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/activity/save"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'steps': steps,
          'drivenKm': drivenKm,
          'savedCO2': savedCO2,
          if (date != null) 'date': date,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Activity saved to backend for $date');
        return true;
      } else {
        print('❌ Failed to save activity: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error saving activity: $e');
      return false;
    }
  }

  /// Update monthly summary (called at midnight)
  static Future<bool> updateMonthlySummary({
    required String userId,
    required String month, // YYYY-MM format
    required int steps,
    required double drivenKm,
    required double savedCO2,
    String? date, // Optional YYYY-MM-DD format for idempotency
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/activity/monthly/update"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'month': month,
          'steps': steps,
          'drivenKm': drivenKm,
          'savedCO2': savedCO2,
          if (date != null) 'date': date,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Monthly summary updated for $month${date != null ? " (date: $date)" : ""}');
        return true;
      } else {
        print('❌ Failed to update monthly summary: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error updating monthly summary: $e');
      return false;
    }
  }

  /// Get past week activity (for calendar display)
  static Future<List<Map<String, dynamic>>> getPastWeekActivity(String userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/activity/$userId/past-week"),
      );

      print('📡 Backend response status: ${response.statusCode}');
      print('📡 Backend response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // The response structure is: {data: {data: [...]}}
        // We need to access the nested 'data' array
        if (data['data'] != null && data['data']['data'] != null && data['data']['data'] is List) {
          final activities = List<Map<String, dynamic>>.from(data['data']['data']);
          print('📊 Parsed ${activities.length} activities from backend');
          return activities;
        }
      }
      return [];
    } catch (e) {
      print('❌ Error fetching past week activity: $e');
      return [];
    }
  }

  /// Get current month summary
  static Future<Map<String, dynamic>?> getCurrentMonthlySummary(String userId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/activity/$userId/monthly/current"),
      );

      print('📡 Monthly summary response status: ${response.statusCode}');
      print('📡 Monthly summary response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // The response structure is: {data: {data: summary}}
        if (data['data'] != null && data['data']['data'] != null) {
          final summary = data['data']['data'];
          print('📊 Monthly summary retrieved: $summary');
          return summary;
        }
      }
      return null;
    } catch (e) {
      print('❌ Error fetching monthly summary: $e');
      return null;
    }
  }

  /// Sync today's data from SharedPreferences to backend at midnight
  static Future<void> syncTodayToBackend() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDetails = await AuthStorage.getUserDetails();
      final userId = userDetails['userId'];

      if (userId == null || userId.isEmpty) {
        print('⚠️ No userId found, skipping sync');
        return;
      }

      // Get yesterday's date (since this runs at midnight)
      final yesterday = DateTime.now().subtract(Duration(days: 1));
      final dateStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      // Get data from SharedPreferences
      final steps = prefs.getInt('steps_$dateStr') ?? 0;
      final drivenKm = prefs.getDouble('driven_km_$dateStr') ?? 0.0;
      
      // Calculate saved CO2 using same formula as HomeScreen
      // Walking saves: (steps / 1000) * 0.75 km * 0.12 kg CO2/km
      // Driving emits: drivenKm * 0.12 kg CO2/km
      final co2SavedByWalking = (steps / 1000) * 0.75 * 0.12;
      final co2EmittedByDriving = drivenKm * 0.12;
      final savedCO2 = co2SavedByWalking - co2EmittedByDriving;

      print('🔄 Syncing data for $dateStr: steps=$steps, driven=${drivenKm.toStringAsFixed(2)}km, CO2=${savedCO2.toStringAsFixed(2)}kg');

      // Save to backend
      await saveDailyActivity(
        userId: userId,
        steps: steps,
        drivenKm: drivenKm,
        savedCO2: savedCO2,
        date: dateStr,
      );

      // Update monthly summary
      final monthStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}';
      await updateMonthlySummary(
        userId: userId,
        month: monthStr,
        steps: steps,
        drivenKm: drivenKm,
        savedCO2: savedCO2,
        date: dateStr, // Pass date for idempotency
      );

      print('✅ Midnight sync completed for $dateStr');
    } catch (e) {
      print('❌ Error during midnight sync: $e');
    }
  }
}
