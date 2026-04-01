import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for fetching interview statistics and session data
/// All Firestore logic is encapsulated here
class InterviewStatsService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get stats stream for the current user
  Stream<InterviewStats> getStatsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(InterviewStats.empty());
    }

    return _firestore
        .collection('interviews')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .asyncMap((snapshot) async {
      final completedDocs = snapshot.docs.where((doc) {
        final data = doc.data();
        return data['status'] == 'completed';
      }).toList();
      
      return await _computeStats(completedDocs);
    });
  }

  /// Compute statistics from interview documents
  Future<InterviewStats> _computeStats(List<QueryDocumentSnapshot> docs) async {
    if (docs.isEmpty) {
      return InterviewStats.empty();
    }

    int totalInterviews = docs.length;
    List<double> scores = [];
    int successfulInterviews = 0;
    double successThreshold = 50.0; // default threshold lowered to 50%

    // Get user's custom threshold if it exists
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists && userDoc.data()?['successThreshold'] != null) {
          successThreshold = (userDoc.data()!['successThreshold'] as num).toDouble();
        }
      } catch (e) {
        // Use default threshold
      }
    }

    // Process each interview
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      double? sessionScore = await _getSessionScore(doc.id, data);
      
      if (sessionScore != null) {
        scores.add(sessionScore);
        if (sessionScore >= successThreshold) {
          successfulInterviews++;
        }
      }
    }

    // Calculate metrics
    double averageScore = scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length;
    double successRate = scores.isEmpty ? 0.0 : (successfulInterviews / scores.length) * 100;
    double skillImprovement = _calculateSkillImprovement(docs, scores);

    return InterviewStats(
      interviewsCompleted: totalInterviews,
      averageScore: averageScore.round(),
      successRate: successRate,
      skillImprovement: skillImprovement,
    );
  }

  /// Get score for a single interview session
  Future<double?> _getSessionScore(String interviewId, Map<String, dynamic> data) async {
    try {
      if (data['overallScore'] != null) {
        return (data['overallScore'] as num).toDouble();
      }

      if (data['avgAccuracy'] != null) {
        return (data['avgAccuracy'] as num).toDouble();
      }

      final attemptsSnapshot = await _firestore
          .collection('interviews')
          .doc(interviewId)
          .collection('attempts')
          .where('status', isEqualTo: 'answered')
          .get();

      if (attemptsSnapshot.docs.isEmpty) {
        return null;
      }

      List<double> answerScores = [];
      
      for (var attempt in attemptsSnapshot.docs) {
        final attemptData = attempt.data();
        
        if (attemptData['accuracyScore'] != null) {
          answerScores.add((attemptData['accuracyScore'] as num).toDouble());
        }
      }

      if (answerScores.isEmpty) {
        return null;
      }

      return answerScores.reduce((a, b) => a + b) / answerScores.length;
    } catch (e) {
      print('Error computing session score: $e');
      return null;
    }
  }

  /// Calculate skill improvement by comparing recent vs older sessions
  double _calculateSkillImprovement(List<QueryDocumentSnapshot> docs, List<double> scores) {
    if (docs.length < 2 || scores.length < 2) {
      return 0.5;
    }

    final sortedDocs = List<QueryDocumentSnapshot>.from(docs);
    sortedDocs.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      final aTime = aData['startedAt'] as Timestamp?;
      final bTime = bData['startedAt'] as Timestamp?;
      if (aTime == null || bTime == null) return 0;
      return aTime.compareTo(bTime);
    });

    final midpoint = sortedDocs.length ~/ 2;
    List<double> olderScores = [];
    List<double> newerScores = [];

    for (int i = 0; i < scores.length; i++) {
      if (i < midpoint) {
        olderScores.add(scores[i]);
      } else {
        newerScores.add(scores[i]);
      }
    }

    if (olderScores.isEmpty || newerScores.isEmpty) {
      return 0.5;
    }

    final olderAvg = olderScores.reduce((a, b) => a + b) / olderScores.length;
    final newerAvg = newerScores.reduce((a, b) => a + b) / newerScores.length;

    final difference = newerAvg - olderAvg;
    final normalized = 0.5 + (difference / 100.0);
    
    return normalized.clamp(0.0, 1.0);
  }

  /// Get recent interviews ordered by date
  Stream<List<InterviewSession>> getRecentInterviewsStream({int limit = 20}) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('interviews')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .asyncMap((snapshot) async {
      final completedDocs = snapshot.docs.where((doc) {
        final data = doc.data();
        return data['status'] == 'completed';
      }).toList();

      completedDocs.sort((a, b) {
        final aData = a.data();
        final bData = b.data();
        final aTime = aData['startedAt'] as Timestamp?;
        final bTime = bData['startedAt'] as Timestamp?;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      final limitedDocs = completedDocs.take(limit).toList();
      List<InterviewSession> sessions = [];
      
      for (var doc in limitedDocs) {
        final data = doc.data();
        final score = await _getSessionScore(doc.id, data);
        
        if (score != null) {
          sessions.add(InterviewSession(
            id: doc.id,
            title: data['title'] as String? ?? 'Interview Session',
            dateTime: (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            score: score.round(),
          ));
        }
      }
      
      return sessions;
    });
  }
}

/// Data class for interview statistics
class InterviewStats {
  final int interviewsCompleted;
  final int averageScore;
  final double successRate;
  final double skillImprovement;

  InterviewStats({
    required this.interviewsCompleted,
    required this.averageScore,
    required this.successRate,
    required this.skillImprovement,
  });

  factory InterviewStats.empty() {
    return InterviewStats(
      interviewsCompleted: 0,
      averageScore: 0,
      successRate: 0.0,
      skillImprovement: 0.0,
    );
  }
}

/// Data class for individual interview session
class InterviewSession {
  final String id;
  final String title;
  final DateTime dateTime;
  final int score;

  InterviewSession({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.score,
  });
}
