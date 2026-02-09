import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'detail2.dart';

class ManualDetailPage extends StatefulWidget {
  final String applianceName;
  final String powerRating;

  const ManualDetailPage({
    Key? key,
    required this.applianceName,
    required this.powerRating,
  }) : super(key: key);

  @override
  State<ManualDetailPage> createState() => _ManualDetailPageState();
}

class _ManualDetailPageState extends State<ManualDetailPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _deviceNameController = TextEditingController();
  final TextEditingController _powerRatingController = TextEditingController();
  final TextEditingController _usageController = TextEditingController();
  final TextEditingController _perUnitCostController = TextEditingController();
  final TextEditingController _deviceAgeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize controllers with passed values
    _deviceNameController.text = widget.applianceName;
    _powerRatingController.text = widget.powerRating;
  }

  @override
  void dispose() {
    _deviceNameController.dispose();
    _powerRatingController.dispose();
    _usageController.dispose();
    _perUnitCostController.dispose();
    _deviceAgeController.dispose();
    super.dispose();
  }

  void _calculateCost() {
    if (_formKey.currentState!.validate()) {
      final double power =
          double.tryParse(
            _powerRatingController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
          ) ??
          0;
      final double hours =
          double.tryParse(
            _usageController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
          ) ??
          0;

      // Validate average daily usage is between 0-24 hours
      if (hours < 0 || hours > 24) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Invalid Daily Usage'),
            content: const Text('Average daily usage must be between 0-24 hours.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      final double costPerUnit =
          double.tryParse(
            _perUnitCostController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
          ) ??
          6;

      // Validate per unit cost is positive
      if (costPerUnit <= 0) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Invalid Cost'),
            content: const Text('Per unit cost must be a positive number.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      final deviceAge = double.tryParse(
        _deviceAgeController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
      ) ?? 0;

      // Validate device age is positive
      if (deviceAge <= 0) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Invalid Device Age'),
            content: const Text('Device age must be a positive number.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      // Energy calculations
      final double dailyConsumption = (power * hours) / 1000; // kWh/day
      final double monthlyCost = dailyConsumption * costPerUnit * 30; // ₹/month
      final double co2PerDay = dailyConsumption * 0.82; // kg/day

      // Navigate to detail2 page with calculated data
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DeviceDetailsPage2(
            data: {
              "deviceName": _deviceNameController.text,
              "powerRating": power.toStringAsFixed(1),
              "usageHours": hours.toStringAsFixed(1),
              "perUnitCost": costPerUnit.toStringAsFixed(2),
              "deviceAge": _deviceAgeController.text,
              "beeRating": 3, // Default star rating
              "dailyConsumption": dailyConsumption.toStringAsFixed(2),
              "monthlyCost": monthlyCost.toStringAsFixed(2),
              "co2PerDay": co2PerDay.toStringAsFixed(2),
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Set status bar color
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and title
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: screenHeight * 0.02,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF2D8B6E),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF2D8B6E),
                        size: 20,
                      ),
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.04),
                  Expanded(
                    child: Text(
                      'Home Energy\nConsumption Setup',
                      style: TextStyle(
                        fontSize: screenWidth * 0.055,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'WorkSansB',
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Form content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: screenHeight * 0.02),

                      // Device Name field
                      _buildLabel('Device Name'),
                      _buildInputField(
                        controller: _deviceNameController,
                        hintText: 'Enter device name',
                        readOnly: false,
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // Power Rating field
                      _buildLabel('Power Rating (Watts)'),
                      _buildInputField(
                        controller: _powerRatingController,
                        hintText: 'Enter power rating in watts',
                        keyboardType: TextInputType.number,
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // Average Daily Usage field
                      _buildLabel('Average Daily Usage:'),
                      _buildInputField(
                        controller: _usageController,
                        hintText: '5 hours/day',
                        keyboardType: TextInputType.number,
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // Per unit cost and How old is your device (side by side)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Per unit cost'),
                                _buildInputField(
                                  controller: _perUnitCostController,
                                  hintText: '₹6/unit',
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.04),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Device\'s Age'),
                                _buildInputField(
                                  controller: _deviceAgeController,
                                  hintText: '1 year',
                                  keyboardType: TextInputType.number,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: screenHeight * 0.04),
                    ],
                  ),
                ),
              ),
            ),

            // Calculate button
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: screenHeight * 0.02,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _calculateCost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA726),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Calculate',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'WorkSansM',
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 15,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF4CAF50),
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: (value) {
        if (!readOnly && (value == null || value.isEmpty)) {
          return 'This field is required';
        }
        return null;
      },
    );
  }
}
