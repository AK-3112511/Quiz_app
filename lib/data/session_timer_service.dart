// lib/data/session_timer_service.dart

import 'dart:async';
import 'package:Quiz_app/data/quiz_session_service.dart';
import 'package:Quiz_app/data/quiz_session.dart';

class SessionTimerService {
  static final Map<String, Timer> _sessionTimers = {};
  static final Map<String, StreamSubscription> _sessionSubscriptions = {};

  // Start monitoring a session for automatic phase transitions
  static void startSessionMonitoring(String sessionId) {
    // Cancel existing monitoring if any
    stopSessionMonitoring(sessionId);

    // Listen to session changes
    _sessionSubscriptions[sessionId] = QuizSessionService.sessionStream(sessionId).listen(
      (session) {
        if (session != null && session.isActive) {
          _handleSessionPhase(session);
        }
      },
    );
  }

  // Stop monitoring a session
  static void stopSessionMonitoring(String sessionId) {
    _sessionTimers[sessionId]?.cancel();
    _sessionTimers.remove(sessionId);
    
    _sessionSubscriptions[sessionId]?.cancel();
    _sessionSubscriptions.remove(sessionId);
  }

  // Handle different session phases and set appropriate timers
  static void _handleSessionPhase(QuizSession session) {
    final sessionId = session.sessionId;
    
    // Cancel existing timer for this session
    _sessionTimers[sessionId]?.cancel();
    
    final now = DateTime.now();
    
    switch (session.phase) {
      case 'question':
        if (session.questionStartTime != null) {
          final elapsed = now.difference(session.questionStartTime!).inSeconds;
          final remaining = QuizSessionService.QUESTION_DURATION - elapsed;
          
          if (remaining > 0) {
            // Set timer to move to leaderboard phase
            _sessionTimers[sessionId] = Timer(Duration(seconds: remaining), () {
              QuizSessionService.moveToLeaderboard(sessionId);
            });
          } else {
            // Question time already expired, move to leaderboard immediately
            QuizSessionService.moveToLeaderboard(sessionId);
          }
        }
        break;

      case 'leaderboard':
        if (session.leaderboardStartTime != null) {
          final elapsed = now.difference(session.leaderboardStartTime!).inSeconds;
          final remaining = QuizSessionService.LEADERBOARD_DURATION - elapsed;
          
          if (remaining > 0) {
            // Set timer to move to next question or complete quiz
            _sessionTimers[sessionId] = Timer(Duration(seconds: remaining), () {
              QuizSessionService.moveToNextQuestion(sessionId);
            });
          } else {
            // Leaderboard time already expired, move to next question immediately
            QuizSessionService.moveToNextQuestion(sessionId);
          }
        }
        break;

      case 'completed':
        // Clean up monitoring for completed sessions
        stopSessionMonitoring(sessionId);
        break;
    }
  }

  // Manually trigger next phase (useful for testing or admin control)
  static Future<void> forceNextPhase(String sessionId) async {
    final session = await QuizSessionService.getSession(sessionId);
    if (session == null || !session.isActive) return;

    switch (session.phase) {
      case 'waiting':
        await QuizSessionService.startQuizSession(sessionId);
        break;
      case 'question':
        await QuizSessionService.moveToLeaderboard(sessionId);
        break;
      case 'leaderboard':
        await QuizSessionService.moveToNextQuestion(sessionId);
        break;
    }
  }

  // Clean up all timers (call when app is closing)
  static void dispose() {
    for (final timer in _sessionTimers.values) {
      timer.cancel();
    }
    _sessionTimers.clear();
    
    for (final subscription in _sessionSubscriptions.values) {
      subscription.cancel();
    }
    _sessionSubscriptions.clear();
  }

  // Get remaining time for current phase
  static int getRemainingTime(QuizSession session) {
    final now = DateTime.now();
    
    switch (session.phase) {
      case 'question':
        if (session.questionStartTime != null) {
          final elapsed = now.difference(session.questionStartTime!).inSeconds;
          return (QuizSessionService.QUESTION_DURATION - elapsed).clamp(0, QuizSessionService.QUESTION_DURATION);
        }
        break;
      case 'leaderboard':
        if (session.leaderboardStartTime != null) {
          final elapsed = now.difference(session.leaderboardStartTime!).inSeconds;
          return (QuizSessionService.LEADERBOARD_DURATION - elapsed).clamp(0, QuizSessionService.LEADERBOARD_DURATION);
        }
        break;
    }
    
    return 0;
  }
}
