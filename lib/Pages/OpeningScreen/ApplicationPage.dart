import 'package:flutter/material.dart';

class ApplianceSelectionPage extends StatelessWidget {
  const ApplianceSelectionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.only(
          left: screenWidth * 0.08,
          right: screenWidth * 0.08,
          top: screenHeight * 0.1,
          bottom: screenHeight * 0.03,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: screenHeight * 0.03),
            Text(
              'Check your\nappliance\'s energy?',
              style: TextStyle(
                fontSize: screenWidth * 0.08,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                height: 1.2,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: screenWidth * 0.04,
                mainAxisSpacing: screenHeight * 0.02,
                childAspectRatio: 1.0,
                children: [
                  _buildApplianceCard(
                    context,
                    screenWidth,
                    screenHeight,
                    'Fan',
                    Icons.air,
                    Color(0xFF4CAF50),
                  ),
                  _buildApplianceCard(
                    context,
                    screenWidth,
                    screenHeight,
                    'TV',
                    Icons.tv,
                    Colors.grey.shade700,
                  ),
                  _buildApplianceCard(
                    context,
                    screenWidth,
                    screenHeight,
                    'Fridge',
                    Icons.kitchen,
                    Colors.grey.shade700,
                  ),
                  _buildApplianceCard(
                    context,
                    screenWidth,
                    screenHeight,
                    'A.C.',
                    Icons.ac_unit,
                    Colors.grey.shade700,
                  ),
                  _buildApplianceCard(
                    context,
                    screenWidth,
                    screenHeight,
                    'Washing\nMachine',
                    Icons.local_laundry_service,
                    Colors.grey.shade700,
                  ),
                  _buildAddCard(
                    context,
                    screenWidth,
                    screenHeight,
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.05),
            ],
          ),
        ),
      );
  }

  Widget _buildApplianceCard(
    BuildContext context,
    double screenWidth,
    double screenHeight,
    String title,
    IconData icon,
    Color iconColor,
  ) {
    return GestureDetector(
        onTap: () {
           print('Selected appliance: $title');// Handle appliance selection
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: screenWidth * 0.12,
              color: iconColor,
            ),
            SizedBox(height: screenHeight * 0.015),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w500,
                color: iconColor,
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
        print('Add new appliance');
        // Handle add new appliance
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.add,
            size: screenWidth * 0.12,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

// Usage: Navigate from EnergyOnboardingPage
// In the "Yes, let's measure" button onPressed:
// Navigator.push(context, MaterialPageRoute(builder: (context) => ApplianceSelectionPage()));