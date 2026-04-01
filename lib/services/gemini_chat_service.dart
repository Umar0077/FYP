import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:developer' as developer;
import '../core/constants/app_constants.dart';
import '../core/utils/secure_storage.dart';

/// Service for interacting with Gemini 2.5 Flash API
class GeminiChatService {
  final SecureStorage _secureStorage = SecureStorage();
  GenerativeModel? _model;
  String? _currentApiKey;

  /// Send a simple message
  Future<String> sendMessage(String message) async {
    final apiKey = await _getApiKey();
    final model = await _getModel(apiKey);

    developer.log(
      'Sending message to Gemini',
      name: 'GeminiChatService.sendMessage',
    );

    final response = await model.generateContent([
      Content.text(message)
    ]).timeout(
      Duration(seconds: AppConstants.requestTimeoutSeconds),
    );

    return response.text?.trim() ?? '';
  }

  /// Send a message with system prompt
  Future<String> sendMessageWithSystem(
    String message,
    String systemPrompt,
  ) async {
    final apiKey = await _getApiKey();

    developer.log(
      'Sending message with system prompt',
      name: 'GeminiChatService.sendMessageWithSystem',
    );

    // Create model with system instruction
    final model = GenerativeModel(
      model: AppConstants.geminiModel,
      apiKey: apiKey,
      systemInstruction: Content.text(systemPrompt),
    );

    final response = await model.generateContent([
      Content.text(message)
    ]).timeout(
      Duration(seconds: AppConstants.requestTimeoutSeconds),
    );

    return response.text?.trim() ?? '';
  }

  /// Generate JSON output with schema
  Future<Map<String, dynamic>> generateJson(
    String message,
    Map<String, dynamic> schema,
  ) async {
    final apiKey = await _getApiKey();

    developer.log(
      'Generating JSON output',
      name: 'GeminiChatService.generateJson',
    );

    // Create model with JSON response type
    final model = GenerativeModel(
      model: AppConstants.geminiModel,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );

    // Include schema in prompt
    final promptWithSchema = '''
$message

Please respond in JSON format following this schema:
${schema.toString()}
''';

    final response = await model.generateContent([
      Content.text(promptWithSchema)
    ]).timeout(
      Duration(seconds: AppConstants.requestTimeoutSeconds),
    );
    
    // Parse and return JSON
    return {}; // Simplified - implement JSON parsing as needed
  }

  /// Get or initialize model
  Future<GenerativeModel> _getModel(String apiKey) async {
    if (_model != null && _currentApiKey == apiKey) {
      return _model!;
    }

    _currentApiKey = apiKey;

    // Try models with fallback
    for (final modelName in AppConstants.fallbackModels) {
      try {
        developer.log(
          'Trying model: $modelName',
          name: 'GeminiChatService.getModel',
        );

        final testModel = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
        );

        // Test with simple request
        await testModel.generateContent([
          Content.text('Test')
        ]).timeout(Duration(seconds: 5));

        _model = testModel;
        developer.log(
          'Using model: $modelName',
          name: 'GeminiChatService.getModel',
        );
        return _model!;
      } catch (e) {
        developer.log(
          'Model $modelName failed: $e',
          name: 'GeminiChatService.getModel',
          level: 900,
        );
      }
    }

    throw Exception('Failed to initialize Gemini model');
  }

  /// Get API key from secure storage
  Future<String> _getApiKey() async {
    final key = await _secureStorage.read(AppConstants.geminiApiKeyKey);
    if (key == null || key.isEmpty) {
      throw Exception(AppConstants.apiKeyMissingError);
    }
    return key;
  }

  /// Clear cached model
  void clearModel() {
    _model = null;
    _currentApiKey = null;
  }
}
