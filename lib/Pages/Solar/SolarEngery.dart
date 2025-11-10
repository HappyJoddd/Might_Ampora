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
  State<RenewableEnergyEstimation> createState() =>
      _RenewableEnergyEstimationState();
}

class _RenewableEnergyEstimationState extends State<RenewableEnergyEstimation> {
  final MapController _mapController = MapController();
  LatLng _currentPosition = LatLng(28.6139, 77.2090); // Default Delhi
  int _selectedNavIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchSuggestions = [];
  final FocusNode _searchFocusNode = FocusNode();

  bool _isLoading = true;
  double? _avgSolarKwh;
  String _solarQuality = "";
  double? _recentIrradiance;
  double? _windSpeed;

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
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5&addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'MightAmpora/1.0'},
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

    final offsetLat = lat - 0.008;
    _mapController.move(LatLng(offsetLat, lon), 15.0);

    _fetchSolarData(lat, lon);
  }

Future<void> _getCurrentLocation() async {
  try {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      print('🚫 Location permanently denied. Using default location.');
      await _fetchSolarData(_currentPosition.latitude, _currentPosition.longitude);
      return;
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      print('⚠️ User denied or unable to determine location.');
      await _fetchSolarData(_currentPosition.latitude, _currentPosition.longitude);
      return;
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });

      final offsetLat = _currentPosition.latitude - 0.008;
      _mapController.move(
        LatLng(offsetLat, _currentPosition.longitude),
        15.0,
      );

      await _fetchSolarData(position.latitude, position.longitude);
    }
  } catch (e) {
    print('🚨 Error getting location: $e');
    await _fetchSolarData(_currentPosition.latitude, _currentPosition.longitude);
  }
}

  /// Fetch solar + wind data from backend or Open-Meteo
Future<void> _fetchSolarData(double lat, double lon) async {
  if (!mounted) return;
  setState(() => _isLoading = true);

  try {
    print('🌞 Fetching Solar & Wind data for $lat, $lon');

    // Build both Open-Meteo URIs
    final solarUri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '$lat',
      'longitude': '$lon',
      'daily': 'shortwave_radiation_sum',
      'timezone': 'auto',
    });

    final windUri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': '$lat',
      'longitude': '$lon',
      'hourly': 'windspeed_10m',
      'timezone': 'auto',
    });

    // Fetch both concurrently
    final responses = await Future.wait([
      http.get(solarUri),
      http.get(windUri),
    ]);

    double? avgSolarKwh;
    String solarQuality = "Unknown";
    double? latestWindSpeed;

    // ✅ Parse solar data
    if (responses[0].statusCode == 200) {
      final solarData = json.decode(responses[0].body);
      final daily = solarData['daily'];

      if (daily != null && daily['shortwave_radiation_sum'] != null) {
        final values = List<double>.from(
          (daily['shortwave_radiation_sum'] as List)
              .map((e) => (e ?? 0).toDouble()),
        );
        final avg = values.isNotEmpty
            ? values.reduce((a, b) => a + b) / values.length
            : 0.0;
        avgSolarKwh = avg / 3.6; // MJ/m² → kWh/m²/day
        if (avgSolarKwh >= 5.0) {
          solarQuality = "High";
        } else if (avgSolarKwh >= 3.0) {
          solarQuality = "Medium";
        } else {
          solarQuality = "Low";
        }
      }
    } else {
      print('⚠️ Solar request failed: ${responses[0].statusCode}');
    }

    // ✅ Parse wind data
    if (responses[1].statusCode == 200) {
      final windData = json.decode(responses[1].body);
      final hourly = windData['hourly'];
      if (hourly != null && hourly['windspeed_10m'] != null) {
        final windValues = List<double>.from(
          (hourly['windspeed_10m'] as List).map((e) => (e ?? 0).toDouble()),
        );
        latestWindSpeed =
            windValues.isNotEmpty ? windValues.last : null; // latest hour value
      }
    } else {
      print('⚠️ Wind request failed: ${responses[1].statusCode}');
    }

    if (!mounted) return;
    setState(() {
      _avgSolarKwh = avgSolarKwh;
      _solarQuality = solarQuality;
      _recentIrradiance = avgSolarKwh;
      _windSpeed = latestWindSpeed;
      _isLoading = false;
    });

    print('✅ Solar=${_avgSolarKwh}, Wind=${_windSpeed}');
  } catch (e) {
    print('🚨 Error fetching energy data: $e');
    if (!mounted) return;
    setState(() => _isLoading = false);
  }
}

  void _onNavItemSelected(int index) {
    setState(() {
      _selectedNavIndex = index;
    });
    if (index == 0) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final offsetPosition = LatLng(
      _currentPosition.latitude - 0.008,
      _currentPosition.longitude,
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2B9A66)),
            )
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Stack(
                children: [
                  /// 🌍 Map
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
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.might_ampora',
                        maxZoom: 19,
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentPosition,
                            width: 50,
                            height: 50,
                            child: const Icon(
                              Icons.location_on,
                              size: 50,
                              color: Color(0xFF2B9A66),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  /// ☀️ Bottom sheet with live data
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
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05,
                          vertical: screenHeight * 0.02,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Energy Estimation',
                              style: TextStyle(
                                fontSize: screenWidth * 0.055,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildEnergyCard(
                              context: context,
                              title: 'Solar Irradiance',
                              value: _avgSolarKwh != null
                                  ? "${_avgSolarKwh!.toStringAsFixed(2)} kWh/m²/day"
                                  : '-',
                              subtitle: _solarQuality.isNotEmpty
                                  ? _solarQuality
                                  : 'Unknown',
                              description:
                                  'Based on Open-Meteo data, this represents the daily solar potential for your area.',
                              valueColor: const Color(0xFF2B9A66),
                              icon: Icons.wb_sunny,
                            ),
                            _buildEnergyCard(
                              context: context,
                              title: 'Wind Potential',
                              value: _windSpeed != null
                                  ? "${_windSpeed!.toStringAsFixed(1)} m/s"
                                  : '-',
                              subtitle: 'Average windspeed',
                              description:
                                  'Estimated wind speed from Open-Meteo near your location.',
                              valueColor: const Color(0xFFEF5F00),
                              icon: Icons.air,
                            ),
                            SizedBox(height: screenHeight * 0.1),
                          ],
                        ),
                      ),
                    ),
                  ),

                  /// 🌊 Navbar
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
                        fontSize: screenWidth * 0.055,
                        fontWeight: FontWeight.bold,
                        color: valueColor,
                      ),
                    ),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenWidth * 0.034,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: screenWidth * 0.04),
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
