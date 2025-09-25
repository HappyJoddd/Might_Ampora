import 'package:flutter/material.dart';
import 'package:might_ampora/Pages/OpeningScreen/ApplicationPage.dart';

class EnergyOnboardingPage extends StatelessWidget {
  const EnergyOnboardingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Check your first\nappliance\'s energy?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenWidth * 0.08,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.075),
                    SizedBox(
                      width: screenWidth * 0.84,
                      height: screenHeight * 0.07,
                      child: ElevatedButton(
                        onPressed: () {
                                Navigator.push(
                                  context, 
                                  MaterialPageRoute(builder: (context) => ApplianceSelectionPage())
                                );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4CAF50), // Green color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(screenWidth * 0.03),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Yes, let\'s measure',
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    TextButton(
                      onPressed: () {
                        // Handle skip button press
                        print('Skip button pressed');
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Skip for now',
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              color: Color(0xFF4CAF50),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Icon(
                            Icons.arrow_forward,
                            color: Color(0xFF4CAF50),
                            size: screenWidth * 0.045,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Usage: Navigate to this page from anywhere in your app
// Navigator.push(context, MaterialPageRoute(builder: (context) => EnergyOnboardingPage()));