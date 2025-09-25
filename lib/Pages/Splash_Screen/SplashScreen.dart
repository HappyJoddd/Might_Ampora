import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:might_ampora/Pages/Controller/splashcontroller.dart';

class SplashPage extends GetView<SplashController> {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
        body: Center(
      child: Column(
        children: [
          Spacer(),
          ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset("images/Logo.png", width: screenWidth * 0.7)),
          Spacer(),
          ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset("images/SlashScreen.png", width: screenWidth)),
        ],
      ),
    ));
  }
}
