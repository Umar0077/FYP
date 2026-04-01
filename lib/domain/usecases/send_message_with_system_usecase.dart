import '../entities/message.dart';
import '../entities/chat_settings.dart';
import '../repositories/gemini_repository.dart';

/// Use case for sending a message with custom system prompt
class SendMessageWithSystemUseCase {
  final GeminiRepository repository;

  SendMessageWithSystemUseCase(this.repository);

  Future<Message> call(
    String message,
    String systemPrompt,
    ChatSettings settings,
  ) async {
    if (message.trim().isEmpty) {
      throw Exception('Message cannot be empty');
    }

    if (systemPrompt.trim().isEmpty) {
      throw Exception('System prompt cannot be empty');
    }

    return await repository.sendMessageWithSystem(
      message,
      systemPrompt,
      settings,
    );
  }
}
