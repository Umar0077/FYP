import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StreakData {
  final int currentStreak;
  final int longestStreak;
  final String? lastPracticeDate;

  StreakData({
    required this.currentStreak,
    required this.longestStreak,
    this.lastPracticeDate,
  });

  bool get practicedToday {
    if (lastPracticeDate == null) return false;
    final lastDate = DateTime.parse(lastPracticeDate!);
    final today = DateTime.now();
    return lastDate.year == today.year && 
           lastDate.month == today.month && 
           lastDate.day == today.day;
  }
}

class StreakService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Record that the user practiced today and update their streak
  static Future<void> recordPracticeToday() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final today = DateTime.now();
    final todayDateString = _formatDate(today);
    
    try {
      final docRef = _firestore.collection('users').doc(uid);
      
      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(docRef);
        
        Map<String, dynamic> userData = userDoc.data() ?? {};
        
        // Get current streak data
        int currentStreak = userData['currentStreak'] ?? 0;
        int longestStreak = userData['longestStreak'] ?? 0;
        String? lastPracticeDate = userData['lastPracticeDate'];
        List<dynamic> practiceDates = userData['practiceDates'] ?? [];
        
        // Convert practice dates to strings for comparison
        List<String> practiceDateStrings = practiceDates.cast<String>();
        
        // Check if user already practiced today
        if (practiceDateStrings.contains(todayDateString)) {
          // Already practiced today, no need to update streak
          return;
        }
        
        // Add today to practice dates
        practiceDateStrings.add(todayDateString);
        
        // Calculate new streak
        if (lastPracticeDate == null) {
          // First time practicing
          currentStreak = 1;
        } else {
          final lastDate = DateTime.parse(lastPracticeDate);
          final yesterday = today.subtract(const Duration(days: 1));
          
          if (_isSameDay(lastDate, yesterday)) {
            // Practiced yesterday, continue streak
            currentStreak += 1;
          } else if (_isSameDay(lastDate, today)) {
            // Already practiced today (shouldn't happen due to check above)
            return;
          } else {
            // Broke the streak, start new one
            currentStreak = 1;
          }
        }
        
        // Update longest streak if needed
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }
        
        // Update user document
        transaction.update(docRef, {
          'currentStreak': currentStreak,
          'longestStreak': longestStreak,
          'lastPracticeDate': todayDateString,
          'practiceDates': practiceDateStrings,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      print('Error updating streak: $e');
    }
  }

  /// Get the current streak for the logged-in user
  static Future<StreakData> getCurrentStreak() async {
    final user = _auth.currentUser;
    if (user == null) {
      return StreakData(currentStreak: 0, longestStreak: 0, lastPracticeDate: null);
    }

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data() ?? {};
      
      int currentStreak = data['currentStreak'] ?? 0;
      int longestStreak = data['longestStreak'] ?? 0;
      String? lastPracticeDate = data['lastPracticeDate'];
      
      // Check if streak is still valid (practiced yesterday or today)
      if (lastPracticeDate != null) {
        final lastDate = DateTime.parse(lastPracticeDate);
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        
        if (!_isSameDay(lastDate, today) && !_isSameDay(lastDate, yesterday)) {
          // Streak is broken, reset to 0
          currentStreak = 0;
          // Update the document to reflect broken streak
          await _firestore.collection('users').doc(user.uid).update({
            'currentStreak': 0,
          });
        }
      }
      
      return StreakData(
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        lastPracticeDate: lastPracticeDate,
      );
    } catch (e) {
      print('Error getting streak: $e');
      return StreakData(currentStreak: 0, longestStreak: 0, lastPracticeDate: null);
    }
  }

  /// Stream of streak data for real-time updates
  static Stream<StreakData> getStreakStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(StreakData(currentStreak: 0, longestStreak: 0, lastPracticeDate: null));
    }

    return _firestore.collection('users').doc(user.uid).snapshots().map((doc) {
      final data = doc.data() ?? {};
      int currentStreak = data['currentStreak'] ?? 0;
      int longestStreak = data['longestStreak'] ?? 0;
      String? lastPracticeDate = data['lastPracticeDate'];
      
      return StreakData(
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        lastPracticeDate: lastPracticeDate,
      );
    });
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}