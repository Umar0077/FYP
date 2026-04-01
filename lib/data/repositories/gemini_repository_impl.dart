import '../../domain/entities/message.dart';
import '../../domain/entities/chat_settings.dart';
import '../../domain/repositories/gemini_repository.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/secure_storage.dart';
import '../datasources/gemini_remote_datasource.dart';
import '../models/gemini_message.dart';

/// Implementation of Gemini repository
class GeminiRepositoryImpl implements GeminiRepository {
  final GeminiRemoteDatasource _remoteDatasource;
  final SecureStorage _secureStorage;

  GeminiRepositoryImpl({
    required GeminiRemoteDatasource remoteDatasource,
    required SecureStorage secureStorage,
  })  : _remoteDatasource = remoteDatasource,
        _secureStorage = secureStorage;

  @override
  Future<Message> sendMessage(String message, ChatSettings settings) async {
    final apiKey = await getApiKey();
    if (apiKey == null) {
      throw Exception(AppConstants.apiKeyMissingError);
    }

    try {
      final response = await _remoteDatasource.sendMessage(
        apiKey,
        message,
        systemPrompt: settings.systemPrompt,
        temperature: settings.temperature,
        maxTokens: settings.maxTokens,
        modelId: settings.modelId,
        enableFallback: settings.enableFallback,
      );

      return GeminiMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      if (e.toString().contains('timeout')) {
        throw Exception(AppConstants.timeoutError);
      } else if (e.toString().contains('network')) {
        throw Exception(AppConstants.networkError);
      }
      rethrow;
    }
  }

  @override
  Future<Message> sendMessageWithSystem(
    String message,
    String systemPrompt,
    ChatSettings settings,
  ) async {
    final apiKey = await getApiKey();
    if (apiKey == null) {
      throw Exception(AppConstants.apiKeyMissingError);
    }

    try {
      final response = await _remoteDatasource.sendMessage(
        apiKey,
        message,
        systemPrompt: systemPrompt,
        temperature: settings.temperature,
        maxTokens: settings.maxTokens,
        modelId: settings.modelId,
        enableFallback: settings.enableFallback,
      );

      return GeminiMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      if (e.toString().contains('timeout')) {
        throw Exception(AppConstants.timeoutError);
      } else if (e.toString().contains('network')) {
        throw Exception(AppConstants.networkError);
      }
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> generateJson(
    String message,
    Map<String, dynamic> schema,
    ChatSettings settings,
  ) async {
    final apiKey = await getApiKey();
    if (apiKey == null) {
      throw Exception(AppConstants.apiKeyMissingError);
    }

    try {
      return await _remoteDatasource.generateJson(
        apiKey,
        message,
        schema,
        systemPrompt: settings.systemPrompt,
        temperature: settings.temperature,
        maxTokens: settings.maxTokens,
        modelId: settings.modelId,
        enableFallback: settings.enableFallback,
      );
    } catch (e) {
      if (e.toString().contains('timeout')) {
        throw Exception(AppConstants.timeoutError);
      } else if (e.toString().contains('network')) {
        throw Exception(AppConstants.networkError);
      }
      rethrow;
    }
  }

  @override
  Future<ChatSettings> getSettings() async {
    final systemPrompt = await _secureStorage.read(AppConstants.systemPromptKey);
    final temperatureStr = await _secureStorage.read(AppConstants.temperatureKey);
    final maxTokensStr = await _secureStorage.read(AppConstants.maxTokensKey);
    final modelId = await _secureStorage.read(AppConstants.modelIdKey);
    final enableFallbackStr = await _secureStorage.read(AppConstants.enableFallbackKey);

    return ChatSettings(
      systemPrompt: systemPrompt ?? AppConstants.defaultSystemPrompt,
      temperature: temperatureStr != null 
        ? double.parse(temperatureStr) 
        : AppConstants.defaultTemperature,
      maxTokens: maxTokensStr != null 
        ? int.parse(maxTokensStr) 
        : AppConstants.defaultMaxTokens,
      modelId: modelId ?? AppConstants.defaultModelId,
      enableFallback: enableFallbackStr != null 
        ? enableFallbackStr.toLowerCase() == 'true' 
        : AppConstants.defaultEnableFallback,
    );
  }

  @override
  Future<void> saveSettings(ChatSettings settings) async {
    await _secureStorage.write(
      AppConstants.systemPromptKey,
      settings.systemPrompt,
    );
    await _secureStorage.write(
      AppConstants.temperatureKey,
      settings.temperature.toString(),
    );
    await _secureStorage.write(
      AppConstants.maxTokensKey,
      settings.maxTokens.toString(),
    );
    await _secureStorage.write(
      AppConstants.modelIdKey,
      settings.modelId,
    );
    await _secureStorage.write(
      AppConstants.enableFallbackKey,
      settings.enableFallback.toString(),
    );
  }

  @override
  Future<String?> getApiKey() async {
    return await _secureStorage.read(AppConstants.geminiApiKeyKey);
  }

  @override
  Future<void> saveApiKey(String apiKey) async {
    await _secureStorage.write(AppConstants.geminiApiKeyKey, apiKey);
  }
}
