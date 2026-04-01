/// Domain entity for chat settings
class ChatSettings {
  final String systemPrompt;
  final double temperature;
  final int maxTokens;
  final String modelId;
  final bool enableFallback;

  ChatSettings({
    required this.systemPrompt,
    required this.temperature,
    required this.maxTokens,
    required this.modelId,
    required this.enableFallback,
  });

  ChatSettings copyWith({
    String? systemPrompt,
    double? temperature,
    int? maxTokens,
    String? modelId,
    bool? enableFallback,
  }) {
    return ChatSettings(
      systemPrompt: systemPrompt ?? this.systemPrompt,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      modelId: modelId ?? this.modelId,
      enableFallback: enableFallback ?? this.enableFallback,
    );
  }
}
