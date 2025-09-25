import 'package:get/get.dart';
import 'package:might_ampora/Routes/routes_name.dart';

class SplashController extends GetxController {
  SplashController();

  @override
  void onInit() {
    navigateScreen();
    super.onInit();
  }

  navigateScreen() {
    Future.delayed(Duration(seconds: 3), () {
      Get.toNamed(RouteName.login);
    });
  }
}
