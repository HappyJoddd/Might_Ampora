import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'detail.dart';

class ExtraDetailPage extends StatefulWidget {
  final File imageFile;
  final dynamic data; // JSON string or Map

  const ExtraDetailPage({
    Key? key,
    required this.imageFile,
    required this.data,
  }) : super(key: key);

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
  String brand = "";
  int selectedStarRating = 3; // Example default rating

  @override
  void initState() {
    super.initState();
    _parseBackendData();
  }

  /// ✅ Fixed navigation + correct field references
  void _calculateCost() {
    if (_formKey.currentState!.validate()) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DeviceDetailsPage(
            imageFile: widget.imageFile,
            data: {
              "deviceName": mainName,
              "brand": brand,
              "powerRating": _powerRatingController.text,
              "usageHours": _usageController.text,
              "perUnitCost": _perUnitCostController.text,
              "deviceAge": _deviceAgeController.text,
              "beeRating": selectedStarRating,
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

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

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
                        border:
                            Border.all(color: const Color(0xFF2D8B6E), width: 2),
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Color(0xFF2D8B6E), size: 20),
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
                          ),
                        ),
                        if (brand.isNotEmpty)
                          Text(
                            brand,
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              color: Colors.grey.shade600,
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
                                _buildLabel('Estimated Monthly Cost'),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.grey.shade200),
                                  ),
                                  child: Text(
                                    '₹112.50/month',
                                    style: TextStyle(
                                      fontSize: screenWidth * 0.035,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      _buildLabel('How old is your device'),
                      _buildInputField(
                        controller: _deviceAgeController,
                        hintText: '1 year',
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
                        borderRadius: BorderRadius.circular(28)),
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

  /// ✅ Safely parse backend data
  void _parseBackendData() {
    try {
      dynamic parsed =
          widget.data is String ? jsonDecode(widget.data) : widget.data;

      if (parsed is! Map) {
        debugPrint("❌ Data is not a Map");
        return;
      }

      Map<String, dynamic> data = Map<String, dynamic>.from(parsed);
      debugPrint("✅ Parsed data: $data");

      setState(() {
        mainName = data["mainName"]?.toString() ?? "Unknown Appliance";
        brand = data["mainBrand"]?.toString() ?? "";
      });

      debugPrint("✅ FINAL mainName: $mainName");
      debugPrint("✅ FINAL brand: $brand");
    } catch (e, st) {
      debugPrint("❌ Error parsing backend data: $e\n$st");
    }
  }

  Widget _buildLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      );

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
  }) =>
      TextFormField(
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (value) {
          if (!readOnly && (value == null || value.isEmpty)) {
            return 'This field is required';
          }
          return null;
        },
      );
}
