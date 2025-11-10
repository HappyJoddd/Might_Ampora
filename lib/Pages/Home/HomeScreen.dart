import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:might_ampora/Pages/Solar/SolarEngery.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Components/LiquidNavbar.dart';
import '../Scaning_Option/EnergyPage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _steps = 0;
  int _baselineSteps = 0; // Store the step count at the start of the day
  StreamSubscription<StepCount>? _stepCountStream;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  int _aqiValue = 86; // Default AQI value (int for UI)
  String? _location;
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    _initPedometer();
    _requestLocationPermissionAndFetch();
    _scheduleMidnightReset();
  }

  @override
  void dispose() {
    _stepCountStream?.cancel();
    _midnightTimer?.cancel();
    super.dispose();
  }

  Future<void> _initPedometer() async {
    PermissionStatus permission = await Permission.activityRecognition.request();
    if (permission.isGranted) {
      await _loadDailySteps();
      _stepCountStream = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
        cancelOnError: false,
      );
    }
  }

  Future<void> _loadDailySteps() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String today = DateTime.now().toIso8601String().split('T')[0];
    String? savedDate = prefs.getString('step_date');

    if (savedDate != today) {
      // New day - reset steps
      await prefs.setString('step_date', today);
      await prefs.setInt('baseline_steps', 0);
      _baselineSteps = 0;
    } else {
      // Same day - load saved baseline
      _baselineSteps = prefs.getInt('baseline_steps') ?? 0;
    }
  }

  void _onStepCount(StepCount event) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (_baselineSteps == 0 && event.steps > 0) {
      // First time getting steps today - set baseline
      _baselineSteps = event.steps;
      await prefs.setInt('baseline_steps', _baselineSteps);
    }

    if (!mounted) return;
    setState(() {
      // Calculate daily steps by subtracting baseline
      _steps = event.steps - _baselineSteps;
      if (_steps < 0) _steps = 0; // Handle edge cases
    });
  }

  void _onStepCountError(error) {
    print('Pedometer error: $error');
  }

  void _scheduleMidnightReset() {
    DateTime now = DateTime.now();
    DateTime midnight = DateTime(now.year, now.month, now.day + 1);
    Duration timeUntilMidnight = midnight.difference(now);

    _midnightTimer = Timer(timeUntilMidnight, () {
      if (!mounted) return;
      _resetDailySteps();
      _scheduleMidnightReset(); // Schedule next reset
    });
  }

  Future<void> _resetDailySteps() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String today = DateTime.now().toIso8601String().split('T')[0];
    await prefs.setString('step_date', today);
    await prefs.setInt('baseline_steps', 0);
    if (!mounted) return;
    setState(() {
      _baselineSteps = 0;
      _steps = 0;
    });
  }

  /// Robust location permission + fetch wrapper.
  /// If permission is deniedForever, prompts user to open app settings.
  Future<void> _requestLocationPermissionAndFetch() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        // Show a small dialog asking user to open settings
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Location required"),
            content: const Text(
                "Location permission is permanently denied. Please enable it in app settings to get local AQI and solar data."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await openAppSettings();
                },
                child: const Text("Open Settings"),
              ),
            ],
          ),
        );
        // still try to fetch using default coordinates
        await _simulateAQI(); // will use current default _location / coords
        return;
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        await _getCurrentLocation();
      } else {
        // permission denied - try fetching with default location (Delhi)
        await _simulateAQI();
      }
    } catch (e) {
      print('Error requesting location permission: $e');
      await _simulateAQI();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      setState(() {
        _location = '${position.latitude}, ${position.longitude}';
      });
      await _simulateAQI(latitude: position.latitude, longitude: position.longitude);
    } catch (e) {
      print('Error getting location: $e');
      // fallback to default fetch
      await _simulateAQI();
    }
  }

  /// Fetches AQI from Open-Meteo air-quality API using the exact query you provided.
  /// If lat/lon not provided, uses a default (Delhi).
  Future<void> _simulateAQI({double? latitude, double? longitude}) async {
    // keep UI responsive
    if (!mounted) return;
    setState(() { /* we won't set loading spinner here to keep UI consistent */ });

    try {
      final double lat = latitude ?? 28.6139;
      final double lon = longitude ?? 77.2090;

      // Build date window: last 2 days up to today
      final DateTime end = DateTime.now();
      final DateTime start = end.subtract(const Duration(days: 2));
      final String startDate = start.toIso8601String().split("T")[0];
      final String endDate = end.toIso8601String().split("T")[0];

      final Uri aqiUri = Uri.https(
        "air-quality-api.open-meteo.com",
        "/v1/air-quality",
        {
          "latitude": lat.toString(),
          "longitude": lon.toString(),
          "hourly": "us_aqi",
          "timezone": "auto",
          "start_date": startDate,
          "end_date": endDate,
        },
      );

      debugPrint("Fetching AQI: $aqiUri");

      final response = await http.get(aqiUri).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final hourly = body['hourly'];
        int? latestAqi;

        if (hourly != null && hourly['us_aqi'] != null) {
          final List<dynamic> vals = List<dynamic>.from(hourly['us_aqi']);
          // find last non-null numeric value
          for (int i = vals.length - 1; i >= 0; i--) {
            final v = vals[i];
            if (v == null) continue;
            if (v is int) {
              latestAqi = v;
              break;
            } else if (v is double) {
              latestAqi = v.round();
              break;
            } else {
              final parsed = int.tryParse(v.toString());
              if (parsed != null) {
                latestAqi = parsed;
                break;
              }
            }
          }
        }

        if (!mounted) return;
        setState(() {
          _aqiValue = latestAqi ?? _aqiValue;
        });
        debugPrint("AQI updated: $_aqiValue");
      } else {
        debugPrint("AQI API returned ${response.statusCode}");
        // keep previous/default _aqiValue
      }
    } catch (e) {
      debugPrint("Error fetching AQI: $e");
      // ignore and keep current/default _aqiValue
    } finally {
      if (!mounted) return;
      // no global loading flag change here to avoid UI jumps
    }
  }

  Map<String, dynamic> _getAQIInfo() {
    if (_aqiValue < 50) {
      return {
        'label': 'Good',
        'color': const Color(0xFF90EE90), // Light green
        'backgroundColor': const Color(0xFFE8F5E9), // Lightest green
      };
    } else if (_aqiValue <= 100) {
      return {
        'label': 'Moderate',
        'color': const Color(0xFFFFA726), // Orange
        'backgroundColor': const Color(0xFFFFE0B2), // Light orange
      };
    } else {
      return {
        'label': 'Bad',
        'color': const Color.fromARGB(255, 237, 6, 6), // Light red
        'backgroundColor': Color.fromRGBO(251, 150, 153, 1), // Light red
      };
    }
  }

  void _showCalendarDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Date',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now(),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                calendarFormat: CalendarFormat.month,
                onDaySelected: (selectedDay, focusedDay) {
                  if (!mounted) return;
                  setState(() {
                    _selectedDate = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  Navigator.pop(context);
                },
                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: const Color(0xFF1E3A5F),
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _getDayLetter(int weekday) {
    switch (weekday) {
      case 1:
        return 'M';
      case 2:
        return 'T';
      case 3:
        return 'W';
      case 4:
        return 'T';
      case 5:
        return 'F';
      case 6:
        return 'S';
      case 7:
        return 'S';
      default:
        return '';
    }
  }

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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(screenWidth, screenHeight),

                      // Live AQI Banner - No space between header and banner
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.04,
                          vertical: screenHeight * 0.01,
                        ),
                        decoration: BoxDecoration(
                          color: _getAQIInfo()['backgroundColor'], // Dynamic background color
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between items
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: _getAQIInfo()['color'],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Text(
                                  'Live AQI',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.035,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${_aqiValue}',
                              style: TextStyle(
                                fontSize: screenWidth * 0.06,
                                fontWeight: FontWeight.bold,
                                color: _getAQIInfo()['color'],
                              ),
                            ),
                            Text(
                              _getAQIInfo()['label'],
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.01),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                        child: Text(
                          "Dashboard",
                          style: TextStyle(
                            color: Colors.green.shade900,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.01),

                      // Energy Summary Card
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.035),
                        child: _buildEnergySummaryCard(screenWidth, screenHeight),
                      ),

                      const SizedBox(height: 20),

                      _infoCard(
                        context,
                        title: "Discover the energy drain",
                        description: "Scan your appliances and track their impact!",
                        buttonText: "Add now !",
                        imagePath: "images/Mask.png",
                        navigateToPage: const EnergyOnboardingPage(),
                      ),
                      _infoCard(
                        context,
                        title: "Pedal your way to a healthier planet!",
                        description: "Scan your appliances and track their impact!",
                        buttonText: "Scan now !",
                        imagePath: "images/Cycle.png",
                        navigateToPage: const EnergyOnboardingPage(),
                      ),
                      _infoCard(
                        context,
                        title: "Add your routine",
                        description: "Add your routines and see their impact on the environment",
                        buttonText: "Add now !",
                        imagePath: "images/Routine.png",
                      ),
                      _infoCard(
                        context,
                        title: "Harness the power of the sun and wind",
                        description: "Find out what works for you today",
                        buttonText: "Scan now !",
                        imagePath: "images/Sun.png",
                        navigateToPage: RenewableEnergyEstimation(),
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
      height: screenHeight * 0.32, // Increased height to match the design
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
              left: screenWidth * 0.05,
              right: screenWidth * 0.05,
              top: screenHeight * 0.05,
              bottom: screenHeight * 0.005,
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

  Widget _buildEnergySummaryCard(double screenWidth, double screenHeight) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE6F4FE), // Background color
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(left: screenWidth * 0.04, right: screenWidth * 0.04, top: screenHeight * 0.012),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date selector - Clickable
            GestureDetector(
              onTap: _showCalendarDialog,
              child: Row(
                children: [
                  Text(
                    _formatDate(_selectedDate),
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // Custom Calendar matching design - Non-scrollable
            Container(
              height: 75,
              padding: EdgeInsets.only(bottom: screenHeight * 0.005),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (index) {
                  final date = DateTime.now().add(Duration(days: index - 3));
                  final isSelected = date.day == _selectedDate.day &&
                      date.month == _selectedDate.month &&
                      date.year == _selectedDate.year;

                  return GestureDetector(
                    onTap: () {
                      if (!mounted) return;
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                    child: Container(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Date number with white border for selected
                          Container(
                            width: screenWidth * 0.115,
                            height: screenWidth * 0.115,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF1E3A5F) : Colors.transparent,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    )
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : Colors.black54,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 4),
                          // Day letter
                          Text(
                            _getDayLetter(date.weekday),
                            style: TextStyle(
                              fontSize: screenWidth * 0.028,
                              color: isSelected ? Colors.black87 : Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Main row with left content and Mascot
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left side content
                Expanded(
                  child: Column(
                    children: [
                      // Target and You Saved in one box
                      Container(
                        padding: EdgeInsets.all(screenWidth * 0.03),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCFCFC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            // Target section
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'images/target.png',
                                  width: screenWidth * 0.1,
                                  height: screenWidth * 0.1,
                                  fit: BoxFit.contain,
                                ),
                                SizedBox(width: screenWidth * 0.025),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Target',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.035,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      '20 kg CO₂eq',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.042,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Divider
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.008),
                              child: Divider(
                                color: const Color(0xFFE0E0E0),
                                thickness: 1,
                              ),
                            ),

                            // You Saved section
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'images/save.png',
                                  width: screenWidth * 0.1,
                                  height: screenWidth * 0.1,
                                  fit: BoxFit.contain,
                                ),
                                SizedBox(width: screenWidth * 0.025),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'You Saved',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.035,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      '10 kg CO₂eq',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.042,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFFFA726),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.01),

                      // Steps box
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(screenWidth * 0.03),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCFCFC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Steps 🚶',
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Text(
                              '$_steps',
                              style: TextStyle(
                                fontSize: screenWidth * 0.055,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4CAF50),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: screenWidth * 0.02),

                // Mascot on the right
                Container(
                  width: screenWidth * 0.28,
                  height: screenWidth * 0.35,
                  child: Image.asset(
                    'images/Mascot_good.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.emoji_emotions,
                        size: screenWidth * 0.25,
                        color: Colors.green,
                      );
                    },
                  ),
                ),
              ],
            ),

            SizedBox(height: screenHeight * 0.012),

            // Bottom message - Centered
            Center(
              child: Text(
                'Great job! You\'re helping the planet\nwith your eco-friendly choices!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.32,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF14532B),
                  height: 1.2,
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
          ],
        ),
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
