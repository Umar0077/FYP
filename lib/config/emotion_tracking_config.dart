/// Configuration for emotion tracking API and behavior
class EmotionTrackingConfig {
  /// Base URL of the FastAPI backend
  /// 
  /// IMPORTANT: Use actual IP address or domain name for the CLIENT.
  /// - 0.0.0.0 is ONLY for server binding (uvicorn --host 0.0.0.0)
  /// - Clients cannot connect to 0.0.0.0, they need a real IP or domain
  /// 
  /// For local development:
  /// - Android Emulator: 'http://10.0.2.2:8000' (maps to host machine)
  /// - iOS Simulator: 'http://localhost:8000' or 'http://127.0.0.1:8000'
  /// - Real device on WiFi: 'http://192.168.x.x:8000' (use your PC's LAN IP)
  ///   
  /// To find your PC's LAN IP:
  /// - Windows: Open CMD and run 'ipconfig', look for IPv4 Address
  /// - Mac/Linux: Run 'ifconfig' or 'ip addr show', look for inet address
  /// 
  /// For production:
  /// - Use full domain: 'https://your-domain.com' (HTTPS recommended)
  static const String baseUrl = 'http://13.48.85.142:8000';
  
  /// Optional API key (set if backend requires x-api-key header)
  /// Leave null if backend API_KEY env var is not set
  static const String? apiKey = null;
  
  /// Frame capture interval in milliseconds
  /// Recommended: 900ms for stable, reliable capture
  /// Too fast may cause performance issues, too slow may miss emotions
  static const int frameIntervalMs = 900;
  
  /// Health check timeout in seconds
  static const int healthCheckTimeoutSeconds = 3;
  
  /// Maximum retry attempts for failed network requests
  static const int maxRetries = 3;
  
  /// Retry backoff delay in milliseconds
  static const int retryBackoffMs = 500;
  
  /// Request timeout in seconds
  static const int requestTimeoutSeconds = 10;
  
  /// Whether to show camera preview (true) or hide it (false)
  static const bool showCameraPreview = true;
  
  /// Camera preview size when visible (ignored if showCameraPreview = false)
  static const double previewWidth = 120.0;
  static const double previewHeight = 160.0;
  
  /// Maximum number of frames to include in Gemini analysis
  /// (top N frames per emotion)
  static const int maxFramesPerEmotionForGemini = 2;
  
  /// Whether to send frames as base64 images to Gemini
  /// Set to false if Gemini model doesn't support images or to reduce token usage
  static const bool sendFramesToGemini = false;
}
