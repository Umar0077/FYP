import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:nova_prep/domain/usecases/send_message_usecase.dart';
import 'package:nova_prep/domain/repositories/gemini_repository.dart';
import 'package:nova_prep/domain/entities/message.dart';
import 'package:nova_prep/domain/entities/chat_settings.dart';

@GenerateMocks([GeminiRepository])
import 'send_message_usecase_test.mocks.dart';

void main() {
  late SendMessageUseCase useCase;
  late MockGeminiRepository mockRepository;
  late ChatSettings testSettings;

  setUp(() {
    mockRepository = MockGeminiRepository();
    useCase = SendMessageUseCase(mockRepository);
    testSettings = ChatSettings(
      systemPrompt: 'You are a helpful assistant',
      temperature: 0.7,
      maxTokens: 2048,
      modelId: 'gemini-2.5-flash',
      enableFallback: true,
    );
  });

  group('SendMessageUseCase', () {
    test('should return message when input is valid', () async {
      const testMessageText = 'Hello, Gemini!';
      final testResponse = Message(
        id: '1',
        content: 'Hi! How can I help you?',
        isUser: false,
        timestamp: DateTime.now(),
      );

      when(mockRepository.sendMessage(testMessageText, testSettings)).thenAnswer(
        (_) async => testResponse,
      );

      final result = await useCase.call(testMessageText, testSettings);

      expect(result.content, testResponse.content);
      verify(mockRepository.sendMessage(testMessageText, testSettings)).called(1);
    });

    test('should throw exception when message is empty', () async {
      expect(
        () => useCase.call('', testSettings),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw exception when message is only whitespace', () async {
      expect(
        () => useCase.call('   ', testSettings),
        throwsA(isA<Exception>()),
      );
    });

    test('should propagate repository exceptions', () async {
      const testMessage = 'Test message';

      when(mockRepository.sendMessage(testMessage, testSettings)).thenThrow(
        Exception('Network error'),
      );

      expect(
        () => useCase.call(testMessage, testSettings),
        throwsException,
      );
    });
  });
}
