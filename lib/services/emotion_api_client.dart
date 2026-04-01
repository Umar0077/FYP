import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:developer' as developer;

double? _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

Map<String, dynamic>? _asStringDynamicMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), v));
  }
  return null;
}

List<dynamic>? _asList(dynamic value) {
  if (value is List<dynamic>) return value;
  if (value is List) return value.cast<dynamic>();
  return null;
}

/// Centralized API route paths
class EmotionApiRoutes {
  static const String startSessionPath = '/start_session';
  static const String predictFramePath = '/predict_frame';
  static const String stopSessionPath = '/stop_session';
  static const String healthPath = '/health';

  /// Build full URL from base URL and path, handling slashes correctly
  static String buildUrl(String baseUrl, String path) {
    final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final route = path.startsWith('/') ? path : '/$path';
    return '$base$route';
  }
}

/// Magic bytes constants for image validation
class ImageMagicBytes {
  static const List<int> jpegSignature = [0xFF, 0xD8, 0xFF];
  static const List<int> pngSignature = [0x89, 0x50, 0x4E];
  
  static String? detectImageType(List<int> bytes) {
    if (bytes.length < 3) return null;
    
    final first3 = bytes.sublist(0, 3);
    
    if (first3[0] == jpegSignature[0] && 
        first3[1] == jpegSignature[1] && 
        first3[2] == jpegSignature[2]) {
      return 'jpeg';
    }
    
    if (first3[0] == pngSignature[0] && 
        first3[1] == pngSignature[1] && 
        first3[2] == pngSignature[2]) {
      return 'png';
    }
    
    return null;
  }
  
  static String bytesToHex(List<int> bytes, int limit) {
    final count = bytes.length < limit ? bytes.length : limit;
    return bytes.sublist(0, count).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ').toUpperCase();
  }
}

/// Response models
class StartSessionResponse {
  final String sessionId;
  
  StartSessionResponse({required this.sessionId});
  
  factory StartSessionResponse.fromJson(Map<String, dynamic> json) {
    return StartSessionResponse(
      sessionId: json['session_id'] as String,
    );
  }
}

class PredictFrameResponse {
  final int? facesFound;
  final PredictFrameResult? topResult;
  final List<PredictFrameResult> results;
  final Map<String, int>? storedFrameUpdate;
  
  PredictFrameResponse({
    this.facesFound,
    this.topResult,
    required this.results,
    this.storedFrameUpdate,
  });

  String? get emotion => topResult?.emotion ?? (results.isNotEmpty ? results.first.emotion : null);
  double? get confidence => topResult?.confidence ?? (results.isNotEmpty ? results.first.confidence : null);
  
  factory PredictFrameResponse.fromJson(Map<String, dynamic> json) {
    final topResultMap = _asStringDynamicMap(json['top_result']);
    final resultsRaw = _asList(json['results']) ?? const <dynamic>[];

    final parsedResults = resultsRaw
        .map((item) => _asStringDynamicMap(item))
        .whereType<Map<String, dynamic>>()
        .map(PredictFrameResult.fromJson)
        .toList();

    final storedFrameRaw = _asStringDynamicMap(json['stored_frame_update']);
    final parsedStoredFrame = storedFrameRaw?.map(
      (key, value) => MapEntry(key, _asInt(value) ?? 0),
    );

    return PredictFrameResponse(
      facesFound: _asInt(json['faces_found']),
      topResult: topResultMap == null ? null : PredictFrameResult.fromJson(topResultMap),
      results: parsedResults,
      storedFrameUpdate: parsedStoredFrame,
    );
  }
}

class PredictFrameResult {
  final String? emotion;
  final double? confidence;
  final List<int>? bbox;

  PredictFrameResult({
    this.emotion,
    this.confidence,
    this.bbox,
  });

  factory PredictFrameResult.fromJson(Map<String, dynamic> json) {
    final bboxRaw = _asList(json['bbox']);
    final parsedBbox = bboxRaw?.map((e) => _asInt(e)).whereType<int>().toList();

    return PredictFrameResult(
      emotion: json['emotion']?.toString(),
      confidence: _asDouble(json['confidence']),
      bbox: parsedBbox,
    );
  }
}

class StopSessionResponse {
  final Map<String, dynamic> emotionReport;
  
  StopSessionResponse({required this.emotionReport});
  
  factory StopSessionResponse.fromJson(Map<String, dynamic> json) {
    return StopSessionResponse(
      emotionReport: json,
    );
  }
}

/// Client for FastAPI Emotion Detection Backend
class EmotionApiClient {
  final String baseUrl;
  final http.Client _httpClient;
  
  // Retry configuration
  static const int maxRetries = 2;
  static const Duration initialBackoff = Duration(milliseconds: 500);
  static const Duration predictTimeout = Duration(seconds: 10);
  
