import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:might_ampora/Routes/routes.dart';
import 'package:might_ampora/Routes/routes_name.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 Load environment variables
  await dotenv.load(fileName: ".env");

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
