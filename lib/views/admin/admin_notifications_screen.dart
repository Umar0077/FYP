import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/admin/admin_controller.dart';
import '../widgets/GlassCard.dart';

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});

  Future<void> _showCreateDialog(BuildContext context, AdminController controller) async {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    final audience = 'all'.obs;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Create Notification'),
          content: Obx(
            () => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                  const SizedBox(height: 8),
                  TextField(controller: messageController, maxLines: 3, decoration: const InputDecoration(labelText: 'Message')),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: audience.value,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Users')),
                      DropdownMenuItem(value: 'active', child: Text('Active Users')),
                    ],
                    onChanged: (value) {
                      if (value != null) audience.value = value;
                    },
                    decoration: const InputDecoration(labelText: 'Audience'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty || messageController.text.trim().isEmpty) {
                  return;
                }
                await controller.sendNotification(
                  title: titleController.text.trim(),
                  message: messageController.text.trim(),
                  audience: audience.value,
                );
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = Get.find<AdminController>();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF00002E) : Colors.white,
      appBar: AppBar(title: const Text('Notifications')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Create Notification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  const TextField(decoration: InputDecoration(labelText: 'Title')),
                  const SizedBox(height: 8),
                  const TextField(decoration: InputDecoration(labelText: 'Message'), maxLines: 3),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Users')),
                      DropdownMenuItem(value: 'active', child: Text('Active Users')),
                    ],
                    onChanged: (_) {},
                    decoration: const InputDecoration(labelText: 'Audience'),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _showCreateDialog(context, controller),
                      child: const Text('Send'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(
                () => ListView.builder(
                  itemCount: controller.notifications.length,
                  itemBuilder: (context, index) {
                    final item = controller.notifications[index];
                    return GlassCard(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.notifications_active),
                        title: Text(item.title),
                        subtitle: Text('status: ${item.status} • audience: ${item.audience}'),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
