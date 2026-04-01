import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'dart:developer' as developer;

/// Service for capturing frames from camera using takePicture()
class FrameCaptureService {
  CameraController? _cameraController;
  Timer? _captureTimer;
  bool _isCapturing = false;
  
  // Configuration
  Duration captureInterval;
  
  FrameCaptureService({
    this.captureInterval = const Duration(milliseconds: 900),
  });
  
  /// Initialize camera
  Future<void> initializeCamera(CameraDescription camera) async {
    developer.log('Initializing camera: ${camera.name}', name: 'FrameCaptureService');
    
    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    
    await _cameraController!.initialize();
    developer.log('Camera initialized successfully', name: 'FrameCaptureService');
  }
  
  /// Start capturing frames on timer
  void startCapture(Future<void> Function(File imageFile) onFrameCaptured) {
    if (_isCapturing) {
      developer.log('Already capturing, ignoring start request', name: 'FrameCaptureService');
      return;
    }
    
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      developer.log('Camera not initialized', name: 'FrameCaptureService', error: 'Camera not ready');
      throw Exception('Camera not initialized');
    }
    
    _isCapturing = true;
    developer.log(
      'Starting frame capture every ${captureInterval.inMilliseconds}ms',
      name: 'FrameCaptureService',
    );
    
    _captureTimer = Timer.periodic(captureInterval, (timer) async {
      if (!_isCapturing || _cameraController == null) {
        timer.cancel();
        return;
      }
      
      try {
        // Capture still image
        final image = await _cameraController!.takePicture();
        final imageFile = File(image.path);
        
        developer.log(
          'Frame captured: ${image.path}',
          name: 'FrameCaptureService',
        );
        
        // Invoke callback
        await onFrameCaptured(imageFile);
        
      } catch (e) {
        developer.log(
          'Frame capture error: $e',
          name: 'FrameCaptureService',
          error: e,
        );
      }
    });
  }
  
  /// Stop capturing frames
  void stopCapture() {
    if (!_isCapturing) {
      return;
    }
    
    developer.log('Stopping frame capture', name: 'FrameCaptureService');
    _isCapturing = false;
    _captureTimer?.cancel();
    _captureTimer = null;
  }
  
  /// Update capture interval
  void updateInterval(Duration newInterval) {
    captureInterval = newInterval;
    developer.log(
      'Capture interval updated to ${newInterval.inMilliseconds}ms',
      name: 'FrameCaptureService',
    );
  }
  
  /// Get camera controller for preview
  CameraController? get cameraController => _cameraController;
  
  /// Check if capturing
  bool get isCapturing => _isCapturing;
  
  /// Dispose camera
  Future<void> dispose() async {
    developer.log('Disposing camera', name: 'FrameCaptureService');
    stopCapture();
    await _cameraController?.dispose();
    _cameraController = null;
  }
}
