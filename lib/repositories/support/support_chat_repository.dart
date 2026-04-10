import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/support/support_chat_model.dart';
import '../../models/support/support_message_model.dart';

class SupportChatRepository {
  SupportChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _supportChats =>
      _firestore.collection('support_chats');

  Future<SupportChatModel> getOrCreateUserSupportChat({
    required String userId,
    required String userName,
    String? userEmail,
  }) async {
    final chatRef = _supportChats.doc(userId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(chatRef);
      if (snapshot.exists) {
        return;
      }

      transaction.set(chatRef, {
        'chatId': userId,
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': null,
        'lastSenderRole': '',
        'adminUnreadCount': 0,
        'userUnreadCount': 0,
        'isOpen': true,
      });
    });

    final chatDoc = await chatRef.get();
    return SupportChatModel.fromDocument(chatDoc);
  }

  Stream<SupportChatModel?> streamSupportChatById(String chatId) {
    return _supportChats.doc(chatId).snapshots().map((doc) {
      if (!doc.exists) {
        return null;
      }
      return SupportChatModel.fromDocument(doc);
    });
  }

  Stream<List<SupportMessageModel>> streamSupportMessages(String chatId) {
    return _supportChats
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(SupportMessageModel.fromDocument).toList());
  }

  Stream<List<SupportChatModel>> streamSupportChatsForAdmin() {
    return _supportChats
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(SupportChatModel.fromDocument).toList());
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderRole,
    required String text,
  }) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    final chatRef = _supportChats.doc(chatId);
    final messageRef = chatRef.collection('messages').doc();

    await _firestore.runTransaction((transaction) async {
      final chatSnapshot = await transaction.get(chatRef);

      if (!chatSnapshot.exists) {
        throw Exception('Support chat not found for chatId: $chatId');
      }

      transaction.set(messageRef, {
        'messageId': messageRef.id,
        'senderId': senderId,
        'senderRole': senderRole,
        'text': trimmedText,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'readAt': null,
      });

      final update = <String, dynamic>{
        'lastMessage': trimmedText,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastSenderRole': senderRole,
        'isOpen': true,
      };

      if (senderRole == 'user') {
        update['adminUnreadCount'] = FieldValue.increment(1);
      } else {
        update['userUnreadCount'] = FieldValue.increment(1);
      }

      transaction.update(chatRef, update);
    });
  }

  Future<void> markMessagesAsReadForUser({
    required String chatId,
  }) async {
    final chatRef = _supportChats.doc(chatId);
    final unreadSnapshot = await chatRef
        .collection('messages')
        .where('senderRole', isEqualTo: 'admin')
        .where('isRead', isEqualTo: false)
        .get();

    if (unreadSnapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();

    for (final doc in unreadSnapshot.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }

    batch.set(chatRef, {
      'userUnreadCount': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> markMessagesAsReadForAdmin({
    required String chatId,
  }) async {
    final chatRef = _supportChats.doc(chatId);
    final unreadSnapshot = await chatRef
        .collection('messages')
        .where('senderRole', isEqualTo: 'user')
        .where('isRead', isEqualTo: false)
        .get();

    if (unreadSnapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();

    for (final doc in unreadSnapshot.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }

    batch.set(chatRef, {
      'adminUnreadCount': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }
}
