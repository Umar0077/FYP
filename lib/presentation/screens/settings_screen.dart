import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../../core/constants/app_constants.dart';

/// Settings screen for configuring Gemini
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.restore),
            label: const Text('Reset'),
            onPressed: () {
              Get.dialog(
                AlertDialog(
                  title: const Text('Reset Settings'),
                  content: const Text(
                    'Are you sure you want to reset all settings to defaults?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        settingsController.resetToDefaults();
                        Get.back();
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // API Key Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.key,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'API Key',
                        style: theme.textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get your API key from Google AI Studio',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Obx(() => TextField(
                        controller: TextEditingController(
                          text: settingsController.apiKey.value,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Gemini API Key',
                          hintText: 'Enter your API key',
                          prefixIcon: Icon(Icons.vpn_key),
                        ),
                        obscureText: true,
                        onChanged: (value) => settingsController.apiKey.value = value,
                      )),
                  const SizedBox(height: 12),
                  Obx(() => FilledButton.icon(
                        icon: settingsController.isSaving.value
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: const Text('Save API Key'),
                        onPressed: settingsController.isSaving.value
                            ? null
                            : () => settingsController.saveApiKey(
                                  settingsController.apiKey.value,
                                ),
                      )),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Model Configuration Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.memory,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Model Configuration',
                        style: theme.textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Configure which Gemini model to use',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Obx(() => TextField(
                        controller: TextEditingController(
                          text: settingsController.modelId.value,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Model ID',
                          hintText: AppConstants.defaultModelId,
                          helperText: 'Default: ${AppConstants.defaultModelId}',
                          prefixIcon: const Icon(Icons.model_training),
                        ),
                        onChanged: (value) =>
                            settingsController.modelId.value = value,
                      )),
                  const SizedBox(height: 16),
                  Obx(() => SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Enable Fallback'),
                        subtitle: Text(
                          'Falls back to ${AppConstants.defaultFallbackModelId} if primary model fails',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        value: settingsController.enableFallback.value,
                        onChanged: (value) =>
                            settingsController.enableFallback.value = value,
                        secondary: const Icon(Icons.backup),
                      )),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Emotion API Configuration Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.cloud_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Emotion API Configuration',
                        style: theme.textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Configure the FastAPI backend for emotion detection',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Obx(() => TextField(
                        controller: TextEditingController(
                          text: settingsController.emotionApiBaseUrl.value,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Base URL',
                          hintText: 'http://192.168.43.252:8000',
                          helperText: 'FastAPI backend URL (e.g., http://192.168.43.252:8000)',
                          prefixIcon: Icon(Icons.link),
                        ),
                        onChanged: (value) =>
                            settingsController.emotionApiBaseUrl.value = value,
                      )),
                  const SizedBox(height: 12),
                  Obx(() => FilledButton.icon(
                        icon: settingsController.isSaving.value
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: const Text('Save Emotion API URL'),
                        onPressed: settingsController.isSaving.value
                            ? null
                            : () => settingsController.saveEmotionApiUrl(),
                      )),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // System Prompt Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.chat_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'System Prompt',
                        style: theme.textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Define the AI\'s behavior and personality',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Obx(() => TextField(
                        controller: TextEditingController(
                          text: settingsController.systemPrompt.value,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'System Prompt',
                          hintText: 'You are a helpful assistant...',
                        ),
                        maxLines: 4,
                        onChanged: (value) =>
                            settingsController.systemPrompt.value = value,
                      )),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Temperature Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.thermostat,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Temperature',
                        style: theme.textTheme.titleLarge,
                      ),
                      const Spacer(),
                      Obx(() => Text(
                            settingsController.temperature.value.toStringAsFixed(2),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Controls randomness (0.0 = focused, 2.0 = creative)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(() => Slider(
                        value: settingsController.temperature.value,
                        min: 0.0,
                        max: 2.0,
                        divisions: 20,
                        label: settingsController.temperature.value.toStringAsFixed(2),
                        onChanged: (value) =>
                            settingsController.temperature.value = value,
                      )),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Max Tokens Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.format_size,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Max Output Tokens',
                        style: theme.textTheme.titleLarge,
                      ),
                      const Spacer(),
                      Obx(() => Text(
                            settingsController.maxTokens.value.toString(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Maximum length of the response (1-8192)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Obx(() => TextField(
                        controller: TextEditingController(
                          text: settingsController.maxTokens.value.toString(),
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Max Tokens',
                          hintText: '2048',
                          prefixIcon: Icon(Icons.numbers),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) {
                          final tokens = int.tryParse(value);
                          if (tokens != null &&
                              settingsController.validateMaxTokens(tokens)) {
                            settingsController.maxTokens.value = tokens;
                          }
                        },
                      )),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Save Button
          Obx(() => FilledButton.icon(
                icon: settingsController.isSaving.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: const Text('Save All Settings'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                onPressed: settingsController.isSaving.value
                    ? null
                    : () => settingsController.saveSettings(),
              )),

          const SizedBox(height: 16),

          // Info Card
          Card(
            color: theme.colorScheme.primaryContainer.withAlpha(128),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'About',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Obx(() => Text(
                    'Current Model: ${settingsController.modelId.value.isEmpty ? AppConstants.defaultModelId : settingsController.modelId.value}',
                    style: theme.textTheme.bodySmall,
                  )),
                  Obx(() => Text(
                    'Fallback: ${settingsController.enableFallback.value ? AppConstants.defaultFallbackModelId : "Disabled"}',
                    style: theme.textTheme.bodySmall,
                  )),
                  const SizedBox(height: 4),
                  Text(
                    'API keys are stored securely',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
