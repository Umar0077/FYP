import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _toNullableDateTime(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

class SupportMessageModel {
  final String messageId;
  final String senderId;
  final String senderRole;
  final String text;
  final DateTime? createdAt;
  final bool isRead;
  final DateTime? readAt;

  const SupportMessageModel({
    required this.messageId,
    required this.senderId,
    required this.senderRole,
    required this.text,
    this.createdAt,
    required this.isRead,
    this.readAt,
  });

  bool get isUserMessage => senderRole == 'user';

  bool get isAdminMessage => senderRole == 'admin';

  factory SupportMessageModel.fromMap(Map<String, dynamic> map, {required String fallbackMessageId}) {
    return SupportMessageModel(
      messageId: map['messageId']?.toString() ?? fallbackMessageId,
      senderId: map['senderId']?.toString() ?? '',
      senderRole: map['senderRole']?.toString() ?? 'user',
      text: map['text']?.toString() ?? '',
      createdAt: _toNullableDateTime(map['createdAt']),
      isRead: map['isRead'] == true,
      readAt: _toNullableDateTime(map['readAt']),
    );
  }

  factory SupportMessageModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? <String, dynamic>{};
    return SupportMessageModel.fromMap(map, fallbackMessageId: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'senderRole': senderRole,
      'text': text,
      'createdAt': createdAt,
      'isRead': isRead,
      'readAt': readAt,
    };
  }
}
