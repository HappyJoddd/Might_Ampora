import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:might_ampora/Pages/Scaning_Option/ApplicationPage.dart';
import 'package:might_ampora/Pages/Scaning_Option/Camera.dart';

class EnergyOnboardingPage extends StatelessWidget {
  const EnergyOnboardingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Set status bar color
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
          child: Column(
            children: [
              // Back button
              SizedBox(height: screenHeight * 0.02),
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF2D8B6E),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF2D8B6E),
                      size: 20,
                    ),
                  ),
                ),
              ),
              
              // Main content - centered
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title
                      Text(
                        'Check your\nappliance\'s energy\nconsumption',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 35.83,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          height: 1.3,
                        ),
                      ),
                      
                      SizedBox(height: screenHeight * 0.05),
                      
                      // Scan the device button
                      SizedBox(
                        width: screenWidth * 0.75,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CameraGalleryPickerPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFA726), // Orange color
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Scan the device >>',
                            style: TextStyle(
                              fontSize: 17.28,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: screenHeight * 0.02),
                      
                      // Enter details manually button
                      SizedBox(
                        width: screenWidth * 0.75,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: () {
                            // Handle manual entry
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ApplianceSelectionPage(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFFFA726),
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            backgroundColor: Colors.white,
                          ),
                          child: Text(
                            'Enter details Mannually',
                            style: TextStyle(
                              fontSize: 17.28,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFFA726),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Usage: Navigate to this page from anywhere in your app
// Navigator.push(context, MaterialPageRoute(builder: (context) => EnergyOnboardingPage()));