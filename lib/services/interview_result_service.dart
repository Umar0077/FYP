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
    int? correctCount,
    required int totalCount,
    required int questionCount,
    required Map<String, dynamic> confidenceAnalysis,
    Map<String, dynamic>? emotionReport,
    String? difficulty,
    dynamic startedAt,
    String status = 'completed',
    double? relevanceOverall,
    double? accuracyOverall,
    int? evaluatedAnsweredCount,
    String? resultVersion,
    String? resultSource,
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
    final Map<String, dynamic> normalizedConfidenceAnalysis = _normalizedConfidenceAnalysisPayload(
      confidenceAnalysis,
      confidenceLevel: confidenceLevel,
      confidenceLabel: confidenceLabel,
      confidenceSummary: confidenceSummary,
    );
    final List<String> emotionBasedObservations = _asStringList(
      normalizedConfidenceAnalysis['emotion_based_observations'],
    );
    final List<String> coachingTips = _asStringList(
      normalizedConfidenceAnalysis['coaching_tips'],
    );
    final Map<String, dynamic>? emotionSummaryUsed = _asMap(
      normalizedConfidenceAnalysis['emotion_summary_used'],
    );
    final bool fallbackUsed = normalizedConfidenceAnalysis['fallback_used'] == true;
    final String fallbackReason =
        normalizedConfidenceAnalysis['fallback_reason']?.toString().trim() ?? '';
    final String analysisSource =
        normalizedConfidenceAnalysis['analysis_source']?.toString().trim().isNotEmpty == true
            ? normalizedConfidenceAnalysis['analysis_source'].toString().trim()
            : 'unknown';

    final double effectiveRelevanceOverall = relevanceOverall ?? avgRelevance;
    final double effectiveAccuracyOverall = accuracyOverall ?? avgAccuracy;
    final int effectiveEvaluatedAnsweredCount = evaluatedAnsweredCount ?? answeredCount;
    final int effectiveCorrectCount = correctCount ?? (answeredCount - wrongCount).clamp(0, answeredCount);
    final String effectiveResultVersion = resultVersion?.trim().isNotEmpty == true
        ? resultVersion!.trim()
        : 'v2';
    final String effectiveResultSource = resultSource?.trim().isNotEmpty == true
        ? resultSource!.trim()
      : 'attempt_aggregated_in_app';

    final existingDoc = await docRef.get();
    final payload = <String, dynamic>{
      'userId': user.uid,
      'interviewId': interviewId,
      'sessionId': interviewId,
      'relevanceOverall': effectiveRelevanceOverall,
      'accuracyOverall': effectiveAccuracyOverall,
      'avgRelevance': avgRelevance,
      'avgAccuracy': avgAccuracy,
      'confidenceLevel': confidenceLevel,
      'confidenceLabel': confidenceLabel,
      'confidenceAnalysis': normalizedConfidenceAnalysis,
      'answeredCount': answeredCount,
      'answeredQuestions': answeredCount,
      'skippedCount': skippedCount,
      'wrongCount': wrongCount,
      'wrongAnswers': wrongCount,
      'correctCount': effectiveCorrectCount,
      'totalCount': effectiveTotalCount,
      'totalQuestions': effectiveTotalCount,
      'questionCount': effectiveQuestionCount > 0 ? effectiveQuestionCount : effectiveTotalCount,
      'evaluatedAnsweredCount': effectiveEvaluatedAnsweredCount,
      'resultVersion': effectiveResultVersion,
      'resultSource': effectiveResultSource,
      'difficulty': effectiveDifficulty,
      'status': status,
      'endedAt': FieldValue.serverTimestamp(),
      'computedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'analysisSource': analysisSource,
      'fallbackUsed': fallbackUsed,
      if (fallbackReason.isNotEmpty) 'fallbackReason': fallbackReason,
      if (emotionBasedObservations.isNotEmpty)
        'emotion_based_observations': emotionBasedObservations,
      if (coachingTips.isNotEmpty) 'coaching_tips': coachingTips,
      if (emotionSummaryUsed != null && emotionSummaryUsed.isNotEmpty)
        'emotion_summary_used': emotionSummaryUsed,
      if (effectiveStartedAt != null) 'startedAt': effectiveStartedAt,
      if (confidenceSummary.isNotEmpty) 'confidenceAnalysisSummary': confidenceSummary,
      if (emotionReport != null && emotionReport.isNotEmpty) 'emotionReport': emotionReport,
      if (!existingDoc.exists) 'createdAt': FieldValue.serverTimestamp(),
    };

    developer.log('Preparing to save final interview result', name: 'InterviewResultService.saveInterviewResultToFirestore');
    developer.log('userId=${user.uid}', name: 'InterviewResultService.saveInterviewResultToFirestore');
    developer.log('interviewId=$interviewId', name: 'InterviewResultService.saveInterviewResultToFirestore');
    developer.log('relevanceOverall=$effectiveRelevanceOverall', name: 'InterviewResultService.saveInterviewResultToFirestore');
    developer.log('accuracyOverall=$effectiveAccuracyOverall', name: 'InterviewResultService.saveInterviewResultToFirestore');
    developer.log('avgRelevance=$avgRelevance', name: 'InterviewResultService.saveInterviewResultToFirestore');
    developer.log('avgAccuracy=$avgAccuracy', name: 'InterviewResultService.saveInterviewResultToFirestore');
    developer.log('correctCount=$effectiveCorrectCount', name: 'InterviewResultService.saveInterviewResultToFirestore');
    developer.log('confidenceLevel=$confidenceLevel', name: 'InterviewResultService.saveInterviewResultToFirestore');
    developer.log('confidenceLabel=$confidenceLabel', name: 'InterviewResultService.saveInterviewResultToFirestore');
    developer.log('analysisSource=$analysisSource fallbackUsed=$fallbackUsed fallbackReason=$fallbackReason', name: 'InterviewResultService.saveInterviewResultToFirestore');
    developer.log('confidenceAnalysisKeys=${normalizedConfidenceAnalysis.keys.join(', ')}', name: 'InterviewResultService.saveInterviewResultToFirestore');
    developer.log('emotionReportKeys=${emotionReport?.keys.toList() ?? const <dynamic>[]}', name: 'InterviewResultService.saveInterviewResultToFirestore');
    developer.log('Final Firestore payload keys=${payload.keys.join(', ')}', name: 'InterviewResultService.saveInterviewResultToFirestore');
    developer.log('documentPath=${docRef.path}', name: 'InterviewResultService.saveInterviewResultToFirestore');

    try {
      await docRef.set(payload, SetOptions(merge: true));

      await legacyInterviewRef.set({
        'relevanceOverall': effectiveRelevanceOverall,
        'accuracyOverall': effectiveAccuracyOverall,
        'avgRelevance': avgRelevance,
        'avgAccuracy': avgAccuracy,
        'confidenceAnalysis': normalizedConfidenceAnalysis,
        'confidenceLevel': confidenceLevel,
        'confidenceLabel': confidenceLabel,
        'analysisSource': analysisSource,
        'fallbackUsed': fallbackUsed,
        if (fallbackReason.isNotEmpty) 'fallbackReason': fallbackReason,
        if (confidenceSummary.isNotEmpty) 'confidenceAnalysisSummary': confidenceSummary,
        if (emotionBasedObservations.isNotEmpty)
          'emotion_based_observations': emotionBasedObservations,
        if (coachingTips.isNotEmpty) 'coaching_tips': coachingTips,
        if (emotionSummaryUsed != null && emotionSummaryUsed.isNotEmpty)
          'emotion_summary_used': emotionSummaryUsed,
        if (emotionReport != null && emotionReport.isNotEmpty) 'emotionReport': emotionReport,
        'answeredCount': answeredCount,
        'skippedCount': skippedCount,
        'wrongCount': wrongCount,
        'correctCount': effectiveCorrectCount,
        'evaluatedAnsweredCount': effectiveEvaluatedAnsweredCount,
        'resultVersion': effectiveResultVersion,
        'resultSource': effectiveResultSource,
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
      correctCount: (answeredQuestions - wrongAnswers).clamp(0, answeredQuestions),
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

  static Map<String, dynamic> _normalizedConfidenceAnalysisPayload(
    Map<String, dynamic> confidenceAnalysis, {
    required double confidenceLevel,
    required String confidenceLabel,
    required String confidenceSummary,
  }) {
    final normalized = Map<String, dynamic>.from(confidenceAnalysis);
    normalized['confidence_level'] = confidenceLevel;
    normalized['confidence_label'] = confidenceLabel;

    if (confidenceSummary.isNotEmpty &&
        (normalized['reasoning']?.toString().trim().isEmpty ?? true)) {
      normalized['reasoning'] = confidenceSummary;
    }

    if (!normalized.containsKey('emotion_based_observations')) {
      normalized['emotion_based_observations'] = const <String>[];
    }
    if (!normalized.containsKey('coaching_tips')) {
      normalized['coaching_tips'] = const <String>[];
    }

    if (!normalized.containsKey('fallback_used')) {
      normalized['fallback_used'] = false;
    }

    if (!normalized.containsKey('analysis_source') ||
        normalized['analysis_source']?.toString().trim().isEmpty == true) {
      normalized['analysis_source'] = 'unknown';
    }

    return normalized;
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return null;
  }

  static List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const <String>[];
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
