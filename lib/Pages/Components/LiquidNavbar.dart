// lib/components/liquid_navbar.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:might_ampora/Pages/Scaning_Option/EnergyPage.dart';
import 'package:might_ampora/Pages/Solar/SolarEngery.dart';

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
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _overlayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _overlayController.dispose();
    super.dispose();
  }

  void _toggleOverlay() {
    if (_showOverlay) {
      _removeOverlay();
    } else {
      _showOverlayMenu();
    }
  }

  void _showOverlayMenu() {
    setState(() => _showOverlay = true);
    _overlayController.forward();

    _overlayEntry = OverlayEntry(
      builder: (context) => _buildOverlayContent(),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayController.reverse().then((_) {
      if (mounted) {
        _overlayEntry?.remove();
        _overlayEntry = null;
        setState(() => _showOverlay = false);
      }
    });
  }

  void _removeOverlayImmediate() {
    // Immediately remove the overlay entry without animation
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _showOverlay = false);
    _overlayController.reset();
  }

  Widget _buildOverlayContent() {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;

    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Black background - tappable to close
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  _toggleOverlay();
                },
                child: AnimatedBuilder(
                  animation: _overlayController,
                  builder: (context, child) {
                    return Container(
                      color: Colors.black.withValues(alpha: 0.45 * _overlayController.value),
                    );
                  },
                ),
              ),
            ),
            // Overlay cards
            Positioned(
              left: 0,
              right: 0,
              bottom: screenH * 0.14,
              child: ScaleTransition(
                scale: _overlayController.drive(
                  Tween<double>(begin: 0.3, end: 1.0).chain(
                    CurveTween(curve: Curves.easeOutBack),
                  ),
                ),
                child: FadeTransition(
                  opacity: _overlayController,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenW * 0.05),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // First card
                        _OverlayItem(
                          imagePath: "images/Overlay/Scan.png",
                          label: "Discover the\nenergy drain",
                          onTap: () {
                            _removeOverlayImmediate();
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => EnergyOnboardingPage()),
                            );
                          },
                        ),
                        SizedBox(height: screenW * 0.03),
                        // Second card
                        _OverlayItem(
                          imagePath: "images/Overlay/Solar.png",
                          label: "Harness the \npower of the \nsun and wind",
                          onTap: () {
                            _removeOverlayImmediate();
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => RenewableEnergyEstimation()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;

    return SizedBox(
      height: screenH * 0.12,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Glassmorphism navbar with gradient border at BOTTOM
          Positioned(
            bottom: 0,
            left: screenW * 0.05,
            right: screenW * 0.05,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(35),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Color(0xFF2E7D32).withValues(alpha: 0.6),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 15,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Color.fromARGB(255, 6, 106, 9).withValues(alpha: 0.6),
                    blurRadius: 10,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(1.5),
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
                      Color(0xFF8EE9BE).withValues(alpha: 0.6),
                      Colors.white.withValues(alpha: 0.1),
                      Color(0xFF8EE9BE).withValues(alpha: 0.6),
                    ],
                  ),
                  borderGradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.3),
                      Colors.white.withValues(alpha: 0.1),
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
    );
  }

  Widget _navItem(IconData icon, int index) {
    final isSelected = widget.currentIndex == index;
    return GestureDetector(
      onTap: () {
        widget.onItemSelected(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          color: const Color(0xFF193B2D),
          size: isSelected ? 34 : 32,
          weight: isSelected ? 700 : 400,
        ),
      ),
    );
  }

  Widget _centerPlusButton() {
    return GestureDetector(
      onTap: () {
        _toggleOverlay();
      },
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
                Colors.white.withValues(alpha: 0.1),
                Color(0xFF2E7D32).withValues(alpha: 0.6),
                Colors.white.withValues(alpha: 0.05),
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
                    color:  Color(0xFF193B2D),
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
}

class _OverlayItem extends StatelessWidget {
  final String imagePath;
  final String label;
  final VoidCallback? onTap;
  
  const _OverlayItem({
    required this.imagePath,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap!();
        }
      },
      child: Container(
        width: double.infinity,
        height: screenHeight * 0.2,
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: screenWidth * 0.04,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFFA726),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            // Image icon on the left
            Container(
              width: screenWidth * 0.35,
              height: screenWidth * 0.35,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Image.asset(
                  imagePath,
                  height: screenWidth * 0.2,
                  width: screenWidth * 0.2,
                  fit: BoxFit.contain,
                  color: Colors.white,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.image_not_supported,
                      size: screenWidth * 0.15,
                      color: Colors.white,
                    );
                  },
                ),
              ),
            ),
            SizedBox(width: screenWidth * 0.05),
            // Label on the right
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.left,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'WorkSans',
                  fontSize: screenWidth * 0.055,
                  fontWeight: FontWeight.w400,
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
