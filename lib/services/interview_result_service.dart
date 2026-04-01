import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InterviewResultService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> saveInterviewResultToFirestore({
    required String interviewId,
    required double avgRelevance,
    required double avgAccuracy,
    required int answeredCount,
    required int skippedCount,
    required int wrongCount,
    required int totalCount,
    required int questionCount,
    required Map<String, dynamic> confidenceAnalysis,
    Map<String, dynamic>? emotionReport,
    String? difficulty,
    dynamic startedAt,
    String status = 'completed',
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      developer.log(
        'Cannot save interview_result: no authenticated user',
        name: 'InterviewResultService.saveInterviewResultToFirestore',
        level: 1000,
      );
      return;
    }

    final docRef = _firestore.collection('interview_result').doc(interviewId);
    final legacyInterviewRef = _firestore.collection('interviews').doc(interviewId);

    Map<String, dynamic> sessionData = <String, dynamic>{};
    dynamic effectiveStartedAt = startedAt;
    String effectiveDifficulty = difficulty?.trim() ?? '';
    int effectiveQuestionCount = questionCount;
    int effectiveTotalCount = totalCount;

    try {
      final sessionDoc = await legacyInterviewRef.get();
      sessionData = sessionDoc.data() ?? <String, dynamic>{};
      effectiveStartedAt ??= sessionData['startedAt'];
      effectiveDifficulty = effectiveDifficulty.isEmpty
          ? (sessionData['difficulty']?.toString().trim() ?? '')
          : effectiveDifficulty;

      final int sessionQuestionCount = _asInt(sessionData['questionCount']);
      final int sessionTotalCount = _asInt(sessionData['totalCount']);
      if (effectiveQuestionCount <= 0 && sessionQuestionCount > 0) {
        effectiveQuestionCount = sessionQuestionCount;
      }
      if (effectiveTotalCount <= 0 && sessionTotalCount > 0) {
        effectiveTotalCount = sessionTotalCount;
      }
    } catch (e, st) {
      developer.log(
        'Could not read interviews/$interviewId before result save. Continuing with provided values.',
        name: 'InterviewResultService.saveInterviewResultToFirestore',
        error: e,
        stackTrace: st,
        level: 900,
      );
    }

    final double confidenceLevel = _normalizedConfidenceLevel(confidenceAnalysis);
    final String confidenceLabel = _confidenceLabel(confidenceAnalysis, confidenceLevel);
    final String confidenceSummary = _confidenceSummary(confidenceAnalysis);

    final existingDoc = await docRef.get();
    final payload = <String, dynamic>{
      'userId': user.uid,
      'interviewId': interviewId,
      'sessionId': interviewId,
      'avgRelevance': avgRelevance,
      'avgAccuracy': avgAccuracy,
      'confidenceLevel': confidenceLevel,
      'confidenceLabel': confidenceLabel,
      'confidenceAnalysis': confidenceAnalysis,
      'answeredCount': answeredCount,
      'answeredQuestions': answeredCount,
      'skippedCount': skippedCount,
      'wrongCount': wrongCount,
      'wrongAnswers': wrongCount,
      'totalCount': effectiveTotalCount,
      'totalQuestions': effectiveTotalCount,
      'questionCount': effectiveQuestionCount > 0 ? effectiveQuestionCount : effectiveTotalCount,
      'difficulty': effectiveDifficulty,
      'status': status,
      'endedAt': FieldValue.serverTimestamp(),
      'computedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (effectiveStartedAt != null) 'startedAt': effectiveStartedAt,
      if (confidenceSummary.isNotEmpty) 'confidenceAnalysisSummary': confidenceSummary,
      if (emotionReport != null && emotionReport.isNotEmpty) 'emotionReport': emotionReport,
      if (!existingDoc.exists) 'createdAt': FieldValue.serverTimestamp(),
    };

    developer.log('Preparing to save final interview result', name: 'InterviewResultService.saveInterviewResultToFirestore');
    developer.log('userId=${user.uid}', name: 'InterviewResultService.saveInterviewResultToFirestore');
    developer.log('interviewId=$interviewId', name: 'InterviewResultService.saveInterviewResultToFirestore');
    developer.log('avgRelevance=$avgRelevance', name: 'InterviewResultService.saveInterviewResultToFirestore');
    developer.log('avgAccuracy=$avgAccuracy', name: 'InterviewResultService.saveInterviewResultToFirestore');
    developer.log('confidenceLevel=$confidenceLevel', name: 'InterviewResultService.saveInterviewResultToFirestore');
    developer.log('documentPath=${docRef.path}', name: 'InterviewResultService.saveInterviewResultToFirestore');

    try {
      await docRef.set(payload, SetOptions(merge: true));

      await legacyInterviewRef.set({
        'avgRelevance': avgRelevance,
        'avgAccuracy': avgAccuracy,
        'confidenceAnalysis': confidenceAnalysis,
        if (emotionReport != null && emotionReport.isNotEmpty) 'emotionReport': emotionReport,
        'answeredCount': answeredCount,
        'skippedCount': skippedCount,
        'wrongCount': wrongCount,
        'status': status,
        'endedAt': FieldValue.serverTimestamp(),
        'computedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      developer.log(
        'Interview result saved successfully at ${docRef.path}',
        name: 'InterviewResultService.saveInterviewResultToFirestore',
      );
    } catch (e, st) {
      developer.log(
        'Failed to save interview result to ${docRef.path}: $e',
        name: 'InterviewResultService.saveInterviewResultToFirestore',
        error: e,
        stackTrace: st,
        level: 1000,
      );
      rethrow;
    }
  }

  static Future<void> upsertCompletedInterviewResult({
    required String sessionId,
    required double avgRelevance,
    required double avgAccuracy,
    required int totalQuestions,
    required int answeredQuestions,
    required int wrongAnswers,
    required Map<String, dynamic> confidenceAnalysis,
    Map<String, dynamic>? emotionReport,
  }) async {
    await saveInterviewResultToFirestore(
      interviewId: sessionId,
      avgRelevance: avgRelevance,
      avgAccuracy: avgAccuracy,
      answeredCount: answeredQuestions,
      skippedCount: (totalQuestions - answeredQuestions).clamp(0, totalQuestions),
      wrongCount: wrongAnswers,
      totalCount: totalQuestions,
      questionCount: totalQuestions,
      confidenceAnalysis: confidenceAnalysis,
      emotionReport: emotionReport,
      status: 'completed',
    );
  }

  static double _normalizedConfidenceLevel(Map<String, dynamic> confidenceAnalysis) {
    final dynamic raw = confidenceAnalysis['confidence_level'] ?? confidenceAnalysis['confidenceLevel'];
    double value = 0.0;

    if (raw is num) {
      value = raw.toDouble();
    } else if (raw is String) {
      value = double.tryParse(raw) ?? 0.0;
    }

    if (value <= 1.0) {
      value = value * 100.0;
    }

    return value.clamp(0.0, 100.0);
  }

  static String _confidenceLabel(Map<String, dynamic> confidenceAnalysis, double confidenceLevel) {
    final dynamic rawLabel = confidenceAnalysis['confidence_label'] ?? confidenceAnalysis['confidenceLabel'];
    final normalized = rawLabel?.toString().trim().toLowerCase() ?? '';
    if (normalized == 'low' || normalized == 'medium' || normalized == 'high') {
      return normalized;
    }

    if (confidenceLevel >= 71.0) {
      return 'high';
    }
    if (confidenceLevel >= 41.0) {
      return 'medium';
    }
    return 'low';
  }

  static String _confidenceSummary(Map<String, dynamic> confidenceAnalysis) {
    final dynamic summary = confidenceAnalysis['reasoning'] ??
        confidenceAnalysis['confidenceAnalysisSummary'] ??
        confidenceAnalysis['summary'];
    return summary?.toString().trim() ?? '';
  }

  static int _asInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }
}
