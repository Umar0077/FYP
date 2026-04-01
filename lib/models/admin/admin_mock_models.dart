import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _toDateTime(dynamic v) {
  if (v is Timestamp) return v.toDate();
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
  return DateTime.fromMillisecondsSinceEpoch(0);
}

double _toDouble(dynamic v, {double fallback = 0}) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

int _toInt(dynamic v, {int fallback = 0}) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

List<String> _toStringList(dynamic v) {
  if (v is List) {
    return v.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList();
  }
  return <String>[];
}

Map<String, dynamic> _toMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) {
    return v.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, dynamic>{};
}

class MockUser {
  final String id;
  final String bio;
  final DateTime createdAt;
  final int currentStreak;
  final String dob;
  final String dob_iso;
  final String email;
  final DateTime lastPracticeDate;
  final DateTime lastUpdated;
  final int longestStreak;
  final String name;
  final String phone;
  final List<String> practiceDates;
  final String role;

  const MockUser({
    required this.id,
    required this.bio,
    required this.createdAt,
    required this.currentStreak,
    required this.dob,
    required this.dob_iso,
    required this.email,
    required this.lastPracticeDate,
    required this.lastUpdated,
    required this.longestStreak,
    required this.name,
    required this.phone,
    required this.practiceDates,
    this.role = 'user',
  });

  factory MockUser.fromMap(String id, Map<String, dynamic> map) {
    return MockUser(
      id: id,
      bio: map['bio']?.toString() ?? '',
      createdAt: _toDateTime(map['createdAt']),
      currentStreak: _toInt(map['currentStreak']),
      dob: map['dob']?.toString() ?? '',
      dob_iso: map['dob_iso']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      lastPracticeDate: _toDateTime(map['lastPracticeDate']),
      lastUpdated: _toDateTime(map['lastUpdated']),
      longestStreak: _toInt(map['longestStreak']),
      name: map['name']?.toString() ?? 'Unknown User',
      phone: map['phone']?.toString() ?? '',
      practiceDates: _toStringList(map['practiceDates']),
      role: map['role']?.toString() ?? 'user',
    );
  }
}

class MockEmotionSummaryUsed {
  final double average_confidence;
  final String dominant_emotion;
  final String volatility_assessment;

  const MockEmotionSummaryUsed({
    required this.average_confidence,
    required this.dominant_emotion,
    required this.volatility_assessment,
  });

  factory MockEmotionSummaryUsed.fromMap(Map<String, dynamic> map) {
    return MockEmotionSummaryUsed(
      average_confidence: _toDouble(map['average_confidence']),
      dominant_emotion: map['dominant_emotion']?.toString() ?? 'unknown',
      volatility_assessment: map['volatility_assessment']?.toString() ?? '',
    );
  }
}

class MockConfidenceAnalysis {
  final List<String> coaching_tips;
  final String confidence_label;
  final double confidence_level;
  final List<String> emotion_based_observations;
  final MockEmotionSummaryUsed emotion_summary_used;
  final String reasoning;

  const MockConfidenceAnalysis({
    required this.coaching_tips,
    required this.confidence_label,
    required this.confidence_level,
    required this.emotion_based_observations,
    required this.emotion_summary_used,
    required this.reasoning,
  });

  factory MockConfidenceAnalysis.fromMap(Map<String, dynamic> map) {
    return MockConfidenceAnalysis(
      coaching_tips: _toStringList(map['coaching_tips']),
      confidence_label: map['confidence_label']?.toString() ?? 'unknown',
      confidence_level: _toDouble(map['confidence_level']),
      emotion_based_observations: _toStringList(map['emotion_based_observations']),
      emotion_summary_used: MockEmotionSummaryUsed.fromMap(_toMap(map['emotion_summary_used'])),
      reasoning: map['reasoning']?.toString() ?? '',
    );
  }
}

class MockEmotionSummary {
  final double average_confidence_overall;
  final List<String> dominant_emotions;
  final Map<String, double> emotion_distribution;
  final String session_quality;
  final double total_duration_seconds;
  final int total_frames_processed;
  final int unique_emotions_detected;

  const MockEmotionSummary({
    required this.average_confidence_overall,
    required this.dominant_emotions,
    required this.emotion_distribution,
    required this.session_quality,
    required this.total_duration_seconds,
    required this.total_frames_processed,
    required this.unique_emotions_detected,
  });

  factory MockEmotionSummary.fromMap(Map<String, dynamic> map) {
    final distributionRaw = _toMap(map['emotion_distribution']);
    return MockEmotionSummary(
      average_confidence_overall: _toDouble(map['average_confidence_overall']),
      dominant_emotions: _toStringList(map['dominant_emotions']),
      emotion_distribution: distributionRaw.map((k, v) => MapEntry(k, _toDouble(v))),
      session_quality: map['session_quality']?.toString() ?? '',
      total_duration_seconds: _toDouble(map['total_duration_seconds']),
      total_frames_processed: _toInt(map['total_frames_processed']),
      unique_emotions_detected: _toInt(map['unique_emotions_detected']),
    );
  }
}

