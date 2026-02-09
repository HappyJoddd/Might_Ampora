import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:might_ampora/Routes/routes.dart';
import 'package:might_ampora/Routes/routes_name.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:might_ampora/services/midnight_sync_service.dart';
import 'package:might_ampora/services/permission_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 🔹 Load environment variables
    await dotenv.load(fileName: ".env");

    // 🔥 Initialize Firebase
    await Firebase.initializeApp();

    // 🔐 Request all required permissions at app startup
    try {
      final permissionService = PermissionService();
      await permissionService.requestAllPermissions();
    } catch (e) {
      // Permission error silently handled
    }

    // 🔐 Initialize notification service
    try {
      final permissionService = PermissionService();
      await permissionService.initializeNotificationService();
    } catch (e) {
      // Notification service error silently handled
    }

    // ⏰ Initialize midnight sync service
    MidnightSyncService().initialize();
  } catch (e) {
    // Main initialization error silently handled
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      getPages: AppRoutes.getRoutes(),
      initialRoute: RouteName.splash,
      theme: ThemeData(
        fontFamily: 'Worksans',
      ),
    );
  }
}