  EmotionApiClient({
    required this.baseUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  void _log(String scope, String message, {Object? error, int level = 800}) {
    developer.log(message, name: 'EmotionApiClient.$scope', error: error, level: level);
  }
  
  /// Health check
  Future<bool> checkHealth() async {
    try {
      final url = EmotionApiRoutes.buildUrl(baseUrl, EmotionApiRoutes.healthPath);
      _log('Health', 'Checking $url');
      
      final response = await _httpClient.get(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      _log('Health', 'Health check failed: $e', error: e, level: 1000);
      return false;
    }
  }
  
  /// Start new emotion detection session
  Future<StartSessionResponse> startSession() async {
    final url = EmotionApiRoutes.buildUrl(baseUrl, EmotionApiRoutes.startSessionPath);
    _log('StartSession', 'POST $url');
    
    final response = await _httpClient.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      _log('StartSession', 'Session started: ${data['session_id']}');
      return StartSessionResponse.fromJson(data);
    } else {
      throw Exception('Failed to start session: ${response.statusCode} ${response.body}');
    }
  }
  
  /// Upload frame for emotion prediction with validation and retry logic
  Future<PredictFrameResponse?> predictFrame({
    required String sessionId,
    required File imageFile,
  }) async {
    _log('PredictFrame', 'Capture start: path=${imageFile.path}');

    // Read file bytes
    final bytes = await imageFile.readAsBytes();
    final fileSize = bytes.length;
    
    // Log first 16 bytes for debugging
    final hex16 = ImageMagicBytes.bytesToHex(bytes, 16);
    final hex3 = ImageMagicBytes.bytesToHex(bytes, 3);
    _log('PredictFrame', 'Captured file size=$fileSize bytes, magic3=$hex3, first16=$hex16');
    
    // Validate magic bytes
    final imageType = ImageMagicBytes.detectImageType(bytes);
    if (imageType == null) {
      final error = 'Invalid image format. Magic bytes: $hex3 (expected FF D8 FF for JPEG or 89 50 4E for PNG)';
      _log('PredictFrame', error, error: error, level: 1000);
      throw InvalidImageFormatException(error);
    }
    
    final fileName = imageType == 'jpeg' ? 'frame.jpg' : 'frame.png';
    final contentType = imageType == 'jpeg' ? 'image/jpeg' : 'image/png';
    
    _log('PredictFrame', 'Validated image type=$imageType, name=$fileName, contentType=$contentType');
    
    // Retry logic
    int attempt = 0;
    Duration backoff = initialBackoff;
    
    while (attempt <= maxRetries) {
      try {
        final url = EmotionApiRoutes.buildUrl(baseUrl, EmotionApiRoutes.predictFramePath);
        _log('PredictFrame', 'Upload start: url=$url, session=$sessionId, attempt=${attempt + 1}');
        
        final request = http.MultipartRequest('POST', Uri.parse(url));
        
        // Add X-Client header for backend correlation
        request.headers['X-Client'] = 'flutter';
        
        // Add session_id as form field
        request.fields['session_id'] = sessionId;
        
        // Add image file with field name "frame"
        request.files.add(
          http.MultipartFile.fromBytes(
            'frame', // Field name must match FastAPI UploadFile parameter
            bytes,
            filename: fileName,
            contentType: MediaType.parse(contentType),
          ),
        );
        
        final streamedResponse = await request.send().timeout(predictTimeout);
        final response = await http.Response.fromStream(streamedResponse);

        _log('PredictFrame', 'Response status=${response.statusCode}');
        _log('PredictFrame', 'Response body=${response.body}');
        
        // Handle 404 as configuration error - don't retry
        if (response.statusCode == 404) {
          final error = 'Route not found (404): $url - Check backend configuration';
          _log('PredictFrame', error, error: error, level: 1000);
          throw RouteNotFoundException(url);
        }
        
        // Success
        if (response.statusCode == 200) {
          try {
            final decoded = json.decode(response.body);
            final data = _asStringDynamicMap(decoded);
            if (data == null) {
              _log('PredictFrame', 'JSON parse failed: expected object, got ${decoded.runtimeType}', level: 1000);
              return null;
            }

            final parsed = PredictFrameResponse.fromJson(data);
            _log(
              'PredictFrame',
              'JSON parse success: facesFound=${parsed.facesFound}, emotion=${parsed.emotion}, confidence=${parsed.confidence}',
            );
            return parsed;
          } catch (e) {
            _log('PredictFrame', 'JSON parse failure: $e', error: e, level: 1000);
            return null;
          }
        }
        
        // Retry on 5xx errors
        if (response.statusCode >= 500 && attempt < maxRetries) {
          _log('PredictFrame', 'Server error ${response.statusCode}, retrying after ${backoff.inMilliseconds}ms');
          await Future.delayed(backoff);
          backoff *= 2; // Exponential backoff
          attempt++;
          continue;
        }
        
        // Other errors - don't retry
        throw Exception('Predict failed: ${response.statusCode} ${response.body}');
        
      } on SocketException catch (e) {
        // Network error - retry
        if (attempt < maxRetries) {
          _log('PredictFrame', 'Network error, retrying after ${backoff.inMilliseconds}ms: $e');
          await Future.delayed(backoff);
          backoff *= 2;
          attempt++;
          continue;
        }
        throw Exception('Network error after $maxRetries retries: $e');
      } on http.ClientException catch (e) {
        // HTTP client error - retry
        if (attempt < maxRetries) {
          _log('PredictFrame', 'HTTP error, retrying after ${backoff.inMilliseconds}ms: $e');
          await Future.delayed(backoff);
          backoff *= 2;
          attempt++;
          continue;
        }
        throw Exception('HTTP error after $maxRetries retries: $e');
      }
    }
    
    return null;
  }
  
  /// Stop session and get emotion report
  Future<StopSessionResponse> stopSession(String sessionId) async {
    final url = EmotionApiRoutes.buildUrl(baseUrl, EmotionApiRoutes.stopSessionPath);
    _log('StopSession', 'POST $url session=$sessionId');
    
    final response = await _httpClient.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'session_id': sessionId}),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      _log('StopSession', 'Session stopped successfully');
      return StopSessionResponse.fromJson(data);
    } else {
      throw Exception('Failed to stop session: ${response.statusCode} ${response.body}');
    }
  }
  
  void dispose() {
    _httpClient.close();
  }
}

/// Custom exceptions
class InvalidImageFormatException implements Exception {
  final String message;
  InvalidImageFormatException(this.message);
  
  @override
  String toString() => message;
}

class RouteNotFoundException implements Exception {
  final String url;
  RouteNotFoundException(this.url);
  
  @override
  String toString() => 'Route not found: $url';
}
