import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../models/support/support_chat_model.dart';
import '../../models/support/support_message_model.dart';
import '../../services/support/support_chat_service.dart';
import '../widgets/AppScaffold.dart';

class AdminSupportChatDetailScreen extends StatefulWidget {
  const AdminSupportChatDetailScreen({super.key});

  @override
  State<AdminSupportChatDetailScreen> createState() =>
      _AdminSupportChatDetailScreenState();
}

class _AdminSupportChatDetailScreenState
    extends State<AdminSupportChatDetailScreen> {
  final SupportChatService _supportChatService = SupportChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DateFormat _timeFormat = DateFormat('h:mm a');

  SupportChatModel? _chat;
  bool _isSending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _chat = Get.arguments as SupportChatModel?;
    if (_chat == null) {
      _error = 'Support chat not found.';
    } else {
      _supportChatService.markMessagesAsReadForAdmin(chatId: _chat!.chatId);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_chat == null || _isSending) return;

    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    try {
      await _supportChatService.sendAdminMessage(chatId: _chat!.chatId, text: text);
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send reply: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _bubble(SupportMessageModel message, bool isDark) {
    final isAdminMessage = message.isAdminMessage;
    final bubbleColor = isAdminMessage
        ? (isDark ? const Color(0xFF1B215E) : const Color(0xFFDCE3FF))
        : (isDark ? const Color(0xFF0A1733) : const Color(0xFFF1F3FC));
    final textColor = isDark ? Colors.white : const Color(0xFF0A0F2E);

    return Align(
      alignment: isAdminMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 310),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: isAdminMessage
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(message.text, style: TextStyle(color: textColor)),
              const SizedBox(height: 4),
              Text(
                message.createdAt != null
                    ? _timeFormat.format(message.createdAt!)
                    : 'Sending...',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white70 : const Color(0xFF5D6691),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBgColor = isDark ? const Color(0xFF0B0F4E) : const Color(0xFFF2F4FF);
    final inputFieldColor = isDark ? const Color(0xFF0A0F2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF27308A) : const Color(0xFFD6DBFF);
    final iconBgColor = isDark ? Colors.white10 : const Color(0xFFE8EBF8);
    final iconColor = isDark ? const Color(0xFF0A0F2E) : const Color(0xFF00002E);
    final inputHintColor = isDark ? Colors.white54 : const Color(0xFF7C86B2);

    final chat = _chat;
    if (_error != null || chat == null) {
      return AppScaffold(
        appBarTitle: 'Support Chat',
        body: Center(child: Text(_error ?? 'Unknown error')),
      );
    }

    return AppScaffold(
      appBarTitle: '${chat.userName} (${chat.userId})',
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<SupportMessageModel>>(
                stream: _supportChatService.streamAdminChatMessages(chatId: chat.chatId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Failed to load messages: ${snapshot.error}'));
                  }

                  final messages = snapshot.data ?? <SupportMessageModel>[];
                  if (messages.isNotEmpty) {
                    _supportChatService.markMessagesAsReadForAdmin(chatId: chat.chatId);
                    _scrollToBottom();
                  }

                  if (messages.isEmpty) {
                    return const Center(child: Text('No messages yet.'));
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      MediaQuery.of(context).viewInsets.bottom + 96,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (_, index) => _bubble(messages[index], isDark),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                color: inputBgColor,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: inputFieldColor,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: borderColor),
                        ),
                        child: TextField(
                          controller: _messageController,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration.collapsed(
                            hintText: 'Reply to user...',
                            hintStyle: TextStyle(color: inputHintColor),
                          ),
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
                      child: IconButton(
                        onPressed: _isSending ? null : _sendMessage,
                        icon: _isSending
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: iconColor,
                                ),
                              )
                            : Icon(Icons.send, color: iconColor, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
