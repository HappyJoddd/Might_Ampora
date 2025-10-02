import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CameraGalleryPickerPage extends StatefulWidget {
  const CameraGalleryPickerPage({Key? key}) : super(key: key);

  @override
  State<CameraGalleryPickerPage> createState() => _CameraGalleryPickerPageState();
}

class _CameraGalleryPickerPageState extends State<CameraGalleryPickerPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  final ImagePicker _picker = ImagePicker();

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
        // Return the captured image file
        Navigator.pop(context, File(image.path));
      } catch (e) {
        print('Error taking picture: $e');
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        // Return the selected image file
        Navigator.pop(context, File(image.path));
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
        child: // Replace the entire Stack in your build method with this updated version:

Stack(
  children: [
    // Camera Preview
    if (_isCameraInitialized && _cameraController != null)
      Positioned.fill(
        child: CameraPreview(_cameraController!),
      )
    else
      const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),

    // Frame overlay (the white brackets)
    Positioned.fill(
      child: CustomPaint(
        painter: FramePainter(
          screenWidth: screenWidth,
          screenHeight: screenHeight,
        ),
      ),
    ),

    // Top Bar - with higher z-index
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
              // Back button with Material for ripple effect
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    print('Back button tapped'); // Debug print
                    Navigator.of(context).pop();
                  },
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

    // Bottom Controls
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
              // Gallery Button (left side)
              GestureDetector(
                onTap: _pickFromGallery,
                child: Container(
                  width: screenWidth * 0.16,
                  height: screenWidth * 0.16,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    Icons.photo_library,
                    color: Colors.white,
                    size: screenWidth * 0.08,
                  ),
                ),
              ),

              // Capture Button (center)
              GestureDetector(
                onTap: _takePicture,
                child: Container(
                  width: screenWidth * 0.2,
                  height: screenWidth * 0.2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 5,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.015),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),

              // Flip Camera Button (right side)
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
                child: Container(
                  width: screenWidth * 0.16,
                  height: screenWidth * 0.16,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    Icons.flip_camera_android,
                    color: Colors.white,
                    size: screenWidth * 0.08,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ],
),
      ),
    );
  }
}

// Custom painter for the frame brackets
// Custom painter for the rounded rectangle frame brackets
class FramePainter extends CustomPainter {
  final double screenWidth;
  final double screenHeight;

  FramePainter({
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final frameHeight = screenHeight * 0.5; // Height of the frame
    final frameWidth = screenWidth * 0.75; // Width of the frame
    final cornerLength = screenWidth * 0.12; // Length of corner lines
    final borderRadius = 20.0; // Radius for rounded corners

    // Calculate frame position (centered)
    final left = (size.width - frameWidth) / 2;
    final right = left + frameWidth;
    final top = (size.height - frameHeight) / 2;
    final bottom = top + frameHeight;

    // Top-left corner
    final topLeftPath = Path();
    topLeftPath.moveTo(left + cornerLength, top);
    topLeftPath.lineTo(left + borderRadius, top);
    topLeftPath.quadraticBezierTo(left, top, left, top + borderRadius);
    topLeftPath.lineTo(left, top + cornerLength);
    canvas.drawPath(topLeftPath, paint);

    // Top-right corner
    final topRightPath = Path();
    topRightPath.moveTo(right - cornerLength, top);
    topRightPath.lineTo(right - borderRadius, top);
    topRightPath.quadraticBezierTo(right, top, right, top + borderRadius);
    topRightPath.lineTo(right, top + cornerLength);
    canvas.drawPath(topRightPath, paint);

    // Bottom-left corner
    final bottomLeftPath = Path();
    bottomLeftPath.moveTo(left, bottom - cornerLength);
    bottomLeftPath.lineTo(left, bottom - borderRadius);
    bottomLeftPath.quadraticBezierTo(left, bottom, left + borderRadius, bottom);
    bottomLeftPath.lineTo(left + cornerLength, bottom);
    canvas.drawPath(bottomLeftPath, paint);

    // Bottom-right corner
    final bottomRightPath = Path();
    bottomRightPath.moveTo(right, bottom - cornerLength);
    bottomRightPath.lineTo(right, bottom - borderRadius);
    bottomRightPath.quadraticBezierTo(right, bottom, right - borderRadius, bottom);
    bottomRightPath.lineTo(right - cornerLength, bottom);
    canvas.drawPath(bottomRightPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}