import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/admin/admin_controller.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminController>();
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF00002E) : Colors.white,
      appBar: AppBar(title: const Text('Admin Settings')),
      body: Obx(
        () {
          final settings = controller.adminSettings.value;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCheckTile(
                'Enable New AI Model',
                settings.enableNewAiModel,
                (value) => controller.updateSettings(
                  settings.copyWith(enableNewAiModel: value),
                ),
              ),
              _buildCheckTile(
                'Maintenance Mode',
                settings.maintenanceMode,
                (value) => controller.updateSettings(
                  settings.copyWith(maintenanceMode: value),
                ),
              ),
              _buildCheckTile(
                'Show Beta Features',
                settings.showBetaFeatures,
                (value) => controller.updateSettings(
                  settings.copyWith(showBetaFeatures: value),
                ),
              ),
              _buildCheckTile(
                'Force Client Updates',
                settings.forceClientUpdates,
                (value) => controller.updateSettings(
                  settings.copyWith(forceClientUpdates: value),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.password),
                title: const Text('Change Admin Password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: const Text('View Activity Logs'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/admin/logs'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCheckTile(String title, bool val, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: val,
      onChanged: onChanged,
    );
  }
}
