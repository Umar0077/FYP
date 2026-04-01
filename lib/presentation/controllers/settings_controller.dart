import 'package:get/get.dart';
import '../../domain/repositories/gemini_repository.dart';
import '../../domain/entities/chat_settings.dart';
import '../../core/constants/app_constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Controller for settings screen
class SettingsController extends GetxController {
  final GeminiRepository repository;
  final _secureStorage = const FlutterSecureStorage();

  SettingsController({required this.repository});

  // Reactive state - Gemini settings
  final RxString apiKey = ''.obs;
  final RxString systemPrompt = AppConstants.defaultSystemPrompt.obs;
  final RxDouble temperature = AppConstants.defaultTemperature.obs;
  final RxInt maxTokens = AppConstants.defaultMaxTokens.obs;
  final RxString modelId = AppConstants.defaultModelId.obs;
  final RxBool enableFallback = AppConstants.defaultEnableFallback.obs;
  
  // Emotion API settings
  final RxString emotionApiBaseUrl = 'http://192.168.18.131:8000'.obs;
  
  final RxBool isSaving = false.obs;
  final RxString saveMessage = ''.obs;
  
  // Storage keys
  static const String emotionApiBaseUrlKey = 'emotion_api_base_url';

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  /// Load settings from storage
  Future<void> loadSettings() async {
    try {
      final key = await repository.getApiKey();
      apiKey.value = key ?? '';

      final settings = await repository.getSettings();
      systemPrompt.value = settings.systemPrompt;
      temperature.value = settings.temperature;
      maxTokens.value = settings.maxTokens;
      modelId.value = settings.modelId;
      enableFallback.value = settings.enableFallback;
      
      // Load emotion API base URL
      final savedUrl = await _secureStorage.read(key: emotionApiBaseUrlKey);
      if (savedUrl != null && savedUrl.isNotEmpty) {
        emotionApiBaseUrl.value = savedUrl;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load settings',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Save API key
  Future<void> saveApiKey(String key) async {
    if (key.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'API key cannot be empty',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isSaving.value = true;
    saveMessage.value = '';

    try {
      await repository.saveApiKey(key);
      apiKey.value = key;
      saveMessage.value = 'API key saved successfully';
      
      Get.snackbar(
        'Success',
        'API key saved',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save API key',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
    }
  }

  /// Save all settings
  Future<void> saveSettings() async {
    isSaving.value = true;
    saveMessage.value = '';

    try {
      await repository.saveSettings(
        ChatSettings(
          systemPrompt: systemPrompt.value,
          temperature: temperature.value,
          maxTokens: maxTokens.value,
          modelId: modelId.value.trim().isEmpty 
              ? AppConstants.defaultModelId 
              : modelId.value.trim(),
          enableFallback: enableFallback.value,
        ),
      );
      
      // Save emotion API base URL
      await _secureStorage.write(
        key: emotionApiBaseUrlKey, 
        value: emotionApiBaseUrl.value,
      );
      
      saveMessage.value = 'Settings saved successfully';
      
      Get.snackbar(
        'Success',
        'Settings saved',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save settings',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
    }
  }
  
  /// Save emotion API base URL
  Future<void> saveEmotionApiUrl() async {
    isSaving.value = true;
    try {
      await _secureStorage.write(
        key: emotionApiBaseUrlKey,
        value: emotionApiBaseUrl.value,
      );
      
      Get.snackbar(
        'Success',
        'Emotion API URL saved',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save URL',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
    }
  }

  /// Reset to defaults
  void resetToDefaults() {
    systemPrompt.value = AppConstants.defaultSystemPrompt;
    temperature.value = AppConstants.defaultTemperature;
    maxTokens.value = AppConstants.defaultMaxTokens;
    modelId.value = AppConstants.defaultModelId;
    enableFallback.value = AppConstants.defaultEnableFallback;
  }

  /// Validate temperature (0.0 - 2.0)
  bool validateTemperature(double value) {
    return value >= 0.0 && value <= 2.0;
  }

  /// Validate max tokens (1 - 8192)
  bool validateMaxTokens(int value) {
    return value >= 1 && value <= 8192;
  }
}
