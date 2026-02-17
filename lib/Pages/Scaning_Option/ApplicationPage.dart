import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ManualDetail.dart';
import '../Components/LiquidNavbar.dart';
import '../Home/HomeScreen.dart';
import '../Home/Profilepage.dart';

class ApplianceSelectionPage extends StatefulWidget {
  const ApplianceSelectionPage({Key? key}) : super(key: key);

  @override
  State<ApplianceSelectionPage> createState() => _ApplianceSelectionPageState();
}

class _ApplianceSelectionPageState extends State<ApplianceSelectionPage> {
  int _selectedIndex = 0;

  void _onNavItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      // Home
      Navigator.popUntil(context, (route) => route.isFirst);
    } else if (index == 1) {
      // Add button tapped
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    }
  }

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
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: screenWidth * 0.05,
                right: screenWidth * 0.05,
                top: screenHeight * 0.02,
                bottom: screenHeight * 0.12, // Space for navbar
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button and title
                  Row(
                    children: [
                      GestureDetector(
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
                      SizedBox(width: screenWidth * 0.03),
                      // Title
                      Text(
                        'Home Energy\nConsumption Setup',
                        style: TextStyle(
                          fontSize: 24.88,
                          color: Colors.black,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: screenHeight * 0.015),
                  
                  // Appliances Grid - Compact to fit all on one screen
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: screenWidth * 0.03,
                      mainAxisSpacing: screenHeight * 0.012,
                      childAspectRatio: 1.53, // Increased to make cards shorter
                      physics: const NeverScrollableScrollPhysics(), // Disable scrolling
                      children: [
                    _buildApplianceCard(
                      context,
                      screenWidth,
                      screenHeight,
                      'Fan',
                      'images/Appliance/Fan.png',
                      Colors.grey.shade600,
                      '75',
                    ),
                    _buildApplianceCard(
                      context,
                      screenWidth,
                      screenHeight,
                      'Refrigerator',
                      'images/Appliance/Fridge.png',
                      Colors.grey.shade600,
                      '400',
                    ),
                    _buildApplianceCard(
                      context,
                      screenWidth,
                      screenHeight,
                      'Air Conditioner',
                      'images/Appliance/AC.png',
                      Colors.grey.shade600,
                      '2000',
                    ),
                    _buildApplianceCard(
                      context,
                      screenWidth,
                      screenHeight,
                      'Washing Machine',
                      'images/Appliance/WashingMachine.png',
                      Colors.grey.shade600,
                      '700',
                    ),
                    _buildApplianceCard(
                      context,
                      screenWidth,
                      screenHeight,
                      'Microwave Oven',
                      'images/Appliance/Microwave.png',
                      Colors.grey.shade600,
                      '1200',
                    ),
                    _buildApplianceCard(
                      context,
                      screenWidth,
                      screenHeight,
                      'Television',
                      'images/Appliance/TV.png',
                      Colors.grey.shade600,
                      '100',
                    ),
                    _buildApplianceCard(
                      context,
                      screenWidth,
                      screenHeight,
                      'Water Heater',
                      'images/Appliance/WaterHeater.png',
                      Colors.grey.shade600,
                      '2000',
                    ),
                    _buildApplianceCard(
                      context,
                      screenWidth,
                      screenHeight,
                      'Room Heater',
                      'images/Appliance/RoomHeater.png',
                      Colors.grey.shade600,
                      '1500',
                    ),
                    _buildApplianceCard(
                      context,
                      screenWidth,
                      screenHeight,
                      'Air Cooler',
                      'images/Appliance/AirCooler.png',
                      Colors.grey.shade600,
                      '200',
                    ),
                    _buildAddCard(
                      context,
                      screenWidth,
                      screenHeight,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
        
        // Bottom Navigation Bar
        Positioned(
          bottom: screenHeight * 0.025,
          left: 0,
          right: 0,
          child: LiquidNavbar(
            currentIndex: _selectedIndex,
            onItemSelected: _onNavItemSelected,
          ),
        ),
        SizedBox(height: screenHeight * 0.02),
      ],
    ),
    );
  }

  Widget _buildApplianceCard(
    BuildContext context,
    double screenWidth,
    double screenHeight,
    String title,
    String imagePath,
    Color textColor,
    String powerRating,
  ) {
    return GestureDetector(
      onTap: () {
        // Navigate directly to manual detail page with appliance name and power rating
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ManualDetailPage(
              applianceName: title,
              powerRating: powerRating,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Appliance Image
            Image.asset(
              imagePath,
              height: screenWidth * 0.11,
              width: screenWidth * 0.11,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.image_not_supported,
                  size: screenWidth * 0.11,
                  color: Colors.grey.shade400,
                );
              },
            ),
            SizedBox(height: screenHeight * 0.008),
            // Appliance Name
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenWidth * 0.032,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'WorkSansM',
                  color: textColor,
                  height: 1.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCard(
    BuildContext context,
    double screenWidth,
    double screenHeight,
  ) {
    return GestureDetector(
      onTap: () {
        // Navigate to manual detail page with empty device name and power rating
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ManualDetailPage(
              applianceName: "",
              powerRating: "",
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: screenWidth * 0.11,
              color: const Color(0xFF4CAF50),
            ),
            SizedBox(height: screenHeight * 0.008),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
              child: Text(
                'Other Appliances',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenWidth * 0.032,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'WorkSansM',
                  color: const Color(0xFF4CAF50),
                  height: 1.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}