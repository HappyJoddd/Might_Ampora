import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'activity_service.dart';
import 'auth_storage.dart';

/// Singleton service to handle midnight data synchronization
/// This prevents duplicate timer instances when navigating between screens
class MidnightSyncService {
  static final MidnightSyncService _instance = MidnightSyncService._internal();
  factory MidnightSyncService() => _instance;
  MidnightSyncService._internal();

  Timer? _midnightTimer;
  bool _isInitialized = false;

  /// Initialize the midnight sync timer (call once from main.dart or first screen)
  void initialize() {
    if (_isInitialized) {
      return;
    }

    _isInitialized = true;
    
    // Check if we need to sync yesterday's data (in case app was closed at midnight)
    _checkAndSyncMissedDay();
    
    _scheduleMidnightSync();
  }

  /// Check if yesterday's data needs to be synced (in case app was closed at midnight)
  Future<void> _checkAndSyncMissedDay() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDetails = await AuthStorage.getUserDetails();
      final userId = userDetails['userId'];
      
      if (userId == null || userId.isEmpty) {
        return;
      }

      // Get last sync date
      final lastSyncDateStr = prefs.getString('last_sync_date');
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      // If last sync was not today, we need to sync previous days
      if (lastSyncDateStr != null && lastSyncDateStr != todayStr) {
        final lastSyncDate = DateTime.parse(lastSyncDateStr);
        final daysSinceLastSync = today.difference(lastSyncDate).inDays;
        
        // Sync all missed days (limit to last 7 days to avoid excessive syncing)
        final daysToSync = daysSinceLastSync > 7 ? 7 : daysSinceLastSync;
        
        for (int i = 1; i <= daysToSync; i++) {
          final dateToSync = today.subtract(Duration(days: i));
          final dateStr = '${dateToSync.year}-${dateToSync.month.toString().padLeft(2, '0')}-${dateToSync.day.toString().padLeft(2, '0')}';
          
          // Check if we have data for this date
          final steps = prefs.getInt('steps_$dateStr') ?? 0;
          final drivenKm = prefs.getDouble('driven_km_$dateStr') ?? 0.0;
          
          if (steps > 0 || drivenKm > 0) {
            
            // Calculate CO2
            final co2SavedByWalking = (steps / 1000) * 0.75 * 0.12;
            final co2EmittedByDriving = drivenKm * 0.12;
            final savedCO2 = co2SavedByWalking - co2EmittedByDriving;
            
            // Save to backend
            await ActivityService.saveDailyActivity(
              userId: userId,
              steps: steps,
              drivenKm: drivenKm,
              savedCO2: savedCO2,
              date: dateStr,
            );
            
            // Update monthly summary
            final monthStr = '${dateToSync.year}-${dateToSync.month.toString().padLeft(2, '0')}';
            await ActivityService.updateMonthlySummary(
              userId: userId,
              month: monthStr,
              steps: steps,
              drivenKm: drivenKm,
              savedCO2: savedCO2,
              date: dateStr,
            );
          }
        }
        
        // Update last sync date to today
        await prefs.setString('last_sync_date', todayStr);
      } else if (lastSyncDateStr == null) {
        // First time running, set today as last sync date
        await prefs.setString('last_sync_date', todayStr);
      }
    } catch (e) {
      // Silent error handling
    }
  }

  /// Schedule next midnight sync
  void _scheduleMidnightSync() {
    // Cancel any existing timer
    _midnightTimer?.cancel();

    DateTime now = DateTime.now();
    DateTime midnight = DateTime(now.year, now.month, now.day + 1);
    Duration timeUntilMidnight = midnight.difference(now);

    _midnightTimer = Timer(timeUntilMidnight, () async {
      try {
        // Sync yesterday's data to backend
        await ActivityService.syncTodayToBackend();
        
        // Update last sync date
        final prefs = await SharedPreferences.getInstance();
        final yesterday = DateTime.now().subtract(Duration(days: 1));
        final dateStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
        await prefs.setString('last_sync_date', dateStr);
      } catch (e) {
        // Silent error handling
      }
      
      // Schedule next midnight sync
      _scheduleMidnightSync();
    });
  }

  /// Manually trigger sync (for testing or manual sync needs)
  Future<void> syncNow() async {
    await ActivityService.syncTodayToBackend();
  }

  /// Cleanup (call when app is disposed if needed)
  void dispose() {
    _midnightTimer?.cancel();
    _isInitialized = false;
  }
}
