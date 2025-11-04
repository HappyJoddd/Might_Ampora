// lib/components/liquid_navbar.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:might_ampora/Pages/Home/HomeScreen.dart';
import 'package:might_ampora/Pages/Home/Profilepage.dart';

class LiquidNavbar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  const LiquidNavbar({
    Key? key,
    required this.currentIndex,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  State<LiquidNavbar> createState() => _LiquidNavbarState();
}

class _LiquidNavbarState extends State<LiquidNavbar>
    with SingleTickerProviderStateMixin {
  bool _showOverlay = false;
  late AnimationController _overlayController;

  @override
  void initState() {
    super.initState();
    _overlayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400), // Increased for smoother animation
    );
  }

  @override
  void dispose() {
    _overlayController.dispose();
    super.dispose();
  }

  void _toggleOverlay() {
    setState(() => _showOverlay = !_showOverlay);
    if (_showOverlay) {
      _overlayController.forward();
    } else {
      _overlayController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;

    return Stack(
      clipBehavior: Clip.none, // Allow overlay to extend beyond navbar
      children: [
        // Full screen overlay shown when '+' is tapped (BEHIND navbar)
        if (_showOverlay)
          Positioned(
            top: -screenH + (screenH * 0.12), // Position to cover everything including navbar
            left: 0,
            right: 0,
            bottom: -(screenH * 0.12), // Extend to cover navbar too
            child: Stack(
              children: [
                // Black background fades in from center
                FadeTransition(
                  opacity: _overlayController.drive(
                    CurveTween(curve: Curves.easeInOutCubic),
                  ),
                  child: ScaleTransition(
                    scale: _overlayController.drive(
                      Tween<double>(begin: 0.0, end: 1.0).chain(
                        CurveTween(curve: Curves.easeOutCubic),
                      ),
                    ),
                    child: GestureDetector(
                      onTap: _toggleOverlay,
                      child: Container(
                        width: double.infinity,
                        height: screenH, // Full screen height
                        color: Colors.black.withOpacity(0.45),
                      ),
                    ),
                  ),
                ),
                // Overlay cards scale from center
                Center(
                  child: ScaleTransition(
                    scale: _overlayController.drive(
                      Tween<double>(begin: 0.3, end: 1.0).chain(
                        CurveTween(curve: Curves.easeOutBack), // Bouncy effect from center
                      ),
                    ),
                    child: FadeTransition(
                      opacity: _overlayController.drive(
                        Tween<double>(begin: 0.0, end: 1.0).chain(
                          CurveTween(curve: Curves.easeInOutCubic),
                        ),
                      ),
                      child: _buildOverlayCard(screenW),
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        // Navbar (ON TOP of overlay)
        SizedBox(
          height: screenH * 0.12,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
        // Glassmorphism navbar with gradient border at BOTTOM
        Positioned(
          bottom: screenH * 0.01,
          left: screenW * 0.05,
          right: screenW * 0.05,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(35),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  const Color(0xFF2E7D32).withOpacity(0.6),
                  Colors.white.withOpacity(0.05),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: const Color.fromARGB(255, 6, 106, 9).withOpacity(0.6),
                  blurRadius: 10,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(1.5), // Smaller border width
              child: GlassmorphicContainer(
                width: double.infinity,
                height: screenH * 0.08,
                borderRadius: 33.5,
                blur: 20,
                alignment: Alignment.center,
                border: 0,
                linearGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF8EE9BE).withOpacity(0.6),
                    Colors.white.withOpacity(0.1),
                    const Color(0xFF8EE9BE).withOpacity(0.6),
                  ],
                ),
                borderGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.3),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenW * 0.08,
                    vertical: screenH * 0.01,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Home icon on the left
                      _navItem(Icons.home_outlined, 0),
                      // Spacing
                      SizedBox(width: screenW * 0.05),
                      // Plus button in center with glassmorphism
                      _centerPlusButton(),
                      // Spacing
                      SizedBox(width: screenW * 0.05),
                      // Profile icon on the right
                      _navItem(Icons.person_outline_rounded, 2),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _navItem(IconData icon, int index) {
    final isSelected = widget.currentIndex == index;
    return GestureDetector(
      onTap: () {
        widget.onItemSelected(index);
        // Navigate based on index
        if (index == 0) {
          // Home icon - navigate to HomeScreen
          Get.off(() => const HomeScreen());
        } else if (index == 2) {
          // Profile icon - navigate to ProfilePage
          Get.off(() => const ProfileScreen());
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          color: const Color(0xFF193B2D), // Custom dark green color
          size: isSelected ? 34 : 32,
          weight: isSelected ? 700 : 400,
        ),
      ),
    );
  }

  Widget _centerPlusButton() {
    return GestureDetector(
      onTap: _toggleOverlay,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.1),
                const Color(0xFF2E7D32).withOpacity(0.6),
                Colors.white.withOpacity(0.05),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(1.5),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Icon(
                    _showOverlay ? Icons.close_rounded : Icons.add_rounded,
                    color: const Color(0xFF193B2D),
                    size: 35,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayCard(double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // First row
          Row(
            children: [
              Expanded(
                child: _OverlayItem(
                  imagePath: "images/Overlay/Connect.png",
                  label: "Connect,\nCompete, and\nCreate Change!",
                ),
              ),
              SizedBox(width: screenWidth * 0.04),
              Expanded(
                child: _OverlayItem(
                  imagePath: "images/Overlay/Game.png",
                  label: "Play, Learn, and\nGrow Greener!",
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.04),
          // Second row
          Row(
            children: [
              Expanded(
                child: _OverlayItem(
                  imagePath: "images/Overlay/Scan.png",
                  label: "Discover the\nenergy drain",
                ),
              ),
              SizedBox(width: screenWidth * 0.04),
              Expanded(
                child: _OverlayItem(
                  imagePath: "images/Overlay/Solar.png",
                  label: "Harness the power\nof the sun and wind",
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.04),
          // Third row
          Row(
            children: [
              Expanded(
                child: _OverlayItem(
                  imagePath: "images/Overlay/Routine.png",
                  label: "Add your routine and\nsee their impact",
                ),
              ),
              SizedBox(width: screenWidth * 0.04),
              Expanded(
                child: _OverlayItem(
                  imagePath: "images/Overlay/Cycle.png",
                  label: "Pedal your way to a\nhealthier planet!",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverlayItem extends StatelessWidget {
  final String imagePath;
  final String label;
  const _OverlayItem({required this.imagePath, required this.label});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    
    return GestureDetector(
      onTap: () {
        // handle overlay action: navigate or call callback
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selected: $label')));
      },
      child: Container(
        // Fixed height and width for all items
        height: screenHeight * 0.18,
        width: (screenWidth - (screenWidth * 0.2)) / 2, // Equal width for 2 columns
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: const Color(0xFFFFA726), // Orange color
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image icon with fixed size
            Image.asset(
              imagePath,
              height: screenWidth * 0.12,
              width: screenWidth * 0.12,
              fit: BoxFit.contain,
              color: Colors.white,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.image_not_supported,
                  size: screenWidth * 0.12,
                  color: Colors.white,
                );
              },
            ),
            SizedBox(height: screenWidth * 0.02),
            // Label with fixed size
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth * 0.028,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
