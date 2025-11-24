import 'package:flutter/material.dart';
import '../Components/LiquidNavbar.dart';
import '../Home/HomeScreen.dart';
import '../Home/Profilepage.dart';
import 'ManualDetail.dart';

// ProfileScreen is in Profilepage.dart

class DeviceDetails2Page extends StatefulWidget {
  final Map<String, dynamic> data;

  const DeviceDetails2Page({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  State<DeviceDetails2Page> createState() => _DeviceDetails2PageState();
}

class _DeviceDetails2PageState extends State<DeviceDetails2Page> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Extract passed data safely
    final deviceName =
        widget.data["deviceName"]?.toString() ?? "Unknown Appliance";
    final brand = widget.data["brand"]?.toString() ?? "Unknown Brand";
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
                            Text(
                              brand,
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                color: Colors.grey[600],
                                fontFamily: 'Worksans',
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
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                    ),
                    child: Column(
                      children: [
                        // Rating and Monthly Cost (swapped positions)
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
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(5, (index) {
                                        final rating =
                                            int.tryParse(
                                              beeRating.replaceAll(
                                                RegExp(r'[^0-9]'),
                                                '',
                                              ),
                                            ) ??
                                            0;
                                        return Icon(
                                          index < rating
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: Colors.amber,
                                          size: screenWidth * 0.05,
                                        );
                                      }),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'BEE Star Rating',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.03,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'WorkSansSB',
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
                                      '₹$monthlyCost/month',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.04,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'WorkSansB',
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Monthly Cost',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.03,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'WorkSansSB',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: screenHeight * 0.015),

                        // Power and Usage Info
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
                                      ),
                                    ),
                                    Text(
                                      'Power Rating',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.03,
                                        color: Colors.grey[700],
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
                                      'Average Daily Usage',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.03,
                                        color: Colors.grey[700],
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

                        // Device Health banner
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            vertical: screenHeight * 0.012,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5F1),
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
                                  color: Colors.grey[700],
                                  fontFamily: 'Worksans',
                                ),
                              ),
                            ],
                          ),
                        ),

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
                                        Icon(
                                          Icons.eco_outlined,
                                          color: Colors.orange,
                                          size: screenWidth * 0.05,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          '0.11 kg',
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.045,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange,
                                            fontFamily: 'WorkSansB',
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '$co2PerDay kg',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.045,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
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
                                      '0.14 units/day',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.045,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF2D8B6E),
                                        fontFamily: 'WorkSansB',
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '$dailyConsumption units/day',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.045,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF2D8B6E),
                                        fontFamily: 'WorkSansB',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.pop(context); // Go back to edit
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
                                  // Navigate to ManualDetail page
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ManualDetailPage(
                                            applianceName: deviceName,
                                          ),
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
                        SizedBox(height: screenHeight * 0.1),
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
