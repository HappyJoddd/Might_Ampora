import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'dart:async';
import 'package:might_ampora/Pages/OpeningScreen/OpeningScreen1.dart';
import 'package:might_ampora/Pages/OpeningScreen/EnergyPage.dart';

class OTPpage extends StatefulWidget {
  const OTPpage({Key? key}) : super(key: key);

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
        setState(() {
          _remainingTime--;
        });
      } else {
        setState(() {
          _isResendEnabled = true;
        });
        timer.cancel();
      }
    });
  }

  void _resendOtp() {
    if (_isResendEnabled) {
      // Add your resend OTP logic here
      print('Resending OTP...');
      _startTimer();
    }
  }

  void _onContinue() {
    if (_pinController.text.length == 4) {
      // OTP verification logic here
      print('OTP entered: ${_pinController.text}');
      
      // Navigate to Energy Story selection page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const EnergyOnboardingPage(),
        ),
      );
    } else {
      // Show error for incomplete OTP
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter complete OTP'),
          backgroundColor: Colors.red,
        ),
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
    
    // Dynamic sizing based on screen width
    var pinWidth = screenWidth * 0.15; // 15% of screen width
    var pinHeight = pinWidth; // Keep it square
    var fontSize = screenWidth * 0.06; // 6% of screen width
    
    final defaultPinTheme = PinTheme(
      width: pinWidth,
      height: pinHeight,
      textStyle: TextStyle(
        fontSize: fontSize,
        color: Colors.black,
        fontWeight: FontWeight.w500,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.5,
        ),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(
          color: const Color(0xFF4CAF50), // Green color for focused state
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.1),
            blurRadius: screenWidth * 0.02,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: const Color(0xFF4CAF50).withOpacity(0.1),
        border: Border.all(
          color: const Color(0xFF4CAF50),
          width: 1.5,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenHeight,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: screenHeight * 0.06),
                    
                    // Welcome text and app name
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
                              color: const Color(0xFFEF5F00), // Orange color
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: 'Ampora',
                            style: TextStyle(
                              fontSize: screenWidth * 0.08,
                              color: const Color(0xFF2B9A66), // Green color
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: screenHeight * 0.08),
                    
                    // Enter your OTP text
                    Text(
                      'Enter your OTP',
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    SizedBox(height: screenHeight * 0.03),
                    
                    // OTP Input Fields
                    Pinput(
                      controller: _pinController,
                      focusNode: _focusNode,
                      length: 4,
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: focusedPinTheme,
                      submittedPinTheme: submittedPinTheme,
                      showCursor: true,
                      cursor: Container(
                        width: 2,
                        height: screenWidth * 0.06,
                        color: const Color(0xFF4CAF50),
                      ),
                      onCompleted: (pin) {
                        print('OTP completed: $pin');
                      },
                      onChanged: (pin) {
                        setState(() {
                          _isOtpComplete = pin.length == 4;
                        });
                      },
                    ),
                    
                    SizedBox(height: screenHeight * 0.04),
                    
                    // Resend OTP
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _resendOtp,
                        child: Text(
                          '*Resend OTP',
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            color: _isResendEnabled 
                              ? const Color(0xFF4CAF50) 
                              : Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                            decoration: _isResendEnabled 
                              ? TextDecoration.underline 
                              : TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: screenHeight * 0.03),
                    
                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      height: screenHeight * 0.065,
                      child: ElevatedButton(
                        onPressed: _isOtpComplete ? _onContinue : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isOtpComplete 
                              ? const Color(0xFF2E7D32) // Dark green when OTP complete
                              : const Color(0xFFA8D8A8), // Light green when incomplete
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(screenWidth * 0.03),
                          ),
                        ),
                        child: Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: screenHeight * 0.02),
                    
                    // Remaining time
                    Text(
                      'Remaining time: ${_remainingTime}s',
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    
                    SizedBox(height: screenHeight * 0.04),
                    
                    // Bottom indicator (navigation bar indicator)
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