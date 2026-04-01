import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/admin/admin_controller.dart';
import '../widgets/GlassCard.dart';

class AdminActivityLogsScreen extends StatelessWidget {
  const AdminActivityLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = Get.find<AdminController>();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF00002E) : Colors.white,
      appBar: AppBar(title: const Text('Activity Logs')),
      body: Obx(
        () {
          if (controller.activityLogs.isEmpty) {
            return const Center(child: Text('No activity logs found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.activityLogs.length,
            itemBuilder: (context, index) {
              final item = controller.activityLogs[index];
              return GlassCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.history_edu, color: Colors.grey),
                  title: Text(item.action),
                  subtitle: Text(item.details),
                  trailing: Text(
                    DateFormat('MMM d, h:mm a').format(item.createdAt),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
