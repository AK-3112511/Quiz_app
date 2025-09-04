// lib/data/quiz_session_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Quiz_app/data/quiz_session.dart';
import 'package:Quiz_app/data/quiz_data.dart';
import 'dart:math';

class QuizSessionService {
  static const String SESSIONS_COLLECTION = 'quiz_sessions';
  static const String USERS_COLLECTION = 'session_users';
  static const String ANSWERS_COLLECTION = 'user_answers';
  
  static const int QUESTION_DURATION = 15; // seconds
  static const int LEADERBOARD_DURATION = 8; // seconds

  // Create or join a quiz session for a specific language
  static Future<String> createOrJoinSession(String language, String userId, String userName) async {
    try {
      // Look for an active session for this language that's in waiting phase
      final existingSessionQuery = await FirebaseFirestore.instance
          .collection(SESSIONS_COLLECTION)
          .where('language', isEqualTo: language.toLowerCase())
          .where('isActive', isEqualTo: true)
          .where('phase', isEqualTo: 'waiting')
          .limit(1)
          .get();

      String sessionId;
      
      if (existingSessionQuery.docs.isNotEmpty) {
        // Join existing session
        sessionId = existingSessionQuery.docs.first.id;
      } else {
        // Create new session
        sessionId = await _createNewSession(language);
      }

      // Add user to session
      await _addUserToSession(sessionId, userId, userName);
      
      return sessionId;
    } catch (e) {
      print('Error creating/joining session: $e');
      throw e;
    }
  }

  // Create a new quiz session
  static Future<String> _createNewSession(String language) async {
    // Generate random question order
    final questions = QuizData.getQuestionsByLanguage(language);
    final questionOrder = List.generate(questions.length, (index) => index);
    questionOrder.shuffle(Random());
    
    final session = QuizSession(
      sessionId: '',
      language: language.toLowerCase(),
      currentQuestionIndex: 0,
      phase: 'waiting',
      totalQuestions: questions.length,
      isActive: true,
      questionOrder: questionOrder,
    );

    final docRef = await FirebaseFirestore.instance
        .collection(SESSIONS_COLLECTION)
        .add(session.toFirestore());
    
    return docRef.id;
  }

  // Add user to session
  static Future<void> _addUserToSession(String sessionId, String userId, String userName) async {
    await FirebaseFirestore.instance
        .collection(USERS_COLLECTION)
        .doc('${sessionId}_$userId')
        .set({
      'sessionId': sessionId,
      'userId': userId,
      'userName': userName,
      'score': 0,
      'answeredQuestions': 0,
      'isActive': true,
      'joinedAt': FieldValue.serverTimestamp(),
    });
  }

  // Start quiz session (call this manually or with a timer)
  static Future<void> startQuizSession(String sessionId) async {
    await FirebaseFirestore.instance
        .collection(SESSIONS_COLLECTION)
        .doc(sessionId)
        .update({
      'phase': 'question',
      'questionStartTime': FieldValue.serverTimestamp(),
    });
  }

