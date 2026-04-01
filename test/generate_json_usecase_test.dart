import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:nova_prep/domain/usecases/generate_json_usecase.dart';
import 'package:nova_prep/domain/repositories/gemini_repository.dart';
import 'package:nova_prep/domain/entities/chat_settings.dart';

@GenerateMocks([GeminiRepository])
import 'generate_json_usecase_test.mocks.dart';

void main() {
  late GenerateJsonUseCase useCase;
  late MockGeminiRepository mockRepository;
  late ChatSettings testSettings;

  setUp(() {
    mockRepository = MockGeminiRepository();
    useCase = GenerateJsonUseCase(mockRepository);
    testSettings = ChatSettings(
      systemPrompt: 'You are a helpful assistant',
      temperature: 0.7,
      maxTokens: 2048,
      modelId: 'gemini-2.5-flash',
      enableFallback: true,
    );
  });

  group('GenerateJsonUseCase', () {
    test('should return JSON when message and schema are valid', () async {
      const testMessage = 'Generate user data';
      final testSchema = {'name': 'string', 'age': 'number'};
      final testResponse = {'name': 'John', 'age': 30};

      when(mockRepository.generateJson(testMessage, testSchema, testSettings))
          .thenAnswer((_) async => testResponse);

      final result = await useCase.call(testMessage, testSchema, testSettings);

      expect(result, testResponse);
      verify(mockRepository.generateJson(testMessage, testSchema, testSettings))
          .called(1);
    });

    test('should throw exception when message is empty', () async {
      final testSchema = {'name': 'string'};

      expect(
        () => useCase.call('', testSchema, testSettings),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw exception when schema is empty', () async {
      const testMessage = 'Generate data';

      expect(
        () => useCase.call(testMessage, {}, testSettings),
        throwsA(isA<Exception>()),
      );
    });

    test('should throw exception when message is only whitespace', () async {
      final testSchema = {'name': 'string'};

      expect(
        () => useCase.call('   ', testSchema, testSettings),
        throwsA(isA<Exception>()),
      );
    });

    test('should propagate repository exceptions', () async {
      const testMessage = 'Generate data';
      final testSchema = {'name': 'string'};

      when(mockRepository.generateJson(testMessage, testSchema, testSettings))
          .thenThrow(Exception('Network error'));

      expect(
        () => useCase.call(testMessage, testSchema, testSettings),
        throwsException,
      );
    });

    test('should handle complex nested schemas', () async {
      const testMessage = 'Generate complex data';
      final testSchema = {
        'user': {
          'name': 'string',
          'address': {
            'street': 'string',
            'city': 'string',
          }
        }
      };
      final testResponse = {
        'user': {
          'name': 'John',
          'address': {
            'street': '123 Main St',
            'city': 'NYC',
          }
        }
      };

      when(mockRepository.generateJson(testMessage, testSchema, testSettings))
          .thenAnswer((_) async => testResponse);

      final result = await useCase.call(testMessage, testSchema, testSettings);

      expect(result, testResponse);
    });
  });
}
