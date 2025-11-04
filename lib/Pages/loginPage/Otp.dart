import 'package:flutter/material.dart';
import '../Home/HomeScreen.dart';
import 'package:pinput/pinput.dart';
import 'dart:async';

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
          builder: (context) => const HomeScreen(),
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
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          TextSpan(
                            text: 'Ampora',
                            style: TextStyle(
                              fontSize: screenWidth * 0.08,
                              color: const Color(0xFF2B9A66), // Green color
                              fontWeight: FontWeight.w400,
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
                        onCompleted: (pin) {
                          print('OTP completed: $pin');
                        },
                        onChanged: (pin) {
                          setState(() {
                            _isOtpComplete = pin.length == 4;
                          });
                        },
                      ),
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
                              ? Colors.black
                              : Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: screenHeight * 0.02),
                    
                    // Continue Button
                    SizedBox(
                      width: double.infinity,
                      height: screenHeight * 0.065,
                      child: ElevatedButton(
                        onPressed: _isOtpComplete ? _onContinue : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isOtpComplete 
                              ? const Color(0xFFF59E0B) // Dark green when OTP complete
                              : const Color(0xFFFDD28A), // Light green when incomplete
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(screenWidth * 0.07),
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