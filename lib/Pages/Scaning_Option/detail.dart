import 'package:flutter/material.dart';
import 'dart:io';
import '../Components/LiquidNavbar.dart';
import '../Home/HomeScreen.dart';
import '../Home/Profilepage.dart';

class DeviceDetailsPage extends StatefulWidget {
  final File imageFile;
  final Map<String, dynamic> data;

  const DeviceDetailsPage({
    Key? key,
    required this.imageFile,
    required this.data,
  }) : super(key: key);

  @override
  State<DeviceDetailsPage> createState() => _DeviceDetailsPageState();
}

class _DeviceDetailsPageState extends State<DeviceDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Extract passed data safely
    final deviceName = widget.data["deviceName"]?.toString() ?? "Unknown Appliance";
    final brand = widget.data["brand"]?.toString() ?? "Unknown Brand";
    final powerRating = widget.data["powerRating"]?.toString() ?? "Not provided";
    final usageHours = widget.data["usageHours"]?.toString() ?? "Not provided";
    final beeRating = widget.data["beeRating"]?.toString() ?? "Not detected";

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
                              ),
                            ),
                            Text(
                              brand,
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                color: Colors.grey[600],
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
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                    child: Column(
                      children: [
                        // Image Container
                        Container(
                          width: double.infinity,
                          height: screenHeight * 0.2,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5F1),
                            borderRadius: BorderRadius.circular(screenWidth * 0.04),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(screenWidth * 0.04),
                            child: Image.file(
                              widget.imageFile,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.image,
                                    size: screenWidth * 0.15,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        SizedBox(height: screenHeight * 0.015),

                        // Rating and Device Health
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.all(screenWidth * 0.03),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: List.generate(
                                        5,
                                        (index) {
                                          final rating = int.tryParse(beeRating.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                                          return Icon(
                                            index < rating ? Icons.star : Icons.star_border,
                                            color: Colors.amber,
                                            size: screenWidth * 0.05,
                                          );
                                        },
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'BEE Star Rating',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.03,
                                        fontWeight: FontWeight.w600,
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
                                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Good',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.045,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF2D8B6E),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Device Health',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.03,
                                        fontWeight: FontWeight.w600,
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
                                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '$powerRating Watts',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.045,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Power Rating',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.03,
                                        color: Colors.grey[700],
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
                                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      '$usageHours hours/day',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.045,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Average Daily Usage',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.03,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: screenHeight * 0.015),

                        // Monthly cost (sample static, can be computed later)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.012),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5F1),
                            borderRadius: BorderRadius.circular(screenWidth * 0.03),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '₹112.50/month',
                            style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Estimated Monthly Cost (based on ₹6/unit)',
                            style: TextStyle(fontSize: screenWidth * 0.03, color: Colors.grey[700]),
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
                        style: TextStyle(fontSize: screenWidth * 0.05, fontWeight: FontWeight.bold),
                                ),
                              ),

                    SizedBox(height: screenHeight * 0.012),

                    // Energy metrics
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: screenHeight * 0.0225),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(screenWidth * 0.03),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.eco_outlined, color: Colors.orange, size: screenWidth * 0.05),
                                    SizedBox(width: 4),
                              Text(
                                      '0.11 kg',
                                      style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold, color: Colors.orange),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'CO₂ emissions/ day',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: screenWidth * 0.028, color: Colors.grey[700]),
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
                              borderRadius: BorderRadius.circular(screenWidth * 0.03),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '0.14 units/day',
                                  style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold, color: const Color(0xFF2D8B6E)),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Estimated Daily\nConsumption',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: screenWidth * 0.028, color: Colors.grey[700]),
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
                                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.018),
                                  side: const BorderSide(color: Color(0xFF2D8B6E), width: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(screenWidth * 0.08),
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
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.015),
                                    Icon(Icons.arrow_forward, color: const Color(0xFF2D8B6E), size: screenWidth * 0.045),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.018),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(screenWidth * 0.08),
                                  ),
                                ),
                                child: Text(
                                  'Go to next device',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.038,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
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
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
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
