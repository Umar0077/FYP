import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import 'nlp_evaluation_service.dart';
import 'embeddings_service.dart';

class InterviewService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final NLPEvaluationService _nlpService = NLPEvaluationService();
  static final EmbeddingsService _embeddingsService = EmbeddingsService();

  /// Create a new interview session in Firestore
  static Future<String?> createInterviewSession({
    required String difficulty,
    required int questionCount,
    String? position,
    String? interviewType,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final interviewData = {
        'userId': user.uid,
        'difficulty': difficulty,
        'questionCount': questionCount,
        'position': position,
        'interviewType': interviewType,
        'startedAt': FieldValue.serverTimestamp(),
        'status': 'in_progress',
        'answeredCount': 0,
        'skippedCount': 0,
        'totalCount': questionCount,
      };

      final docRef = await _firestore
          .collection('interviews')
          .add(interviewData);

      return docRef.id;
    } catch (e) {
      developer.log(
        'Error creating interview session: $e',
        name: 'InterviewService.createInterviewSession',
        error: e,
        level: 1000,
      );
      return null;
    }
  }

  /// Add an attempt (question + answer) to the interview
  /// This evaluates the answer client-side using NLP and embeddings
  static Future<void> addAttemptToInterview({
    required String interviewId,
    required String questionId,
    required String questionText,
    required String correctAnswer,
    required String userAnswer,
    required String status, // "answered" or "skipped"
    String? position,
    String? interviewType,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final attemptData = {
        'questionId': questionId,
        'questionText': questionText,
        'correctAnswer': correctAnswer,
        'userAnswer': userAnswer,
        'status': status,
        'position': position,
        'interviewType': interviewType,
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Store without NLP evaluation (will evaluate all at once at interview end)
      if (status == 'answered' && userAnswer.trim().isNotEmpty) {
        // Just save the attempt data for now - evaluation happens at interview completion
        final relevanceFinal = 0.0; // Will be calculated at end
        final accuracyFinal = 0.0; // Will be calculated at end

        // Add placeholder evaluation results to attempt data
        attemptData['relevanceScore'] = relevanceFinal;
        attemptData['accuracyScore'] = accuracyFinal;
        attemptData['feedback'] = 'Evaluation pending...';
        attemptData['missingPoints'] = [];
        attemptData['wrongClaims'] = [];
      } else {
        developer.log('Skipped answer, no evaluation needed', name: 'InterviewService.addAttemptToInterview');
      }

      // Save attempt to Firestore
      await _firestore
          .collection('interviews')
          .doc(interviewId)
          .collection('attempts')
          .add(attemptData);

      developer.log('Attempt saved to Firestore', name: 'InterviewService.addAttemptToInterview');
    } catch (e) {
      developer.log(
        'Error adding attempt to interview: $e',
        name: 'InterviewService.addAttemptToInterview',
        error: e,
        level: 1000,
      );
    }
  }

  /// Complete the interview session and compute aggregated results
  /// NOW performs NLP evaluation on all answers at once to save API calls
  static Future<Map<String, dynamic>?> completeInterview(String interviewId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      developer.log('Starting batch NLP evaluation for all answers', name: 'InterviewService.completeInterview');

      final interviewDoc = await _firestore.collection('interviews').doc(interviewId).get();
      final interviewData = interviewDoc.data() ?? <String, dynamic>{};
      final totalCount = (interviewData['totalCount'] as num?)?.toInt() ?? 0;
      final questionCount = (interviewData['questionCount'] as num?)?.toInt() ?? totalCount;
      final difficulty = interviewData['difficulty']?.toString();
      final startedAt = interviewData['startedAt'];

      // Get all attempts
      final attemptsSnapshot = await _firestore
          .collection('interviews')
          .doc(interviewId)
          .collection('attempts')
          .get();

      // Evaluate each answered question with NLP
      for (final doc in attemptsSnapshot.docs) {
        final data = doc.data();
        
        if (data['status'] == 'answered' && data['userAnswer'] != null && data['userAnswer'].toString().trim().isNotEmpty) {
          try {
            final questionText = data['questionText'] ?? '';
            final correctAnswer = data['correctAnswer'] ?? '';
            final userAnswer = data['userAnswer'] ?? '';

            // Run NLP evaluation
            final rubricResult = await _nlpService.evaluateWithRubric(
              questionText: questionText,
              correctAnswer: correctAnswer,
              userAnswer: userAnswer,
            );

            final geminiRelevance = (rubricResult['relevanceScore'] ?? 50).toDouble();
            final geminiAccuracy = (rubricResult['accuracyScore'] ?? 50).toDouble();

            // Get text similarity
            double embeddingSimilarity = 50.0;
            try {
              embeddingSimilarity = await _embeddingsService.calculateTextSimilarity(
                correctAnswer,
                userAnswer,
              );
            } catch (e) {
              developer.log(
                'Embeddings failed for ${doc.id}: $e',
                name: 'InterviewService.completeInterview',
                level: 900,
              );
            }

            // Combine scores
            final relevanceFinal = (0.6 * geminiRelevance + 0.4 * embeddingSimilarity).clamp(0.0, 100.0);
            final accuracyFinal = (0.8 * geminiAccuracy + 0.2 * embeddingSimilarity).clamp(0.0, 100.0);

            // Update attempt with scores
            await doc.reference.update({
              'relevanceScore': relevanceFinal,
              'accuracyScore': accuracyFinal,
              'geminiRelevance': geminiRelevance,
              'geminiAccuracy': geminiAccuracy,
              'embeddingSimilarity': embeddingSimilarity,
              'feedback': rubricResult['feedback'] ?? '',
              'missingPoints': rubricResult['missingPoints'] ?? [],
              'wrongClaims': rubricResult['wrongClaims'] ?? [],
            });

            developer.log(
              'Evaluated ${doc.id} - R:${relevanceFinal.toStringAsFixed(1)} A:${accuracyFinal.toStringAsFixed(1)}',
              name: 'InterviewService.completeInterview',
            );
          } catch (e) {
            developer.log(
              'Failed to evaluate ${doc.id}: $e',
              name: 'InterviewService.completeInterview',
              level: 900,
            );
            // Continue with next answer even if this one fails
          }
        }
      }

      // Now calculate aggregated scores
      double totalRelevance = 0.0;
      double totalAccuracy = 0.0;
      int answeredCount = 0;
      int wrongCount = 0;

      // Re-fetch to get updated scores
      final updatedSnapshot = await _firestore
          .collection('interviews')
          .doc(interviewId)
          .collection('attempts')
          .get();

      for (final doc in updatedSnapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'answered') {
          answeredCount++;
          final relevance = (data['relevanceScore'] ?? 0).toDouble();
          final accuracy = (data['accuracyScore'] ?? 0).toDouble();
          
          totalRelevance += relevance;
          totalAccuracy += accuracy;

          if (accuracy < 50.0) {
            wrongCount++;
          }
        }
      }

      final avgRelevance = answeredCount > 0 ? totalRelevance / answeredCount : 0.0;
      final avgAccuracy = answeredCount > 0 ? totalAccuracy / answeredCount : 0.0;
      final skippedCount = (totalCount - answeredCount).clamp(0, totalCount);

      developer.log('Interview Results: answered=$answeredCount avgRelevance=${avgRelevance.toStringAsFixed(1)} avgAccuracy=${avgAccuracy.toStringAsFixed(1)} wrongAnswers=$wrongCount', name: 'InterviewService.completeInterview');

      // Update interview with aggregated results
      await _firestore
          .collection('interviews')
          .doc(interviewId)
          .update({
        'endedAt': FieldValue.serverTimestamp(),
        'status': 'completed',
        'answeredCount': answeredCount,
        'avgRelevance': avgRelevance,
        'avgAccuracy': avgAccuracy,
        'wrongCount': wrongCount,
        'computedAt': FieldValue.serverTimestamp(),
      });

      developer.log('Interview completed and results saved', name: 'InterviewService.completeInterview');

      return {
        'sessionId': interviewId,
        'interviewId': interviewId,
        'avgRelevance': avgRelevance,
        'avgAccuracy': avgAccuracy,
        'answeredQuestions': answeredCount,
        'answeredCount': answeredCount,
        'skippedCount': skippedCount,
        'wrongAnswers': wrongCount,
        'wrongCount': wrongCount,
        'totalQuestions': totalCount,
        'totalCount': totalCount,
        'questionCount': questionCount,
        'difficulty': difficulty,
        'startedAt': startedAt,
        'status': 'completed',
      };
    } catch (e) {
      developer.log(
        'Error completing interview: $e',
        name: 'InterviewService.completeInterview',
        error: e,
        level: 1000,
      );
      return null;
    }
  }

  /// Recompute interview results (can be called anytime)
  static Future<Map<String, dynamic>?> computeInterviewResults(String interviewId) async {
    try {
      final attemptsSnapshot = await _firestore
          .collection('interviews')
          .doc(interviewId)
          .collection('attempts')
          .get();

      double totalRelevance = 0.0;
      double totalAccuracy = 0.0;
      int answeredCount = 0;
      int wrongCount = 0;

      for (final doc in attemptsSnapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'answered') {
          answeredCount++;
          final relevance = (data['relevanceScore'] ?? 0).toDouble();
          final accuracy = (data['accuracyScore'] ?? 0).toDouble();
          
          totalRelevance += relevance;
          totalAccuracy += accuracy;

          if (accuracy < 50.0) {
            wrongCount++;
          }
        }
      }

      final avgRelevance = answeredCount > 0 ? totalRelevance / answeredCount : 0.0;
      final avgAccuracy = answeredCount > 0 ? totalAccuracy / answeredCount : 0.0;

      final results = {
        'answeredCount': answeredCount,
        'avgRelevance': avgRelevance,
        'avgAccuracy': avgAccuracy,
        'wrongCount': wrongCount,
      };

      await _firestore
          .collection('interviews')
          .doc(interviewId)
          .update({
        ...results,
        'computedAt': FieldValue.serverTimestamp(),
      });

      return results;
    } catch (e) {
      developer.log(
        'Error computing interview results: $e',
        name: 'InterviewService.computeInterviewResults',
        error: e,
        level: 1000,
      );
      return null;
    }
  }

  /// Get all interviews for the current user
  static Stream<QuerySnapshot> getUserInterviews() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('interviews')
        .where('userId', isEqualTo: user.uid)
        .orderBy('startedAt', descending: true)
        .snapshots();
  }

  /// Get a specific interview by ID
  static Future<DocumentSnapshot?> getInterview(String interviewId) async {
    try {
      return await _firestore
          .collection('interviews')
          .doc(interviewId)
          .get();
    } catch (e) {
      developer.log(
        'Error getting interview: $e',
        name: 'InterviewService.getInterview',
        error: e,
        level: 1000,
      );
      return null;
    }
  }

  /// Get all attempts for an interview
  static Stream<QuerySnapshot> getInterviewAttempts(String interviewId) {
    return _firestore
        .collection('interviews')
        .doc(interviewId)
        .collection('attempts')
        .orderBy('createdAt')
        .snapshots();
  }
}
