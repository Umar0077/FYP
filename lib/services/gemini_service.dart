import 'dart:math';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/secure_storage.dart';

class GeminiService {
  static const String _apiKey = 'key???';
  final SecureStorage _secureStorage = SecureStorage();

  String _buildInterviewTypeInstruction(String interviewType, String position) {
    final type = interviewType.toLowerCase();

    if (type.contains('technical')) {
      return 'Ask role-specific technical questions for a $position, including core concepts, architecture, debugging, and practical implementation trade-offs.';
    }
    if (type.contains('behavioral')) {
      return 'Ask behavioral and situational questions tailored to a $position, focusing on teamwork, conflict resolution, ownership, and communication.';
    }
    if (type.contains('coding')) {
      return 'Ask coding-focused questions for a $position, including algorithms, problem solving, code quality, complexity analysis, and edge cases.';
    }
    if (type.contains('phone')) {
      return 'Ask concise screening questions for a $position, focusing on fundamentals, role fit, and practical experience verification.';
    }
    if (type.contains('hr')) {
      return 'Ask HR-style questions for a $position, focusing on motivation, career goals, strengths/weaknesses, and culture fit.';
    }

    return 'Ask questions that match both the selected interview type and the responsibilities of a $position.';
  }

  GenerativeModel _buildModel(String apiKey) {
    return GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: apiKey,
    );
  }

  Future<String?> _readSavedApiKey() async {
    final saved = await _secureStorage.read(AppConstants.geminiApiKeyKey);
    final trimmed = saved?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  bool _isApiKeyError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('api key') ||
        message.contains('unauthenticated') ||
        message.contains('permission denied') ||
        message.contains('developer_error');
  }

  Future<GenerateContentResponse> _generateContentWithKeyFallback(List<Content> content) async {
    final savedKey = await _readSavedApiKey();
    final primaryKey = savedKey ?? _apiKey;

    try {
      final model = _buildModel(primaryKey);
      return await model.generateContent(content);
    } catch (e) {
      // If a stale key was saved in Settings, retry once with bundled key.
      if (savedKey != null && savedKey != _apiKey && _isApiKeyError(e)) {
        final fallbackModel = _buildModel(_apiKey);
        return await fallbackModel.generateContent(content);
      }
      rethrow;
    }
  }

  /// Generate interview questions AND their correct answers in ONE API call
  /// Returns a Map with 'questions' and 'answers' lists
  Future<Map<String, List<String>>> generateQuestionsWithAnswers({
    String difficulty = 'Easy',
    int? count,
    String? position,
    String? interviewType,
  }) async {
    final random = Random();
    final targetPosition = (position?.trim().isNotEmpty ?? false)
        ? position!.trim()
        : 'Software Engineer';
    final targetInterviewType = (interviewType?.trim().isNotEmpty ?? false)
        ? interviewType!.trim()
        : 'Technical Interview';
    
    // Determine question count
    int finalCount;
    if (count != null && count > 0) {
      finalCount = count;
    } else if (difficulty.toLowerCase() == 'hard') {
      finalCount = 5 + random.nextInt(11); // Random between 5-15
    } else {
      finalCount = 3; // Default to 3 questions
    }

    // Create simplified prompt for Gemini to generate questions based on difficulty
    String difficultyInstruction;
    if (difficulty.toLowerCase() == 'easy') {
      difficultyInstruction = 'Ask really easy questions related to computer science and software engineering. Focus on basic concepts, fundamentals, and simple terminology.';
    } else if (difficulty.toLowerCase() == 'medium') {
      difficultyInstruction = 'Ask medium-level questions related to computer science and software engineering. Focus on problem-solving, algorithms, data structures, and practical applications.';
    } else {
      difficultyInstruction = 'Ask hard questions related to computer science and software engineering. Focus on advanced topics, system design, complex algorithms, and in-depth technical concepts.';
    }

    final interviewTypeInstruction = _buildInterviewTypeInstruction(
      targetInterviewType,
      targetPosition,
    );

    final prompt = '''
You are an expert technical interviewer. Generate exactly $finalCount unique interview questions with their correct answers.

Target Position: $targetPosition
Interview Type: $targetInterviewType
Difficulty Level: $difficulty
$difficultyInstruction
$interviewTypeInstruction

Important:
- Generate EXACTLY $finalCount questions
- For each question, provide a clear, concise correct answer
- Format: Question|Answer (separated by pipe character |)
- Every question must match BOTH the selected position and interview type
- Cover diverse but role-relevant topics for the selected position
- No numbering, no extra text

Format your response as:
Question 1 text|Correct answer 1 text
Question 2 text|Correct answer 2 text
...and so on, one per line.
''';

    try {
      final response = await _generateContentWithKeyFallback([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';
      
      if (text.isEmpty) {
        throw Exception('Empty response from AI');
      }

      // Parse the response - split by newlines
      final lines = text
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty && line.contains('|'))
          .toList();

      if (lines.isEmpty) {
        throw Exception('No valid questions generated');
      }

      List<String> questions = [];
      List<String> answers = [];

      for (final line in lines.take(finalCount)) {
        final parts = line.split('|');
        if (parts.length >= 2) {
          // Remove any numbering from question
          String question = parts[0].trim().replaceAll(RegExp(r'^\d+\.?\s*'), '');
          String answer = parts[1].trim();
          questions.add(question);
          answers.add(answer);
        }
      }

      if (questions.isEmpty) {
        throw Exception('Failed to parse questions and answers');
      }

      return {
        'questions': questions,
        'answers': answers,
      };
    } catch (e) {
      print('Error generating questions with answers: $e');
      rethrow;
    }
  }

  /// Generate interview questions using AI based on difficulty level.
  ///
  /// - difficulty: 'Easy' | 'Medium' | 'Hard'
  /// - count: number of questions desired. For Hard difficulty, AI will generate between 5-15 questions.
  Future<List<String>> generateQuestions({
    String difficulty = 'Easy',
    int? count,
    String? position,
    String? interviewType,
  }) async {
    final random = Random();
    final targetPosition = (position?.trim().isNotEmpty ?? false)
        ? position!.trim()
        : 'Software Engineer';
    final targetInterviewType = (interviewType?.trim().isNotEmpty ?? false)
        ? interviewType!.trim()
        : 'Technical Interview';
    
    // Determine question count
    int finalCount;
    if (count != null && count > 0) {
      finalCount = count;
    } else if (difficulty.toLowerCase() == 'hard') {
      finalCount = 5 + random.nextInt(11); // Random between 5-15
    } else {
      finalCount = 3; // Default to 3 questions
    }

    // Create simplified prompt for Gemini to generate questions based on difficulty
    String difficultyInstruction;
    if (difficulty.toLowerCase() == 'easy') {
      difficultyInstruction = 'Ask really easy questions related to computer science and software engineering. Focus on basic concepts, fundamentals, and simple terminology.';
    } else if (difficulty.toLowerCase() == 'medium') {
      difficultyInstruction = 'Ask medium-level questions related to computer science and software engineering. Focus on problem-solving, algorithms, data structures, and practical applications.';
    } else {
      difficultyInstruction = 'Ask hard questions related to computer science and software engineering. Focus on advanced topics, system design, complex algorithms, and in-depth technical concepts.';
    }

    final interviewTypeInstruction = _buildInterviewTypeInstruction(
      targetInterviewType,
      targetPosition,
    );

    final prompt = '''
You are an expert technical interviewer. Generate exactly $finalCount unique interview questions for software engineering candidates.

Target Position: $targetPosition
Interview Type: $targetInterviewType
Difficulty Level: $difficulty
$difficultyInstruction
$interviewTypeInstruction

Important:
- Generate EXACTLY $finalCount questions
- Each question should be clear and concise
- Every question must match BOTH the selected position and interview type
- Cover diverse but role-relevant topics for the selected position
- Return ONLY the questions, one per line
- No numbering, no extra text, just the questions

Format your response as a simple list of questions, one per line.
''';

    try {
      final response = await _generateContentWithKeyFallback([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';
      
      if (text.isEmpty) {
        throw Exception('Empty response from AI');
      }

      // Parse the response - split by newlines and filter out empty lines
      final questions = text
          .split('\n')
          .map((q) => q.trim())
          .where((q) => q.isNotEmpty && !q.startsWith('#') && !q.startsWith('*'))
          .map((q) => q.replaceAll(RegExp(r'^\d+\.?\s*'), '')) // Remove numbering
          .where((q) => q.length > 10) // Filter out very short lines
          .toList();

      if (questions.isEmpty) {
        throw Exception('No valid questions generated');
      }

      return questions.take(finalCount).toList();
    } catch (e) {
      print('Error generating questions: $e');
      rethrow;
    }
  }

  /// Ask Gemini to evaluate if the given answer is correct.
  /// Uses AI to judge answer quality without a predefined correct answer.
  Future<String> checkAnswer({
    required String question,
    required String answer,
  }) async {
    final prompt = '''
You are an expert technical interviewer evaluating a candidate's answer.

Question: "$question"
Candidate's Answer: "$answer"

Evaluate the answer with a lenient approach:
- If the answer shows ANY relevant understanding or is partially correct, mark it as "Correct"
- If the answer demonstrates knowledge of the topic even if incomplete, mark it as "Correct"
- If the answer is somewhat related to the question, mark it as "Correct"
- ONLY mark as "Incorrect" if the answer is completely wrong, irrelevant, or shows no understanding

Reply with ONLY ONE WORD:
- "Correct" if the answer shows any relevant understanding or partial correctness
- "Incorrect" ONLY if the answer is completely wrong or totally irrelevant

Your response:
''';

    try {
      final response = await _generateContentWithKeyFallback([Content.text(prompt)]);
      final text = response.text?.trim().toLowerCase() ?? '';
      if (text.startsWith('correct')) return 'Correct';
      if (text.startsWith('incorrect')) return 'Incorrect';
      return 'Correct'; // Default to Correct if unclear
    } catch (e) {
      print('Error checking answer: $e');
      return 'Correct'; // Default to Correct on error to be lenient
    }
  }

  /// Generate correct answer for a given question
  Future<String> generateCorrectAnswer(String question) async {
    final prompt = '''
You are an expert technical interviewer. Provide a correct, concise answer to the following interview question.

Question: "$question"

Provide a clear, accurate answer that demonstrates good understanding of the topic.
Keep it concise but complete (2-4 sentences).

Your answer:
''';

    try {
      final response = await _generateContentWithKeyFallback([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';
      
      if (text.isEmpty) {
        return 'Answer not available';
      }

      return text;
    } catch (e) {
      print('Error generating correct answer: $e');
      return 'Answer not available';
    }
  }

  /// Transcribe audio to text using Gemini
  Future<String> transcribeAudio(String audioPath) async {
    try {
      final audioFile = File(audioPath);
      if (!await audioFile.exists()) {
        return '';
      }

      final audioBytes = await audioFile.readAsBytes();
      
      final prompt = 'Transcribe the following audio to text. Return only the transcribed text without any additional commentary or explanation.';

      final response = await _generateContentWithKeyFallback([
        Content.multi([
          TextPart(prompt),
          DataPart('audio/wav', audioBytes),
        ])
      ]);

      return response.text?.trim() ?? '';
    } catch (e) {
      print('Transcription error: $e');
      return '';
    }
  }
}