class MockEmotionReport {
  final double average_confidence;
  final Map<String, int> emotion_counts;
  final MockEmotionSummary summary;

  const MockEmotionReport({
    required this.average_confidence,
    required this.emotion_counts,
    required this.summary,
  });

  factory MockEmotionReport.fromMap(Map<String, dynamic> map) {
    final countsRaw = _toMap(map['emotion_counts']);
    return MockEmotionReport(
      average_confidence: _toDouble(map['average_confidence']),
      emotion_counts: countsRaw.map((k, v) => MapEntry(k, _toInt(v))),
      summary: MockEmotionSummary.fromMap(_toMap(map['summary'])),
    );
  }
}

class MockInterview {
  final String id;
  final String userId;
  final int answeredCount;
  final double avgAccuracy;
  final double avgRelevance;
  final DateTime computedAt;
  final MockConfidenceAnalysis confidenceAnalysis;
  final String difficulty;
  final MockEmotionReport emotionReport;
  final DateTime endedAt;
  final int questionCount;
  final int skippedCount;
  final DateTime startedAt;
  final String status;
  final int totalCount;
  final DateTime updatedAt;
  final int wrongCount;

  const MockInterview({
    required this.id,
    required this.userId,
    required this.answeredCount,
    required this.avgAccuracy,
    required this.avgRelevance,
    required this.computedAt,
    required this.confidenceAnalysis,
    required this.difficulty,
    required this.emotionReport,
    required this.endedAt,
    required this.questionCount,
    required this.skippedCount,
    required this.startedAt,
    required this.status,
    required this.totalCount,
    required this.updatedAt,
    required this.wrongCount,
  });

  factory MockInterview.fromMap(String id, Map<String, dynamic> map) {
    return MockInterview(
      id: id,
      userId: map['userId']?.toString() ?? '',
      answeredCount: _toInt(map['answeredCount']),
      avgAccuracy: _toDouble(map['avgAccuracy']),
      avgRelevance: _toDouble(map['avgRelevance']),
      computedAt: _toDateTime(map['computedAt']),
      confidenceAnalysis: MockConfidenceAnalysis.fromMap(_toMap(map['confidenceAnalysis'])),
      difficulty: map['difficulty']?.toString() ?? 'unknown',
      emotionReport: MockEmotionReport.fromMap(_toMap(map['emotionReport'])),
      endedAt: _toDateTime(map['endedAt']),
      questionCount: _toInt(map['questionCount']),
      skippedCount: _toInt(map['skippedCount']),
      startedAt: _toDateTime(map['startedAt']),
      status: map['status']?.toString() ?? 'unknown',
      totalCount: _toInt(map['totalCount']),
      updatedAt: _toDateTime(map['updatedAt']),
      wrongCount: _toInt(map['wrongCount']),
    );
  }
}

class MockAttempt {
  final String id;
  final double accuracyScore;
  final String correctAnswer;
  final DateTime createdAt;
  final double embeddingSimilarity;
  final String feedback;
  final double geminiAccuracy;
  final double geminiRelevance;
  final List<String> missingPoints;
  final String questionId;
  final String questionText;
  final double relevanceScore;
  final String status;
  final String userAnswer;
  final String userId;
  final List<String> wrongClaims;

  const MockAttempt({
    required this.id,
    required this.accuracyScore,
    required this.correctAnswer,
    required this.createdAt,
    required this.embeddingSimilarity,
    required this.feedback,
    required this.geminiAccuracy,
    required this.geminiRelevance,
    required this.missingPoints,
    required this.questionId,
    required this.questionText,
    required this.relevanceScore,
    required this.status,
    required this.userAnswer,
    required this.userId,
    required this.wrongClaims,
  });

  factory MockAttempt.fromMap(String id, Map<String, dynamic> map) {
    return MockAttempt(
      id: id,
      accuracyScore: _toDouble(map['accuracyScore']),
      correctAnswer: map['correctAnswer']?.toString() ?? '',
      createdAt: _toDateTime(map['createdAt']),
      embeddingSimilarity: _toDouble(map['embeddingSimilarity']),
      feedback: map['feedback']?.toString() ?? '',
      geminiAccuracy: _toDouble(map['geminiAccuracy']),
      geminiRelevance: _toDouble(map['geminiRelevance']),
      missingPoints: _toStringList(map['missingPoints']),
      questionId: map['questionId']?.toString() ?? '',
      questionText: map['questionText']?.toString() ?? '',
      relevanceScore: _toDouble(map['relevanceScore']),
      status: map['status']?.toString() ?? '',
      userAnswer: map['userAnswer']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      wrongClaims: _toStringList(map['wrongClaims']),
    );
  }
}

