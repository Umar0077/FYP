import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../models/support/support_chat_model.dart';
import '../../services/support/support_chat_service.dart';
import '../widgets/GlassCard.dart';

class AdminSupportScreen extends StatelessWidget {
  const AdminSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final service = SupportChatService();
    final DateFormat timeFormat = DateFormat('MMM d, h:mm a');

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF00002E) : Colors.white,
      appBar: AppBar(title: const Text('Support Chats')),
      body: StreamBuilder<List<SupportChatModel>>(
        stream: service.streamAdminSupportChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Failed to load chats: ${snapshot.error}'));
          }

          final chats = snapshot.data ?? <SupportChatModel>[];
          if (chats.isEmpty) {
            return const Center(child: Text('No support chats yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final subtitleMessage = chat.lastMessage.isNotEmpty
                  ? chat.lastMessage
                  : 'No messages yet';
              final timeText = chat.lastMessageTime != null
                  ? timeFormat.format(chat.lastMessageTime!)
                  : '';

              return GlassCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    child: Text(
                      chat.userName.isNotEmpty
                          ? chat.userName.substring(0, 1).toUpperCase()
                          : 'U',
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.userName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (timeText.isNotEmpty)
                        Text(
                          timeText,
                          style: const TextStyle(fontSize: 11),
                        ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('UID: ${chat.userId}', style: const TextStyle(fontSize: 11)),
                        const SizedBox(height: 4),
                        Text(
                          subtitleMessage,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  trailing: chat.adminUnreadCount > 0
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${chat.adminUnreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: () {
                    Get.toNamed('/admin/support/chat', arguments: chat);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
