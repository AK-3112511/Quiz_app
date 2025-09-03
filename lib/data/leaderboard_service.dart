// lib/services/leaderboard_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardServices {
  static Future<void> updateScore(String uid, String name, int score) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('leaderboard').doc(uid);

      // Get current data to check if we should update
      final currentDoc = await docRef.get();
      
      if (currentDoc.exists) {
        final currentScore = currentDoc.data()?['score'] ?? 0;
        // Only update if new score is higher
        if (score > currentScore) {
          await docRef.update({
            'score': score,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      } else {
        // Create new document for first-time user
        await docRef.set({
          'uid': uid,
          'name': name,
          'score': score,
          'lastUpdated': FieldValue.serverTimestamp(),
          'answered': 0, // Track total questions answered
        });
      }
    } catch (e) {
      print('Error updating score: $e');
      throw e;
    }
  }

  static Future<void> incrementAnswered(String uid) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('leaderboard').doc(uid);
      
      await docRef.update({
        'answered': FieldValue.increment(1),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error incrementing answered count: $e');
    }
  }

  static Stream<QuerySnapshot> getTopPlayers(int limit) {
    return FirebaseFirestore.instance
        .collection('leaderboard')
        .orderBy('score', descending: true)
        .limit(limit)
        .snapshots();
  }

  static Future<int> getUserRank(String uid) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('leaderboard')
          .orderBy('score', descending: true)
          .get();

      final docs = snapshot.docs;
      final rank = docs.indexWhere((d) => d['uid'] == uid);
      return rank == -1 ? -1 : rank + 1;
    } catch (e) {
      print('Error getting user rank: $e');
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

  static Stream<QuerySnapshot> getAllPlayersStream() {
    return FirebaseFirestore.instance
        .collection('leaderboard')
        .orderBy('score', descending: true)
        .snapshots();
  }

  static Future<List<Map<String, dynamic>>> getTopPlayersOnce(int limit) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('leaderboard')
          .orderBy('score', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting top players: $e');
      return [];
    }
  }

  static Future<void> resetUserScore(String uid) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('leaderboard').doc(uid);
      
      await docRef.update({
        'score': 0,
        'answered': 0,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error resetting user score: $e');
    }
  }
}