import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';
import 'dart:async';
import 'package:might_ampora/services/api_service.dart';
import 'package:might_ampora/services/auth_storage.dart';
import 'package:might_ampora/Routes/routes_name.dart';
import 'registarPage.dart';
import '../Home/HomeScreen.dart';

class OTPpage extends StatefulWidget {
  const OTPpage({super.key});

  @override
  State<OTPpage> createState() => _OTPpageState();
}

class _OTPpageState extends State<OTPpage> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  int _remainingTime = 30;
  Timer? _timer;
  bool _isResendEnabled = false;
  bool _isOtpComplete = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _pinController.addListener(() {
      setState(() {
        _isOtpComplete = _pinController.text.length == 4;
      });
    });
  }

  void _startTimer() {
    _isResendEnabled = false;
    _remainingTime = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() => _remainingTime--);
      } else {
        setState(() => _isResendEnabled = true);
        timer.cancel();
      }
    });
  }

  Future<void> _resendOtp() async {
    if (!_isResendEnabled) return;

    try {
      final phone = await AuthStorage.getUserNumber();
      if (phone == null || phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Missing phone number. Please login again.")),
        );
        Get.offAllNamed(RouteName.login);
        return;
      }

      final result = await ApiService.sendOtp(phone);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ OTP resent successfully!")),
        );
        _startTimer();
        await AuthStorage.saveUserDetails(phone: phone);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed to resend OTP: ${result['error'] ?? 'Unknown error'}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("🚨 Error: $e")),
      );
    }
  }

Future<void> _onContinue() async {
  final otp = _pinController.text.trim();
  if (otp.length != 4) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("⚠️ Please enter a valid 4-digit OTP")),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    final userDetails = await AuthStorage.getUserDetails();
    final phone = userDetails['phone'];

    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Missing phone number. Please login again.")),
      );
      Get.offAllNamed(RouteName.login);
      return;
    }

    final result = await ApiService.verifyOtp(phone, otp);
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      final data = result['data'] ?? {};

      final accessToken = data['accessToken']?.toString() ?? '';
      final refreshToken = data['refreshToken']?.toString() ?? '';

      // 🔒 Save tokens securely before anything else
      if (accessToken.isNotEmpty && refreshToken.isNotEmpty) {
        await AuthStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }

      // ✅ Mark user as logged in
      await AuthStorage.setLoggedIn(true);

      // ✅ Save user data if returned
      await AuthStorage.saveUserDetails(
        name: data['user']?['name'],
        email: data['user']?['email'],
        phone: data['user']?['phone'] ?? phone,
        location: data['user']?['location'],
      );

      // 🔍 Check if user profile already has basic info
      final name = data['user']?['name'] ?? userDetails['name'];
      final email = data['user']?['email'] ?? userDetails['email'];
      final location = data['user']?['location'] ?? userDetails['location'];

      final hasProfileInfo =
          (name != null && name.toString().isNotEmpty) &&
          (email != null && email.toString().isNotEmpty) &&
          (location != null && location.toString().isNotEmpty);

      // ✅ Navigate
      if (hasProfileInfo) {
        // Existing user → Home
        Navigator.pushNamedAndRemoveUntil(
          context,
          RouteName.home,
          (route) => false,
        );
      } else {
        // New user → RegisterPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RegisterPage()),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ OTP verified successfully!")),
      );
    } else {
      await AuthStorage.clearAll();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Invalid OTP: ${result['error'] ?? 'Unknown error'}"),
        ),
      );
    }
  } catch (e) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("🚨 Something went wrong: $e")),
    );
  }
}

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: screenHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: screenHeight * 0.06),
                    Text(
                      'welcome to',
                      style: TextStyle(
                        fontSize: screenWidth * 0.06,
                        color: Colors.black87,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Might ',
                            style: TextStyle(
                              fontSize: screenWidth * 0.08,
                              color: const Color(0xFFEF5F00),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          TextSpan(
                            text: 'Ampora',
                            style: TextStyle(
                              fontSize: screenWidth * 0.08,
                              color: const Color(0xFF2B9A66),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.08),
                    Text(
                      'Enter your OTP',
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                      child: Pinput(
                        controller: _pinController,
                        focusNode: _focusNode,
                        length: 4,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        defaultPinTheme: PinTheme(
                          width: screenWidth * 0.15,
                          height: screenWidth * 0.15,
                          textStyle: TextStyle(
                            fontSize: screenWidth * 0.06,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                        ),
                        focusedPinTheme: PinTheme(
                          width: screenWidth * 0.15,
                          height: screenWidth * 0.15,
                          textStyle: TextStyle(
                            fontSize: screenWidth * 0.06,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF4CAF50),
                              width: 2,
                            ),
                          ),
                        ),
                        submittedPinTheme: PinTheme(
                          width: screenWidth * 0.15,
                          height: screenWidth * 0.15,
                          textStyle: TextStyle(
                            fontSize: screenWidth * 0.06,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF4CAF50),
                              width: 1.5,
                            ),
                          ),
                        ),
                        showCursor: true,
                        cursor: Container(
                          width: 2,
                          height: screenWidth * 0.06,
                          color: const Color(0xFF4CAF50),
                        ),
                        onCompleted: (pin) => setState(() => _isOtpComplete = true),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _resendOtp,
                        child: Text(
                          '*Resend OTP',
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: _isResendEnabled
                                ? Colors.black
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    SizedBox(
                      width: double.infinity,
                      height: screenHeight * 0.065,
                      child: ElevatedButton(
                        onPressed: !_isLoading && _isOtpComplete ? _onContinue : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isOtpComplete
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFFDD28A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(screenWidth * 0.07),
                          ),
                        ),
                        child: Text(
                          _isLoading ? "Verifying..." : "Continue",
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Text(
                      'Remaining time: ${_remainingTime}s',
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.04),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
