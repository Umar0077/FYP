import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _toNullableDateTime(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

class SupportChatModel {
  final String chatId;
  final String userId;
  final String userName;
  final String? userEmail;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final String lastSenderRole;
  final int adminUnreadCount;
  final int userUnreadCount;
  final bool isOpen;

  const SupportChatModel({
    required this.chatId,
    required this.userId,
    required this.userName,
    this.userEmail,
    this.createdAt,
    this.updatedAt,
    required this.lastMessage,
    this.lastMessageTime,
    required this.lastSenderRole,
    required this.adminUnreadCount,
    required this.userUnreadCount,
    required this.isOpen,
  });

  factory SupportChatModel.fromMap(Map<String, dynamic> map, {required String fallbackChatId}) {
    return SupportChatModel(
      chatId: map['chatId']?.toString() ?? fallbackChatId,
      userId: map['userId']?.toString() ?? '',
      userName: (map['userName']?.toString().trim().isNotEmpty ?? false)
          ? map['userName'].toString().trim()
          : 'Unknown User',
      userEmail: map['userEmail']?.toString(),
      createdAt: _toNullableDateTime(map['createdAt']),
      updatedAt: _toNullableDateTime(map['updatedAt']),
      lastMessage: map['lastMessage']?.toString() ?? '',
      lastMessageTime: _toNullableDateTime(map['lastMessageTime']),
      lastSenderRole: map['lastSenderRole']?.toString() ?? '',
      adminUnreadCount: _toInt(map['adminUnreadCount']),
      userUnreadCount: _toInt(map['userUnreadCount']),
      isOpen: map['isOpen'] == false ? false : true,
    );
  }

  factory SupportChatModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? <String, dynamic>{};
    return SupportChatModel.fromMap(map, fallbackChatId: doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'lastSenderRole': lastSenderRole,
      'adminUnreadCount': adminUnreadCount,
      'userUnreadCount': userUnreadCount,
      'isOpen': isOpen,
    };
  }
}
