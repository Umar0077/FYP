import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/support/support_chat_model.dart';
import '../../models/support/support_message_model.dart';
import '../../repositories/support/support_chat_repository.dart';

class SupportChatService {
  SupportChatService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    SupportChatRepository? repository,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _repository = repository ??
            SupportChatRepository(firestore: firestore ?? FirebaseFirestore.instance);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final SupportChatRepository _repository;

  Future<SupportChatModel> getOrCreateUserSupportChat() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be signed in to start support chat');
    }

    String userName = (user.displayName ?? '').trim();
    String? userEmail = user.email?.trim();

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final docName = userData?['name']?.toString().trim() ?? '';
      final docEmail = userData?['email']?.toString().trim();

      if (docName.isNotEmpty) {
        userName = docName;
      }
      if (docEmail != null && docEmail.isNotEmpty) {
        userEmail = docEmail;
      }
    } catch (_) {
      // Fallback to auth data only.
    }

    if (userName.isEmpty) {
      userName = 'Unknown User';
    }

    return _repository.getOrCreateUserSupportChat(
      userId: user.uid,
      userName: userName,
      userEmail: userEmail,
    );
  }

  Stream<List<SupportMessageModel>> streamUserSupportMessages({
    required String chatId,
  }) {
    return _repository.streamSupportMessages(chatId);
  }

  Stream<List<SupportChatModel>> streamAdminSupportChats() {
    return _repository.streamSupportChatsForAdmin();
  }

  Stream<List<SupportMessageModel>> streamAdminChatMessages({
    required String chatId,
  }) {
    return _repository.streamSupportMessages(chatId);
  }

  Stream<SupportChatModel?> streamSupportChatById({required String chatId}) {
    return _repository.streamSupportChatById(chatId);
  }

  Future<void> sendUserMessage({
    required String chatId,
    required String text,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be signed in to send support message');
    }

    await _repository.sendMessage(
      chatId: chatId,
      senderId: user.uid,
      senderRole: 'user',
      text: text,
    );
  }

  Future<void> sendAdminMessage({
    required String chatId,
    required String text,
  }) async {
    final admin = _auth.currentUser;
    if (admin == null) {
      throw Exception('Admin must be signed in to send support reply');
    }

    await _repository.sendMessage(
      chatId: chatId,
      senderId: admin.uid,
      senderRole: 'admin',
      text: text,
    );
  }

  Future<void> markMessagesAsReadForUser({
    required String chatId,
  }) async {
    await _repository.markMessagesAsReadForUser(chatId: chatId);
  }

  Future<void> markMessagesAsReadForAdmin({
    required String chatId,
  }) async {
    await _repository.markMessagesAsReadForAdmin(chatId: chatId);
  }
}
