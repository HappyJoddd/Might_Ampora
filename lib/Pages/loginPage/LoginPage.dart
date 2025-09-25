import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'Otp.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isPhoneValid = false;

  @override
  Widget build(BuildContext context) {
    // MediaQuery for responsive design
    var screenHeight = MediaQuery.of(context).size.height;
    var screenWidth = MediaQuery.of(context).size.width;
    var isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.06, // 6% of screen width
              vertical: screenHeight * 0.02,  // 2% of screen height
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top spacing
                SizedBox(height: screenHeight * 0.04),
                
                // Welcome Text
                Column(
                  children: [
                    Text(
                      'Welcome to',
                      style: TextStyle(
                        fontSize: screenWidth * 0.06, // Responsive font size
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    
                    // App Name with Text (No Logo Image)
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Might ',
                            style: TextStyle(
                              fontSize: isTablet ? screenWidth * 0.05 : screenWidth * 0.07,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFEF5F00), // Green
                            ),
                          ),
                          TextSpan(
                            text: 'Ampora',
                            style: TextStyle(
                              fontSize: isTablet ? screenWidth * 0.05 : screenWidth * 0.07,
                              fontWeight: FontWeight.bold,
                              color:  Color(0xFF2B9A66), // black
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: screenHeight * 0.04),
                
                // Google Login Button
                Container(
                  width: double.infinity,
                  height: screenHeight * 0.07, // Responsive height
                  child: ElevatedButton(
                    onPressed: () {
                      print('Google login pressed');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
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
                          'images/Google.png',
                          width: screenWidth * 0.06, // Responsive icon size
                          height: screenWidth * 0.06,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: screenWidth * 0.06,
                              height: screenWidth * 0.06,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Center(
                                child: Text(
                                  'G',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: screenWidth * 0.035,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Text(
                          'Continue with Google',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: screenHeight * 0.02),
                
                // Facebook Login Button
                Container(
                  width: double.infinity,
                  height: screenHeight * 0.07,
                  child: ElevatedButton(
                    onPressed: () {
                      print('Facebook login pressed');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
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
                          'images/Facebook.png',
                          width: screenWidth * 0.06,
                          height: screenWidth * 0.06,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: screenWidth * 0.06,
                              height: screenWidth * 0.06,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1877F2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  'f',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: screenWidth * 0.04,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Text(
                          'Continue with Facebook',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: screenHeight * 0.04),
                
                // OR Divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        thickness: 1,
                        color: Colors.grey[300],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                      child: Text(
                        'or',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: screenWidth * 0.035,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        thickness: 1,
                        color: Colors.grey[300],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: screenHeight * 0.04),
                
                // Phone Number Field
                IntlPhoneField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '12345 67890',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: screenWidth * 0.04,
                    ),
                    counterText: '', // Remove digit counter
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.02,
                      horizontal: screenWidth * 0.04,
                    ),
                  ),
                  initialCountryCode: 'IN',
                  style: TextStyle(fontSize: screenWidth * 0.04),
                  dropdownTextStyle: TextStyle(fontSize: screenWidth * 0.035),
                  onChanged: (phone) {
                    setState(() {
                      _isPhoneValid = phone.completeNumber.length >= 10;
                    });
                  },
                ),
                
                SizedBox(height: screenHeight * 0.04),
                
                // Get OTP Button
                Container(
                  width: double.infinity,
                  height: screenHeight * 0.07,
                  child: ElevatedButton(
                    onPressed: _isPhoneValid ? () {
                      print('Get OTP pressed with: ${_phoneController.text}');
                      // Navigate to OTP page
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const OTPpage()),
                      );
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isPhoneValid 
                          ? const Color(0xFF4CAF50) 
                          : Colors.grey[300],
                      foregroundColor: _isPhoneValid 
                          ? Colors.white 
                          : Colors.grey[600],
                      elevation: _isPhoneValid ? 2 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      ),
                    ),
                    child: Text(
                      'Get OTP',
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                // Bottom spacing
                SizedBox(height: screenHeight * 0.05),
              ],
            ),
          ),
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