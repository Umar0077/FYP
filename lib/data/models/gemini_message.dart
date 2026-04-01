import '../../domain/entities/message.dart';

/// Data model for messages (extends domain entity)
class GeminiMessage extends Message {
  GeminiMessage({
    required super.id,
    required super.content,
    required super.isUser,
    required super.timestamp,
  });

  factory GeminiMessage.fromEntity(Message message) {
    return GeminiMessage(
      id: message.id,
      content: message.content,
      isUser: message.isUser,
      timestamp: message.timestamp,
    );
  }

  Message toEntity() {
    return Message(
      id: id,
      content: content,
      isUser: isUser,
      timestamp: timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory GeminiMessage.fromJson(Map<String, dynamic> json) {
    return GeminiMessage(
      id: json['id'],
      content: json['content'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
