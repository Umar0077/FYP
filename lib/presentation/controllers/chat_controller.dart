import 'package:get/get.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/chat_settings.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../core/constants/app_constants.dart';
import 'settings_controller.dart';

/// Controller for chat screen
class ChatController extends GetxController {
  final SendMessageUseCase sendMessageUseCase;

  ChatController({required this.sendMessageUseCase});

  // Reactive state
  final RxList<Message> messages = <Message>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  /// Send a message
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // Clear previous error
    error.value = '';

    // Add user message
    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );
    messages.add(userMessage);

    // Start loading
    isLoading.value = true;

    try {
      // Get current settings
      final settingsController = Get.find<SettingsController>();
      final settings = ChatSettings(
        systemPrompt: settingsController.systemPrompt.value,
        temperature: settingsController.temperature.value,
        maxTokens: settingsController.maxTokens.value,
        modelId: settingsController.modelId.value,
        enableFallback: settingsController.enableFallback.value,
      );

      // Send message and get response
      final response = await sendMessageUseCase.call(content, settings);
      messages.add(response);
    } catch (e) {
      error.value = _getErrorMessage(e);
      
      // Add error message to chat
      final errorMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '❌ ${error.value}',
        isUser: false,
        timestamp: DateTime.now(),
      );
      messages.add(errorMessage);
    } finally {
      isLoading.value = false;
    }
  }

  /// Clear chat history
  void clearChat() {
    messages.clear();
    error.value = '';
  }

  /// Get friendly error message
  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString();
    
    if (errorStr.contains(AppConstants.apiKeyMissingError)) {
      return AppConstants.apiKeyMissingError;
    } else if (errorStr.contains('timeout')) {
      return AppConstants.timeoutError;
    } else if (errorStr.contains('network') || errorStr.contains('SocketException')) {
      return AppConstants.networkError;
    } else if (errorStr.contains('API key')) {
      return 'Invalid API key. Please check your settings.';
    }
    
    return AppConstants.genericError;
  }
}
