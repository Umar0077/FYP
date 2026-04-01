import '../../domain/entities/chat_settings.dart';

/// Data model for chat settings (extends domain entity)
class GeminiSettings extends ChatSettings {
  GeminiSettings({
    required super.systemPrompt,
    required super.temperature,
    required super.maxTokens,
    required super.modelId,
    required super.enableFallback,
  });

  factory GeminiSettings.fromEntity(ChatSettings settings) {
    return GeminiSettings(
      systemPrompt: settings.systemPrompt,
      temperature: settings.temperature,
      maxTokens: settings.maxTokens,
      modelId: settings.modelId,
      enableFallback: settings.enableFallback,
    );
  }

  ChatSettings toEntity() {
    return ChatSettings(
      systemPrompt: systemPrompt,
      temperature: temperature,
      maxTokens: maxTokens,
      modelId: modelId,
      enableFallback: enableFallback,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'systemPrompt': systemPrompt,
      'temperature': temperature,
      'maxTokens': maxTokens,
      'modelId': modelId,
      'enableFallback': enableFallback,
    };
  }

  factory GeminiSettings.fromJson(Map<String, dynamic> json) {
    return GeminiSettings(
      systemPrompt: json['systemPrompt'],
      temperature: json['temperature'],
      maxTokens: json['maxTokens'],
      modelId: json['modelId'] ?? 'gemini-2.5-flash',
      enableFallback: json['enableFallback'] ?? true,
    );
  }
}
