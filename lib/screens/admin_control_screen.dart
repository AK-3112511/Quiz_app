// lib/screens/admin_control_screen.dart

import 'package:flutter/material.dart';
import 'package:Quiz_app/data/quiz_session_service.dart';
import 'package:Quiz_app/data/session_timer_service.dart';
import 'package:Quiz_app/data/quiz_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminControlScreen extends StatefulWidget {
  const AdminControlScreen({super.key});

  @override
  State<AdminControlScreen> createState() => _AdminControlScreenState();
}

class _AdminControlScreenState extends State<AdminControlScreen> {
  List<QuizSession> activeSessions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActiveSessions();
  }

  Future<void> _loadActiveSessions() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(QuizSessionService.SESSIONS_COLLECTION)
          .where('isActive', isEqualTo: true)
          .get();

      setState(() {
        activeSessions = snapshot.docs
            .map((doc) => QuizSession.fromFirestore(doc))
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading sessions: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _forceNextPhase(String sessionId) async {
    try {
      await SessionTimerService.forceNextPhase(sessionId);
      await _loadActiveSessions(); // Refresh the list
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phase advanced successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _createTestSession(String language) async {
    try {
      final sessionId = await QuizSessionService.createOrJoinSession(
        language,
        'admin_${DateTime.now().millisecondsSinceEpoch}',
        'Admin Test User',
      );
      
      await _loadActiveSessions(); // Refresh the list
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Test session created: $sessionId')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating session: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Admin Control'),
        backgroundColor: const Color(0xFF1A1A2E),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0A0A),
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
            ],
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Control buttons
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () => _createTestSession('flutter'),
                          child: const Text('Create Flutter Session'),
                        ),
                        ElevatedButton(
                          onPressed: () => _createTestSession('kotlin'),
                          child: const Text('Create Kotlin Session'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () => _createTestSession('python'),
                          child: const Text('Create Python Session'),
                        ),
                        ElevatedButton(
                          onPressed: _loadActiveSessions,
                          child: const Text('Refresh Sessions'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  // Active sessions list
                  Expanded(
                    child: activeSessions.isEmpty
                        ? const Center(
                            child: Text(
                              'No active sessions',
                              style: TextStyle(color: Colors.white70, fontSize: 18),
                            ),
                          )
                        : ListView.builder(
                            itemCount: activeSessions.length,
                            itemBuilder: (context, index) {
                              final session = activeSessions[index];
                              return Card(
                                color: Colors.white.withOpacity(0.1),
                                margin: const EdgeInsets.all(8.0),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Session: ${session.sessionId.substring(0, 8)}...',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getPhaseColor(session.phase),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              session.phase.toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Language: ${session.language}',
                                        style: const TextStyle(color: Colors.white70),
                                      ),
                                      Text(
                                        'Question: ${session.currentQuestionIndex + 1}/${session.totalQuestions}',
                                        style: const TextStyle(color: Colors.white70),
                                      ),
                                      if (session.questionStartTime != null)
                                        Text(
                                          'Question started: ${_formatTime(session.questionStartTime!)}',
                                          style: const TextStyle(color: Colors.white70),
                                        ),
                                      if (session.leaderboardStartTime != null)
                                        Text(
                                          'Leaderboard started: ${_formatTime(session.leaderboardStartTime!)}',
                                          style: const TextStyle(color: Colors.white70),
                                        ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () => _forceNextPhase(session.sessionId),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.orange,
                                              ),
                                              child: Text(_getNextPhaseText(session.phase)),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Remaining: ${SessionTimerService.getRemainingTime(session)}s',
                                            style: const TextStyle(
                                              color: Colors.cyan,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Color _getPhaseColor(String phase) {
    switch (phase) {
      case 'waiting':
        return Colors.grey;
      case 'question':
        return Colors.blue;
      case 'leaderboard':
        return Colors.green;
      case 'completed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getNextPhaseText(String currentPhase) {
    switch (currentPhase) {
      case 'waiting':
        return 'Start Quiz';
      case 'question':
        return 'Show Leaderboard';
      case 'leaderboard':
        return 'Next Question';
      case 'completed':
        return 'Completed';
      default:
        return 'Next Phase';
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time).inSeconds;
    return '${diff}s ago';
  }
}
