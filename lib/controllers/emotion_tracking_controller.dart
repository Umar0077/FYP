import 'dart:async';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/emotion_api_client.dart';
import '../config/emotion_tracking_config.dart';

/// Controller for managing emotion tracking during interviews
/// 
/// Uses takePicture() on Timer.periodic for reliable JPEG frame capture
/// Includes comprehensive error handling and logging
class EmotionTrackingController extends GetxController {
  late final EmotionApiClient _apiClient;

  // Reactive state
  final RxBool isActive = false.obs;
  final RxBool isPermissionGranted = false.obs;
  final RxBool isHealthy = false.obs;
  final RxString sessionId = ''.obs;
  final RxString statusMessage = ''.obs;
  final Rx<Map<String, dynamic>?> emotionReport = Rx<Map<String, dynamic>?>(null);

  CameraController? _cameraController;
  Timer? _captureTimer;
  bool _uploadInProgress = false; // Lock to prevent overlapping uploads
  bool _isStopping = false;
  bool _stopSessionCalled = false;
  Future<void>? _stopFuture;
  int _attemptNumber = 0;
  int _successfulUploads = 0;

  /// Get camera controller for UI preview (if enabled)
  CameraController? get cameraController => _cameraController;

  void _log(String scope, String message, {Object? error, int level = 800}) {
    developer.log(message, name: 'EmotionController.$scope', error: error, level: level);
    print('[EmotionTracking][$scope] $message');
  }

  @override
  void onInit() {
    super.onInit();
    // Initialize API client with base URL from config
    _apiClient = EmotionApiClient(
      baseUrl: EmotionTrackingConfig.baseUrl,
    );
    _log('Lifecycle', 'EmotionTrackingController initialized');
  }

  @override
  void onClose() {
    _captureTimer?.cancel();
    _disposeCamera();
    _apiClient.dispose();
    super.onClose();
  }

