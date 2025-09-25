import 'package:flutter/material.dart';
import 'package:might_ampora/Pages/OpeningScreen/EnergyPage.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({Key? key}) : super(key: key);

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  String? _selectedLivingType;

  final List<String> _livingTypes = ['Hostel', 'Home'];

  void _onContinue() {
    if (_nameController.text.isNotEmpty && 
        _schoolController.text.isNotEmpty &&
        _dobController.text.isNotEmpty && 
        _selectedLivingType != null) {
      // Add your continue logic here
      print('Name: ${_nameController.text}');
      print('School: ${_schoolController.text}');
      print('DOB: ${_dobController.text}');
      print('Living Type: $_selectedLivingType');
      
      // Navigate to next page
      Navigator.push(context, MaterialPageRoute(builder: (context) => EnergyOnboardingPage()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onBack() {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _schoolController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: screenHeight,
          ),
          child: IntrinsicHeight(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: screenHeight * 0.06),
                  
                  // App name
                  Center(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Might ',
                            style: TextStyle(
                              fontSize: screenWidth * 0.08,
                              color: const Color(0xFFFF6B35),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: 'Ampora',
                            style: TextStyle(
                              fontSize: screenWidth * 0.08,
                              color: const Color(0xFF4CAF50),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: screenHeight * 0.05),
                  
                  // Page title
                  Text(
                    'Student',
                    style: TextStyle(
                      fontSize: screenWidth * 0.08,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  SizedBox(height: screenHeight * 0.04),
                  
                  // Name field
                  Text(
                    'Your Name',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Ramesh Sharma',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: screenWidth * 0.04,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.02,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: screenHeight * 0.03),
                  
                  // School/College field
                  Text(
                    'Your School/College Name',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  TextField(
                    controller: _schoolController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Dhirubhai Ambani university',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: screenWidth * 0.04,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.02,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: screenHeight * 0.03),
                  
                  // Date of Birth field
                  Text(
                    'Your Date of Birth',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  TextField(
                    controller: _dobController,
                    readOnly: true,
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        _dobController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'DD/MM/YYYY',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: screenWidth * 0.04,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                      ),
                      suffixIcon: Icon(
                        Icons.calendar_today,
                        color: Colors.grey.shade600,
                        size: screenWidth * 0.05,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: screenHeight * 0.02,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: screenHeight * 0.03),
                  
                  // Living type question
                  Text(
                    'Do you live in a hostel or at home?',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  
                  // Living type selection chips
                  Row(
                    children: _livingTypes.map((livingType) {
                      final isSelected = _selectedLivingType == livingType;
                      return Container(
                        margin: EdgeInsets.only(right: screenWidth * 0.03),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedLivingType = livingType;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.06,
                              vertical: screenHeight * 0.015,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? const Color(0xFF4CAF50).withOpacity(0.1)
                                  : Colors.grey.shade50,
                              border: Border.all(
                                color: isSelected 
                                    ? const Color(0xFF4CAF50)
                                    : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(screenWidth * 0.06),
                            ),
                            child: Text(
                              livingType,
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                color: isSelected 
                                    ? const Color(0xFF4CAF50)
                                    : Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const Spacer(),
                  
                  // Back and Continue buttons
                  Row(
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: _onBack,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_back,
                              color: const Color(0xFF4CAF50),
                              size: screenWidth * 0.05,
                            ),
                            SizedBox(width: screenWidth * 0.02),
                            Text(
                              'Back',
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                color: const Color(0xFF4CAF50),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Continue button
                      SizedBox(
                        width: screenWidth * 0.4,
                        height: screenHeight * 0.06,
                        child: ElevatedButton(
                          onPressed: _onContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(screenWidth * 0.03),
                            ),
                          ),
                          child: Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: screenHeight * 0.015),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}