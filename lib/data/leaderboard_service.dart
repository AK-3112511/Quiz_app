// lib/data/leaderboard_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardServices {
  // Initialize user when they start the quiz
  static Future<void> initializeUser(String uid, String name) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('leaderboard').doc(uid);
      
      // Check if user already exists to avoid overwriting progress
      final doc = await docRef.get();
      
      if (!doc.exists || doc.data()?['isActive'] != true) {
        // Initialize new user or reactivate existing user
        await docRef.set({
          'uid': uid,
          'name': name,
          'score': 0,
          'lastUpdated': FieldValue.serverTimestamp(),
          'answered': 0,
          'isActive': true, // User is actively taking quiz
          'isCompleted': false, // User hasn't completed quiz yet
          'currentQuestion': 0,
          'startedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error initializing user: $e');
      // Don't throw error, allow quiz to continue even if Firebase fails
    }
  }

  // Update user progress when they answer a question
  static Future<void> updateUserProgress(String uid, String name, int score, int currentQuestion) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('leaderboard').doc(uid);

      await docRef.set({
        'uid': uid,
        'name': name,
        'score': score,
        'currentQuestion': currentQuestion,
        'lastUpdated': FieldValue.serverTimestamp(),
        'isActive': true, // Still active during quiz
        'isCompleted': false, // Still in progress
        'answered': currentQuestion,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating user progress: $e');
      // Don't throw error, continue quiz even if Firebase update fails
    }
  }

  // Mark user as completed when they finish the quiz
  static Future<void> markUserCompleted(String uid, int finalScore) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('leaderboard').doc(uid);
      
      await docRef.update({
        'isCompleted': true, // Quiz completed
        'finalScore': finalScore,
        'completedAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'score': finalScore, // Make sure final score is updated
        // Keep isActive true so they show in leaderboards
      });
    } catch (e) {
      print('Error marking user completed: $e');
    }
  }

  // Get top players for dynamic leaderboard (during quiz)
  static Stream<QuerySnapshot> getTopPlayers(int limit) {
    return FirebaseFirestore.instance
        .collection('leaderboard')
        .where('isActive', isEqualTo: true) // Active participants
        .orderBy('score', descending: true)
        .orderBy('lastUpdated', descending: false) // Earlier timestamp wins in case of tie
        .limit(limit)
        .snapshots();
  }

  // Get all active participants for counting
  static Stream<QuerySnapshot> getAllActiveParticipants() {
    return FirebaseFirestore.instance
        .collection('leaderboard')
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  // Get final leaderboard (all participants who participated) - shows top 10
  static Stream<QuerySnapshot> getFinalLeaderboard() {
    return FirebaseFirestore.instance
        .collection('leaderboard')
        .orderBy('score', descending: true)
        .orderBy('lastUpdated', descending: false)
        .limit(10) // Only show top 10 in final leaderboard
        .snapshots();
  }

  static Future<int> getUserRank(String uid) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('leaderboard')
          .where('isActive', isEqualTo: true)
          .orderBy('score', descending: true)
          .orderBy('lastUpdated', descending: false)
          .get();

      final docs = snapshot.docs;
      for (int i = 0; i < docs.length; i++) {
        if (docs[i]['uid'] == uid) {
          return i + 1;
        }
      }
      return -1;
    } catch (e) {
      print('Error getting user rank: $e');
      return -1;
    }
  }

  static Future<int> getFinalUserRank(String uid) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('leaderboard')
          .orderBy('score', descending: true)
          .orderBy('lastUpdated', descending: false)
          .get();

      final docs = snapshot.docs;
      for (int i = 0; i < docs.length; i++) {
        if (docs[i]['uid'] == uid) {
          return i + 1;
        }
      }
      return -1;
    } catch (e) {
      print('Error getting final user rank: $e');
      return -1;
    }
  }

  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('leaderboard')
          .doc(uid)
          .get();
      
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Reset user for new quiz attempt
  static Future<void> resetUserForNewQuiz(String uid, String name) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('leaderboard').doc(uid);
      
      await docRef.set({
        'uid': uid,
        'name': name,
        'score': 0,
        'answered': 0,
        'currentQuestion': 0,
        'isActive': true,
        'isCompleted': false,
        'lastUpdated': FieldValue.serverTimestamp(),
        'startedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error resetting user for new quiz: $e');
    }
  }

  // Get total active participants count
  static Future<int> getActiveParticipantsCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('leaderboard')
          .where('isActive', isEqualTo: true)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting active participants count: $e');
      return 0;
    }
  }
}