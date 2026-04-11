import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import 'nlp_cloud_service.dart';

class InterviewService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final NLPCloudService _nlpCloudService = NLPCloudService();

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
  /// Backend cloud evaluator is the primary scoring source.
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
        'evaluationRequestedAt': null,
        'evaluationRequestError': null,
      };

      if (_isAnsweredAttempt(attemptData)) {
        attemptData['evaluationStatus'] = 'pending';
        attemptData['feedback'] = 'Evaluation pending...';
        attemptData['missingPoints'] = [];
        attemptData['wrongClaims'] = [];
      } else {
        developer.log(
          'Skipped or empty answer. Cloud evaluation is not required for this attempt.',
          name: 'InterviewService.addAttemptToInterview',
        );
      }

      final attemptRef = await _firestore
          .collection('interviews')
          .doc(interviewId)
          .collection('attempts')
          .add(attemptData);

      developer.log(
        'Attempt saved to Firestore: interviewId=$interviewId attemptId=${attemptRef.id}',
        name: 'InterviewService.addAttemptToInterview',
      );

      if (_isAnsweredAttempt(attemptData)) {
        try {
          await attemptRef.set({
            'evaluationRequestedAt': FieldValue.serverTimestamp(),
            'evaluationStatus': 'requested',
            'evaluationRequestError': null,
          }, SetOptions(merge: true));

          await _evaluateAttemptWithRetry(
            interviewId: interviewId,
            attemptId: attemptRef.id,
          );

          await attemptRef.set({
            'evaluationStatus': 'evaluated',
            'evaluationRequestError': null,
          }, SetOptions(merge: true));

          developer.log(
            'Cloud evaluation completed for attemptId=${attemptRef.id}',
            name: 'InterviewService.addAttemptToInterview',
          );
        } catch (error, stackTrace) {
          developer.log(
            'Cloud evaluation failed for attemptId=${attemptRef.id}: $error',
            name: 'InterviewService.addAttemptToInterview',
            error: error,
            stackTrace: stackTrace,
            level: 900,
          );

          await attemptRef.set({
            'evaluationStatus': 'request_failed',
            'evaluationRequestError': error.toString(),
            'evaluationRequestFailedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      developer.log(
        'Error adding attempt to interview: $e',
        name: 'InterviewService.addAttemptToInterview',
        error: e,
        level: 1000,
      );
    }
  }

  /// Complete interview with backend-first scoring and aggregation.
  static Future<Map<String, dynamic>?> completeInterview(String interviewId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      developer.log(
        'Starting attempt-aggregated completion flow for interviewId=$interviewId',
        name: 'InterviewService.completeInterview',
      );

      final interviewRef = _firestore.collection('interviews').doc(interviewId);
      final interviewDoc = await interviewRef.get();
      final interviewData = interviewDoc.data() ?? <String, dynamic>{};
      final totalCount = (interviewData['totalCount'] as num?)?.toInt() ?? 0;
      final questionCount = (interviewData['questionCount'] as num?)?.toInt() ?? totalCount;
      final difficulty = interviewData['difficulty']?.toString();
      final startedAt = interviewData['startedAt'];

      final attemptsSnapshot = await interviewRef.collection('attempts').get();
      final aggregate = _aggregateFromAttemptDocs(attemptsSnapshot.docs);

      final int fetchedAttemptCount = attemptsSnapshot.docs.length;
      final int answeredCount = aggregate['answeredCount'] as int? ?? 0;
      final int skippedCount = aggregate['skippedCount'] as int? ?? 0;
      final int wrongCount = aggregate['wrongCount'] as int? ?? 0;
      final int correctCount = aggregate['correctCount'] as int? ?? 0;
      final int evaluatedAnsweredCount = aggregate['evaluatedAnsweredCount'] as int? ?? 0;
      final int computedTotalCount = aggregate['totalCount'] as int? ?? 0;
      final int resolvedTotalCount = computedTotalCount > 0
          ? computedTotalCount
          : (totalCount > 0 ? totalCount : questionCount);
      final double relevanceOverall = aggregate['relevanceOverall'] as double? ?? 0.0;
      final double accuracyOverall = aggregate['accuracyOverall'] as double? ?? 0.0;

      developer.log(
        'Attempts fetched for final aggregation: $fetchedAttemptCount',
        name: 'InterviewService.completeInterview',
      );
      developer.log(
        'Final counts answered=$answeredCount skipped=$skippedCount wrong=$wrongCount correct=$correctCount evaluatedAnswered=$evaluatedAnsweredCount total=$resolvedTotalCount',
        name: 'InterviewService.completeInterview',
      );
      developer.log(
        'Final averages accuracyOverall=${accuracyOverall.toStringAsFixed(2)} relevanceOverall=${relevanceOverall.toStringAsFixed(2)}',
        name: 'InterviewService.completeInterview',
      );

      await interviewRef.set({
        'endedAt': FieldValue.serverTimestamp(),
        'status': 'completed',
        'computedAt': FieldValue.serverTimestamp(),
        'resultSource': 'attempt_aggregated_in_app',
        'answeredCount': answeredCount,
        'skippedCount': skippedCount,
        'wrongCount': wrongCount,
        'correctCount': correctCount,
        'totalCount': resolvedTotalCount,
        'evaluatedAnsweredCount': evaluatedAnsweredCount,
        'relevanceOverall': relevanceOverall,
        'accuracyOverall': accuracyOverall,
        // Keep legacy aliases for compatibility with existing UI and admin paths.
        'avgRelevance': relevanceOverall,
        'avgAccuracy': accuracyOverall,
        'resultVersion': 'v2',
      }, SetOptions(merge: true));

      developer.log(
        'Interview completion finalized. answered=$answeredCount skipped=$skippedCount wrong=$wrongCount relevanceOverall=${relevanceOverall.toStringAsFixed(1)} accuracyOverall=${accuracyOverall.toStringAsFixed(1)}',
        name: 'InterviewService.completeInterview',
      );

      return {
        'sessionId': interviewId,
        'interviewId': interviewId,
        'relevanceOverall': relevanceOverall,
        'accuracyOverall': accuracyOverall,
        // Legacy compatibility keys.
        'avgRelevance': relevanceOverall,
        'avgAccuracy': accuracyOverall,
        'answeredQuestions': answeredCount,
        'answeredCount': answeredCount,
        'skippedCount': skippedCount,
        'wrongAnswers': wrongCount,
        'wrongCount': wrongCount,
        'correctCount': correctCount,
        'totalQuestions': resolvedTotalCount,
        'totalCount': resolvedTotalCount,
        'questionCount': questionCount,
        'difficulty': difficulty,
        'startedAt': startedAt,
        'evaluatedAnsweredCount': evaluatedAnsweredCount,
        'resultVersion': 'v2',
        'resultSource': 'attempt_aggregated_in_app',
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

  /// Recompute interview results directly from already evaluated attempts.
  static Future<Map<String, dynamic>?> computeInterviewResults(String interviewId) async {
    try {
      final interviewRef = _firestore.collection('interviews').doc(interviewId);
      final attemptsSnapshot = await interviewRef.collection('attempts').get();
      final aggregate = _aggregateFromAttemptDocs(attemptsSnapshot.docs);

      final int answeredCount = aggregate['answeredCount'] as int? ?? 0;
      final int skippedCount = aggregate['skippedCount'] as int? ?? 0;
      final int wrongCount = aggregate['wrongCount'] as int? ?? 0;
      final int correctCount = aggregate['correctCount'] as int? ?? 0;
      final int evaluatedAnsweredCount = aggregate['evaluatedAnsweredCount'] as int? ?? 0;
      final int totalCount = aggregate['totalCount'] as int? ?? 0;
      final double relevanceOverall = aggregate['relevanceOverall'] as double? ?? 0.0;
      final double accuracyOverall = aggregate['accuracyOverall'] as double? ?? 0.0;

      await interviewRef.set({
        'computedAt': FieldValue.serverTimestamp(),
        'resultSource': 'attempt_aggregated_in_app',
        'resultVersion': 'v2',
        'answeredCount': answeredCount,
        'skippedCount': skippedCount,
        'wrongCount': wrongCount,
        'correctCount': correctCount,
        'totalCount': totalCount,
        'evaluatedAnsweredCount': evaluatedAnsweredCount,
        'relevanceOverall': relevanceOverall,
        'accuracyOverall': accuracyOverall,
        'avgRelevance': relevanceOverall,
        'avgAccuracy': accuracyOverall,
      }, SetOptions(merge: true));

      return {
        'answeredCount': answeredCount,
        'skippedCount': skippedCount,
        'wrongCount': wrongCount,
        'correctCount': correctCount,
        'totalCount': totalCount,
        'evaluatedAnsweredCount': evaluatedAnsweredCount,
        'relevanceOverall': relevanceOverall,
        'accuracyOverall': accuracyOverall,
        'avgRelevance': relevanceOverall,
        'avgAccuracy': accuracyOverall,
        'resultSource': 'attempt_aggregated_in_app',
      };
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

  static bool _isAnsweredAttempt(Map<String, dynamic> attemptData) {
    final status = attemptData['status']?.toString() ?? '';
    final userAnswer = attemptData['userAnswer']?.toString() ?? '';
    return status == 'answered' && userAnswer.trim().isNotEmpty;
  }

  static Future<void> _evaluateAttemptWithRetry({
    required String interviewId,
    required String attemptId,
    int maxAttempts = 2,
  }) async {
    Object? lastError;

    for (int run = 1; run <= maxAttempts; run++) {
      try {
        await _nlpCloudService.evaluateAttempt(
          interviewId: interviewId,
          attemptId: attemptId,
        );
        return;
      } catch (error, stackTrace) {
        lastError = error;

        developer.log(
          'Cloud evaluation attempt $run/$maxAttempts failed for attemptId=$attemptId: $error',
          name: 'InterviewService._evaluateAttemptWithRetry',
          error: error,
          stackTrace: stackTrace,
          level: run == maxAttempts ? 1000 : 900,
        );

        if (run < maxAttempts) {
          await Future<void>.delayed(const Duration(milliseconds: 600));
        }
      }
    }

    if (lastError is Exception) {
      throw lastError;
    }

    throw Exception(lastError?.toString() ?? 'Unknown cloud evaluation failure');
  }

  static Map<String, dynamic> _aggregateFromAttemptDocs(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    int answeredCount = 0;
    int skippedCount = 0;
    int wrongCount = 0;
    int evaluatedAnsweredCount = 0;
    double totalAccuracy = 0.0;
    double totalRelevance = 0.0;

    for (final doc in docs) {
      final data = doc.data();

      final String status = data['status']?.toString() ?? '';
      final String userAnswer = data['userAnswer']?.toString().trim() ?? '';

      if (status == 'skipped') {
        skippedCount++;
      }

      if (userAnswer.isNotEmpty) {
        answeredCount++;

        final dynamic accuracyRaw = data['accuracyFinal'];
        final dynamic relevanceRaw = data['relevanceFinal'];

        if (accuracyRaw is num && relevanceRaw is num) {
          final double accuracy = accuracyRaw.toDouble();
          final double relevance = relevanceRaw.toDouble();

          evaluatedAnsweredCount++;
          totalAccuracy += accuracy;
          totalRelevance += relevance;

          if (accuracy < 50.0) {
            wrongCount++;
          }
        }
      }
    }

    final int correctCount = (answeredCount - wrongCount).clamp(0, answeredCount);
    final int totalCount = answeredCount + skippedCount;
    final double accuracyOverall = evaluatedAnsweredCount > 0
        ? totalAccuracy / evaluatedAnsweredCount
        : 0.0;
    final double relevanceOverall = evaluatedAnsweredCount > 0
        ? totalRelevance / evaluatedAnsweredCount
        : 0.0;

    return <String, dynamic>{
      'answeredCount': answeredCount,
      'skippedCount': skippedCount,
      'wrongCount': wrongCount,
      'correctCount': correctCount,
      'totalCount': totalCount,
      'evaluatedAnsweredCount': evaluatedAnsweredCount,
      'accuracyOverall': accuracyOverall,
      'relevanceOverall': relevanceOverall,
    };
  }
}