  // Submit user answer
  static Future<void> submitAnswer(
    String sessionId,
    String userId,
    int questionIndex,
    int selectedAnswer,
    DateTime questionStartTime,
  ) async {
    try {
      final session = await getSession(sessionId);
      if (session == null) return;

      final questions = QuizData.getQuestionsByLanguage(session.language);
      final actualQuestionIndex = session.questionOrder[questionIndex];
      final question = questions[actualQuestionIndex];
      
      final isCorrect = selectedAnswer == question['correct'];
      final timeToAnswer = DateTime.now().difference(questionStartTime).inSeconds;
      
      // Save user answer
      final userAnswer = UserAnswer(
        userId: userId,
        sessionId: sessionId,
        questionIndex: questionIndex,
        selectedAnswer: selectedAnswer,
        isCorrect: isCorrect,
        answeredAt: DateTime.now(),
        timeToAnswer: timeToAnswer,
      );

      await FirebaseFirestore.instance
          .collection(ANSWERS_COLLECTION)
          .add(userAnswer.toFirestore());

      // Update user score and progress
      final userDocId = '${sessionId}_$userId';
      final userDoc = await FirebaseFirestore.instance
          .collection(USERS_COLLECTION)
          .doc(userDocId)
          .get();

      if (userDoc.exists) {
        final currentScore = userDoc.data()?['score'] ?? 0;
        final answeredQuestions = userDoc.data()?['answeredQuestions'] ?? 0;
        
        await FirebaseFirestore.instance
            .collection(USERS_COLLECTION)
            .doc(userDocId)
            .update({
          'score': isCorrect ? currentScore + 1 : currentScore,
          'answeredQuestions': answeredQuestions + 1,
          'lastAnsweredAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error submitting answer: $e');
    }
  }

  // Move to leaderboard phase
  static Future<void> moveToLeaderboard(String sessionId) async {
    await FirebaseFirestore.instance
        .collection(SESSIONS_COLLECTION)
        .doc(sessionId)
        .update({
      'phase': 'leaderboard',
      'leaderboardStartTime': FieldValue.serverTimestamp(),
    });
  }

  // Move to next question
  static Future<void> moveToNextQuestion(String sessionId) async {
    final session = await getSession(sessionId);
    if (session == null) return;

    final nextQuestionIndex = session.currentQuestionIndex + 1;
    
    if (nextQuestionIndex >= session.totalQuestions) {
      // Quiz completed
      await FirebaseFirestore.instance
          .collection(SESSIONS_COLLECTION)
          .doc(sessionId)
          .update({
        'phase': 'completed',
        'isActive': false,
      });
    } else {
      // Next question
      await FirebaseFirestore.instance
          .collection(SESSIONS_COLLECTION)
          .doc(sessionId)
          .update({
        'currentQuestionIndex': nextQuestionIndex,
        'phase': 'question',
        'questionStartTime': FieldValue.serverTimestamp(),
      });
    }
  }

  // Get session data
  static Future<QuizSession?> getSession(String sessionId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(SESSIONS_COLLECTION)
          .doc(sessionId)
          .get();
      
      if (doc.exists) {
        return QuizSession.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting session: $e');
      return null;
    }
  }

  // Listen to session changes
  static Stream<QuizSession?> sessionStream(String sessionId) {
    return FirebaseFirestore.instance
        .collection(SESSIONS_COLLECTION)
        .doc(sessionId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return QuizSession.fromFirestore(doc);
      }
      return null;
    });
  }

  // Get current leaderboard for session
  static Stream<QuerySnapshot> getSessionLeaderboard(String sessionId) {
    return FirebaseFirestore.instance
        .collection(USERS_COLLECTION)
        .where('sessionId', isEqualTo: sessionId)
        .where('isActive', isEqualTo: true)
        .orderBy('score', descending: true)
        .orderBy('lastAnsweredAt', descending: false)
        .limit(10)
        .snapshots();
  }

  // Get user's answer for a specific question
  static Future<UserAnswer?> getUserAnswer(String sessionId, String userId, int questionIndex) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection(ANSWERS_COLLECTION)
          .where('sessionId', isEqualTo: sessionId)
          .where('userId', isEqualTo: userId)
          .where('questionIndex', isEqualTo: questionIndex)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return UserAnswer.fromFirestore(query.docs.first);
      }
      return null;
    } catch (e) {
      print('Error getting user answer: $e');
      return null;
    }
  }

  // Get user data from session
  static Future<Map<String, dynamic>?> getSessionUserData(String sessionId, String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(USERS_COLLECTION)
          .doc('${sessionId}_$userId')
          .get();
      
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('Error getting session user data: $e');
      return null;
    }
  }

  // Session management - these would typically be called by Cloud Functions or admin
  static Future<void> processSessionTiming(String sessionId) async {
    final session = await getSession(sessionId);
    if (session == null || !session.isActive) return;

    final now = DateTime.now();

    switch (session.phase) {
      case 'question':
        if (session.questionStartTime != null) {
          final questionElapsed = now.difference(session.questionStartTime!).inSeconds;
          if (questionElapsed >= QUESTION_DURATION) {
            await moveToLeaderboard(sessionId);
          }
        }
        break;

      case 'leaderboard':
        if (session.leaderboardStartTime != null) {
          final leaderboardElapsed = now.difference(session.leaderboardStartTime!).inSeconds;
          if (leaderboardElapsed >= LEADERBOARD_DURATION) {
            await moveToNextQuestion(sessionId);
          }
        }
        break;
    }
  }
}
