import 'dart:developer' as developer;
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/constants/app_constants.dart';

/// Remote data source for Gemini API operations
class GeminiRemoteDatasource {
  /// Create Gemini model with specified configuration
  GenerativeModel _createModel(
    String apiKey,
    String modelId, {
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
    String? responseMimeType,
  }) {
    // Validate and sanitize model ID
    final sanitizedModelId = modelId.trim().isEmpty 
        ? AppConstants.defaultModelId 
        : modelId.trim();

    developer.log(
      'Creating model: $sanitizedModelId',
      name: 'GeminiDatasource.createModel',
    );

    return GenerativeModel(
      model: sanitizedModelId,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: temperature,
        maxOutputTokens: maxTokens,
        responseMimeType: responseMimeType,
      ),
      systemInstruction: systemPrompt != null 
        ? Content.text(systemPrompt) 
        : null,
    );
  }

  /// Send message to Gemini with optional fallback
  Future<String> sendMessage(
    String apiKey,
    String message, {
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
    String? modelId,
    bool enableFallback = true,
  }) async {
    final primaryModelId = modelId?.trim().isEmpty ?? true 
        ? AppConstants.defaultModelId 
        : modelId!.trim();

    developer.log(
      'Sending message to Gemini (model: $primaryModelId, fallback: $enableFallback)',
      name: 'GeminiDatasource.sendMessage',
    );

    try {
      // Try primary model
      final model = _createModel(
        apiKey,
        primaryModelId,
        systemPrompt: systemPrompt,
        temperature: temperature,
        maxTokens: maxTokens,
      );

      final response = await model.generateContent([
        Content.text(message)
      ]).timeout(
        Duration(seconds: AppConstants.requestTimeoutSeconds),
      );

      final text = response.text?.trim() ?? '';
      if (text.isEmpty) {
        throw Exception('Empty response from Gemini');
      }

      developer.log(
        'Received response from primary model',
        name: 'GeminiDatasource.sendMessage',
      );

      return text;
    } catch (e) {
      developer.log(
        'Primary model failed: $e',
        name: 'GeminiDatasource.sendMessage',
        error: e,
        level: 900,
      );

      // Retry with fallback if enabled and error suggests model issue
      if (enableFallback && _isModelError(e)) {
        developer.log(
          'Retrying with fallback model: ${AppConstants.defaultFallbackModelId}',
          name: 'GeminiDatasource.sendMessage',
        );

        try {
          final fallbackModel = _createModel(
            apiKey,
            AppConstants.defaultFallbackModelId,
            systemPrompt: systemPrompt,
            temperature: temperature,
            maxTokens: maxTokens,
          );

          final response = await fallbackModel.generateContent([
            Content.text(message)
          ]).timeout(
            Duration(seconds: AppConstants.requestTimeoutSeconds),
          );

          final text = response.text?.trim() ?? '';
          if (text.isEmpty) {
            throw Exception('Empty response from fallback model');
          }

          developer.log(
            'Received response from fallback model',
            name: 'GeminiDatasource.sendMessage',
          );

          return text;
        } catch (fallbackError) {
          developer.log(
            'Fallback model also failed: $fallbackError',
            name: 'GeminiDatasource.sendMessage',
            error: fallbackError,
            level: 1000,
          );
          rethrow;
        }
      }

      rethrow;
    }
  }

  /// Generate JSON output with schema
  Future<Map<String, dynamic>> generateJson(
    String apiKey,
    String message,
    Map<String, dynamic> schema, {
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
    String? modelId,
    bool enableFallback = true,
  }) async {
    final primaryModelId = modelId?.trim().isEmpty ?? true 
        ? AppConstants.defaultModelId 
        : modelId!.trim();

    developer.log(
      'Generating JSON with schema (model: $primaryModelId)',
      name: 'GeminiDatasource.generateJson',
    );

    final promptWithSchema = '''
$message

Please respond in JSON format following this schema:
${schema.toString()}
''';

    try {
      // Try primary model
      final model = _createModel(
        apiKey,
        primaryModelId,
        systemPrompt: systemPrompt,
        temperature: temperature,
        maxTokens: maxTokens,
        responseMimeType: 'application/json',
      );

      final response = await model.generateContent([
        Content.text(promptWithSchema)
      ]).timeout(
        Duration(seconds: AppConstants.requestTimeoutSeconds),
      );

      final text = response.text?.trim() ?? '';
      if (text.isEmpty) {
        throw Exception('Empty response from Gemini');
      }

      developer.log(
        'Received JSON response from primary model',
        name: 'GeminiDatasource.generateJson',
      );

      // Parse JSON
      final jsonResponse = Map<String, dynamic>.from(
        Uri.splitQueryString(text.replaceAll('\n', '').replaceAll(' ', '')),
      );

      return jsonResponse;
    } catch (e) {
      developer.log(
        'Primary model failed for JSON: $e',
        name: 'GeminiDatasource.generateJson',
        error: e,
        level: 900,
      );

      // Retry with fallback if enabled
      if (enableFallback && _isModelError(e)) {
        developer.log(
          'Retrying JSON with fallback model',
          name: 'GeminiDatasource.generateJson',
        );

        try {
          final fallbackModel = _createModel(
            apiKey,
            AppConstants.defaultFallbackModelId,
            systemPrompt: systemPrompt,
            temperature: temperature,
            maxTokens: maxTokens,
            responseMimeType: 'application/json',
          );

          final response = await fallbackModel.generateContent([
            Content.text(promptWithSchema)
          ]).timeout(
            Duration(seconds: AppConstants.requestTimeoutSeconds),
          );

          final text = response.text?.trim() ?? '';
          if (text.isEmpty) {
            throw Exception('Empty response from fallback model');
          }

          final jsonResponse = Map<String, dynamic>.from(
            Uri.splitQueryString(text.replaceAll('\n', '').replaceAll(' ', '')),
          );

          return jsonResponse;
        } catch (fallbackError) {
          developer.log(
            'Fallback model also failed for JSON: $fallbackError',
            name: 'GeminiDatasource.generateJson',
            error: fallbackError,
            level: 1000,
          );
          rethrow;
        }
      }

      rethrow;
    }
  }

  /// Check if error is model-related (not found, unavailable, etc.)
  bool _isModelError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('model') ||
           errorString.contains('not found') ||
           errorString.contains('unavailable') ||
           errorString.contains('invalid');
  }
}
