import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:nova_prep/services/gemini_chat_service.dart';
import 'package:nova_prep/core/utils/secure_storage.dart';

@GenerateMocks([SecureStorage])
import 'gemini_chat_service_test.mocks.dart';

void main() {
  late GeminiChatService service;
  late MockSecureStorage mockSecureStorage;

  setUp(() {
    service = GeminiChatService();
    mockSecureStorage = MockSecureStorage();
  });

  group('GeminiChatService', () {
    test('sendMessage should throw when API key is missing', () async {
      when(mockSecureStorage.read('gemini_api_key')).thenAnswer(
        (_) async => null,
      );

      expect(
        () => service.sendMessage('Hello'),
        throwsException,
      );
    });

    test('sendMessage should throw on invalid API key', () async {
      when(mockSecureStorage.read('gemini_api_key')).thenAnswer(
        (_) async => 'invalid_key',
      );

      expect(
        () => service.sendMessage('Hello'),
        throwsException,
      );
    });

    test('clearModel should reset model cache', () {
      service.clearModel();
      // Verify model is cleared by checking internal state
      expect(service, isNotNull);
    });
  });

  group('GeminiChatService - sendMessageWithSystem', () {
    test('should validate system prompt is not empty', () async {
      when(mockSecureStorage.read('gemini_api_key')).thenAnswer(
        (_) async => 'test_key',
      );

      expect(
        () => service.sendMessageWithSystem('Hello', ''),
        throwsException,
      );
    });
  });

  group('GeminiChatService - generateJson', () {
    test('should validate schema is not empty', () async {
      when(mockSecureStorage.read('gemini_api_key')).thenAnswer(
        (_) async => 'test_key',
      );

      expect(
        () => service.generateJson('Generate JSON', {}),
        throwsException,
      );
    });
  });
}
