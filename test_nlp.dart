import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';
import 'lib/services/nlp_evaluation_service.dart';
import 'lib/services/embeddings_service.dart';

void main() async {
  print('🚀 Starting NLP Evaluation Test...\n');

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully\n');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
    return;
  }

  final nlpService = NLPEvaluationService();
  final embeddingsService = EmbeddingsService();

  // Test Case 1: Good answer
  print('=' * 60);
  print('TEST CASE 1: Good Answer');
  print('=' * 60);
  await testEvaluation(
    nlpService: nlpService,
    embeddingsService: embeddingsService,
    questionText: 'What is object-oriented programming?',
    correctAnswer: 'Object-oriented programming (OOP) is a programming paradigm based on the concept of objects, which contain data in the form of fields (attributes) and code in the form of procedures (methods). Key principles include encapsulation, inheritance, polymorphism, and abstraction.',
    userAnswer: 'OOP is a programming style that uses objects. Objects have data and methods. The main concepts are encapsulation, inheritance, polymorphism, and abstraction. It helps organize code better.',
  );

  print('\n');

  // Test Case 2: Partially correct answer
  print('=' * 60);
  print('TEST CASE 2: Partially Correct Answer');
  print('=' * 60);
  await testEvaluation(
    nlpService: nlpService,
    embeddingsService: embeddingsService,
    questionText: 'What is object-oriented programming?',
    correctAnswer: 'Object-oriented programming (OOP) is a programming paradigm based on the concept of objects, which contain data in the form of fields (attributes) and code in the form of procedures (methods). Key principles include encapsulation, inheritance, polymorphism, and abstraction.',
    userAnswer: 'OOP is about using objects in programming. Objects have properties and methods.',
  );

  print('\n');

  // Test Case 3: Wrong answer
  print('=' * 60);
  print('TEST CASE 3: Wrong Answer');
  print('=' * 60);
  await testEvaluation(
    nlpService: nlpService,
    embeddingsService: embeddingsService,
    questionText: 'What is object-oriented programming?',
    correctAnswer: 'Object-oriented programming (OOP) is a programming paradigm based on the concept of objects, which contain data in the form of fields (attributes) and code in the form of procedures (methods). Key principles include encapsulation, inheritance, polymorphism, and abstraction.',
    userAnswer: 'OOP is a database management system used for storing data in tables.',
  );

  print('\n' + '=' * 60);
  print('✅ ALL TESTS COMPLETED!');
  print('=' * 60);
}

Future<void> testEvaluation({
  required NLPEvaluationService nlpService,
  required EmbeddingsService embeddingsService,
  required String questionText,
  required String correctAnswer,
  required String userAnswer,
}) async {
  print('\n📝 Question: $questionText');
  print('✓ Correct Answer: ${_truncate(correctAnswer, 80)}');
  print('👤 User Answer: ${userAnswer.isEmpty ? "(empty)" : _truncate(userAnswer, 80)}');
  print('\n🔍 Evaluating...\n');

  try {
    // 1. Gemini Rubric Evaluation
    final rubricResult = await nlpService.evaluateWithRubric(
      questionText: questionText,
      correctAnswer: correctAnswer,
      userAnswer: userAnswer,
    );

    final geminiRelevance = (rubricResult['relevanceScore'] ?? 0).toDouble();
    final geminiAccuracy = (rubricResult['accuracyScore'] ?? 0).toDouble();

    print('📊 Gemini Rubric Scores:');
    print('  • Relevance: ${geminiRelevance.toStringAsFixed(1)}/100');
    print('  • Accuracy: ${geminiAccuracy.toStringAsFixed(1)}/100');

    // 2. Embeddings Similarity
    double embeddingSimilarity = 50.0;
    if (userAnswer.trim().isNotEmpty) {
      try {
        embeddingSimilarity = await embeddingsService.calculateTextSimilarity(
          correctAnswer,
          userAnswer,
        );
        print('\n🧬 Embeddings Similarity: ${embeddingSimilarity.toStringAsFixed(1)}/100');
      } catch (e) {
        print('\n⚠️ Embeddings failed: $e');
      }
    } else {
      print('\n⏭️ Embeddings skipped (empty answer)');
    }

    // 3. Combined Final Scores
    final relevanceFinal = (0.6 * geminiRelevance + 0.4 * embeddingSimilarity)
        .clamp(0.0, 100.0);
    final accuracyFinal = (0.8 * geminiAccuracy + 0.2 * embeddingSimilarity)
        .clamp(0.0, 100.0);

    print('\n🎯 FINAL SCORES:');
    print('  • Relevance: ${relevanceFinal.toStringAsFixed(1)}/100 (60% Gemini + 40% Embeddings)');
    print('  • Accuracy: ${accuracyFinal.toStringAsFixed(1)}/100 (80% Gemini + 20% Embeddings)');

    print('\n💬 Feedback: ${rubricResult['feedback']}');

    if (rubricResult['missingPoints'] != null &&
        (rubricResult['missingPoints'] as List).isNotEmpty) {
      print('\n📌 Missing Points:');
      for (final point in rubricResult['missingPoints'] as List) {
        print('  • $point');
      }
    }

    if (rubricResult['wrongClaims'] != null &&
        (rubricResult['wrongClaims'] as List).isNotEmpty) {
      print('\n⚠️ Wrong Claims:');
      for (final claim in rubricResult['wrongClaims'] as List) {
        print('  • $claim');
      }
    }

    // Pass/Fail indicator
    print('\n' + _getPassFailIndicator(accuracyFinal));
  } catch (e) {
    print('❌ Error during evaluation: $e');
  }
}

String _truncate(String text, int maxLength) {
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength)}...';
}

String _getPassFailIndicator(double accuracy) {
  if (accuracy >= 70) {
    return '✅ PASS (Accuracy >= 70%)';
  } else if (accuracy >= 50) {
    return '⚠️ MARGINAL (Accuracy 50-70%)';
  } else {
    return '❌ FAIL (Accuracy < 50%)';
  }
}