class AdminResourceItem {
  final String id;
  final String title;
  final String description;
  final String url;
  final bool isVisible;
  final DateTime createdAt;

  const AdminResourceItem({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.isVisible,
    required this.createdAt,
  });

  factory AdminResourceItem.fromMap(String id, Map<String, dynamic> map) {
    return AdminResourceItem(
      id: id,
      title: map['title']?.toString() ?? 'Untitled',
      description: map['description']?.toString() ?? '',
      url: map['url']?.toString() ?? '',
      isVisible: map['isVisible'] == true,
      createdAt: _toDateTime(map['createdAt']),
    );
  }
}

class AdminJobItem {
  final String id;
  final String title;
  final String description;
  final bool published;
  final DateTime createdAt;

  const AdminJobItem({
    required this.id,
    required this.title,
    required this.description,
    required this.published,
    required this.createdAt,
  });

  factory AdminJobItem.fromMap(String id, Map<String, dynamic> map) {
    return AdminJobItem(
      id: id,
      title: map['title']?.toString() ?? 'Untitled Role',
      description: map['description']?.toString() ?? '',
      published: map['published'] == true,
      createdAt: _toDateTime(map['createdAt']),
    );
  }
}

class AdminSupportTicket {
  final String id;
  final String userId;
  final String subject;
  final String message;
  final String status;
  final DateTime createdAt;

  const AdminSupportTicket({
    required this.id,
    required this.userId,
    required this.subject,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory AdminSupportTicket.fromMap(String id, Map<String, dynamic> map) {
    return AdminSupportTicket(
      id: id,
      userId: map['userId']?.toString() ?? '',
      subject: map['subject']?.toString() ?? 'Support Request',
      message: map['message']?.toString() ?? '',
      status: map['status']?.toString() ?? 'pending',
      createdAt: _toDateTime(map['createdAt']),
    );
  }
}

class AdminNotificationItem {
  final String id;
  final String title;
  final String message;
  final String audience;
  final String status;
  final DateTime createdAt;

  const AdminNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.audience,
    required this.status,
    required this.createdAt,
  });

  factory AdminNotificationItem.fromMap(String id, Map<String, dynamic> map) {
    return AdminNotificationItem(
      id: id,
      title: map['title']?.toString() ?? 'Notification',
      message: map['message']?.toString() ?? '',
      audience: map['audience']?.toString() ?? 'all',
      status: map['status']?.toString() ?? 'sent',
      createdAt: _toDateTime(map['createdAt']),
    );
  }
}

class AdminLogItem {
  final String id;
  final String action;
  final String details;
  final String adminId;
  final DateTime createdAt;

  const AdminLogItem({
    required this.id,
    required this.action,
    required this.details,
    required this.adminId,
    required this.createdAt,
  });

  factory AdminLogItem.fromMap(String id, Map<String, dynamic> map) {
    return AdminLogItem(
      id: id,
      action: map['action']?.toString() ?? 'Admin action',
      details: map['details']?.toString() ?? '',
      adminId: map['adminId']?.toString() ?? '',
      createdAt: _toDateTime(map['createdAt']),
    );
  }
}

class AdminSettings {
  final bool enableNewAiModel;
  final bool maintenanceMode;
  final bool showBetaFeatures;
  final bool forceClientUpdates;

  const AdminSettings({
    required this.enableNewAiModel,
    required this.maintenanceMode,
    required this.showBetaFeatures,
    required this.forceClientUpdates,
  });

  factory AdminSettings.defaults() {
    return const AdminSettings(
      enableNewAiModel: true,
      maintenanceMode: false,
      showBetaFeatures: true,
      forceClientUpdates: false,
    );
  }

  factory AdminSettings.fromMap(Map<String, dynamic> map) {
    return AdminSettings(
      enableNewAiModel: map['enableNewAiModel'] == true,
      maintenanceMode: map['maintenanceMode'] == true,
      showBetaFeatures: map['showBetaFeatures'] == true,
      forceClientUpdates: map['forceClientUpdates'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'enableNewAiModel': enableNewAiModel,
      'maintenanceMode': maintenanceMode,
      'showBetaFeatures': showBetaFeatures,
      'forceClientUpdates': forceClientUpdates,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  AdminSettings copyWith({
    bool? enableNewAiModel,
    bool? maintenanceMode,
    bool? showBetaFeatures,
    bool? forceClientUpdates,
  }) {
    return AdminSettings(
      enableNewAiModel: enableNewAiModel ?? this.enableNewAiModel,
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      showBetaFeatures: showBetaFeatures ?? this.showBetaFeatures,
      forceClientUpdates: forceClientUpdates ?? this.forceClientUpdates,
    );
  }
}
