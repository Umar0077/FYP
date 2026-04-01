import '../entities/message.dart';
import '../entities/chat_settings.dart';
import '../repositories/gemini_repository.dart';

/// Use case for sending a simple message
class SendMessageUseCase {
  final GeminiRepository repository;

  SendMessageUseCase(this.repository);

  Future<Message> call(String message, ChatSettings settings) async {
    if (message.trim().isEmpty) {
      throw Exception('Message cannot be empty');
    }

    return await repository.sendMessage(message, settings);
  }
}
