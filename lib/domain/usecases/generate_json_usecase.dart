import '../entities/chat_settings.dart';
import '../repositories/gemini_repository.dart';

/// Use case for generating JSON output with schema
class GenerateJsonUseCase {
  final GeminiRepository repository;

  GenerateJsonUseCase(this.repository);

  Future<Map<String, dynamic>> call(
    String message,
    Map<String, dynamic> schema,
    ChatSettings settings,
  ) async {
    if (message.trim().isEmpty) {
      throw Exception('Message cannot be empty');
    }

    if (schema.isEmpty) {
      throw Exception('Schema cannot be empty');
    }

    return await repository.generateJson(message, schema, settings);
  }
}
