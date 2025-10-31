import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Components/LiquidNavbar.dart';
import '../Scaning_Option/EnergyPage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onNavItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      // Home
    } else if (index == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add Button Pressed!')),
      );
    } else if (index == 2) {
      Navigator.pushNamed(context, '/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('HomeScreen building...'); // Debug print
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    print('Screen size: $screenWidth x $screenHeight'); // Debug print

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF4CAF50), // Green color matching your header
        statusBarIconBrightness: Brightness.light, // White icons on green background
        statusBarBrightness: Brightness.dark, // For iOS
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          top: false, // Don't apply SafeArea to top so status bar can be colored
          child: Stack(
          children: [
            // Scrollable content
            Positioned.fill(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: screenHeight * 0.12, // Add bottom padding for navbar
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(screenWidth, screenHeight),
                    const SizedBox(height: 20),
  
                    Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Dashboard",
                      style: TextStyle(
                        color: Colors.green.shade900,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                    const SizedBox(height: 10),

                    _infoCard(
                    context,
                    title: "Discover the energy drain",
                    description:
                        "Scan your appliances and track their impact!",
                    buttonText: "Add now !",
                    imagePath: "images/Mask.png",
                    navigateToPage: const EnergyOnboardingPage(),
                  ),
                    _infoCard(
                    context,
                    title: "Pedal your way to a healthier planet!",
                    description:
                        "Scan your appliances and track their impact!",
                    buttonText: "Scan now !",
                    imagePath: "images/Cycle.png",
                    navigateToPage: const EnergyOnboardingPage(),
                  ),
                    _infoCard(
                    context,
                    title: "Add your routine",
                    description:
                        "Add your routines and see their impact on the environment",
                    buttonText: "Add now !",
                    imagePath: "images/Routine.png",
                  ),
                    _infoCard(
                    context,
                    title: "Harness the power of the sun and wind",
                    description: "Find out what works for you today",
                    buttonText: "Scan now !",
                    imagePath: "images/Sun.png",
                  ),
                    _infoCard(
                    context,
                    title: "Join the Green Movement",
                    description: "Connect, Compete, and Create Change!",
                    buttonText: "Join now !",
                    imagePath: "images/Sun.png",
                  ),
                    _infoCard(
                    context,
                    title: "Test Your Eco IQ",
                    description: "Play, Learn, and Grow Greener!",
                    buttonText: "Play now !",
                    imagePath: "images/Sun.png",
                  ),
                  ],
                ),
              ),
            ),

            // Fixed Liquid Navbar at BOTTOM
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: LiquidNavbar(
                currentIndex: _selectedIndex,
                onItemSelected: _onNavItemSelected,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildHeader(double screenWidth, double screenHeight) {
    return Container(
      width: screenWidth,
      height: screenHeight * 0.345, // Increased height to match the design
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Tree illustration in bottom right corner - touches the bottom
          Positioned(
            right: 0,
            bottom: 0,
            child: SizedBox(
              width: screenWidth * 0.6,
              height: screenHeight * 0.5,
              child: Image.asset(
                'images/OBJECTS.png',
                fit: BoxFit.fitWidth, // Changed to cover to ensure it touches bottom
                alignment: Alignment.bottomRight,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if image not found
                  return const Icon(
                    Icons.nature,
                    size: 120,
                    color: Colors.white24,
                  );
                },
              ),
            ),
          ),
          
          
          // Main content
          Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: MediaQuery.of(context).padding.top + 20,
              bottom: 15, // Reduced from 30 to 15
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row with logo and profile
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Full logo image for "Smart Energy Learning Center"
                    Image.asset(
                      'images/Logo_SELc.png',
                      height: 60,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback if image not found
                        return Container(
                          width: screenWidth * 0.55,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.energy_savings_leaf,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        );
                      },
                    ),
                    // Profile avatar
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: const Color(0xFF1B5E20),
                      child: const Text(
                        "HB",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                // Push welcome text and button to bottom
                
                // Welcome text
                const Text(
                  "Hey! Harshil",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.74,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  "DAU, Gandhinagar",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Text(
                  "Ready to save energy and\nhelp the planet?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.4,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
                
                // "Let's go" button
                ElevatedButton(
                  onPressed: () {
                    // Handle button press
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.only(top: 9, bottom: 9, right: 10, left: 14),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Let's go >>",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(
    BuildContext context, {
    required String title,
    required String description,
    required String buttonText,
    required String imagePath,
    Widget? navigateToPage,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFE3F2FD), // Light blue
              const Color(0xFFBBDEFB), // Slightly darker blue
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image at the top
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    imagePath,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.pedal_bike,
                          size: 80,
                          color: Colors.blue.shade400,
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Title
              Text(
                title,
                style: TextStyle(
                  color: const Color(0xFF1E3A5F), // Dark blue
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Description
              Text(
                description,
                style: TextStyle(
                  color: const Color(0xFF5A6C7D), // Medium gray-blue
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    if (navigateToPage != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => navigateToPage),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA726), // Orange
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
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
