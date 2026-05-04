import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/admin/admin_mock_models.dart';
import 'admin_auth_service.dart';

class AdminDataService {
  AdminDataService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  String get _adminId => AdminAuthService.currentAdminIdentifier;

  Future<List<MockUser>> fetchUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.map((d) => MockUser.fromMap(d.id, d.data())).toList();
  }

  Future<int> fetchUsersCount() async {
    try {
      final aggregate = await _firestore.collection('users').count().get();
      return aggregate.count ?? 0;
    } catch (_) {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.size;
    }
  }

  Future<List<AdminUserPerformance>> fetchUserPerformanceLeaderboard() async {
    final usersSnapshot = await _firestore.collection('users').get();
    final interviewsSnapshot = await _firestore.collection('interviews').get();

    int toInt(dynamic value, {int fallback = 0}) {
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    double toDouble(dynamic value, {double fallback = 0.0}) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? fallback;
      return fallback;
    }

    double toPercent(dynamic value, {double fallback = 0.0}) {
      final raw = toDouble(value, fallback: fallback);
      final normalized = raw <= 1.0 ? raw * 100.0 : raw;
      return normalized.clamp(0.0, 100.0);
    }

    DateTime toDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
      }
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    final Map<String, Map<String, dynamic>> statsByUser = <String, Map<String, dynamic>>{};

    for (final interviewDoc in interviewsSnapshot.docs) {
      final data = interviewDoc.data();
      final userId = data['userId']?.toString() ?? '';
      if (userId.isEmpty) continue;

      final status = data['status']?.toString().toLowerCase() ?? '';
      if (status.isNotEmpty && status != 'completed') {
        continue;
      }

      final totalCount = toInt(data['totalCount'] ?? data['questionCount']);
      final wrong = toInt(data['wrongCount']);
      final correct = toInt(data['correctCount']);
      final skipped = toInt(data['skippedCount']);

      final answeredRaw = toInt(
        data['answeredCount'] ?? data['answeredQuestions'] ?? data['evaluatedAnsweredCount'],
      );
      final answered = answeredRaw > 0
          ? answeredRaw
          : (totalCount - skipped).clamp(0, totalCount);

      final dynamic accuracyRaw = data['accuracyOverall'] ?? data['avgAccuracy'];
      final hasAccuracyMetric = accuracyRaw != null;
      final accuracyPercent = toPercent(accuracyRaw);

      final bool hasCountMetric = answered > 0 &&
          (data.containsKey('wrongCount') ||
              data.containsKey('correctCount') ||
              wrong > 0 ||
              correct > 0);

      double countBasedSuccessPercent = 0.0;
      if (hasCountMetric) {
        final inferredCorrect = (answered - wrong).clamp(0, answered);
        final correctAnswers = correct > 0
            ? correct.clamp(0, answered)
            : inferredCorrect;
        countBasedSuccessPercent = answered > 0
            ? (correctAnswers / answered) * 100.0
            : 0.0;
      }

      final double interviewSuccessPercent = hasAccuracyMetric
          ? accuracyPercent
          : (hasCountMetric ? countBasedSuccessPercent : 0.0);

      final double interviewWeight = answered > 0
          ? answered.toDouble()
          : (totalCount > 0 ? totalCount.toDouble() : 1.0);
      final endedAt = toDateTime(data['endedAt']);

      final userStats = statsByUser.putIfAbsent(
        userId,
        () => <String, dynamic>{
          'totalInterviews': 0,
          'totalAnswered': 0,
          'totalWrong': 0,
          'totalSkipped': 0,
          'successWeightedSum': 0.0,
          'successWeight': 0.0,
          'accuracySum': 0.0,
          'lastInterviewAt': DateTime.fromMillisecondsSinceEpoch(0),
        },
      );

      userStats['totalInterviews'] = (userStats['totalInterviews'] as int) + 1;
      userStats['totalAnswered'] = (userStats['totalAnswered'] as int) + answered;
      userStats['totalWrong'] = (userStats['totalWrong'] as int) + wrong;
      userStats['totalSkipped'] = (userStats['totalSkipped'] as int) + skipped;
        userStats['successWeightedSum'] =
          (userStats['successWeightedSum'] as double) +
            (interviewSuccessPercent * interviewWeight);
        userStats['successWeight'] =
          (userStats['successWeight'] as double) + interviewWeight;
        userStats['accuracySum'] = (userStats['accuracySum'] as double) + accuracyPercent;

      final lastInterviewAt = userStats['lastInterviewAt'] as DateTime;
      if (endedAt.isAfter(lastInterviewAt)) {
        userStats['lastInterviewAt'] = endedAt;
      }
    }

    final leaderboard = usersSnapshot.docs.map((doc) {
      final data = doc.data();
      final userId = doc.id;
      final stats = statsByUser[userId] ??
          <String, dynamic>{
            'totalInterviews': 0,
            'totalAnswered': 0,
            'totalWrong': 0,
            'totalSkipped': 0,
            'successWeightedSum': 0.0,
            'successWeight': 0.0,
            'accuracySum': 0.0,
            'lastInterviewAt': DateTime.fromMillisecondsSinceEpoch(0),
          };

      final totalInterviews = stats['totalInterviews'] as int;
      final totalAnswered = stats['totalAnswered'] as int;
      final totalWrong = stats['totalWrong'] as int;
      final totalSkipped = stats['totalSkipped'] as int;
      final successWeightedSum = stats['successWeightedSum'] as double;
      final successWeight = stats['successWeight'] as double;
      final accuracySum = stats['accuracySum'] as double;
      final lastInterviewAt = stats['lastInterviewAt'] as DateTime;

      final successRate = successWeight > 0 ? successWeightedSum / successWeight : 0.0;
      final averageAccuracy = totalInterviews > 0 ? accuracySum / totalInterviews : 0.0;

      return AdminUserPerformance(
        userId: userId,
        name: data['name']?.toString() ?? 'Unknown User',
        email: data['email']?.toString() ?? '',
        role: data['role']?.toString() ?? 'user',
        currentStreak: toInt(data['currentStreak']),
        totalInterviews: totalInterviews,
        totalAnswered: totalAnswered,
        totalWrong: totalWrong,
        totalSkipped: totalSkipped,
        successRate: successRate,
        averageAccuracy: averageAccuracy,
        lastInterviewAt: lastInterviewAt,
      );
    }).toList();

    leaderboard.sort((a, b) {
      final bySuccessRate = b.successRate.compareTo(a.successRate);
      if (bySuccessRate != 0) return bySuccessRate;

      final byInterviewCount = b.totalInterviews.compareTo(a.totalInterviews);
      if (byInterviewCount != 0) return byInterviewCount;

      final byAccuracy = b.averageAccuracy.compareTo(a.averageAccuracy);
      if (byAccuracy != 0) return byAccuracy;

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return leaderboard;
  }

  Future<List<MockInterview>> fetchInterviews() async {
    final snapshot = await _firestore.collection('interviews').get();
    return snapshot.docs.map((d) => MockInterview.fromMap(d.id, d.data())).toList();
  }

  Future<List<MockInterview>> fetchInterviewsByUser(String userId) async {
    final snapshot = await _firestore
        .collection('interviews')
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs.map((d) => MockInterview.fromMap(d.id, d.data())).toList();
  }

  Future<MockInterview?> fetchInterviewById(String interviewId) async {
    final doc = await _firestore.collection('interviews').doc(interviewId).get();
    if (!doc.exists || doc.data() == null) return null;
    return MockInterview.fromMap(doc.id, doc.data()!);
  }

  Future<List<MockAttempt>> fetchAttempts(String interviewId) async {
    final snapshot = await _firestore
        .collection('interviews')
        .doc(interviewId)
        .collection('attempts')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((d) => MockAttempt.fromMap(d.id, d.data())).toList();
  }

  Future<List<AdminResourceItem>> fetchResources() async {
    final snapshot = await _firestore
        .collection('resources')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((d) => AdminResourceItem.fromMap(d.id, d.data())).toList();
  }

  Future<void> addResource({
    required String title,
    required String description,
    required String url,
  }) async {
    await _firestore.collection('resources').add(<String, dynamic>{
      'title': title,
      'description': description,
      'url': url,
      'isVisible': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _adminId,
    });
    await addLog(action: 'resource_create', details: 'Created resource: $title');
  }

  Future<void> updateResourceVisibility(String id, bool isVisible) async {
    await _firestore.collection('resources').doc(id).set(<String, dynamic>{
      'isVisible': isVisible,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _adminId,
    }, SetOptions(merge: true));
    await addLog(action: 'resource_visibility', details: 'Updated resource $id visibility to $isVisible');
  }

  Future<void> deleteResource(String id) async {
    await _firestore.collection('resources').doc(id).delete();
    await addLog(action: 'resource_delete', details: 'Deleted resource: $id');
  }

  Future<List<AdminJobItem>> fetchJobSuggestions() async {
    final snapshot = await _firestore
        .collection('job_suggestions')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((d) => AdminJobItem.fromMap(d.id, d.data())).toList();
  }

  Future<void> addJobSuggestion({
    required String title,
    required String description,
  }) async {
    await _firestore.collection('job_suggestions').add(<String, dynamic>{
      'title': title,
      'description': description,
      'published': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _adminId,
    });
    await addLog(action: 'job_create', details: 'Created job suggestion: $title');
  }

  Future<void> updateJobPublishState(String id, bool published) async {
    await _firestore.collection('job_suggestions').doc(id).set(<String, dynamic>{
      'published': published,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _adminId,
    }, SetOptions(merge: true));
    await addLog(action: 'job_publish', details: 'Updated job $id publish state to $published');
  }

  Future<void> deleteJobSuggestion(String id) async {
    await _firestore.collection('job_suggestions').doc(id).delete();
    await addLog(action: 'job_delete', details: 'Deleted job suggestion: $id');
  }

  Future<List<AdminSupportTicket>> fetchSupportTickets() async {
    final snapshot = await _firestore
        .collection('support_tickets')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((d) => AdminSupportTicket.fromMap(d.id, d.data())).toList();
  }

  Future<void> replySupportTicket({
    required String ticketId,
    required String reply,
  }) async {
    await _firestore.collection('support_tickets').doc(ticketId).set(<String, dynamic>{
      'adminReply': reply,
      'status': 'resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
      'resolvedBy': _adminId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await addLog(action: 'support_reply', details: 'Resolved ticket: $ticketId');
  }

  Future<List<AdminNotificationItem>> fetchNotifications() async {
    final snapshot = await _firestore
        .collection('admin_notifications')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((d) => AdminNotificationItem.fromMap(d.id, d.data())).toList();
  }

  Future<void> createNotification({
    required String title,
    required String message,
    required String audience,
  }) async {
    await _firestore.collection('admin_notifications').add(<String, dynamic>{
      'title': title,
      'message': message,
      'audience': audience,
      'status': 'sent',
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': _adminId,
    });
    await addLog(action: 'notification_send', details: 'Sent notification: $title to $audience');
  }

  Future<List<AdminLogItem>> fetchAdminLogs() async {
    final snapshot = await _firestore
        .collection('admin_activity_logs')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();
    return snapshot.docs.map((d) => AdminLogItem.fromMap(d.id, d.data())).toList();
  }

  Future<void> addLog({required String action, required String details}) async {
    if (_adminId.isEmpty) return;
    try {
      await _firestore.collection('admin_activity_logs').add(<String, dynamic>{
        'action': action,
        'details': details,
        'adminId': _adminId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      log('Failed to write admin log: $e', name: 'AdminDataService');
    }
  }

  Future<AdminSettings> fetchAdminSettings() async {
    final doc = await _firestore.collection('admin_settings').doc('global').get();
    if (!doc.exists || doc.data() == null) {
      return AdminSettings.defaults();
    }
    return AdminSettings.fromMap(doc.data()!);
  }

  Future<void> saveAdminSettings(AdminSettings settings) async {
    await _firestore
        .collection('admin_settings')
        .doc('global')
        .set(settings.toMap(), SetOptions(merge: true));
    await addLog(action: 'settings_update', details: 'Updated admin settings');
  }
}
