import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:might_ampora/Routes/routes.dart';
import 'package:might_ampora/Routes/routes_name.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:might_ampora/services/midnight_sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 Load environment variables
  await dotenv.load(fileName: ".env");

  // 🔥 Initialize Firebase
  await Firebase.initializeApp();

  // ⏰ Initialize midnight sync service
  MidnightSyncService().initialize();

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
