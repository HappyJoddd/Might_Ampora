import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'detail.dart';


// Use environment variable for backend URL
final String baseUrl = dotenv.env['BACKEND_URL'] ?? 
  "https://might-ampora-backend-p4tz.onrender.com/api/v1";


class ExtraDetailPage extends StatefulWidget {
  final File imageFile;
  final dynamic data; // JSON string or Map

  const ExtraDetailPage({Key? key, required this.imageFile, required this.data})
    : super(key: key);

  @override
  State<ExtraDetailPage> createState() => _ExtraDetailPageState();
}

class _ExtraDetailPageState extends State<ExtraDetailPage> {
  final _formKey = GlobalKey<FormState>();
  final _powerRatingController = TextEditingController();
  final _usageController = TextEditingController();
  final _perUnitCostController = TextEditingController();
  final _deviceAgeController = TextEditingController();

  String mainName = "Unknown Appliance";
  String? mainBrand; // null means hidden, non-null & non-Unknown means shown

  @override
  void initState() {
    super.initState();
    _parseBackendData();
  }

  /// ✅ Fixed navigation + correct field references
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

      // 🔹 Energy calculations
      final double dailyConsumption = (power * hours) / 1000; // kWh/day
      final double monthlyCost = dailyConsumption * costPerUnit * 30; // ₹/month
      final double co2PerDay = dailyConsumption * 0.82; // kg/day

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DeviceDetailsPage(
            imageFile: widget.imageFile,
            data: {
              "deviceName": mainName,
              "brand": mainBrand,
              "powerRating": power.toStringAsFixed(1),
              "usageHours": hours.toStringAsFixed(1),
              "perUnitCost": costPerUnit.toStringAsFixed(2),
              "deviceAge": _deviceAgeController.text,
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
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mainName,
                          style: TextStyle(
                            fontSize: screenWidth * 0.055,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'WorkSansB',
                          ),
                        ),
                        if (mainBrand != null &&
                            mainBrand!.isNotEmpty &&
                            mainBrand!.toLowerCase() != 'unknown')
                          Text(
                            mainBrand!,
                            style: TextStyle(
                              fontSize: screenWidth * 0.035,
                              color: Colors.grey[600],
                              fontFamily: 'WorkSans',
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: screenHeight * 0.02),
                      _buildLabel('Power Rating:'),
                      _buildInputField(
                        controller: _powerRatingController,
                        hintText: '~75 Watts',
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      _buildLabel('Average Daily Usage:'),
                      _buildInputField(
                        controller: _usageController,
                        hintText: '5 hours/day',
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: screenHeight * 0.02),
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

  /// Parse the new Gemini backend response
  void _parseBackendData() {
    try {
      dynamic parsed = widget.data is String
          ? jsonDecode(widget.data)
          : widget.data;

      if (parsed is! Map) return;

      // Extract nested "data" object
      final Map<String, dynamic> innerData =
          parsed.containsKey("data")
              ? Map<String, dynamic>.from(parsed["data"])
              : {};

      setState(() {
        mainName = innerData["mainName"]?.toString() ?? "Unknown Appliance";

        // Brand — only set if present and not "Unknown"
        final brand = innerData["mainBrand"]?.toString();
        mainBrand = (brand != null &&
                brand.isNotEmpty &&
                brand.toLowerCase() != 'unknown')
            ? brand
            : null;

        // Gemini returns estimatedWattage as "700 W" — strip the unit and prefill
        final estimatedWattage = innerData["estimatedWattage"]?.toString();
        if (estimatedWattage != null && estimatedWattage.isNotEmpty) {
          _powerRatingController.text =
              estimatedWattage.replaceAll(RegExp(r'\s*[Ww]\s*$'), '').trim();
        }
      });
    } catch (e) {
      // Silent error handling
    }
  }

  Widget _buildLabel(String label) => Padding(
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) => TextFormField(
    controller: controller,
    readOnly: readOnly,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 15),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    validator: (value) {
      if (!readOnly && (value == null || value.isEmpty)) {
        return 'This field is required';
      }
      return null;
    },
  );
}
