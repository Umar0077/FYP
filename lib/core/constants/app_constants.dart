/// Application-wide constants
class AppConstants {
  // Secure storage keys
  static const String geminiApiKeyKey = 'gemini_api_key';
  static const String systemPromptKey = 'system_prompt';
  static const String temperatureKey = 'temperature';
  static const String maxTokensKey = 'max_tokens';
  static const String modelIdKey = 'model_id';
  static const String enableFallbackKey = 'enable_fallback';

  // Default settings
  static const String defaultSystemPrompt = 'You are a helpful AI assistant.';
  static const double defaultTemperature = 0.7;
  static const int defaultMaxTokens = 2048;
  static const String defaultModelId = 'gemini-2.5-flash-lite';
  static const String defaultFallbackModelId = 'gemini-2.5-flash-lite';
  static const bool defaultEnableFallback = false;

  // Gemini model
  static const String geminiModel = 'gemini-2.5-flash-lite';
  
  // Fallback models (deprecated - now using configurable model ID)
  static const List<String> fallbackModels = [
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
  ];

  // Timeouts
  static const int requestTimeoutSeconds = 30;

  // Interview module
  static const int interviewQuestionDurationSeconds = 60;
  static const int interviewSpeechListenForSeconds = 55;
  static const int interviewSpeechPauseForSeconds = 3;

  // Error messages
  static const String apiKeyMissingError = 'API key not configured. Please add it in Settings.';
  static const String networkError = 'Network error. Please check your connection.';
  static const String timeoutError = 'Request timed out. Please try again.';
  static const String genericError = 'An error occurred. Please try again.';
}
