import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'Extradetail.dart';
import '../../services/gadget_service.dart';
Map<String, dynamic> parseBackendData(dynamic response) {
  final data = response["data"];

  if (data == null) {
    return {"name": "Unknown Appliance", "confidence": 0.0};
  }

  List labels = data["labels"] ?? [];
  List objects = data["objects"] ?? [];

  labels.sort((a, b) => (b["score"] ?? 0).compareTo(a["score"] ?? 0));
  final bestLabel = labels.isNotEmpty ? labels.first : null;

  objects.sort((a, b) => (b["score"] ?? 0).compareTo(a["score"] ?? 0));
  final bestObject = objects.isNotEmpty ? objects.first : null;

  return {
    "name": bestLabel?["description"] ?? bestObject?["name"] ?? "Unknown Appliance",
    "confidence": bestLabel?["score"] ?? bestObject?["score"] ?? 0.0,
  };
}


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

Future<void> _processImage(File imageFile) async {
  setState(() => _isLoading = true);

  final result = await GadgetService.recognizeGadget(imageFile);

  setState(() => _isLoading = false);

  if (!mounted) return;

  if (result != null) {
    debugPrint("✅ Backend result: $result");

    // ⚡️ If result is a String, decode it
    final parsed = result is String ? jsonDecode(result) : result;

    // Now pass directly to the ExtraDetailPage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ExtraDetailPage(
          imageFile: imageFile,
          data: parsed, // ✅ pass backend data directly
        ),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Failed to identify device. Try again.")),
    );
  }
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
          // Camera Preview
          if (_isCameraInitialized && _cameraController != null)
            Positioned.fill(child: CameraPreview(_cameraController!))
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Frame overlay
          Positioned.fill(
            child: CustomPaint(
              painter: FramePainter(
                screenWidth: screenWidth,
                screenHeight: screenHeight,
              ),
            ),
          ),

          // Top Bar
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
                        onTap: () {
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
                padding: EdgeInsets.symmetric(
                  vertical: screenHeight * 0.02,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Gallery
                    GestureDetector(
                      onTap: _pickFromGallery,
                      child: Container(
                        width: screenWidth * 0.16,
                        height: screenWidth * 0.16,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: Icon(
                          Icons.photo_library,
                          color: Colors.white,
                          size: screenWidth * 0.08,
                        ),
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
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Flip
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
                          border: Border.all(color: Colors.white, width: 3),
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

          // ✅ LOADING OVERLAY (MOVED HERE)
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
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

  FramePainter({required this.screenWidth, required this.screenHeight});

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
    bottomRightPath.quadraticBezierTo(
      right,
      bottom,
      right - borderRadius,
      bottom,
    );
    bottomRightPath.lineTo(right - cornerLength, bottom);
    canvas.drawPath(bottomRightPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
