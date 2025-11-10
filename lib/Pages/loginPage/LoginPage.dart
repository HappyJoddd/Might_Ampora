import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:might_ampora/Pages/loginPage/registarPage.dart';
import 'package:might_ampora/Routes/routes_name.dart';
import 'package:might_ampora/services/api_service.dart';
import 'package:might_ampora/services/auth_storage.dart';
import 'Otp.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isPhoneValid = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginStatus();
    });
  }

  Future<void> _checkLoginStatus() async {
    if (await AuthStorage.isLoggedIn()) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(RouteName.home);
      }
    }
  }

  /// ✅ Handles OTP / Registration routing based on backend response
Future<void> _handleSendOtp() async {
  final phoneNumber = _phoneController.text.trim();

  if (phoneNumber.isEmpty || !_isPhoneValid) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("⚠️ Please enter a valid phone number")),
    );
    return;
  }

  if (!mounted) return;
  setState(() => _isLoading = true);

  try {
    // 🔹 Step 1: Attempt to send OTP
    final result = await ApiService.sendOtp(phoneNumber);
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      await AuthStorage.saveUserDetails(phone: phoneNumber);

      // 🔹 Step 2: Check if access token already exists
      final accessToken = await AuthStorage.getAccessToken();
      final refreshToken = await AuthStorage.getRefreshToken();
      final storedPhone = await AuthStorage.getUserNumber();

      // If user has valid token, just go home
      if (accessToken != null && refreshToken != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Already logged in!")),
        );
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, RouteName.home);
        return;
      }

      // If phone matches previously stored one → old user → OTP
      if (storedPhone == phoneNumber) {
        await AuthStorage.setHasRegistered(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ OTP sent successfully!")),
        );
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OTPpage()),
        );
      } else {
        // No phone saved → new user → registration
        await AuthStorage.setHasRegistered(false);
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RegisterPage()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "❌ Failed: ${result['error'] ?? 'Unknown error'}",
          ),
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
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.06,
                vertical: screenHeight * 0.02,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: screenHeight * 0.04),

                  /// Title Section
                  Column(
                    children: [
                      Text(
                        'Welcome to',
                        style: TextStyle(
                          fontSize: screenWidth * 0.06,
                          color: Colors.black,
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Might ',
                              style: TextStyle(
                                fontSize: isTablet
                                    ? screenWidth * 0.05
                                    : screenWidth * 0.07,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFEF5F00),
                              ),
                            ),
                            TextSpan(
                              text: 'Ampora',
                              style: TextStyle(
                                fontSize: isTablet
                                    ? screenWidth * 0.05
                                    : screenWidth * 0.07,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2B9A66),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: screenHeight * 0.04),

                  /// Social Login (kept intact)
                  _buildSocialButton(
                    label: "Continue with Google",
                    asset: "images/Google.png",
                    color: Colors.white,
                    onTap: () => print("Google login pressed"),
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  _buildSocialButton(
                    label: "Continue with Facebook",
                    asset: "images/Facebook.png",
                    color: Colors.white,
                    onTap: () => print("Facebook login pressed"),
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                  ),
                  SizedBox(height: screenHeight * 0.04),

                  /// Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(thickness: 1, color: Colors.grey[300]),
                      ),
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                        child: Text(
                          'or',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: screenWidth * 0.035,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(thickness: 1, color: Colors.grey[300]),
                      ),
                    ],
                  ),

                  SizedBox(height: screenHeight * 0.04),

                  /// Phone Number Field
                  IntlPhoneField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: '12345 67890',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: screenWidth * 0.04,
                      ),
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(screenWidth * 0.03),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(screenWidth * 0.03),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(screenWidth * 0.03),
                        borderSide: const BorderSide(
                            color: Color(0xFF4CAF50), width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: screenHeight * 0.02,
                        horizontal: screenWidth * 0.04,
                      ),
                    ),
                    initialCountryCode: 'IN',
                    style: TextStyle(fontSize: screenWidth * 0.04),
                    dropdownTextStyle:
                        TextStyle(fontSize: screenWidth * 0.035),
                    onChanged: (phone) {
                      setState(() {
                        _isPhoneValid = phone.completeNumber.length >= 10;
                      });
                    },
                  ),

                  SizedBox(height: screenHeight * 0.04),

                  /// Get OTP Button
                  SizedBox(
                    width: double.infinity,
                    height: screenHeight * 0.07,
                    child: ElevatedButton(
                      onPressed:
                          _isPhoneValid && !_isLoading ? _handleSendOtp : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isPhoneValid
                            ? const Color(0xFFF59E0B)
                            : Colors.grey[300],
                        foregroundColor:
                            _isPhoneValid ? Colors.white : Colors.grey[600],
                        elevation: _isPhoneValid ? 2 : 0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(screenWidth * 0.1),
                        ),
                      ),
                      child: Text(
                        _isLoading ? "Sending..." : "Get OTP",
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.05),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ Reusable social login button
  Widget _buildSocialButton({
    required String label,
    required String asset,
    required Color color,
    required Function() onTap,
    required double screenWidth,
    required double screenHeight,
  }) {
    return SizedBox(
      width: double.infinity,
      height: screenHeight * 0.07,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black87,
          elevation: 1,
          side: BorderSide(color: Colors.grey[300]!, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              asset,
              width: screenWidth * 0.06,
              height: screenWidth * 0.06,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.person, size: screenWidth * 0.06);
              },
            ),
            SizedBox(width: screenWidth * 0.03),
            Text(
              label,
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}
