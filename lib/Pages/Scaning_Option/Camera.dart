import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'Extradetail.dart';
import 'package:mime/mime.dart'; // for detecting mime type
import 'package:http_parser/http_parser.dart'; // for MediaType


class CameraGalleryPickerPage extends StatefulWidget {
  const CameraGalleryPickerPage({Key? key}) : super(key: key);

  @override
  State<CameraGalleryPickerPage> createState() =>
      _CameraGalleryPickerPageState();
}

bool _isLoading = false;

class _CameraGalleryPickerPageState extends State<CameraGalleryPickerPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  final ImagePicker _picker = ImagePicker();

  // ✅ Upload function using Hugging Face backend
Future<Map<String, dynamic>?> _uploadImage(File imageFile) async {
  try {
    final baseUrl = dotenv.env['BACKEND_URL'] ?? 
      "https://might-ampora-backend-p4tz.onrender.com/api/v1";
    final uri = Uri.parse("$baseUrl/gadgets/recognize");

    // ✅ Detect the MIME type (e.g., image/jpeg or image/png)
    final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
    print("🧠 Detected MIME type: $mimeType");

    final request = http.MultipartRequest('POST', uri);

    // ✅ Explicitly set MIME type when attaching file
    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType.parse(mimeType),
      ),
    );

    // Headers
    request.headers.addAll({
      'Accept': 'application/json',
    });

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print("URI: $uri");
    print("STATUS CODE: ${response.statusCode}");
    print("RAW BODY: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("Upload failed → ${response.body}");
      return jsonDecode(response.body);
    }
  } catch (e) {
    print("🚨 Upload exception: $e");
    return null;
  }
}

  Future<void> _processImage(File imageFile) async {
    setState(() => _isLoading = true);

    final result = await _uploadImage(imageFile);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result != null && result['success'] == true) {
      debugPrint("✅ Backend result: $result");

      // Extract mainName and confidence from result
      final data = result['data'];
      final mainName = data['mainName'] ?? '';
      final confidenceStr = data['confidence'] ?? '0%';
      
      // Parse confidence percentage (e.g., "75.50%" -> 75.50)
      final confidenceValue = double.tryParse(
        confidenceStr.toString().replaceAll('%', '').trim()
      ) ?? 0.0;

      // Check if it's "Other" or confidence is less than 60%
      if (mainName.toLowerCase() == 'other' || confidenceValue < 60.0) {
        _showRetryDialog(mainName, confidenceValue);
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ExtraDetailPage(
            imageFile: imageFile,
            data: result,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result?['message'] ?? "Failed to identify device. Try again."),
        ),
      );
    }
  }

  void _showRetryDialog(String detectedName, double confidence) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange, size: 28),
            SizedBox(width: 10),
            Expanded(child: Text('Unable to Recognize')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'We couldn\'t identify this as a home appliance. Let\'s try again!',
              style: TextStyle(fontSize: 15, height: 1.4),
            ),
            SizedBox(height: 15),
            Text(
              'For best results, please ensure:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            SizedBox(height: 8),
            _buildTipRow('Good lighting on the appliance'),
            _buildTipRow('Clear, steady angle'),
            _buildTipRow('Entire appliance is visible in frame'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it, Try Again',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipRow(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
          SizedBox(width: 8),
          Expanded(
            child: Text(tip, style: TextStyle(fontSize: 13, height: 1.3)),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final XFile image = await _cameraController!.takePicture();
        await _processImage(File(image.path));
      } catch (e) {
        print('Error taking picture: $e');
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        await _processImage(File(image.path));
      }
    } catch (e) {
      print('Error picking from gallery: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox(
        height: screenHeight,
        width: screenWidth,
        child: Stack(
          children: [
            if (_isCameraInitialized && _cameraController != null)
              Positioned.fill(child: CameraPreview(_cameraController!))
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            Positioned.fill(
              child: CustomPaint(
                painter: FramePainter(
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                ),
              ),
            ),

            // 🔙 Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  height: screenHeight * 0.08,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.01,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: screenWidth * 0.07,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 📸 Bottom Controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  height: screenHeight * 0.15,
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Gallery
                      GestureDetector(
                        onTap: _pickFromGallery,
                        child: _buildControlButton(
                          screenWidth,
                          icon: Icons.photo_library,
                        ),
                      ),

                      // Capture
                      GestureDetector(
                        onTap: _takePicture,
                        child: Container(
                          width: screenWidth * 0.2,
                          height: screenWidth * 0.2,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 5),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(screenWidth * 0.015),
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Flip Camera
                      GestureDetector(
                        onTap: () async {
                          if (_cameras != null && _cameras!.length > 1) {
                            final currentCamera = _cameraController!.description;
                            final newCamera = _cameras!.firstWhere(
                              (camera) => camera != currentCamera,
                            );

                            await _cameraController?.dispose();
                            _cameraController = CameraController(
                              newCamera,
                              ResolutionPreset.high,
                              enableAudio: false,
                            );
                            await _cameraController!.initialize();
                            setState(() {});
                          }
                        },
                        child: _buildControlButton(
                          screenWidth,
                          icon: Icons.flip_camera_android,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton(double screenWidth, {required IconData icon}) {
    return Container(
      width: screenWidth * 0.16,
      height: screenWidth * 0.16,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Icon(icon, color: Colors.white, size: screenWidth * 0.08),
    );
  }
}

// 🎯 Frame painter (unchanged)
class FramePainter extends CustomPainter {
  final double screenWidth;
  final double screenHeight;

  FramePainter({required this.screenWidth, required this.screenHeight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final frameHeight = screenHeight * 0.5;
    final frameWidth = screenWidth * 0.75;
    final cornerLength = screenWidth * 0.12;
    final borderRadius = 20.0;

    final left = (size.width - frameWidth) / 2;
    final right = left + frameWidth;
    final top = (size.height - frameHeight) / 2;
    final bottom = top + frameHeight;

    final corners = [
      Path()
        ..moveTo(left + cornerLength, top)
        ..lineTo(left + borderRadius, top)
        ..quadraticBezierTo(left, top, left, top + borderRadius)
        ..lineTo(left, top + cornerLength),
      Path()
        ..moveTo(right - cornerLength, top)
        ..lineTo(right - borderRadius, top)
        ..quadraticBezierTo(right, top, right, top + borderRadius)
        ..lineTo(right, top + cornerLength),
      Path()
        ..moveTo(left, bottom - cornerLength)
        ..lineTo(left, bottom - borderRadius)
        ..quadraticBezierTo(left, bottom, left + borderRadius, bottom)
        ..lineTo(left + cornerLength, bottom),
      Path()
        ..moveTo(right, bottom - cornerLength)
        ..lineTo(right, bottom - borderRadius)
        ..quadraticBezierTo(right, bottom, right - borderRadius, bottom)
        ..lineTo(right - cornerLength, bottom),
    ];

    for (var path in corners) {
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
