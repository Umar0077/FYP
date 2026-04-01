import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/admin/admin_controller.dart';
import '../widgets/GlassCard.dart';

class AdminSupportScreen extends StatelessWidget {
  const AdminSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = Get.find<AdminController>();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF00002E) : Colors.white,
      appBar: AppBar(title: const Text('Support')),
      body: Obx(
        () {
          if (controller.supportTickets.isEmpty) {
            return const Center(child: Text('No support tickets found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.supportTickets.length,
            itemBuilder: (context, index) {
              final ticket = controller.supportTickets[index];
              final bool resolved = ticket.status.toLowerCase() == 'resolved';
              return GlassCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(resolved ? Icons.check_circle : Icons.report, color: resolved ? Colors.green : Colors.orange),
                  title: Text(ticket.subject),
                  subtitle: Text(ticket.message.isEmpty ? 'No details provided' : ticket.message),
                  trailing: Chip(label: Text(resolved ? 'Resolved' : 'Pending')),
                  onTap: () {
                    final replyController = TextEditingController();
                showModalBottomSheet<void>(
                  context: context,
                  builder: (context) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Reply to Support Ticket', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 10),
                          TextField(
                            controller: replyController,
                            maxLines: 4,
                            decoration: const InputDecoration(hintText: 'Type your response...'),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                await controller.resolveSupportTicket(
                                  ticketId: ticket.id,
                                  reply: replyController.text.trim(),
                                );
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                              child: const Text('Send Reply'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
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
