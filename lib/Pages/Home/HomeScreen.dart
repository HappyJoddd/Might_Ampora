import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:might_ampora/Pages/Solar/SolarEngery.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui'; // Add this if not present
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../Components/LiquidNavbar.dart';
import 'Profilepage.dart';
import '../Scaning_Option/EnergyPage.dart';
import 'package:might_ampora/services/auth_storage.dart';
import 'package:might_ampora/services/activity_service.dart';
import 'package:might_ampora/services/midnight_sync_service.dart';

// ==========================================
// DRIVING TRACKING CONSTANTS (Module-level for background service access)
// ==========================================
const double _kDrivingSpeedThreshold = 12.0; // km/h — reduce idle false positives
const double _kMaxRealisticSpeed = 180.0; // km/h — reject GPS teleportation
const double _kMinDistanceThreshold = 10.0; // meters — reduce GPS jitter
const double _kMinAccuracy = 80.0; // meters — filter noisy fixes
const double _kVehicleVibrationThreshold = 1.0; // m/s² — slightly lower
const int _kAccelWindowSize = 15; // larger window = less noise
// Advanced tuning
const double _kMinDrivingSpeed = 12.0; // km/h (tighten idle filtering)
const double _kFastSpeedThreshold = 16.0; // km/h — unambiguous driving
const double _kMinDistanceChange = 10.0; // meters (tighten idle filtering)
const double _kMaxBearingChange = 75.0; // degrees — relaxed from 60
const int _kSpeedHistorySize = 3;
const double _kCurrentSpeedWeight = 1.5; //  Weight current speed more
const double _kStationarySpeedKmh = 3.0; // km/h — ignore tiny drift
const double _kStationaryDistanceMeters = 12.0; // meters — ignore tiny jumps
const int _kDrivingStreakRequired = 2; // consecutive driving detections

// ==========================================
// BACKGROUND SERVICE ENTRY POINTS (Module-level for AOT/release compatibility)
// ==========================================

/// iOS background handler
@pragma('vm:entry-point')

Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

