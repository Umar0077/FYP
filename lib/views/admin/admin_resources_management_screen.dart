import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/admin/admin_controller.dart';
import '../widgets/GlassCard.dart';

class AdminResourcesManagementScreen extends StatelessWidget {
  const AdminResourcesManagementScreen({super.key});

  Future<void> _showAddDialog(BuildContext context, AdminController controller) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final urlController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Resource'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description')),
                TextField(controller: urlController, decoration: const InputDecoration(labelText: 'URL')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;
                await controller.createResource(
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                  url: urlController.text.trim(),
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
      appBar: AppBar(title: const Text('Resources Management')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, controller),
        child: const Icon(Icons.add),
      ),
      body: Obx(
        () {
          if (controller.resources.isEmpty) {
            return const Center(child: Text('No resources found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.resources.length,
            itemBuilder: (context, index) {
              final item = controller.resources[index];
              return GlassCard(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(item.title),
                  subtitle: Text('status: ${item.isVisible ? 'active' : 'hidden'}'),
                  leading: const Icon(Icons.menu_book),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: item.isVisible,
                        onChanged: (value) => controller.setResourceVisibility(item.id, value),
                      ),
                      IconButton(
                        onPressed: () => controller.removeResource(item.id),
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
