import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/admin/admin_controller.dart';
import '../widgets/GlassCard.dart';

class AdminJobSuggestionsManagementScreen extends StatelessWidget {
  const AdminJobSuggestionsManagementScreen({super.key});

  Future<void> _showAddDialog(BuildContext context, AdminController controller) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Job Suggestion'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;
                await controller.createJobSuggestion(
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                );
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Save'),
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
      appBar: AppBar(title: const Text('Job Suggestions')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, controller),
        child: const Icon(Icons.add),
      ),
      body: Obx(
        () {
          if (controller.jobSuggestions.isEmpty) {
            return const Center(child: Text('No job suggestions found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.jobSuggestions.length,
            itemBuilder: (context, index) {
              final item = controller.jobSuggestions[index];
              return GlassCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(item.title),
                  subtitle: Text('status: ${item.published ? 'published' : 'draft'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: item.published,
                        onChanged: (value) => controller.setJobPublished(item.id, value),
                      ),
                      IconButton(
                        onPressed: () => controller.removeJobSuggestion(item.id),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
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