/// Main background service entry point (Android/iOS foreground)
/// Improved driving detection algorithm with EMA, weighted speed, and bearing consistency
@pragma('vm:entry-point')
Future<void> onBackgroundServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings =
      InitializationSettings(android: androidInit);
  await notificationsPlugin.initialize(initSettings);

  // --- State ---
  Position? lastPosition;
  DateTime? lastPositionTime;
  double distanceDriven = 0.0;
  bool isServiceRunning = true;

  // Accelerometer state (exponential moving average)
  double vibrationEMA = 0.0;
  const double emaAlpha = 0.2; // smoothing factor

  // Require a short streak before counting driving to avoid idle jitter
  int drivingStreak = 0;

  // Speed history for weighted average (last 3 readings)
  List<double> speedHistory = [];
  const int speedWindowSize = 3;

  // Bearing history for consistency check
  double? lastBearing;

  StreamSubscription? accelerometerSubscription;
  StreamSubscription<Position>? positionSubscription;

  // --- Load saved distance ---
  final prefs = await SharedPreferences.getInstance();
  final savedDate = prefs.getString('lastDrivingDate');
  final today = DateTime.now().toIso8601String().split('T')[0];
  final todayDistanceKey = 'driven_km_$today';
  final storedDistanceForToday = prefs.getDouble(todayDistanceKey);

  if (savedDate != today) {
    if (storedDistanceForToday != null && storedDistanceForToday > 0.0) {
      await prefs.setDouble('dailyDistance', storedDistanceForToday);
      distanceDriven = storedDistanceForToday;
    } else {
      await prefs.setDouble('dailyDistance', 0.0);
      distanceDriven = 0.0;
    }
    await prefs.setString('lastDrivingDate', today);
  } else {
    distanceDriven = prefs.getDouble('dailyDistance') ?? 0.0;
  }

  // --- CHECK LOCATION PERMISSION IN BACKGROUND ISOLATE ---
  LocationPermission permission = await Geolocator.checkPermission();
  
  if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
    // Try requesting (may not work in background, but worth trying)
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      service.stopSelf();
      return;
    }
  }

  // --- Accelerometer: exponential moving average ---
  accelerometerSubscription = accelerometerEventStream().listen((event) {
    double magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z);
    double vibration = (magnitude - 9.8).abs();
    vibrationEMA = emaAlpha * vibration + (1 - emaAlpha) * vibrationEMA;
  });

  // Initial notification
  await notificationsPlugin.show(
    888,
    'Driving Tracker Active',
    'Tracking your driving activity',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'driving_tracker_channel',
        'Driving Tracker',
        channelDescription: 'Tracks your driving distance in the background',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
      ),
    ),
  );

  // Listen for stop
  service.on('stop').listen((event) {
    isServiceRunning = false;
    accelerometerSubscription?.cancel();
    positionSubscription?.cancel();
    service.stopSelf();
  });

  final locationSettings = Platform.isAndroid
      ? AndroidSettings(accuracy: LocationAccuracy.high, distanceFilter: 5)
      : AppleSettings(accuracy: LocationAccuracy.high, distanceFilter: 5);

  try {
    positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((current) async {
      if (!isServiceRunning) return;

    try {
      // DEBUG: Log GPS position received
      // Day rollover
      final currentDate = DateTime.now().toIso8601String().split('T')[0];
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('lastDrivingDate');
      if (saved != currentDate) {
        final currentDateKey = 'driven_km_$currentDate';
        final stored = prefs.getDouble(currentDateKey);
        if (stored != null && stored > 0.0) {
          await prefs.setDouble('dailyDistance', stored);
          distanceDriven = stored;
        } else {
          await prefs.setDouble('dailyDistance', 0.0);
          distanceDriven = 0.0;
        }
        await prefs.setString('lastDrivingDate', currentDate);
        lastPosition = null;
        lastPositionTime = null;
        speedHistory.clear();
        lastBearing = null;
      }

      // Permission check
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return;

      // Reject inaccurate fixes
      if (current.accuracy > _kMinAccuracy) {
        return;
      }

      final pos = lastPosition;
      final posTime = lastPositionTime;
      if (pos == null || posTime == null) {
        lastPosition = current;
        lastPositionTime = DateTime.now();
        return;
      }

      double distMeters = Geolocator.distanceBetween(
        pos.latitude, pos.longitude,
        current.latitude, current.longitude,
      );

      final now = DateTime.now();
      final timeDiffSec = now.difference(posTime).inSeconds;
      if (timeDiffSec <= 0) {
        lastPosition = current;
        lastPositionTime = now;
        return;
      }

      final gpsSpeedKmh = (current.speed.isFinite ? current.speed : 0.0) * 3.6;
      final calcSpeedKmh = (distMeters / timeDiffSec) * 3.6;
      final instantSpeed = gpsSpeedKmh > 0.5 ? gpsSpeedKmh : calcSpeedKmh;

      // --- Weighted speed average ---
      speedHistory.add(instantSpeed);
      if (speedHistory.length > speedWindowSize) {
        speedHistory.removeAt(0);
      }
      // Weighted: most recent reading has highest weight
      double weightedSpeed = 0.0;
      double totalWeight = 0.0;
      for (int i = 0; i < speedHistory.length; i++) {
        double w = (i + 1).toDouble(); // 1, 2, 3
        weightedSpeed += speedHistory[i] * w;
        totalWeight += w;
      }
      weightedSpeed /= totalWeight;

      // --- Bearing consistency check ---
      double bearing = Geolocator.bearingBetween(
        pos.latitude, pos.longitude,
        current.latitude, current.longitude,
      );

      bool bearingConsistent = true;
      if (lastBearing != null && distMeters > 20.0) {
        double bearingDiff = (bearing - lastBearing!).abs();
        if (bearingDiff > 180) bearingDiff = 360 - bearingDiff;
        // If bearing changed > 150° in one interval, likely GPS noise
        bearingConsistent = bearingDiff < 150;
      }
      if (distMeters > _kMinDistanceThreshold) lastBearing = bearing;

      // --- Vehicle vibration check (EMA-based) ---
      bool inVehicle = vibrationEMA >= _kVehicleVibrationThreshold &&
          vibrationEMA < 6.0;

      // Guard against stationary GPS jitter
      final bool isStationaryJitter =
          weightedSpeed < _kStationarySpeedKmh &&
          distMeters < _kStationaryDistanceMeters;
      if (isStationaryJitter) {
        drivingStreak = 0;
        lastPosition = current;
        lastPositionTime = now;
        return;
      }

      // --- Driving decision ---
      bool isDriving = weightedSpeed >= _kDrivingSpeedThreshold &&
          weightedSpeed < _kMaxRealisticSpeed &&
          distMeters >= _kMinDistanceThreshold &&
          bearingConsistent &&
          (inVehicle || weightedSpeed >= _kFastSpeedThreshold); // speed alone can qualify

      if (isDriving) {
        drivingStreak += 1;
      } else {
        drivingStreak = 0;
      }

      if (isDriving && drivingStreak >= _kDrivingStreakRequired) {
        // Accuracy-weighted distance: trust high-accuracy fixes more
        double accuracyFactor = 1.0;
        if (current.accuracy > 20) {
          accuracyFactor = 20.0 / current.accuracy; // scale down noisy fixes
        }

        double distKm = (distMeters / 1000) * accuracyFactor;
        distanceDriven += distKm;

        // Persist
        final today = DateTime.now().toIso8601String().split('T')[0];
        await prefs.setDouble('dailyDistance', distanceDriven);
        await prefs.setDouble('driven_km_$today', distanceDriven);

        // Update notification
        await notificationsPlugin.show(
          888,
          'Driving Tracker Active',
          'Tracking your driving activity',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'driving_tracker_channel',
              'Driving Tracker',
              channelDescription: 'Tracks your driving distance in the background',
              importance: Importance.low,
              priority: Priority.low,
              ongoing: true,
              autoCancel: false,
            ),
          ),
        );

        // Send to UI
        service.invoke('update', {
          'distance': distanceDriven,
          'speed': weightedSpeed,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }

      lastPosition = current;
      lastPositionTime = now;
    } catch (e) {
      // Silent catch
    }
  }, onError: (error) {
    // Silent error
  }, onDone: () {
    // Stream completed
  });
  
  } catch (e) {
    service.stopSelf();
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _steps = 0;
  StreamSubscription<StepCount>? _stepCountStream;
  
  // Normalize to date only (remove time component)
  DateTime get _todayDate => DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  late DateTime _selectedDate;
  
  // Selected date activity data
  int _selectedDateSteps = 0;
  double _selectedDateDriven = 0.0;
  double _selectedDateCO2Saved = 0.0;
  Map<String, Map<String, dynamic>> _activityDataCache = {}; // Cache for fetched data
  
  // CO2 calculation and target
  static const double _co2Target = 10.0; // Daily CO2 target in kg
  double _currentCO2Saved = 0.0; // Real-time calculated CO2 saved for today
  Timer? _co2UpdateTimer;
  
  int _aqiValue = 86; // Default AQI value (int for UI)
  String _userName = 'User'; // User's first name
  String _cityName = 'Your City'; // User's current city
  String _userInitials = 'U'; // User's initials (first + last)
  // Driving tracking variables
  double _distanceDriven = 0.0; // in kilometers
  
  // Calendar scroll controller
  final ScrollController _calendarScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedDate = _todayDate; // Initialize with normalized today's date
    _initializeTrackingState();
    _loadUserData();
    _requestLocationPermissionAndFetch();
    MidnightSyncService().initialize(); // Singleton - only creates one timer
    _initializeAndStartBackgroundService();
    _listenToBackgroundService();
    _fetchActivityForDate(_selectedDate);
    _startCO2UpdateTimer();
    
    // Scroll to center (today) after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_calendarScrollController.hasClients) {
        // Today is at index 6 (0-5 past, 6 today, 7-9 future)
        // Calculate position to center today
        final itemWidth = MediaQuery.of(context).size.width * 0.13 + 2; // width + margin
        final screenWidth = MediaQuery.of(context).size.width;
        final centerOffset = (itemWidth * 6) - (screenWidth / 2) + (itemWidth / 2);
        
        _calendarScrollController.jumpTo(
          centerOffset.clamp(0.0, _calendarScrollController.position.maxScrollExtent),
        );
      }
    });
  }

  @override
  void dispose() {
    _stepCountStream?.cancel();
    _co2UpdateTimer?.cancel();
    _calendarScrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeTrackingState() async {
    await _loadSteps();
    await _loadDrivingDistance();
    await _restoreTodayFromBackendIfNeeded();
    _initPedometer();
  }

  /// Fetch activity data for selected date
  Future<void> _fetchActivityForDate(DateTime date) async {
    try {
      final userDetails = await AuthStorage.getUserDetails();
      final userId = userDetails['userId'];
      
      if (userId == null) return;
      
      // Check if date is today - use current values
      final isToday = date.year == _todayDate.year &&
          date.month == _todayDate.month &&
          date.day == _todayDate.day;
      
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      if (isToday) {
        setState(() {
          _selectedDateSteps = _steps;
          _selectedDateDriven = _distanceDriven;
          _selectedDateCO2Saved = _currentCO2Saved;
        });
        return;
      }
      
      // Check cache first
      if (_activityDataCache.containsKey(dateKey)) {
        final cached = _activityDataCache[dateKey]!;
        setState(() {
          _selectedDateSteps = cached['steps'] ?? 0;
          _selectedDateDriven = cached['drivenKm'] ?? 0.0;
          _selectedDateCO2Saved = cached['savedCO2'] ?? 0.0;
        });
        return;
      }
      
      // Fetch from backend
      final weekData = await ActivityService.getPastWeekActivity(userId);
      
      // Update cache
      for (var activity in weekData) {
        final activityDate = activity['date'];
        _activityDataCache[activityDate] = {
          'steps': (activity['steps'] ?? 0) is int ? activity['steps'] : (activity['steps'] ?? 0).toInt(),
          'drivenKm': (activity['drivenKm'] ?? 0).toDouble(),
          'savedCO2': (activity['savedCO2'] ?? 0).toDouble(),
        };
      }
      
      // Update UI with selected date data
      if (_activityDataCache.containsKey(dateKey)) {
        final data = _activityDataCache[dateKey]!;
        setState(() {
          _selectedDateSteps = data['steps'] ?? 0;
          _selectedDateDriven = data['drivenKm'] ?? 0.0;
          _selectedDateCO2Saved = data['savedCO2'] ?? 0.0;
        });
      } else {
        // No data for this date
        setState(() {
          _selectedDateSteps = 0;
          _selectedDateDriven = 0.0;
          _selectedDateCO2Saved = 0.0;
        });
      }
    } catch (e) {
      setState(() {
        _selectedDateSteps = 0;
        _selectedDateDriven = 0.0;
        _selectedDateCO2Saved = 0.0;
      });
    }
  }
  
  /// Calculate CO2 saved from steps and driven distance
  double _calculateCO2Saved(int steps, double drivenKm) {
    // Walking reduces CO2 by avoiding car usage
    // Average person walks ~0.75 km per 1000 steps
    // Car emits ~0.12 kg CO2 per km
    // So walking saves: (steps / 1000) * 0.75 * 0.12 kg CO2
    final co2SavedByWalking = (steps / 1000) * 0.75 * 0.12;
    
    // Driving emits CO2
    // Car emits ~0.12 kg CO2 per km driven
    final co2EmittedByDriving = drivenKm * 0.12;
    
    // Net CO2 saved = saved by walking - emitted by driving
    return co2SavedByWalking - co2EmittedByDriving;
  }
  
  /// Start timer to update CO2 calculation every minute
  void _startCO2UpdateTimer() {
    // Initial calculation
    _updateCO2Calculation();
    
    // Update every minute (60 seconds)
    _co2UpdateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateCO2Calculation();
    });
  }
  
  /// Update CO2 calculation based on current steps and driven distance
  void _updateCO2Calculation() {
    if (!mounted) return;
    
    final co2Saved = _calculateCO2Saved(_steps, _distanceDriven);
    
    setState(() {
      _currentCO2Saved = co2Saved;
      
      // If today is selected, update the displayed values
      final isToday = _selectedDate.year == _todayDate.year &&
          _selectedDate.month == _todayDate.month &&
          _selectedDate.day == _todayDate.day;
      
      if (isToday) {
        _selectedDateSteps = _steps;
        _selectedDateDriven = _distanceDriven;
        _selectedDateCO2Saved = co2Saved;
      }
    });
  }

  /// Load user's name from storage
  Future<void> _loadUserData() async {
    try {
      final userDetails = await AuthStorage.getUserDetails();
      final fullName = userDetails['name'] ?? 'User';
      // Extract first name
      final firstName = fullName.split(' ').first;
      
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
          _userName = firstName;
          _userInitials = initials.isNotEmpty ? initials : 'U';
        });
      }
    } catch (e) {
      // Silent error handling
    }
  }

  Future<void> _restoreTodayFromBackendIfNeeded() async {
    try {
      final userDetails = await AuthStorage.getUserDetails();
      final userId = userDetails['userId'];
      if (userId == null || userId.isEmpty) return;

      final today = DateTime.now().toIso8601String().split('T')[0];
      final prefs = await SharedPreferences.getInstance();
      final localSteps = prefs.getInt('dailySteps') ?? 0;
      final localDistance = prefs.getDouble('dailyDistance') ?? 0.0;

      if (localSteps > 0 || localDistance > 0.0) return;

      final weekData = await ActivityService.getPastWeekActivity(userId);
      final todayData = weekData.firstWhere(
        (item) => item['date'] == today,
        orElse: () => {},
      );

      if (todayData.isEmpty) return;

      final steps = (todayData['steps'] ?? 0) is int
          ? todayData['steps'] as int
          : (todayData['steps'] ?? 0).toInt();
      final drivenKm = (todayData['drivenKm'] ?? 0).toDouble();
      final savedCO2 = (todayData['savedCO2'] ?? 0).toDouble();

      if (steps > 0) {
        await prefs.setInt('dailySteps', steps);
        await prefs.setInt('steps_$today', steps);
        await prefs.setString('lastStepDate', today);
        await prefs.remove('baselineSteps');
      }

      if (drivenKm > 0.0) {
        await prefs.setDouble('dailyDistance', drivenKm);
        await prefs.setDouble('driven_km_$today', drivenKm);
        await prefs.setString('lastDrivingDate', today);
      }

      _activityDataCache[today] = {
        'steps': steps,
        'drivenKm': drivenKm,
        'savedCO2': savedCO2,
      };

      if (!mounted) return;
      setState(() {
        _steps = steps;
        _distanceDriven = drivenKm;
        if (_selectedDate.year == _todayDate.year &&
            _selectedDate.month == _todayDate.month &&
            _selectedDate.day == _todayDate.day) {
          _selectedDateSteps = steps;
          _selectedDateDriven = drivenKm;
          _selectedDateCO2Saved = savedCO2;
        }
      });
      _updateCO2Calculation();
    } catch (e) {
      // Silent error handling
    }
  }

  /// Load saved steps from SharedPreferences
  Future<void> _loadSteps() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString('lastStepDate');
    final today = DateTime.now().toIso8601String().split('T')[0];
    final todayStepsKey = 'steps_$today';
    final storedStepsForToday = prefs.getInt(todayStepsKey);

    if (savedDate != today) {
      // New day or missing date, but recover if same-day data exists
      if (storedStepsForToday != null && storedStepsForToday > 0) {
        await prefs.setInt('dailySteps', storedStepsForToday);
      } else {
        await prefs.setInt('dailySteps', 0);
        await prefs.remove('baselineSteps');
      }
      await prefs.setString('lastStepDate', today);
    } else if (storedStepsForToday != null && storedStepsForToday > 0) {
      final currentDaily = prefs.getInt('dailySteps') ?? 0;
      if (currentDaily == 0) {
        await prefs.setInt('dailySteps', storedStepsForToday);
      }
    }

    if (!mounted) return;
    setState(() {
      _steps = prefs.getInt('dailySteps') ?? 0;
    });
    _updateCO2Calculation();
  }

  /// Initialize pedometer to track steps
  /// The step counter provides total steps since last reboot (device power on)
  Future<void> _initPedometer() async {
    // Request activity recognition permission
    var status = await Permission.activityRecognition.status;
    if (!status.isGranted) {
      status = await Permission.activityRecognition.request();
    }

    if (status.isGranted) {
      try {
        _stepCountStream = Pedometer.stepCountStream.listen(
          _onStepCount,
          onError: _onStepCountError,
          cancelOnError: false,
        );
      } catch (e) {
        // Silent error handling
      }
    }
  }

  /// Handle step count updates from the device sensor
  /// The sensor returns total steps since last reboot (device power on)
  /// We maintain a baseline to calculate today's steps
  void _onStepCount(StepCount event) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final savedDate = prefs.getString('lastStepDate');
    final todayStepsKey = 'steps_$today';
    final storedStepsForToday = prefs.getInt(todayStepsKey);
    

    // Check if it's a new day
    if (savedDate != today) {
      int restoredSteps = 0;
      if (storedStepsForToday != null && storedStepsForToday > 0) {
        restoredSteps = storedStepsForToday;
      }
      await prefs.setInt('dailySteps', restoredSteps);
      await prefs.setString('lastStepDate', today);
      final inferredBaseline = event.steps - restoredSteps;
      final safeBaseline = inferredBaseline >= 0 ? inferredBaseline : event.steps;
      await prefs.setInt('baselineSteps', safeBaseline);

      if (!mounted) return;
      setState(() {
        _steps = restoredSteps;
      });
      return;
    }

    // Get or set baseline (steps count at start of day or app launch)
    int baseline = prefs.getInt('baselineSteps') ?? event.steps;
    
    // If baseline is not set yet (first run today), set it now
    if (!prefs.containsKey('baselineSteps')) {
      final existingDaily = prefs.getInt('dailySteps') ?? 0;
      final inferredBaseline = event.steps - existingDaily;
      final safeBaseline = inferredBaseline >= 0 ? inferredBaseline : event.steps;
      await prefs.setInt('baselineSteps', safeBaseline);
      baseline = safeBaseline;
    }
    
    // Calculate today's steps: current steps since reboot - baseline
    // The sensor gives us total steps since last reboot, so we subtract the baseline
    int dailySteps = event.steps - baseline;
    
    // Handle device reboot: if current steps < baseline, device was rebooted
    // In this case, current steps ARE the new steps added after reboot
    if (event.steps < baseline) {
      // Add current steps to existing daily total (before reboot)
      final previousDailySteps = prefs.getInt('dailySteps') ?? 0;
      dailySteps = previousDailySteps + event.steps;
      // Update baseline to 0 since device just rebooted
      await prefs.setInt('baselineSteps', 0);
    }

    // Ensure steps are not negative
    dailySteps = dailySteps >= 0 ? dailySteps : 0;
    
    await prefs.setInt('dailySteps', dailySteps);
    
    // Also save with date key for midnight sync
    await prefs.setInt('steps_$today', dailySteps);

    if (!mounted) return;
    setState(() {
      _steps = dailySteps;
    });
    _updateCO2Calculation();
  }

  /// Handle pedometer errors
  void _onStepCountError(error) {
    // Silent error handling
  }

  // Midnight sync is now handled by MidnightSyncService singleton

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
                  await Geolocator.openAppSettings();
                },
                child: const Text("Open Settings"),
              ),
            ],
          ),
        );
        // still try to fetch using default coordinates
        await _simulateAQI();
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
      await _simulateAQI();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final locationSettings = Platform.isAndroid
          ? AndroidSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 0,
            )
          : AppleSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 0,
            );
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
      if (!mounted) return;
      
      // Get city name from coordinates
      await _getCityFromCoordinates(position.latitude, position.longitude);
      
      await _simulateAQI(latitude: position.latitude, longitude: position.longitude);
    } catch (e) {
      // fallback to default fetch
      await _simulateAQI();
    }
  }

  /// Get city name from coordinates using reverse geocoding
  Future<void> _getCityFromCoordinates(double lat, double lon) async {
    try {
      // Use Nominatim OpenStreetMap reverse geocoding API
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/reverse',
        {
          'lat': lat.toString(),
          'lon': lon.toString(),
          'format': 'json',
        },
      );

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'MightAmpora/1.0'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];
        
        // Try to get city from various possible fields
        String? city = address['city'] ?? 
                      address['town'] ?? 
                      address['village'] ?? 
                      address['municipality'] ??
                      address['state_district'];
        
        if (city != null && mounted) {
          setState(() {
            _cityName = city;
          });
        }
      }
    } catch (e) {
      // Keep default city name
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
      } else {
        // keep previous/default _aqiValue
      }
    } catch (e) {
      // ignore and keep current/default _aqiValue
    } finally {
      if (!mounted) return;
      // no global loading flag change here to avoid UI jumps
    }
  }

  Map<String, dynamic> _getAQIInfo() {
    if (_aqiValue < 100) {
      return {
        'label': 'Good',
        'color': const Color(0xFF90EE90), // Light green
        'backgroundColor': const Color(0xFFE8F5E9), // Lightest green
      };
    } else if (_aqiValue <= 200) {
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

  /// Get mascot image based on CO2 saved
  String _getMascotImage(double co2Saved) {
    if (co2Saved > 5.0) {
      return 'images/Mascot_good.png';
    } else if (co2Saved >= 0.0) {
      return 'images/Mascot_mid.png';
    } else {
      return 'images/Mascot_bad.png';
    }
  }

  /// Get bottom message text based on CO2 saved
  String _getBottomMessageText(double co2Saved) {
    if (co2Saved > 5.0) {
      return 'Great job! You\'re helping the planet\nwith your eco-friendly choices!';
    } else if (co2Saved >= 0.0) {
      return "You're doing okay! Keep building those sustainable habits to make a bigger impact !";
    } else {
      return "You're failing your green goals! Major improvement to reduce your environmental impact.";
    }
  }

  /// Get bottom message color based on CO2 saved
  Color _getBottomMessageColor(double co2Saved) {
    if (co2Saved > 5.0) {
      return  Color(0xFF14532B); // Dark green
    } else if (co2Saved >= 0.0) {
      return  Color(0xFFF59E0B); // Orange/amber
    } else {
      return  Color.fromARGB(255, 220, 38, 38); // Red
    }
  }

  void _onDateSelected(DateTime date) async {
    if (!mounted) return;
    
    // Normalize to date only (remove time component)
    final normalizedDate = DateTime(date.year, date.month, date.day);
    
    setState(() {
      _selectedDate = normalizedDate;
    });
    await _fetchActivityForDate(normalizedDate);
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
      // Already on home page
    } else if (index == 1) {
      // Handle add action
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
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
          bottom: false,
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
                                    fontFamily: 'WorkSansM',
                                    fontSize: screenWidth * 0.035,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '$_aqiValue',
                              style: TextStyle(
                                fontSize: screenWidth * 0.06,
                                fontFamily: 'WorkSansB',
                                color: _getAQIInfo()['color'],
                              ),
                            ),
                            Text(
                              _getAQIInfo()['label'],
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                color: Colors.black87,
                                fontFamily: 'WorkSansSB',
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
                            fontFamily: 'WorkSansB',
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
                        title: "Harness the power of the sun and wind",
                        description: "Find out what works for you today",
                        buttonText: "Scan now !",
                        imagePath: "images/Sun.png",
                        navigateToPage: RenewableEnergyEstimation(),
                      ),
                      SizedBox(height: screenHeight * 0.08), // Extra space to avoid content being hidden behind navbar
                    ],
                  ),
                ),
              ),

              // Fixed Liquid Navbar at BOTTOM
              Positioned(
                bottom: screenHeight * 0.025,
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
      height: screenHeight * 0.305, // Increased height to match the design
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
                            color: Colors.white.withValues(alpha: 0.15),
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
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: const Color(0xFF1B5E20),
                        child: Text(
                          _userInitials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'WorkSansB',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Push welcome text and button to bottom

                // Welcome text
                Text(
                  "Hey! $_userName",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20.74,
                    fontFamily: 'WorkSansB',
                  ),
                ),
                Text(
                  _cityName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.4,
                    fontFamily: 'WorkSansM',
                  ),
                ),
                const Text(
                  "Ready to save energy and\nhelp the planet?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.4,
                    fontFamily: 'WorkSansM',
                    height: 1.4,
                  ),
                ),

                // "Let's go" button
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EnergyOnboardingPage()),
                    );
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
                      fontFamily: 'WorkSansSB',
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
            color: Colors.black.withValues(alpha: 0.08),
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
            // Date selector - Display only
            Row(
              children: [
                Text(
                  _formatDate(_selectedDate),
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontFamily: 'WorkSansSB',
                    color: Colors.black87,
                  ),
                ),
              ],
            ),

            // Custom Calendar - Scrollable (6 past days + today + 3 future days)
            Container(
              height: 75,
              padding: EdgeInsets.only(bottom: screenHeight * 0.005),
              child: ListView.builder(
                controller: _calendarScrollController,
                scrollDirection: Axis.horizontal,
                itemCount: 10, // 6 past + 1 today + 3 future
                itemBuilder: (context, index) {
                  final date = _todayDate.add(Duration(days: index - 6));
                  final isSelected = date.day == _selectedDate.day &&
                      date.month == _selectedDate.month &&
                      date.year == _selectedDate.year;
                  final isToday = date.day == _todayDate.day &&
                      date.month == _todayDate.month &&
                      date.year == _todayDate.year;

                  return GestureDetector(
                    onTap: () => _onDateSelected(date),
                    child: Container(
                      width: screenWidth * 0.12,
                      margin: EdgeInsets.symmetric(horizontal: 1),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Date number with white border for selected, green border for today
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
                                  : isToday
                                      ? Border.all(
                                          color: const Color(0xFF4CAF50),
                                          width: 2,
                                        )
                                      : null,
                            ),
                            child: Center(
                              child: Text(
                                '${date.day}',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  fontFamily: 'WorkSansSB',
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
                              fontFamily: 'WorkSansM',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Target and You Saved in Row
            Row(
              children: [
                // Target box
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(screenWidth * 0.03),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCFCFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'images/target.png',
                          width: screenWidth * 0.08,
                          height: screenWidth * 0.08,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(width: screenWidth * 0.015),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Target',
                              style: TextStyle(
                                fontSize: screenWidth * 0.03,
                                color: Colors.black87,
                                fontFamily: 'Worksans',
                              ),
                            ),
                            Text(
                              '${_co2Target.toStringAsFixed(0)} kg CO₂eq',
                              style: TextStyle(
                                fontSize: screenWidth * 0.038,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontFamily: 'WorkSansB',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: screenWidth * 0.02),

                // You Saved box
                Expanded(
                  child: Container(
                    padding: EdgeInsets.only(
                      left: screenWidth * 0.01,
                      top: screenWidth * 0.03,
                      bottom: screenWidth * 0.03,
                      right: screenWidth * 0.01, // Reduced right padding to prevent overflow
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCFCFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'images/save.png',
                          width: screenWidth * 0.08,
                          height: screenWidth * 0.08,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(width: screenWidth * 0.015),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'You Saved',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.03,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  fontFamily: 'WorkSansB',
                                ),
                              ),
                              Text(
                                '${_selectedDateCO2Saved.toStringAsFixed(1)} kg CO₂eq',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.038,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedDateCO2Saved > 5 
                                      ? const Color(0xFF4CAF50)  // Green for > 5
                                      : _selectedDateCO2Saved >= 0 
                                          ? const Color(0xFFF59E0B)  // Orange/amber for 0-5
                                          : const Color(0xFFEF4444),  // Red for negative
                                  fontFamily: 'WorkSansB',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: screenHeight * 0.01),

            // Steps, Driven, and Mascot in Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Steps and Driven boxes column
                Expanded(
                  child: Column(
                    children: [
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
                            Image.asset(
                              'images/Steps.png',
                              width: screenWidth * 0.08,
                              height: screenWidth * 0.08,
                              fit: BoxFit.contain,
                            ),
                            SizedBox(width: screenWidth * 0.015),
                            Text(
                              'Steps',
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                                fontFamily: 'Worksans',
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Text(
                              '$_selectedDateSteps',
                              style: TextStyle(
                                fontSize: screenWidth * 0.055,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4CAF50),
                                fontFamily: 'WorkSansB',
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.01),

                      // Driven Distance box
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
                            Image.asset(
                              'images/car.png',
                              width: screenWidth * 0.08,
                              height: screenWidth * 0.08,
                              fit: BoxFit.contain,
                            ),
                            SizedBox(width: screenWidth * 0.015),
                            Text(
                              'Driven',
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontFamily: 'Worksans',
                              ),
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Text(
                              '${_selectedDateDriven.toStringAsFixed(1)} km',
                              style: TextStyle(
                                fontSize: screenWidth * 0.055,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFEF4444),
                                fontFamily: 'WorkSansB',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: screenWidth * 0.02),

                // Mascot on the right (changes based on selected date's CO2)
                Container(
                  width: screenWidth * 0.28,
                  height: screenWidth * 0.35,
                  child: Image.asset(
                    _getMascotImage(_selectedDateCO2Saved),
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

            // Bottom message - Centered (dynamic based on CO2 saved)
            Center(
              child: Text(
                _getBottomMessageText(_selectedDateCO2Saved),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.32,
                  fontWeight: FontWeight.w600,
                  color: _getBottomMessageColor(_selectedDateCO2Saved),
                  height: 1.2,
                  fontFamily: 'WorkSansSB',
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
              color: Colors.black.withValues(alpha: 0.08),
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
                  fontFamily: 'WorkSansB',
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
                  fontFamily: 'Worksans',
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
                      fontFamily: 'WorkSansSB',
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

  // ==========================================
  // DRIVING DISTANCE TRACKING (INTEGRATED)
  // ==========================================
  // Note: Constants moved to module level above the class for background service access

  /// Initialize and start background service
  Future<void> _initializeAndStartBackgroundService() async {
    try {
      // Request notification permission first
      final notificationStatus = await Permission.notification.request();
      if (!notificationStatus.isGranted) {
        return;
      }

      // Check location permission
      LocationPermission locationPermission = await Geolocator.checkPermission();
      if (locationPermission == LocationPermission.denied) {
        locationPermission = await Geolocator.requestPermission();
      }
      if (locationPermission == LocationPermission.denied ||
          locationPermission == LocationPermission.deniedForever) {
        return;
      }

      final service = FlutterBackgroundService();

      // Create notification channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'driving_tracker_channel',
        'Driving Tracker',
        description: 'Tracks your driving distance in the background',
        importance: Importance.low,
      );

      final FlutterLocalNotificationsPlugin notificationsPlugin =
          FlutterLocalNotificationsPlugin();

      await notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // Configure background service
      await service.configure(
        iosConfiguration: IosConfiguration(
          autoStart: true,
          onForeground: onBackgroundServiceStart,
          onBackground: onIosBackground,
        ),
        androidConfiguration: AndroidConfiguration(
          onStart: onBackgroundServiceStart,
          autoStart: true,
          isForegroundMode: true,
          notificationChannelId: 'driving_tracker_channel',
          initialNotificationTitle: 'Driving Tracker',
          initialNotificationContent: 'Tracking your driving distance',
          foregroundServiceNotificationId: 888,
        ),
      );

      await service.startService();
    } catch (e) {
      // Silent catch
    }
  }

  /// Listen to updates from background service
  void _listenToBackgroundService() {
    final service = FlutterBackgroundService();
    service.on('update').listen((event) {
      if (event != null && mounted) {
        final distance = event['distance'] as double?;
        if (distance != null) {
          setState(() {
            _distanceDriven = distance;
          });
          _updateCO2Calculation();
        }
      }
    });
  }

  /// Load saved driving distance from SharedPreferences
  Future<void> _loadDrivingDistance() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString('lastDrivingDate');
    final today = DateTime.now().toIso8601String().split('T')[0];
    final todayDistanceKey = 'driven_km_$today';
    final storedDistanceForToday = prefs.getDouble(todayDistanceKey);

    if (savedDate != today) {
      if (storedDistanceForToday != null && storedDistanceForToday > 0.0) {
        await prefs.setDouble('dailyDistance', storedDistanceForToday);
      } else {
        await prefs.setDouble('dailyDistance', 0.0);
      }
      await prefs.setString('lastDrivingDate', today);
    } else if (storedDistanceForToday != null && storedDistanceForToday > 0.0) {
      final currentDaily = prefs.getDouble('dailyDistance') ?? 0.0;
      if (currentDaily == 0.0) {
        await prefs.setDouble('dailyDistance', storedDistanceForToday);
      }
    }

    if (!mounted) return;
    setState(() {
      _distanceDriven = prefs.getDouble('dailyDistance') ?? 0.0;
    });
    _updateCO2Calculation();
  }
}