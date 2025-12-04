import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class CameraCaptureScreen extends StatefulWidget {
  final Map<String, dynamic> sessionData;

  const CameraCaptureScreen({Key? key, required this.sessionData})
    : super(key: key);

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  late CameraController _controller;
  Future<void>? _initializeControllerFuture;

  List<XFile> _capturedImages = [];
  bool _isLoading = false;
  bool _isCameraReady = false;
  bool _isDisposed = false;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    _isDisposed = false;
    _initializeCamera();
  }

  @override
  void deactivate() {
    if (!_isDisposed) {
      try {
        _controller.dispose();
      } catch (_) {}
      _isDisposed = true;
    }
    super.deactivate();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        _showError('No camera available');
        return;
      }

      _controller = CameraController(
        _cameras!.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      setState(() => _isCameraReady = false);

      _initializeControllerFuture = _controller.initialize();
      await _initializeControllerFuture;

      if (mounted && !_isDisposed) {
        setState(() => _isCameraReady = true);
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        _showError('Failed to initialize camera: $e');
      }
    }
  }

  void _handleBackPressed() {
    context.pop();
  }

  // ----------------------------------------
  // SAFE CAMERA PREVIEW WIDGET
  // ----------------------------------------
  Widget _buildSafeCameraPreview() {
    if (!_isCameraReady || !_controller.value.isInitialized || _isDisposed) {
      return _buildCameraLoadingWidget();
    }

    return CameraPreview(_controller);
  }

  Widget _buildCameraLoadingWidget() {
    return Container(
      color: Colors.grey.shade900,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(color: Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'Initializing Camera...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: Color(0xFF475569),
            ),
          ),
          onPressed: _handleBackPressed,
        ),
        title: const Text(
          'Click Class Photos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),

      body: Column(
        children: [
          // CAMERA PREVIEW
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _buildSafeCameraPreview(),
              ),
            ),
          ),

          // IMAGES PREVIEW
          if (_capturedImages.isNotEmpty)
            Container(
              height: 120,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade800, width: 1),
                ),
              ),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, index) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_capturedImages[index].path),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () => _removeImage(index),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemCount: _capturedImages.length,
              ),
            ),

          // CONTROLS
          _buildBottomControls(),
        ],
      ),
    );
  }

  // ----------------------------------------
  // BOTTOM CONTROLS
  // ----------------------------------------
  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        border: Border(top: BorderSide(color: Colors.grey.shade800, width: 1)),
      ),
      child: Column(
        children: [
          // Flip + Capture
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Flip camera
              IconButton(
                icon: Icon(
                  Icons.flip_camera_ios,
                  color: _isCameraReady ? Colors.white : Colors.grey.shade600,
                  size: 28,
                ),
                onPressed: _isCameraReady ? _switchCamera : null,
              ),

              // Capture button
              GestureDetector(
                onTap: _captureImage,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _isCameraReady
                        ? const Color(0xFF2563EB)
                        : Colors.grey.shade600,
                    shape: BoxShape.circle,
                  ),
                  child: _isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 32,
                        ),
                ),
              ),

              const SizedBox(width: 50),
            ],
          ),

          const SizedBox(height: 16),

          // Submit button
          if (_capturedImages.isNotEmpty)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitAttendance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Submit Attendance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ----------------------------------------
  // CAMERA ACTIONS (FIXED)
  // ----------------------------------------

  Future<void> _captureImage() async {
    if (!_isCameraReady || _isLoading || _isDisposed) return;

    try {
      setState(() => _isLoading = true);

      // Add small delay to prevent rapid captures
      await Future.delayed(const Duration(milliseconds: 200));

      final XFile image = await _controller.takePicture();

      if (mounted && !_isDisposed) {
        setState(() {
          _capturedImages.add(image);
          _isLoading = false;
        });
      }

      HapticFeedback.lightImpact();
    } catch (e) {
      if (mounted && !_isDisposed) {
        setState(() => _isLoading = false);
        _showError("Failed to capture image: $e");
      }
    }
  }

  void _removeImage(int index) {
    if (_isDisposed) return;

    setState(() {
      _capturedImages.removeAt(index);
    });

    HapticFeedback.lightImpact();
  }

  Future<void> _switchCamera() async {
    if (_cameras == null ||
        _cameras!.length < 2 ||
        !_isCameraReady ||
        _isLoading ||
        _isDisposed)
      return;

    try {
      setState(() {
        _isLoading = true;
        _isCameraReady = false;
      });

      final newCamera = _controller.description == _cameras!.first
          ? _cameras!.last
          : _cameras!.first;

      // Dispose current controller
      await _controller.dispose();

      // Create new controller
      _controller = CameraController(
        newCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      _initializeControllerFuture = _controller.initialize();
      await _initializeControllerFuture;

      if (mounted && !_isDisposed) {
        setState(() {
          _isCameraReady = true;
          _isLoading = false;
        });
      }

      HapticFeedback.lightImpact();
    } catch (e) {
      if (mounted && !_isDisposed) {
        setState(() => _isLoading = false);
        _showError("Failed to switch camera: $e");

        // Try to reinitialize with original camera
        _initializeCamera();
      }
    }
  }

  Future<void> _submitAttendance() async {
    if (_capturedImages.isEmpty || _isLoading || _isDisposed) return;

    final attendanceId = widget.sessionData['attendance_id'];

    // 🚀 Dispose camera BEFORE navigation
    try {
      await _controller.dispose();
    } catch (_) {}
    _isDisposed = true;

    if (!mounted) return;

    context.pushReplacement(
      '/teacher/mark-attendance',
      extra: {
        "attendance_id": attendanceId,
        "session_data": widget.sessionData,
        "images": _capturedImages,
      },
    );
  }

  void _showError(String message) {
    if (!mounted || _isDisposed) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
