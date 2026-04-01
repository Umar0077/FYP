import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'dart:developer' as developer;

class NLPEvaluationService {
  static const String _apiKey = 'AIzaSyBzeQj9eY4s13lT2mWf1oCoz9axq5y67tI';
  
  // Preferred model with fallback chain
  static const List<String> _modelPriority = [
    'models/gemini-2.5-flash-lite',
    'models/gemini-2.5-flash',
    'models/gemini-1.5-flash',
    'models/gemini-pro',
  ];
  
  GenerativeModel? _cachedModel;
  String? _selectedModelId;
  
  /// Get or initialize Gemini model with fallback
  Future<GenerativeModel> _getModel() async {
    if (_cachedModel != null) {
      print('🤖 Using cached Gemini model: $_selectedModelId');
      return _cachedModel!;
    }
    
    print('🔍 Selecting Gemini model from priority list...');
    
    for (final modelId in _modelPriority) {
      try {
        print('   Testing: $modelId');
        final testModel = GenerativeModel(
          model: modelId,
          apiKey: _apiKey,
        );
        
        // Quick test to verify model works
        await testModel.generateContent([
          Content.text('Test')
        ]).timeout(Duration(seconds: 5));
        
        _cachedModel = testModel;
        _selectedModelId = modelId;
        print('✅ Selected Gemini model: $modelId\n');
        developer.log('Using Gemini model: $modelId', name: 'NLPEvaluation');
        return testModel;
      } catch (e) {
        print('   ❌ Failed: $e');
        developer.log('Model $modelId failed: $e', name: 'NLPEvaluation');
      }
    }
    
    // Fallback to default if all fail
    final fallbackModel = 'models/gemini-2.5-flash-lite';
    print('⚠️  All models failed, using fallback: $fallbackModel');
    _cachedModel = GenerativeModel(
      model: fallbackModel,
      apiKey: _apiKey,
    );
    _selectedModelId = fallbackModel;
    return _cachedModel!;
  }

  /// Evaluates answer using Gemini rubric-based scoring
  /// Returns JSON with relevanceScore, accuracyScore, feedback, missingPoints, wrongClaims
  Future<Map<String, dynamic>> evaluateWithRubric({
    required String questionText,
    required String correctAnswer,
    required String userAnswer,
  }) async {
    print('🧠 GEMINI RUBRIC EVALUATION STARTED');
    developer.log('Gemini evaluation request started', name: 'NLPEvaluation');
    
    if (userAnswer.trim().isEmpty) {
      print('⚠️  Empty answer - returning zero scores');
      return {
        'relevanceScore': 0,
        'accuracyScore': 0,
        'feedback': 'No answer provided',
        'missingPoints': ['Answer was not provided'],
        'wrongClaims': [],
      };
    }

    try {
      final model = await _getModel();
      print('📝 Generating rubric evaluation with model: $_selectedModelId');
      
      final prompt = '''
You are an expert evaluator for interview answers.

Question: "$questionText"

Correct Answer: "$correctAnswer"

User's Answer: "${userAnswer.length > 4000 ? userAnswer.substring(0, 4000) : userAnswer}"

Evaluate the user's answer and return a JSON object with:
{
  "relevanceScore": <0-100, how relevant is the answer to the question>,
  "accuracyScore": <0-100, how accurate is the answer compared to the correct answer>,
  "feedback": "<constructive feedback for the user>",
  "missingPoints": [<array of important points from correct answer that user missed>],
  "wrongClaims": [<array of incorrect or misleading statements in user's answer>]
}

Scoring guidelines:
- relevanceScore: Does the answer address the question? 100 if fully on topic, 0 if completely off-topic
- accuracyScore: How correct is the factual content? 100 if all correct, 0 if all wrong
- Provide actionable feedback that helps the user improve
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final text = response.text;

      print('✅ Gemini response received');
      developer.log('Gemini evaluation completed successfully', name: 'NLPEvaluation');

      if (text == null || text.isEmpty) {
        print('❌ Empty response from Gemini');
        throw Exception('Empty response from Gemini');
      }

      // Parse the JSON response
      final jsonStr = text.trim();
      final result = _parseJsonSimple(jsonStr);

      // Validate scores are in range
      result['relevanceScore'] = _clamp(result['relevanceScore'] ?? 0, 0, 100);
      result['accuracyScore'] = _clamp(result['accuracyScore'] ?? 0, 0, 100);

      return result;
    } catch (e, stackTrace) {
      print('❌ Error in rubric evaluation: $e');
      print('Stack trace: $stackTrace');
      developer.log('Gemini evaluation error: $e', name: 'NLPEvaluation', error: e);
      // Return fallback scores on error
      return {
        'relevanceScore': 50,
        'accuracyScore': 50,
        'feedback': 'Error during evaluation. Please try again.',
        'missingPoints': [],
        'wrongClaims': [],
        'error': e.toString(),
      };
    }
  }

  Map<String, dynamic> _parseJsonSimple(String jsonStr) {
    try {
      // Remove markdown code blocks if present
      var cleaned = jsonStr.trim();
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      } else if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      cleaned = cleaned.trim();

      // Use dart:convert
      final parsed = jsonDecode(cleaned);
      if (parsed is Map<String, dynamic>) {
        return parsed;
      } else {
        throw Exception('Expected JSON object, got ${parsed.runtimeType}');
      }
    } catch (e) {
      throw Exception('Failed to parse JSON: $e\nRaw response: $jsonStr');
    }
  }

  int _clamp(dynamic value, int min, int max) {
    if (value is num) {
      return value.toInt().clamp(min, max);
    }
    return min;
  }
}
