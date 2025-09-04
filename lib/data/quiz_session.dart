// lib/data/quiz_session.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class QuizSession {
  final String sessionId;
  final String language;
  final int currentQuestionIndex;
  final String phase; // 'waiting', 'question', 'leaderboard', 'completed'
  final DateTime? questionStartTime;
  final DateTime? leaderboardStartTime;
  final int totalQuestions;
  final bool isActive;
  final List<int> questionOrder;

  QuizSession({
    required this.sessionId,
    required this.language,
    required this.currentQuestionIndex,
    required this.phase,
    this.questionStartTime,
    this.leaderboardStartTime,
    required this.totalQuestions,
    required this.isActive,
    required this.questionOrder,
  });

  factory QuizSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return QuizSession(
      sessionId: doc.id,
      language: data['language'] ?? '',
      currentQuestionIndex: data['currentQuestionIndex'] ?? 0,
      phase: data['phase'] ?? 'waiting',
      questionStartTime: (data['questionStartTime'] as Timestamp?)?.toDate(),
      leaderboardStartTime: (data['leaderboardStartTime'] as Timestamp?)?.toDate(),
      totalQuestions: data['totalQuestions'] ?? 15,
      isActive: data['isActive'] ?? false,
      questionOrder: List<int>.from(data['questionOrder'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'language': language,
      'currentQuestionIndex': currentQuestionIndex,
      'phase': phase,
      'questionStartTime': questionStartTime != null ? Timestamp.fromDate(questionStartTime!) : null,
      'leaderboardStartTime': leaderboardStartTime != null ? Timestamp.fromDate(leaderboardStartTime!) : null,
      'totalQuestions': totalQuestions,
      'isActive': isActive,
      'questionOrder': questionOrder,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  QuizSession copyWith({
    String? sessionId,
    String? language,
    int? currentQuestionIndex,
    String? phase,
    DateTime? questionStartTime,
    DateTime? leaderboardStartTime,
    int? totalQuestions,
    bool? isActive,
    List<int>? questionOrder,
  }) {
    return QuizSession(
      sessionId: sessionId ?? this.sessionId,
      language: language ?? this.language,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      phase: phase ?? this.phase,
      questionStartTime: questionStartTime ?? this.questionStartTime,
      leaderboardStartTime: leaderboardStartTime ?? this.leaderboardStartTime,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      isActive: isActive ?? this.isActive,
      questionOrder: questionOrder ?? this.questionOrder,
    );
  }
}

class UserAnswer {
  final String userId;
  final String sessionId;
  final int questionIndex;
  final int selectedAnswer;
  final bool isCorrect;
  final DateTime answeredAt;
  final int timeToAnswer; // in seconds

  UserAnswer({
    required this.userId,
    required this.sessionId,
    required this.questionIndex,
    required this.selectedAnswer,
    required this.isCorrect,
    required this.answeredAt,
    required this.timeToAnswer,
  });

  factory UserAnswer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserAnswer(
      userId: data['userId'] ?? '',
      sessionId: data['sessionId'] ?? '',
      questionIndex: data['questionIndex'] ?? 0,
      selectedAnswer: data['selectedAnswer'] ?? -1,
      isCorrect: data['isCorrect'] ?? false,
      answeredAt: (data['answeredAt'] as Timestamp).toDate(),
      timeToAnswer: data['timeToAnswer'] ?? 15,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'sessionId': sessionId,
      'questionIndex': questionIndex,
      'selectedAnswer': selectedAnswer,
      'isCorrect': isCorrect,
      'answeredAt': Timestamp.fromDate(answeredAt),
      'timeToAnswer': timeToAnswer,
    };
  }
}