  /// Check camera permission status
  Future<bool> checkCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      isPermissionGranted.value = status.isGranted;
      _log('Permission', 'Camera permission status: ${status.isGranted ? 'granted' : 'denied'}');
      return status.isGranted;
    } catch (e) {
      _log('Permission', 'Permission check error: $e', error: e, level: 1000);
      return false;
    }
  }

  /// Request camera permission
  Future<bool> requestCameraPermission() async {
    try {
      final status = await Permission.camera.request();
      isPermissionGranted.value = status.isGranted;
      _log('Permission', 'Camera permission request result: ${status.isGranted ? 'granted' : 'denied'}');
      return status.isGranted;
    } catch (e) {
      _log('Permission', 'Permission request error: $e', error: e, level: 1000);
      return false;
    }
  }

  /// Initialize camera with front camera
  Future<bool> _initializeCamera() async {
    try {
      _log('CameraInit', 'Initializing camera');

      if (_cameraController != null) {
        _log('CameraInit', 'Existing camera controller found, disposing before re-init');
        await _disposeCamera();
      }
      
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _log('CameraInit', 'No cameras available', level: 1000);
        statusMessage.value = 'No camera available';
        return false;
      }

      _log('CameraInit', 'Available cameras: ${cameras.length}');

      // Prefer front camera for interviews
      final camera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _log('CameraInit', 'Selected front camera: ${camera.name} (${camera.lensDirection.name})');

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium, // Balance quality and performance
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      _log('CameraInit', 'Camera initialized successfully');
      return true;
    } catch (e) {
      _log('CameraInit', 'Camera initialization failed: $e', error: e, level: 1000);
      statusMessage.value = 'Camera initialization failed';
      return false;
    }
  }

  /// Start emotion tracking
  Future<bool> startTracking() async {
    try {
      _log('Start', 'Start emotion tracking requested');
      
      if (isActive.value) {
        _log('Start', 'Already active, skipping');
        return true;
      }

      _isStopping = false;
      _stopSessionCalled = false;

      statusMessage.value = 'Checking permissions...';
      
      // Check permission
      final hasPermission = await checkCameraPermission();
      if (!hasPermission) {
        final granted = await requestCameraPermission();
        if (!granted) {
          _log('Start', 'Camera permission denied', level: 900);
          statusMessage.value = 'Camera permission denied';
          return false;
        }
      }

      // Check backend health BEFORE starting session
      statusMessage.value = 'Checking backend...';
      final healthy = await _apiClient.checkHealth();
      isHealthy.value = healthy;
      
      if (!healthy) {
        _log('Start', 'Backend unhealthy, cannot start tracking', level: 1000);
        statusMessage.value = 'Backend unavailable';
        return false;
      }

      // Initialize camera
      statusMessage.value = 'Initializing camera...';
      final cameraReady = await _initializeCamera();
      if (!cameraReady) {
        return false;
      }

      // Start session
      statusMessage.value = 'Starting session...';
      final response = await _apiClient.startSession();
      sessionId.value = response.sessionId;
      _log('Start', 'Session started: ${response.sessionId}');
      _log('Start', 'Backend URL: ${EmotionTrackingConfig.baseUrl}');
      _log('Start', 'Capture interval: ${EmotionTrackingConfig.frameIntervalMs}ms');
      
      isActive.value = true;
      statusMessage.value = 'Tracking active';
      _attemptNumber = 0;
      _successfulUploads = 0;

      // Start periodic capture timer
      _startCaptureTimer();

      _log('Start', 'Emotion tracking active with session ${response.sessionId}');
      return true;
    } catch (e) {
      _log('Start', 'Start tracking error: $e', error: e, level: 1000);
      statusMessage.value = 'Failed to start tracking';
      await _disposeCamera();
      return false;
    }
  }

  /// Start periodic capture timer using takePicture()
  void _startCaptureTimer() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _log('CaptureTimer', 'Cannot start timer: camera not initialized');
      return;
    }

    _log('CaptureTimer', 'Timer started, interval=${EmotionTrackingConfig.frameIntervalMs}ms');
    
    _captureTimer = Timer.periodic(
      Duration(milliseconds: EmotionTrackingConfig.frameIntervalMs),
      (timer) async {
        if (_isStopping || !isActive.value) {
          timer.cancel();
          return;
        }
        await _captureAndUploadFrame();
      },
    );
  }

  /// Capture a single frame using takePicture and upload it
  Future<void> _captureAndUploadFrame() async {
    if (_isStopping || !isActive.value) {
      _log('Capture', 'Capture skipped: stop in progress or tracking inactive');
      return;
    }

    // Lock check - prevent overlapping uploads
    if (_uploadInProgress) {
      _log('Capture', 'Skipping tick: previous upload still in progress');
      return;
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _log('Capture', 'Camera not ready for capture');
      return;
    }

    if (sessionId.value.isEmpty) {
      _log('Capture', 'No session ID, skipping upload');
      return;
    }

    _uploadInProgress = true;
    _attemptNumber++;

    final activeSessionId = sessionId.value;
    _log('Capture', 'Capture attempt=$_attemptNumber session=$activeSessionId');

    try {
      // 1. Take picture
      final XFile imageFile = await _cameraController!.takePicture();
      _log('Capture', 'takePicture success path=${imageFile.path}');

      // 2. Read file and check size
      final file = File(imageFile.path);
      final bytes = await file.readAsBytes();
      final fileSize = bytes.length;
      _log('Capture', 'Captured file size=$fileSize bytes');

      // 3. Check magic bytes
      if (bytes.length < 4) {
        _log('Capture', 'File too small: ${bytes.length} bytes');
        await file.delete();
        return;
      }

      final magicHex = bytes.sublist(0, 4).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
      _log('Capture', 'Magic bytes=$magicHex');

      // Validate JPEG magic bytes (FF D8 FF)
      if (bytes[0] != 0xFF || bytes[1] != 0xD8 || bytes[2] != 0xFF) {
        _log('Capture', 'Invalid JPEG: expected FF D8 FF, got=$magicHex');
        await file.delete();
        return;
      }

      _log('Capture', 'Valid JPEG detected');

      if (_isStopping || !isActive.value || activeSessionId.isEmpty || activeSessionId != sessionId.value) {
        _log('Capture', 'Skipping upload because stop/session change was detected');
        await file.delete();
        return;
      }

      // 4. Upload to backend
      _log('Capture', 'Upload start: ${EmotionTrackingConfig.baseUrl}/predict_frame session=$activeSessionId');
      
      final result = await _apiClient.predictFrame(
        sessionId: activeSessionId,
        imageFile: file,
      );

      if (result != null) {
        _successfulUploads++;
        _log(
          'Capture',
          'Upload success #$_successfulUploads emotion=${result.emotion ?? 'unknown'} confidence=${result.confidence?.toStringAsFixed(4) ?? 'null'}',
        );
      } else {
        _log('Capture', 'Upload completed with null parsed response');
      }

      // Clean up temp file
      try {
        await file.delete();
        _log('Capture', 'Temp file deleted');
      } catch (e) {
        _log('Capture', 'Temp file delete error: $e', error: e, level: 900);
      }

    } catch (e, stackTrace) {
      _log('Capture', 'captureAndUploadFrame error: $e', error: '$e\n$stackTrace', level: 1000);
    } finally {
      _uploadInProgress = false;
    }
  }

  /// Stop emotion tracking
  Future<void> stopTracking() async {
    if (_stopFuture != null) {
      await _stopFuture;
      return;
    }

    final completer = Completer<void>();
    _stopFuture = completer.future;

    try {
      _log('Stop', 'Stop tracking requested');

      if (!isActive.value) {
        _log('Stop', 'Tracking already inactive, cleaning camera only');
        await _disposeCamera();
        statusMessage.value = 'Stopped';
        completer.complete();
        _stopFuture = null;
        return;
      }

      _isStopping = true;
      statusMessage.value = 'Stopping...';

      // Stop timer
      _captureTimer?.cancel();
      _captureTimer = null;
      _log('Stop', 'Capture timer cancelled');

      // Wait for current upload to finish before stopping backend session.
      int waitLoops = 0;
      while (_uploadInProgress && waitLoops < 60) {
        waitLoops++;
        await Future.delayed(const Duration(milliseconds: 100));
      }
      _log('Stop', 'In-flight upload state after wait: $_uploadInProgress (waitLoops=$waitLoops)');

      // Stop session and get report
      final activeSessionId = sessionId.value;
      if (activeSessionId.isNotEmpty && !_stopSessionCalled) {
        _stopSessionCalled = true;
        _log('Stop', 'Calling stop_session for session=$activeSessionId');
        final response = await _apiClient.stopSession(activeSessionId);
        emotionReport.value = response.emotionReport;

        _log('Stop', 'Emotion report received');
        if (response.emotionReport.containsKey('total_frames_processed')) {
          _log('Stop', 'Total frames processed: ${response.emotionReport['total_frames_processed']}');
        }
        _log('Stop', 'Report keys: ${response.emotionReport.keys.join(', ')}');
        _log('Stop', 'Local successful uploads=$_successfulUploads');
      }

      // Mark inactive before releasing resources to block any pending callbacks.
      isActive.value = false;
      sessionId.value = '';

      // Dispose camera
      await _disposeCamera();

      statusMessage.value = 'Stopped';

      _log('Stop', 'Emotion tracking stopped successfully');
    } catch (e, stackTrace) {
      _log('Stop', 'Stop tracking error: $e', error: '$e\n$stackTrace', level: 1000);
      isActive.value = false;
      sessionId.value = '';
      statusMessage.value = 'Stopped with errors';
    } finally {
      _isStopping = false;
      _stopSessionCalled = false;
      completer.complete();
      _stopFuture = null;
    }
  }

  /// Dispose camera controller
  Future<void> _disposeCamera() async {
    try {
      if (_cameraController != null) {
        _log('CameraDispose', 'Disposing camera controller');
        await _cameraController!.dispose();
        _cameraController = null;
        _log('CameraDispose', 'Camera disposed');
      }
    } catch (e) {
      _log('CameraDispose', 'Camera disposal error: $e', error: e, level: 900);
    }
  }

  /// Get latest emotion report
  Map<String, dynamic>? getEmotionReport() {
    return emotionReport.value;
  }

  /// Parse emotion summary from report
  Map<String, dynamic>? getEmotionSummary() {
    final report = emotionReport.value;
    if (report == null) return null;

    try {
      final summary = report['summary'];
      if (summary == null) return null;

      return {
        'total_duration': summary['total_duration_seconds'] ?? 0.0,
        'total_frames': summary['total_frames_processed'] ?? 0,
        'dominant_emotions': summary['dominant_emotions'] ?? [],
        'emotion_distribution': summary['emotion_distribution'] ?? {},
        'average_confidence': summary['average_confidence_overall'] ?? 0.0,
        'session_quality': summary['session_quality'] ?? 'unknown',
      };
    } catch (e) {
      _log('Summary', 'Failed to parse emotion summary: $e', error: e, level: 900);
      return null;
    }
  }
}
