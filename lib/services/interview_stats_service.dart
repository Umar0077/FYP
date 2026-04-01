import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InterviewStatsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream that provides real-time interview statistics
  static Stream<InterviewStats> getStatsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(InterviewStats.empty());
    }

    return _firestore
        .collection('interviews')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .asyncMap((snapshot) {
          // Filter completed interviews client-side to avoid composite index requirement
          final completedDocs = snapshot.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == 'completed';
          }).toList();
          return _computeStats(completedDocs);
        });
  }

  /// Compute statistics from interview documents
  static Future<InterviewStats> _computeStats(List<QueryDocumentSnapshot> docs) async {
    if (docs.isEmpty) {
      return InterviewStats.empty();
    }

    int totalInterviews = docs.length;
    List<double> scores = [];
    int successfulInterviews = 0;
    double successThreshold = 50.0; // Default threshold lowered to 50%

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
  static Future<double?> _getSessionScore(String interviewId, Map<String, dynamic> data) async {
    // First, try to get overallScore from the interview document
    if (data['overallScore'] != null) {
      return (data['overallScore'] as num).toDouble();
    }

    // If avgAccuracy exists, use that (this is what completeInterview sets)
    if (data['avgAccuracy'] != null) {
      return (data['avgAccuracy'] as num).toDouble();
    }

    // Otherwise, compute from attempts
    try {
      final attemptsSnapshot = await _firestore
          .collection('interviews')
          .doc(interviewId)
          .collection('attempts')
          .where('status', isEqualTo: 'answered')
          .get();

      if (attemptsSnapshot.docs.isEmpty) {
        return null; // No valid answers
      }

      // Try to get scores from answerScores array if it exists
      List<double> answerScores = [];
      
      for (var attempt in attemptsSnapshot.docs) {
        final attemptData = attempt.data();
        
        // Check if accuracyScore exists
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
  static double _calculateSkillImprovement(List<QueryDocumentSnapshot> docs, List<double> scores) {
    if (docs.length < 2 || scores.length < 2) {
      return 0.5; // Neutral improvement if not enough data
    }

    // Sort documents by date
    final sortedDocs = List<QueryDocumentSnapshot>.from(docs);
    sortedDocs.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      final aTime = aData['startedAt'] as Timestamp?;
      final bTime = bData['startedAt'] as Timestamp?;
      if (aTime == null || bTime == null) return 0;
      return aTime.compareTo(bTime);
    });

    // Split into older and newer halves
    final midpoint = sortedDocs.length ~/ 2;
    final olderHalf = sortedDocs.sublist(0, midpoint);
    final newerHalf = sortedDocs.sublist(midpoint);

    // Get corresponding scores
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

    // Calculate improvement
    // If newer is better, improvement is positive
    // Normalize between 0 and 1, where 0.5 is no change
    final difference = newerAvg - olderAvg;
    
    // Map difference to 0-1 range
    // -50 to +50 point difference maps to 0 to 1
    final normalized = 0.5 + (difference / 100.0);
    
    // Clamp to 0-1 range
    return normalized.clamp(0.0, 1.0);
  }

  /// Get recent interviews ordered by date
  static Stream<List<InterviewSession>> getRecentInterviewsStream({int limit = 20}) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('interviews')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .asyncMap((snapshot) async {
      // Filter and sort client-side to avoid composite index requirement
      final completedDocs = snapshot.docs.where((doc) {
        final data = doc.data();
        return data['status'] == 'completed';
      }).toList();

      // Sort by startedAt descending
      completedDocs.sort((a, b) {
        final aData = a.data();
        final bData = b.data();
        final aTime = aData['startedAt'] as Timestamp?;
        final bTime = bData['startedAt'] as Timestamp?;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime); // Descending
      });

      // Apply limit
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
  final double skillImprovement; // 0.0 to 1.0

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
