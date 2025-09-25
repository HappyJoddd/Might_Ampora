import 'package:flutter/material.dart';
import 'package:might_ampora/Pages/OpeningScreen/CommonPerson.dart';
import 'package:might_ampora/Pages/OpeningScreen/Student.dart';
import 'package:might_ampora/Pages/OpeningScreen/Teacher.dart';

class EnergyStoryPage extends StatefulWidget {
  const EnergyStoryPage({Key? key}) : super(key: key);

  @override
  State<EnergyStoryPage> createState() => _EnergyStoryPageState();
}

class _EnergyStoryPageState extends State<EnergyStoryPage> {
  String? _selectedRole;

  final List<Map<String, dynamic>> _roles = [
    {
      'title': 'Student',
      'value': 'student',
    },
    {
      'title': 'Teacher',
      'value': 'teacher',
    },
    {
      'title': 'Common Person',
      'value': 'common_person',
    },
  ];

  void _onRoleSelected(String role) {
    setState(() {
      _selectedRole = role;
    });
    
    print('Selected role: $role');
    
    // Navigate to appropriate profile page based on selection
    Future.delayed(const Duration(milliseconds: 300), () {
      switch (role) {
        case 'student':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StudentProfilePage(),
            ),
          );
          break;
        case 'teacher':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TeacherProfilePage(),
            ),
          );
          break;
        case 'common_person':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CommonPersonProfilePage(),
            ),
          );
          break;
        default:
          print('Unknown role selected: $role');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenHeight,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: screenHeight * 0.06),
                    
                    // App name
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Might ',
                            style: TextStyle(
                              fontSize: screenWidth * 0.08,
                              color: const Color(0xFFFF6B35), // Orange color
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: 'Ampora',
                            style: TextStyle(
                              fontSize: screenWidth * 0.08,
                              color: const Color(0xFF4CAF50), // Green color
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: screenHeight * 0.08),
                    
                    // Question text
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Who are you in this\nenergy story?',
                        style: TextStyle(
                          fontSize: screenWidth * 0.065,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ),
                    
                    SizedBox(height: screenHeight * 0.06),
                    
                    // Role selection buttons
                    ...List.generate(
                      _roles.length,
                      (index) {
                        final role = _roles[index];
                        final isSelected = _selectedRole == role['value'];
                        
                        return Container(
                          margin: EdgeInsets.only(
                            bottom: screenHeight * 0.02,
                          ),
                          width: double.infinity,
                          height: screenHeight * 0.07,
                          child: ElevatedButton(
                            onPressed: () => _onRoleSelected(role['value']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected 
                                  ? const Color(0xFF4CAF50).withOpacity(0.1)
                                  : const Color(0xFFF5F5F5),
                              foregroundColor: isSelected 
                                  ? const Color(0xFF4CAF50)
                                  : Colors.black87,
                              elevation: 0,
                              side: BorderSide(
                                color: isSelected 
                                    ? const Color(0xFF4CAF50)
                                    : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                              ),
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.only(left: screenWidth * 0.04),
                                child: Text(
                                  role['title'],
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const Spacer(),
                    
                    // Bottom indicator (navigation bar indicator)
                    Container(
                      width: screenWidth * 0.35,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}