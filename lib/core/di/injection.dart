import 'package:get/get.dart';
import '../../core/utils/secure_storage.dart';
import '../../data/datasources/gemini_remote_datasource.dart';
import '../../data/repositories/gemini_repository_impl.dart';
import '../../domain/repositories/gemini_repository.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../domain/usecases/send_message_with_system_usecase.dart';
import '../../domain/usecases/generate_json_usecase.dart';
import '../../presentation/controllers/chat_controller.dart';
import '../../presentation/controllers/settings_controller.dart';
import '../../services/gemini_chat_service.dart';

/// Initialize all dependencies
class DependencyInjection {
  static Future<void> init() async {
    // Core
    Get.lazyPut<SecureStorage>(() => SecureStorage(), fenix: true);

    // Data sources
    Get.lazyPut<GeminiRemoteDatasource>(
      () => GeminiRemoteDatasource(),
      fenix: true,
    );

    // Repositories
    Get.lazyPut<GeminiRepository>(
      () => GeminiRepositoryImpl(
        remoteDatasource: Get.find<GeminiRemoteDatasource>(),
        secureStorage: Get.find<SecureStorage>(),
      ),
      fenix: true,
    );

    // Use cases
    Get.lazyPut<SendMessageUseCase>(
      () => SendMessageUseCase(Get.find<GeminiRepository>()),
      fenix: true,
    );

    Get.lazyPut<SendMessageWithSystemUseCase>(
      () => SendMessageWithSystemUseCase(Get.find<GeminiRepository>()),
      fenix: true,
    );

    Get.lazyPut<GenerateJsonUseCase>(
      () => GenerateJsonUseCase(Get.find<GeminiRepository>()),
      fenix: true,
    );

    // Services
    Get.lazyPut<GeminiChatService>(
      () => GeminiChatService(),
      fenix: true,
    );

    // Controllers
    Get.lazyPut<ChatController>(
      () => ChatController(
        sendMessageUseCase: Get.find<SendMessageUseCase>(),
      ),
    );

    Get.lazyPut<SettingsController>(
      () => SettingsController(
        repository: Get.find<GeminiRepository>(),
      ),
    );
  }
}
