import 'package:get/get.dart';
import 'package:might_ampora/Pages/Splash_Screen/SplashScreen.dart';
import 'package:might_ampora/Pages/loginPage/LoginPage.dart';
import 'package:might_ampora/Pages/Home/HomeScreen.dart';
import 'package:might_ampora/Pages/loginPage/Otp.dart';
import 'package:might_ampora/Routes/routes_name.dart';

// Controllers
import 'package:might_ampora/Pages/Controller/splashcontroller.dart';
import 'package:might_ampora/Pages/Controller/LoginPageController.dart';

class AppRoutes {
  static List<GetPage> getRoutes() => [
        // 🟢 Splash Screen (Auto-login logic handled in controller)
        GetPage(
          name: RouteName.splash,
          page: () => const SplashPage(),
          binding: BindingsBuilder(() {
            Get.put(SplashController());
          }),
        ),

        // 🟡 Login Page
        GetPage(
          name: RouteName.login,
          page: () => const LoginPage(),
          binding: BindingsBuilder(() {
            Get.put(LoginPageController());
          }),
        ),

        // 🔵 Home Screen (after successful login)
        GetPage(
          name: RouteName.home,
          page: () => const HomeScreen(),
        ),

        GetPage(
          name: RouteName.otp,
          page: () => const OTPpage(),
        ),
      ];
}
