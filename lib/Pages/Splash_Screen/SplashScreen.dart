import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:might_ampora/Pages/Controller/splashcontroller.dart';

class SplashPage extends GetView<SplashController> {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          children: [
            const Spacer(),

            /// App Logo
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                "images/Logo.png",
                width: screenWidth * 0.7,
                fit: BoxFit.contain,
              ),
            ),

            const Spacer(),

            /// Splash Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                "images/SlashScreen.png",
                width: screenWidth,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
