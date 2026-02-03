import 'package:flutter/material.dart';
import '../Components/LiquidNavbar.dart';
import '../Home/HomeScreen.dart';
import '../Home/Profilepage.dart';
import 'ManualDetail.dart';
import 'EnergyPage.dart';
import 'editdetails2.dart';

// ProfileScreen is in Profilepage.dart

class DeviceDetailsPage2 extends StatefulWidget {
  final Map<String, dynamic> data;

  const DeviceDetailsPage2({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  State<DeviceDetailsPage2> createState() => _DeviceDetailsPage2State();
}

class _DeviceDetailsPage2State extends State<DeviceDetailsPage2> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Extract passed data safely
    final deviceName =
        widget.data["deviceName"]?.toString() ?? "Unknown Appliance";
    final powerRating =
        widget.data["powerRating"]?.toString() ?? "Not provided";
    final usageHours = widget.data["usageHours"]?.toString() ?? "Not provided";
    final beeRating = widget.data["beeRating"]?.toString() ?? "Not detected";
    final dailyConsumption = widget.data["dailyConsumption"]?.toString() ?? "0";
    final monthlyCost = widget.data["monthlyCost"]?.toString() ?? "0";
    final co2PerDay = widget.data["co2PerDay"]?.toString() ?? "0";

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: screenWidth * 0.1,
                          height: screenWidth * 0.1,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF2D8B6E),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            color: const Color(0xFF2D8B6E),
                            size: screenWidth * 0.05,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              deviceName,
                              style: TextStyle(
                                fontSize: screenWidth * 0.055,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'WorkSansB',
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.1),
                    ],
                  ),
                ),

                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Blue container with padding - No Image, starts with Monthly Cost
                        Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                          ),
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F4FE),
                            borderRadius: BorderRadius.circular(
                              screenWidth * 0.05,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Row 1: Monthly Cost (full width)
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(screenWidth * 0.02),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(
                                    screenWidth * 0.03,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '₹$monthlyCost/month',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.05,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'WorkSansB',
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Estimated Monthly Cost',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.03,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: screenHeight * 0.015),

                              // Row 2: Power Rating and Daily Usage
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.all(screenWidth * 0.03),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(
                                          screenWidth * 0.03,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            '$powerRating Watts',
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.045,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'WorkSansB',
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            'Power Rating',
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.03,
                                              color: Colors.black87,
                                              fontFamily: 'Worksans',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.03),
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.all(screenWidth * 0.03),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(
                                          screenWidth * 0.03,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            '$usageHours hours/day',
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.045,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'WorkSansB',
                                            ),
                                          ),
                                          Text(
                                            'Daily Usage',
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.03,
                                              color: Colors.black87,
                                              fontFamily: 'Worksans',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: screenHeight * 0.015),

                              // Row 3: Device Health (full width)
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  vertical: screenHeight * 0.012,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(
                                    screenWidth * 0.03,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Device Health is Good',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.045,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF2D8B6E),
                                        fontFamily: 'WorkSansB',
                                      ),
                                    ),
                                    Text(
                                      'Can use it for more years',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.03,
                                        color: Colors.black87,
                                        fontFamily: 'Worksans',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // White background section - Energy Consumption onwards
                        Container(
                          color: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                          ),
                          child: Column(
                            children: [
                              SizedBox(height: screenHeight * 0.02),

                              // Energy Consumption title
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Energy Consumption',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.05,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'WorkSansB',
                                  ),
                                ),
                              ),

                              SizedBox(height: screenHeight * 0.012),

                              // Energy metrics
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: screenWidth * 0.03,
                                        vertical: screenHeight * 0.0225,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          screenWidth * 0.03,
                                        ),
                                        border: Border.all(color: Colors.grey[300]!),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text('≈', 
                                                  style: TextStyle(
                                                    fontSize: screenWidth * 0.04,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFFEF5F00))
                                                    ),
                                              SizedBox(width: 4),
                                              Text(
                                                '$co2PerDay kg',  
                                                style: TextStyle(
                                                  fontSize: screenWidth * 0.045,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFEF5F00),
                                                  fontFamily: 'WorkSansB',
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'CO₂ emissions/ day',
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.03,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                              fontFamily: 'WorkSansB',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.03),
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.all(screenWidth * 0.03),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          screenWidth * 0.03,
                                        ),
                                        border: Border.all(color: Colors.grey[300]!),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '$dailyConsumption units/day',
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.045,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF218358),
                                              fontFamily: 'WorkSansB',
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Estimated Daily Consumption',
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.03,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                              fontFamily: 'WorkSansB',
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: screenHeight * 0.02),

                              // Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => EditDetailsPage2(
                                              data: widget.data,
                                            ),
                                          ),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          vertical: screenHeight * 0.018,
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFF2D8B6E),
                                          width: 2,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            screenWidth * 0.08,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Edit values',
                                            style: TextStyle(
                                              color: const Color(0xFF2D8B6E),
                                              fontSize: screenWidth * 0.038,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'WorkSansSB',
                                            ),
                                          ),
                                          SizedBox(width: screenWidth * 0.015),
                                          Icon(
                                            Icons.arrow_forward,
                                            color: const Color(0xFF2D8B6E),
                                            size: screenWidth * 0.045,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.03),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const EnergyOnboardingPage(),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                        padding: EdgeInsets.symmetric(
                                          vertical: screenHeight * 0.018,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            screenWidth * 0.08,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Go to next device',
                                        style: TextStyle(
                                          fontSize: screenWidth * 0.038,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          fontFamily: 'WorkSansSB',
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.02),
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

          // Bottom Navbar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: LiquidNavbar(
              currentIndex: 0,
              onItemSelected: (index) {
                if (index == 0) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                } else if (index == 1) {
                  // Placeholder for add new device
                } else if (index == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
