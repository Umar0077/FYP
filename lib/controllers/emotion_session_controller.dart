import 'dart:io';
import 'package:get/get.dart';
import '../services/emotion_api_client.dart';
import '../services/frame_capture_service.dart';
import 'package:camera/camera.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:developer' as developer;

/// Controller for managing emotion detection session
class EmotionSessionController extends GetxController {
  // Services
  EmotionApiClient? _apiClient;
  FrameCaptureService? _captureService;
  final _secureStorage = const FlutterSecureStorage();
  
  // State
  final sessionId = RxnString();
  final currentEmotion = RxString('');
  final isSessionActive = RxBool(false);
  final errorMessage = RxString('');
  final lastEmotionReport = Rx<Map<String, dynamic>?>(null);
  final baseUrl = RxString('http://3.238.23.25:5000');
  
  // Stats
  final framesUploaded = RxInt(0);
  final uploadErrors = RxInt(0);
  
  // Configuration keys
  static const String baseUrlKey = 'emotion_api_base_url';
  static const String defaultBaseUrl = 'http://3.238.23.25:5000';
  
  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }
  
  /// Load settings from secure storage
  Future<void> _loadSettings() async {
    final savedUrl = await _secureStorage.read(key: baseUrlKey);
    if (savedUrl != null && savedUrl.isNotEmpty) {
      baseUrl.value = savedUrl;
    } else {
      baseUrl.value = defaultBaseUrl;
    }
    developer.log('Loaded base URL: ${baseUrl.value}', name: 'EmotionSessionController');
  }
  
  /// Save base URL
  Future<void> saveBaseUrl(String url) async {
    await _secureStorage.write(key: baseUrlKey, value: url);
    baseUrl.value = url;
    developer.log('Saved base URL: $url', name: 'EmotionSessionController');
  }
  
  /// Check if backend is reachable
  Future<bool> checkHealth() async {
    try {
      final client = EmotionApiClient(baseUrl: baseUrl.value);
      final healthy = await client.checkHealth();
      client.dispose();
      return healthy;
    } catch (e) {
      developer.log('Health check error: $e', name: 'EmotionSessionController', error: e);
      return false;
    }
  }
  
  /// Start emotion detection session
  Future<void> startSession(CameraDescription camera) async {
    if (isSessionActive.value) {
      developer.log('Session already active', name: 'EmotionSessionController');
      return;
    }
    
    try {
      errorMessage.value = '';
      framesUploaded.value = 0;
      uploadErrors.value = 0;
      
      // Initialize API client
      _apiClient = EmotionApiClient(baseUrl: baseUrl.value);
      
      // Start backend session
      developer.log('Starting backend session', name: 'EmotionSessionController');
      final response = await _apiClient!.startSession();
      sessionId.value = response.sessionId;
      
      // Initialize camera capture
      _captureService = FrameCaptureService(
        captureInterval: const Duration(milliseconds: 900),
      );
      await _captureService!.initializeCamera(camera);
      
      // Start capturing and uploading
      _captureService!.startCapture(_onFrameCaptured);
      
      isSessionActive.value = true;
      developer.log(
        'Session started successfully: ${sessionId.value}',
        name: 'EmotionSessionController',
      );
      
    } catch (e) {
      errorMessage.value = 'Failed to start session: $e';
      developer.log(errorMessage.value, name: 'EmotionSessionController', error: e);
      await stopSession();
      rethrow;
    }
  }
  
  /// Handle captured frame
  Future<void> _onFrameCaptured(File imageFile) async {
    if (!isSessionActive.value || _apiClient == null || sessionId.value == null) {
      return;
    }
    
    try {
      final response = await _apiClient!.predictFrame(
        sessionId: sessionId.value!,
        imageFile: imageFile,
      );
      
      if (response != null) {
        currentEmotion.value = response.emotion ?? currentEmotion.value;
        framesUploaded.value++;
        developer.log(
          'Emotion detected: ${response.emotion} (frames: ${framesUploaded.value})',
          name: 'EmotionSessionController',
        );
      }
      
    } on InvalidImageFormatException catch (e) {
      uploadErrors.value++;
      errorMessage.value = 'Invalid image format. Please check camera settings.';
      developer.log('Image validation failed: $e', name: 'EmotionSessionController');
      
    } on RouteNotFoundException catch (e) {
      uploadErrors.value++;
      errorMessage.value = 'Backend route not found. Please check configuration.';
      developer.log('Route error: $e', name: 'EmotionSessionController', error: e);
      
      // Stop session on route error
      Get.snackbar(
        'Configuration Error',
        'The backend route was not found. Stopping emotion detection.',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 5),
      );
      await stopSession();
      
    } catch (e) {
      uploadErrors.value++;
      developer.log('Upload error: $e', name: 'EmotionSessionController', error: e);
      
      // Don't show error for every failed upload, just log it
      if (uploadErrors.value % 5 == 0) {
        errorMessage.value = 'Upload issues detected (${uploadErrors.value} errors)';
      }
    }
  }
  
  /// Stop emotion detection session
  Future<void> stopSession() async {
    if (!isSessionActive.value) {
      return;
    }
    
    developer.log('Stopping session', name: 'EmotionSessionController');
    isSessionActive.value = false;
    
    try {
      // Stop capture
      _captureService?.stopCapture();
      await _captureService?.dispose();
      _captureService = null;
      
      // Stop backend session and get report
      if (_apiClient != null && sessionId.value != null) {
        final response = await _apiClient!.stopSession(sessionId.value!);
        lastEmotionReport.value = response.emotionReport;
        
        developer.log(
          'Session stopped, report received',
          name: 'EmotionSessionController',
        );
      }
      
      _apiClient?.dispose();
      _apiClient = null;
      
    } catch (e) {
      developer.log('Error stopping session: $e', name: 'EmotionSessionController', error: e);
    } finally {
      sessionId.value = null;
    }
  }
  
  /// Update capture interval
  void updateCaptureInterval(int milliseconds) {
    _captureService?.updateInterval(Duration(milliseconds: milliseconds));
  }
  
  /// Get camera controller for preview
  CameraController? get cameraController => _captureService?.cameraController;
  
  @override
  void onClose() {
    stopSession();
    super.onClose();
  }
}
