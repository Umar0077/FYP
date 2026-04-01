import '../entities/message.dart';
import '../entities/chat_settings.dart';

/// Abstract repository interface for Gemini operations
abstract class GeminiRepository {
  /// Send a message and get response
  Future<Message> sendMessage(String message, ChatSettings settings);

  /// Send a message with custom system prompt
  Future<Message> sendMessageWithSystem(
    String message,
    String systemPrompt,
    ChatSettings settings,
  );

  /// Generate JSON output with schema
  Future<Map<String, dynamic>> generateJson(
    String message,
    Map<String, dynamic> schema,
    ChatSettings settings,
  );

  /// Get chat settings
  Future<ChatSettings> getSettings();

  /// Save chat settings
  Future<void> saveSettings(ChatSettings settings);

  /// Get API key
  Future<String?> getApiKey();

  /// Save API key
  Future<void> saveApiKey(String apiKey);
}
