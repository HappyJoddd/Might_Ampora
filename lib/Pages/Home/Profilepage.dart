import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:might_ampora/Pages/Components/LiquidNavbar.dart';
import 'package:might_ampora/services/api_service.dart';
import 'package:might_ampora/services/auth_storage.dart';
import 'package:might_ampora/services/activity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'HomeScreen.dart';
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
  String _userPhone = '';
  String _userInitials = 'U';
  
  // Monthly summary data
  int _monthlySteps = 0;
  double _monthlyDrivenKm = 0.0;
  double _monthlySavedCO2 = 0.0;
  bool _isLoadingMonthlySummary = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadMonthlySummary();
  }

  /// Load user's data from storage
  Future<void> _loadUserData() async {
    try {
      final userDetails = await AuthStorage.getUserDetails();
      final fullName = userDetails['name'] ?? 'User';
      final email = userDetails['email'] ?? '';
      final phone = userDetails['phone'] ?? '';
      
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
          _userPhone = phone;
          _userInitials = initials.isNotEmpty ? initials : 'U';
        });
      }
    } catch (e) {
      // Error loading user data - keep defaults
    }
  }

  /// Load monthly summary from backend
  Future<void> _loadMonthlySummary() async {
    try {
      final userDetails = await AuthStorage.getUserDetails();
      final userId = userDetails['userId'];
      
      if (userId != null && userId.isNotEmpty) {
        final summary = await ActivityService.getCurrentMonthlySummary(userId);
        
        if (summary != null && mounted) {
          setState(() {
            _monthlySteps = summary['totalSteps'] ?? 0;
            _monthlyDrivenKm = (summary['totalDrivenKm'] ?? 0).toDouble();
            _monthlySavedCO2 = (summary['totalSavedCO2'] ?? 0).toDouble();
            _isLoadingMonthlySummary = false;
          });
        } else if (mounted) {
          setState(() {
            _isLoadingMonthlySummary = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMonthlySummary = false;
        });
      }
    }
  }

Future<void> _handleLogout() async {
  try {
    // 🔄 First, sync today's data to backend before logout
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDetails = await AuthStorage.getUserDetails();
      final userId = userDetails['userId'];
      
      if (userId != null && userId.isNotEmpty) {
        final today = DateTime.now();
        final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        
        // Get today's data
        final steps = prefs.getInt('steps_$dateStr') ?? prefs.getInt('dailySteps') ?? 0;
        final drivenKm = prefs.getDouble('driven_km_$dateStr') ?? prefs.getDouble('dailyDistance') ?? 0.0;
        
        // Calculate CO2
        final co2SavedByWalking = (steps / 1000) * 0.75 * 0.12;
        final co2EmittedByDriving = drivenKm * 0.12;
        final savedCO2 = co2SavedByWalking - co2EmittedByDriving;
        
        // Save daily activity
        await ActivityService.saveDailyActivity(
          userId: userId,
          steps: steps,
          drivenKm: drivenKm,
          savedCO2: savedCO2,
          date: dateStr,
        );
        
        // Update monthly summary with date for idempotency
        // This prevents double-counting if midnight sync also runs
        final monthStr = '${today.year}-${today.month.toString().padLeft(2, '0')}';
        await ActivityService.updateMonthlySummary(
          userId: userId,
          month: monthStr,
          steps: steps,
          drivenKm: drivenKm,
          savedCO2: savedCO2,
          date: dateStr, // Idempotent - won't double-count if called twice
        );
      }
    } catch (e) {
      // Continue with logout even if sync fails
    }
    
    // Retrieve refresh token before clearing
    final refreshToken = await AuthStorage.getRefreshToken();

    // 🔹 Call backend logout endpoint (optional - continue even if it fails)
    try {
      await ApiService.logout(refreshToken);
    } catch (e) {
      // Backend logout failed, but continue with local logout
    }

    // 🔸 Clear ALL auth data locally
    await AuthStorage.logout();

    if (!mounted) return;

    // 🔁 Force navigate to login page and clear all routes
    Navigator.of(context).pushNamedAndRemoveUntil(
      RouteName.login,
      (route) => false,
    );
  } catch (e) {
    if (!mounted) return;
    
    // Even if something fails, try to clear local data and go to login
    await AuthStorage.logout();
    Navigator.of(context).pushNamedAndRemoveUntil(
      RouteName.login,
      (route) => false,
    );
  }
}

  /// Handle account deletion with confirmation
  Future<void> _handleDeleteAccount() async {
    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            '⚠️ Delete Account?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'WorkSansB',
            ),
          ),
          content: const Text(
            'This action is permanent and cannot be undone.\n'
            'All your data will be permanently deleted:\n'
            '• Profile information\n'
            '• Activity history\n'
            '• All saved data\n'
            'Are you sure you want to delete your account?',
            style: TextStyle(
              fontFamily: 'Worksans',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                  fontFamily: 'WorkSansSB',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'WorkSansB',
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    if (!mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );

    try {
      // Get refresh token
      final refreshToken = await AuthStorage.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        // No token available - clear data and navigate
        if (mounted) Navigator.of(context).pop(); // Close loading
        await AuthStorage.clearAll();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            RouteName.login,
            (route) => false,
          );
        }
        return;
      }

      // Call delete account API
      final result = await ApiService.deleteAccount(refreshToken);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Navigate to login regardless of API response
      // If backend deletion succeeded, account is deleted
      // If it failed, still clear local data and logout
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          RouteName.login,
          (route) => false,
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Clear local data even if API fails
      await AuthStorage.clearAll();

      // Navigate to login
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          RouteName.login,
          (route) => false,
        );
      }
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
                    child: Stack(
                      children: [
                        // Tree illustration in bottom right corner - under the profile card
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: SizedBox(
                            width: screenWidth * 0.6,
                            height: screenHeight * 0.25,
                            child: Image.asset(
                              'images/OBJECTS.png',
                              fit: BoxFit.fitWidth,
                              alignment: Alignment.bottomRight,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback if image not found
                                return const Icon(
                                  Icons.nature,
                                  size: 80,
                                  color: Colors.white24,
                                );
                              },
                            ),
                          ),
                        ),
                        
                        // Main header content
                        SafeArea(
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
                                        if (_userPhone.isNotEmpty)
                                          Text(
                                            _userPhone,
                                            style: TextStyle(
                                              fontSize: screenWidth * 0.035,
                                              color: Colors.grey[600],
                                              fontFamily: 'Worksans',
                                            ),
                                          ),
                                        SizedBox(height: screenHeight * 0.01),
                                      ],
                                    ),
                                  ),
                                  // Badge icon
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

                  // My Energy Summary section
                  Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title aligned to left
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

                        // Stats grid - First row: Energy Saved (full width)
                        _isLoadingMonthlySummary
                            ? Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(screenWidth * 0.04),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withValues(alpha: 0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF4CAF50),
                                  ),
                                ),
                              )
                            : Container(
                                width: double.infinity,
                                child: _buildEnergySavedCard(
                                  screenWidth,
                                  screenHeight,
                                  '${_monthlySavedCO2.toStringAsFixed(1)} kg CO₂eq',
                                  'Energy Saved',
                                  'This Month',
                                  _monthlySavedCO2 > 5 ? Colors.green : (_monthlySavedCO2 > 0 ? Colors.orange : Colors.red),
                                ),
                              ),
                        SizedBox(height: screenHeight * 0.02),
                        // Second row: Steps and Driven kms with icons
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCardWithIcon(
                                screenWidth,
                                screenHeight,
                                _monthlySteps.toString(),
                                'Steps',
                                'This Month',
                                Colors.green,
                                'images/Steps.png',
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Expanded(
                              child: _buildStatCardWithIcon(
                                screenWidth,
                                screenHeight,
                                '${_monthlyDrivenKm.toStringAsFixed(1)} km',
                                'Driven',
                                'This Month',
                                Colors.red,
                                'images/car.png',
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

                        // Log-out
                        _buildSettingItem(
                          screenWidth,
                          'Log-out',
                          Icons.arrow_forward_ios,
                          _handleLogout,
                        ),

                        SizedBox(height: screenHeight * 0.015),

                        // Delete Account
                        _buildSettingItem(
                          screenWidth,
                          'Delete Account',
                          Icons.delete_forever,
                          _handleDeleteAccount,
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
              bottom: screenHeight * 0.025,
              left: 0,
              right: 0,
              child: LiquidNavbar(
                currentIndex: _currentIndex,
                onItemSelected: (index) {
                  if (index == 0) {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  } else if (index == 2) {
                    // Already on profile page
                    setState(() => _currentIndex = index);
                  } else {
                    setState(() => _currentIndex = index);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnergySavedCard(
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
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: screenWidth * 0.06,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'WorkSansB',
            ),
          ),
          SizedBox(height: screenHeight * 0.005),
          Text(
            label,
            style: TextStyle(
              fontSize: screenWidth * 0.04,
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

  Widget _buildStatCardWithIcon(
    double screenWidth,
    double screenHeight,
    String value,
    String label,
    String period,
    Color color,
    String iconPath,
  ) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Value first (centered)
          Text(
            value,
            style: TextStyle(
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'WorkSansB',
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          // Label with icon in a row (centered)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  fontFamily: 'WorkSansSB',
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Image.asset(
                iconPath,
                width: screenWidth * 0.06,
                height: screenWidth * 0.06,
                fit: BoxFit.contain,
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.005),
          // Period last (centered)
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
              color: Colors.grey.withValues(alpha: 0.1),
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
