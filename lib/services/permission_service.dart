import 'dart:async';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();

  factory PermissionService() {
    return _instance;
  }

  PermissionService._internal();

  /// Request all required permissions at app startup
  Future<void> requestAllPermissions() async {
    try {
      // iOS uses HealthKit for step counting, not activityRecognition
      if (Platform.isIOS) {
        // For iOS, motion permission is handled differently
        // Health data permission is requested when you first access HealthKit
        await Permission.sensors.request();
      } else {
        // Android uses activity recognition
        await Permission.activityRecognition.request();
      }

      // Request notification permission (works on both platforms)
      await Permission.notification.request();

      // Request location permission
      await Permission.locationWhenInUse.request();

      // Request camera permission
      await Permission.camera.request();
    } catch (e) {
    }
  }

  /// Initialize notification channels (safe to call at startup)
  Future<void> initializeNotificationService() async {
    try {
      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      if (Platform.isAndroid) {
        // Create notification channel for Android only
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'activity_tracker_channel',
          'Activity Tracker',
          description: 'Tracks your steps and driving',
          importance: Importance.low,
        );

        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }

      // Initialize notification plugin
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS initialization settings
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    } catch (e) {
    }
  }
  
  /// Request camera permission when needed
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }
  
  /// Request location permission when needed
  Future<bool> requestLocationPermission() async {
    final status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }
}