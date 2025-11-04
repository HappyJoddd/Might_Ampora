import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Components/LiquidNavbar.dart';

class RenewableEnergyEstimation extends StatefulWidget {
  const RenewableEnergyEstimation({super.key});

  @override
  State<RenewableEnergyEstimation> createState() => _RenewableEnergyEstimationState();
}

class _RenewableEnergyEstimationState extends State<RenewableEnergyEstimation> {
  final MapController _mapController = MapController();
  LatLng _currentPosition = LatLng(28.6139, 77.2090); // Default Delhi
  int _selectedNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchSuggestions = [];
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _searchSuggestions = [];
      });
      return;
    }

    if (_searchController.text.length >= 3) {
      _searchLocation(_searchController.text);
    }
  }

  Future<void> _searchLocation(String query) async {
    try {
      // Using Nominatim API (OpenStreetMap's free geocoding service)
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5&addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'MightAmpora/1.0',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = json.decode(response.body);
        setState(() {
          _searchSuggestions = results;
        });
      }
    } catch (e) {
      print('Error searching location: $e');
    }
  }

  void _selectLocation(dynamic place) {
    final lat = double.parse(place['lat']);
    final lon = double.parse(place['lon']);
    final displayName = place['display_name'];

    setState(() {
      _currentPosition = LatLng(lat, lon);
      _searchController.text = displayName;
      _searchSuggestions = [];
      _searchFocusNode.unfocus();
    });

    // Move map to selected location with offset
    final offsetLat = lat - 0.008;
    _mapController.move(LatLng(offsetLat, lon), 15.0);
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });

        // Offset the map center to show marker above bottom sheet
        // Negative offset moves the map view down, showing the marker upward in visible area
        final offsetLat = _currentPosition.latitude - 0.008;
        _mapController.move(LatLng(offsetLat, _currentPosition.longitude), 15.0);
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _onNavItemSelected(int index) {
    setState(() {
      _selectedNavIndex = index;
    });
    // Handle navigation based on index
    if (index == 0) {
      Navigator.pop(context); // Go back to home
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Offset map center to show marker above bottom sheet
    // Negative offset moves the map view down, showing the marker upward
    final offsetPosition = LatLng(
      _currentPosition.latitude - 0.008,
      _currentPosition.longitude,
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: SizedBox(
            height: screenHeight,
            child: Stack(
              children: [
                // OpenStreetMap Background
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: offsetPosition,
                    initialZoom: 15.0,
                    minZoom: 5.0,
                    maxZoom: 18.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.might_ampora',
                      maxZoom: 19,
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentPosition,
                          width: 50,
                          height: 50,
                          child: Icon(
                            Icons.location_on,
                            size: 50,
                            color: const Color(0xFF2B9A66),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

          // Top Header with back button and title
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + screenHeight * 0.01,
                bottom: screenHeight * 0.015,
                left: screenWidth * 0.04,
                right: screenWidth * 0.04,
              ),
              decoration: BoxDecoration(
                color: Colors.transparent,
              ),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: screenWidth * 0.11,
                          height: screenWidth * 0.11,
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
                  SizedBox(width: screenWidth * 0.03),
                  // Title
                  Expanded(
                    child: Text(
                      'Renewable Energy Estimation',
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  // Current Location button
                  GestureDetector(
                    onTap: () => _getCurrentLocation(),
                    child: Container(
                      width: screenWidth * 0.11,
                      height: screenWidth * 0.11,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.my_location,
                        color: const Color(0xFF2D8B6E),
                        size: screenWidth * 0.05,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search bar with autocomplete
          Positioned(
            top: MediaQuery.of(context).padding.top + screenHeight * 0.085,
            left: screenWidth * 0.04,
            right: screenWidth * 0.04,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, screenHeight * 0.0025),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Search location...',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: screenWidth * 0.04,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey[400],
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: Colors.grey[400],
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchSuggestions = [];
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenHeight * 0.017,
                        ),
                      ),
                    ),
                  ),
                  // Search suggestions dropdown
                  if (_searchSuggestions.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(top: screenHeight * 0.01),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, screenHeight * 0.0025),
                          ),
                        ],
                      ),
                      constraints: BoxConstraints(
                        maxHeight: screenHeight * 0.35,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const ClampingScrollPhysics(),
                        itemCount: _searchSuggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _searchSuggestions[index];
                          return ListTile(
                            leading: Icon(
                              Icons.location_on,
                              color: const Color(0xFF2B9A66),
                              size: screenWidth * 0.05,
                            ),
                            title: Text(
                              suggestion['display_name'] ?? '',
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _selectLocation(suggestion),
                          );
                        },
                      ),
                    ),
              ],
            ),
          ),

          // Bottom sheet with energy details
          Positioned(
            bottom: 0,
            left: screenWidth * 0.04,
            right: screenWidth * 0.04,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(screenWidth * 0.06),
                  topRight: Radius.circular(screenWidth * 0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, screenHeight * -0.0025),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: EdgeInsets.only(top: screenHeight * 0.015),
                    width: screenWidth * 0.1,
                    height: screenHeight * 0.005,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.05,
                      vertical: screenHeight * 0.02,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          'Energy Consumption',
                          style: TextStyle(
                            fontSize: screenWidth * 0.055,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),


                        // Sunlight Hours Card
                        _buildEnergyCard(
                          context: context,
                          title: 'Sunlight Hours',
                          value: '12hrs /day',
                          subtitle: 'Daily average\nsunlight hours',
                          description:
                              'Your location gets enough sunlight for solar power! Install a solar system to cut electricity bills, generate clean energy, and support a sustainable future.',
                          valueColor: const Color(0xFF2B9A66),
                          icon: Icons.wb_sunny,
                        ),

                        // Wind Potential Card
                        _buildEnergyCard(
                          context: context,
                          title: 'Wind Potential',
                          value: '1.7 m/s',
                          subtitle: 'wind speed',
                          description:
                              'The average wind speed at your location is too low for efficient wind power generation.',
                          valueColor: const Color(0xFFEF5F00),
                          icon: Icons.air,
                        ),

                        SizedBox(height: screenHeight * 0.1), // Space for navbar
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
              currentIndex: _selectedNavIndex,
              onItemSelected: _onNavItemSelected,
            ),
          ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnergyCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required String description,
    required Color valueColor,
    required IconData icon,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: screenHeight * 0.02,
        horizontal: 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),

          SizedBox(height: screenHeight * 0.015),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side - Value and subtitle in box
              // Width is half of bottom sheet content width
              // Bottom sheet width = screenWidth - (2 * margin) - (2 * padding)
              // = screenWidth - (2 * 0.04 * screenWidth) - (2 * 0.05 * screenWidth)
              // = screenWidth * (1 - 0.08 - 0.10) = screenWidth * 0.82
              // Half of that = screenWidth * 0.41
              Container(
                width: (screenWidth * 0.82) / 2,
                padding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.015,
                  horizontal: screenWidth * 0.03,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E8E8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.bold,
                        color: valueColor,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: screenWidth * 0.04),

              // Right side - Description
              Expanded(
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: screenWidth * 0.03,
                    color: valueColor,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
