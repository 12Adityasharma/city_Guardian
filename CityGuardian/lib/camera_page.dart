import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  XFile? _capturedImage;

  List<CameraDescription>? _cameras;
  CameraDescription? _currentCamera;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      _currentCamera = _cameras!.first;
      await _setupCamera(_currentCamera!);
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _setupCamera(CameraDescription cameraDescription) async {
    _cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _cameraController!.initialize();
    setState(() {});
  }

  void _switchCamera() {
    if (_cameras == null || _cameras!.length < 2) return;
    final newCamera = _cameras!.firstWhere(
          (camera) => camera != _currentCamera,
      orElse: () => _cameras!.first,
    );
    _currentCamera = newCamera;
    _setupCamera(_currentCamera!);
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;
    _isFlashOn = !_isFlashOn;
    await _cameraController!.setFlashMode(
      _isFlashOn ? FlashMode.torch : FlashMode.off,
    );
    setState(() {});
  }

  Future<void> _captureImage() async {
    try {
      if (_cameraController == null || !_cameraController!.value.isInitialized) return;
      await _initializeControllerFuture;

      final image = await _cameraController!.takePicture();
      final directory = await getApplicationDocumentsDirectory();
      final savedPath = join(directory.path, '${DateTime.now()}.jpg');
      final savedImage = await File(image.path).copy(savedPath);

      setState(() {
        _capturedImage = XFile(savedImage.path);
      });
    } catch (e) {
      print('Capture error: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: (_initializeControllerFuture == null)
            ? const Center(child: CircularProgressIndicator())
            : FutureBuilder(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                _cameraController != null &&
                _cameraController!.value.isInitialized) {
              return Stack(
                children: [
                  SizedBox.expand(
                    child: CameraPreview(_cameraController!),
                  ),

                  // Dark overlay using withAlpha
                  Container(color: Colors.black.withAlpha((0.2 * 255).round())),

                  // Google Lens-style frame
                  Center(
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: LensFramePainter(),
                    ),
                  ),

                  // Capture Button
                  Positioned(
                    bottom: 30,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: _captureImage,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 70,
                          width: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade800, width: 4),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.black),
                        ),
                      ),
                    ),
                  ),

                  // Flash Toggle Button
                  Positioned(
                    top: 40,
                    left: 20,
                    child: IconButton(
                      icon: Icon(
                        _isFlashOn ? Icons.flash_on : Icons.flash_off,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: _toggleFlash,
                    ),
                  ),

                  // Switch Camera Button
                  Positioned(
                    top: 40,
                    right: 20,
                    child: IconButton(
                      icon: const Icon(Icons.switch_camera, color: Colors.white, size: 30),
                      onPressed: _switchCamera,
                    ),
                  ),

                  // Captured Image Preview
                  if (_capturedImage != null)
                    Positioned(
                      top: 100,
                      right: 20,
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              child: Image.file(File(_capturedImage!.path)),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 30,
                          backgroundImage: FileImage(File(_capturedImage!.path)),
                        ),
                      ),
                    ),
                ],
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}

/// Google Lens-style frame painter
class LensFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final double frameWidth = size.width * 0.7;
    final double frameHeight = size.height * 0.3;
    final double left = (size.width - frameWidth) / 2;
    final double top = (size.height - frameHeight) / 2;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, frameWidth, frameHeight),
      const Radius.circular(20),
    );

    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
