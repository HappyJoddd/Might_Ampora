import 'package:get/get.dart';

import 'package:might_ampora/Pages/Splash_Screen/SplashScreen.dart';
import 'package:might_ampora/Routes/routes_name.dart';
import 'package:might_ampora/Pages/Controller/splashcontroller.dart';
import 'package:might_ampora/Pages/loginPage/LoginPage.dart';
import 'package:might_ampora/Pages/Controller/LoginPageController.dart';

class AppRoutes {
  static  getRoutes() => [
    GetPage(
        name: RouteName.splash,
        page: () => SplashPage(),
        binding: BindingsBuilder.put(() => SplashController()),
        ),
        GetPage(
        name: RouteName.login,
        page: () => LoginPage(),
        binding: BindingsBuilder.put(() => LoginPageController()),
        ),
  ];
}
