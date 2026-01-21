import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:might_ampora/Pages/Components/LiquidNavbar.dart';
import 'package:might_ampora/Pages/Home/HomeScreen.dart';
import 'package:might_ampora/services/api_service.dart';
import 'package:might_ampora/services/auth_storage.dart';
import 'package:might_ampora/Routes/routes_name.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _currentIndex = 2; // Profile is at index 2
  String _userName = 'User';
  String _userEmail = '';
  String _userInitials = 'U';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Load user's data from storage
  Future<void> _loadUserData() async {
    try {
      final userDetails = await AuthStorage.getUserDetails();
      final fullName = userDetails['name'] ?? 'User';
      final email = userDetails['email'] ?? '';
      
      // Extract initials (first name initial + last name initial)
      final nameParts = fullName.trim().split(' ');
      String initials = '';
      if (nameParts.isNotEmpty) {
        initials = nameParts[0][0].toUpperCase(); // First name initial
        if (nameParts.length > 1) {
          initials += nameParts[nameParts.length - 1][0].toUpperCase(); // Last name initial
        }
      }
      
      if (mounted) {
        setState(() {
          _userName = fullName;
          _userEmail = email;
          _userInitials = initials.isNotEmpty ? initials : 'U';
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

Future<void> _handleLogout() async {
  try {
    // Retrieve refresh token before clearing
    final refreshToken = await AuthStorage.getRefreshToken();

    // 🔹 Call backend logout endpoint
    await ApiService.logout(refreshToken);

    // 🔸 Locally clear auth tokens but keep hasRegistered = true
    await AuthStorage.logout();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("👋 Logged out successfully.")),
    );

    // 🔁 Navigate to login & clear navigation stack using GetX
    Get.offAllNamed(RouteName.login);
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("🚨 Logout failed: $e")));
  }
}

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Stack(
          children: [
            // Main content
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Green header section
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF4CAF50),
                          const Color(0xFF66BB6A),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsets.all(screenWidth * 0.04),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              'Profile',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.08,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'WorkSansB',
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            // Profile Card
                            Container(
                              padding: EdgeInsets.all(screenWidth * 0.04),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  // Avatar
                                  Container(
                                    width: screenWidth * 0.18,
                                    height: screenWidth * 0.18,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF1E3A5F),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        _userInitials,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: screenWidth * 0.06,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'WorkSansB',
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.04),
                                  // User info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _userName,
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.05,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                            fontFamily: 'WorkSansB',
                                          ),
                                        ),
                                        SizedBox(height: screenHeight * 0.005),
                                        if (_userEmail.isNotEmpty)
                                          Text(
                                            _userEmail,
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.035,
                                              color: Colors.grey[600],
                                              fontFamily: 'Worksans',
                                            ),
                                          ),
                                        SizedBox(height: screenHeight * 0.01),
                                        Text(
                                          'Green Beginner',
                                          style: TextStyle(
                                            fontSize: screenWidth * 0.035,
                                            color: const Color(0xFF4CAF50),
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'WorkSansSB',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Badge icon
                                  Image.asset(
                                    'images/Logo.png',
                                    width: screenWidth * 0.15,
                                    height: screenWidth * 0.15,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: screenWidth * 0.15,
                                        height: screenWidth * 0.15,
                                        decoration: BoxDecoration(
                                          color: Colors.green[100],
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.eco,
                                          color: Colors.green,
                                          size: screenWidth * 0.08,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // My Energy Summary section
                  Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Energy Summary',
                          style: TextStyle(
                            fontSize: screenWidth * 0.055,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontFamily: 'WorkSansB',
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),

                        // Stats grid
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                screenWidth,
                                screenHeight,
                                '10 kg CO₂eq',
                                'Energy Saved',
                                'This Month',
                                Colors.orange,
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Expanded(
                              child: _buildStatCard(
                                screenWidth,
                                screenHeight,
                                '102',
                                'Steps 🚶',
                                'This Month',
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                screenWidth,
                                screenHeight,
                                '10 kms',
                                'Cycling 🚴',
                                'This Month',
                                Colors.green,
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Expanded(
                              child: _buildStatCard(
                                screenWidth,
                                screenHeight,
                                '5 kms',
                                'Driven 🚗',
                                'This Month',
                                Colors.red,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: screenHeight * 0.03),

                        // Preferences & Settings section
                        Text(
                          'Preferences & Settings',
                          style: TextStyle(
                            fontSize: screenWidth * 0.055,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontFamily: 'WorkSansB',
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),

                        // Edit login info
                        _buildSettingItem(
                          screenWidth,
                          'Log-out',
                          Icons.arrow_forward_ios,
                          _handleLogout,
                        ),

                        SizedBox(height: screenHeight * 0.015),

                        // Log-out
                        _buildSettingItem(
                          screenWidth,
                          'Log-out',
                          Icons.arrow_forward_ios,
                          () {
                            // Handle logout
                          },
                        ),

                        // Add bottom padding for navbar
                        SizedBox(height: screenHeight * 0.15),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Navigation Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: LiquidNavbar(
                currentIndex: _currentIndex,
                onItemSelected: (index) {
                  // LiquidNavbar handles navigation internally, just update the index
                  setState(() => _currentIndex = index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    double screenWidth,
    double screenHeight,
    String value,
    String label,
    String period,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'WorkSansB',
            ),
          ),
          SizedBox(height: screenHeight * 0.005),
          Text(
            label,
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              fontFamily: 'WorkSansSB',
            ),
          ),
          SizedBox(height: screenHeight * 0.003),
          Text(
            period,
            style: TextStyle(
              fontSize: screenWidth * 0.03,
              color: Colors.grey[600],
              fontFamily: 'Worksans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    double screenWidth,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                fontFamily: 'WorkSansM',
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFFA726),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: screenWidth * 0.04),
            ),
          ],
        ),
      ),
    );
  }
}
