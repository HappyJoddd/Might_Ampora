import 'dart:async';
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
      // Request activity recognition for step counting
      await Permission.activityRecognition.request();

      // Request notification permission
      await Permission.notification.request();

      // Request fine location for GPS tracking
      await Permission.location.request();

      // Request camera permission
      await Permission.camera.request();
    } catch (e) {
      // Silent error handling
    }
  }

  /// Initialize notification channels (safe to call at startup)
  Future<void> initializeNotificationService() async {
    try {
      // Create notification channel for Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'activity_tracker_channel',
        'Activity Tracker',
        description: 'Tracks your steps and driving',
        importance: Importance.low,
      );

      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // Initialize notification plugin
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    } catch (e) {
      // Silent error handling
    }
  }
}
