// lib/screens/synchronized_quiz_screen.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:Quiz_app/data/quiz_data.dart';
import 'package:Quiz_app/data/quiz_session.dart';
import 'package:Quiz_app/data/quiz_session_service.dart';
import 'package:Quiz_app/data/session_timer_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SynchronizedQuizScreen extends StatefulWidget {
  const SynchronizedQuizScreen({
    super.key, 
    required this.onQuizComplete,
    required this.selectedLanguage,
    required this.userName,
    required this.userId,
  });

  final void Function(int score, int totalQuestions, int missed) onQuizComplete;
  final String selectedLanguage;
  final String userName;
  final String userId;

  @override
  State<SynchronizedQuizScreen> createState() => _SynchronizedQuizScreenState();
}

class _SynchronizedQuizScreenState extends State<SynchronizedQuizScreen> with TickerProviderStateMixin {
  String? sessionId;
  QuizSession? currentSession;
  StreamSubscription<QuizSession?>? sessionSubscription;
  StreamSubscription<QuerySnapshot>? leaderboardSubscription;
  
  late List<Map<String, dynamic>> questions;
  Map<String, dynamic>? currentQuestionData;
  
  int? selectedAnswer;
  bool hasAnswered = false;
  int userScore = 0;
  int totalAnswered = 0;
  
  Timer? countdownTimer;
  int timeLeft = 15;
  
  List<Map<String, dynamic>> leaderboardData = [];
  bool showingLeaderboard = false;
  
  // Animation controllers
  late AnimationController _timerController;
  late AnimationController _questionController;
  late AnimationController _backgroundController;
  late AnimationController _leaderboardController;
  
  late Animation<double> _questionAnimation;
  late Animation<Color?> _timerColorAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _leaderboardAnimation;

  List<Particle> particles = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeParticles();
    _setupQuizSession();
  }

  void _initializeAnimations() {
    _timerController = AnimationController(duration: const Duration(seconds: 15), vsync: this);
    _questionController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _backgroundController = AnimationController(duration: const Duration(seconds: 12), vsync: this);
    _leaderboardController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    
    _questionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _questionController, curve: Curves.easeOutCubic)
    );
    
    _timerColorAnimation = ColorTween(
      begin: const Color(0xFF1E88E5), 
      end: const Color(0xFFE53935)
    ).animate(_timerController);
    
    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_backgroundController);
    _leaderboardAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_leaderboardController);
    
    _backgroundController.repeat();
  }

  void _initializeParticles() {
    final random = Random();
    particles.clear();
    for (int i = 0; i < 30; i++) {
      particles.add(Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        speed: 0.3 + random.nextDouble() * 1.0,
        size: 1 + random.nextDouble() * 2,
        opacity: 0.2 + random.nextDouble() * 0.4,
      ));
    }
  }

  Future<void> _setupQuizSession() async {
    try {
      // Create or join a session
      sessionId = await QuizSessionService.createOrJoinSession(
        widget.selectedLanguage,
        widget.userId,
        widget.userName,
      );

      print('Joined session: $sessionId');

      // Get questions for this language
      questions = QuizData.getQuestionsByLanguage(widget.selectedLanguage);

      // Listen to session changes
      sessionSubscription = QuizSessionService.sessionStream(sessionId!).listen(_onSessionUpdate);
      
      // Listen to leaderboard changes
      leaderboardSubscription = QuizSessionService.getSessionLeaderboard(sessionId!).listen(_onLeaderboardUpdate);

      // Start automatic session monitoring
      SessionTimerService.startSessionMonitoring(sessionId!);

      // For testing purposes, start the session automatically after 5 seconds
      // In production, you might want to start this manually or with enough users
      Timer(const Duration(seconds: 5), () {
        if (sessionId != null) {
          QuizSessionService.startQuizSession(sessionId!);
        }
      });
      
    } catch (e) {
      print('Error setting up quiz session: $e');
      _showErrorAndExit('Failed to join quiz session. Please try again.');
    }
  }

  void _onSessionUpdate(QuizSession? session) {
    if (!mounted || session == null) return;
    
    setState(() {
      currentSession = session;
    });

    switch (session.phase) {
      case 'waiting':
        _showWaitingState();
        break;
      case 'question':
        _showQuestion();
        break;
      case 'leaderboard':
        _showLeaderboard();
        break;
      case 'completed':
        _showFinalResults();
        break;
    }
  }

  void _onLeaderboardUpdate(QuerySnapshot snapshot) {
    if (!mounted) return;
    
    setState(() {
      leaderboardData = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'userName': data['userName'] ?? 'Player',
          'score': data['score'] ?? 0,
          'answeredQuestions': data['answeredQuestions'] ?? 0,
        };
      }).toList();
    });
  }

  void _showWaitingState() {
    setState(() {
      showingLeaderboard = false;
      hasAnswered = false;
      selectedAnswer = null;
    });
  }

  void _showQuestion() {
    if (currentSession == null) return;
    
    final questionIndex = currentSession!.currentQuestionIndex;
    final actualQuestionIndex = currentSession!.questionOrder[questionIndex];
    
    setState(() {
      currentQuestionData = questions[actualQuestionIndex];
      showingLeaderboard = false;
      hasAnswered = false;
      selectedAnswer = null;
      // Get server-synchronized time
      timeLeft = SessionTimerService.getRemainingTime(currentSession!);
    });

    _questionController.forward(from: 0);
    _startTimer();
  }

  void _showLeaderboard() {
    setState(() {
      showingLeaderboard = true;
    });
    _leaderboardController.forward(from: 0);
    _stopTimer();
  }

  void _showFinalResults() {
    _stopTimer();
    // Calculate final score and missed questions
    final finalScore = userScore;
    final totalQuestions = currentSession?.totalQuestions ?? questions.length;
    final missed = totalQuestions - finalScore;
    
    // Call the completion callback
    widget.onQuizComplete(finalScore, totalQuestions, missed);
  }

  void _startTimer() {
    _timerController.forward(from: 0);
    
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      setState(() {
        if (timeLeft > 0) {
          timeLeft--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  void _stopTimer() {
    countdownTimer?.cancel();
    _timerController.stop();
  }

  void _selectAnswer(int answerIndex) async {
    if (hasAnswered || currentQuestionData == null || currentSession == null) return;
    
    setState(() {
      selectedAnswer = answerIndex;
      hasAnswered = true;
    });

    // Check if answer is correct
    final isCorrect = answerIndex == currentQuestionData!['correct'];
    if (isCorrect) {
      setState(() {
        userScore++;
      });
    }
    
    setState(() {
      totalAnswered++;
    });

    // Submit answer to Firebase
    await QuizSessionService.submitAnswer(
      sessionId!,
      widget.userId,
      currentSession!.currentQuestionIndex,
      answerIndex,
      currentSession!.questionStartTime ?? DateTime.now(),
    );
  }

  void _showErrorAndExit(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    sessionSubscription?.cancel();
    leaderboardSubscription?.cancel();
    countdownTimer?.cancel();
    
    // Stop session monitoring
    if (sessionId != null) {
      SessionTimerService.stopSessionMonitoring(sessionId!);
    }
    
    _timerController.dispose();
    _questionController.dispose();
    _backgroundController.dispose();
    _leaderboardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: Stack(
          children: [
            _buildAnimatedBackground(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: _buildMainContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(particles, _backgroundAnimation.value),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildMainContent() {
    if (currentSession == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    switch (currentSession!.phase) {
      case 'waiting':
        return _buildWaitingScreen();
      case 'question':
        return _buildQuestionScreen();
      case 'leaderboard':
        return _buildLeaderboardScreen();
      case 'completed':
        return _buildCompletedScreen();
      default:
        return const Center(child: Text('Unknown phase'));
    }
  }

  Widget _buildWaitingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text(
            'Waiting for quiz to start...',
            style: TextStyle(fontSize: 24, color: Colors.white),
          ),
          SizedBox(height: 10),
          Text(
            'Please wait while other participants join',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionScreen() {
    if (currentQuestionData == null) return const Center(child: CircularProgressIndicator());

    return AnimatedBuilder(
      animation: _questionAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _questionAnimation.value) * 50),
          child: Opacity(
            opacity: _questionAnimation.value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 30),
                _buildTimerBar(),
                const SizedBox(height: 30),
                _buildQuestionCard(),
                const Spacer(),
                _buildAnswerButtons(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardScreen() {
    return AnimatedBuilder(
      animation: _leaderboardAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (_leaderboardAnimation.value * 0.2),
          child: Opacity(
            opacity: _leaderboardAnimation.value,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.leaderboard, color: Colors.cyan, size: 30),
                      SizedBox(width: 10),
                      Text(
                        'Live Leaderboard',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: leaderboardData.isEmpty 
                        ? const Center(
                            child: Text(
                              'No participants yet',
                              style: TextStyle(color: Colors.white70, fontSize: 18),
                            ),
                          )
                        : ListView.builder(
                            itemCount: leaderboardData.length,
                            itemBuilder: (context, index) {
                              final participant = leaderboardData[index];
                              final isCurrentUser = participant['userName'] == widget.userName;
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: isCurrentUser 
                                      ? Colors.cyan.withOpacity(0.2)
                                      : Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: isCurrentUser 
                                      ? Border.all(color: Colors.cyan)
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: _getRankColor(index),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Text(
                                        participant['userName'],
                                        style: TextStyle(
                                          color: isCurrentUser ? Colors.cyan : Colors.white,
                                          fontSize: 16,
                                          fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${participant['score']} pts',
                                      style: TextStyle(
                                        color: isCurrentUser ? Colors.cyan : Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Next question coming soon...',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompletedScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events, color: Colors.yellow, size: 100),
          SizedBox(height: 20),
          Text(
            'Quiz Completed!',
            style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            'Loading final results...',
            style: TextStyle(fontSize: 18, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${(currentSession?.currentQuestionIndex ?? 0) + 1}/${currentSession?.totalQuestions ?? questions.length}',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            Text(
              widget.selectedLanguage.toUpperCase(),
              style: const TextStyle(color: Colors.cyan, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green),
          ),
          child: Text(
            'Score: $userScore',
            style: const TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildTimerBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Time Left', style: TextStyle(color: Colors.white70)),
            Text('${timeLeft}s', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        AnimatedBuilder(
          animation: _timerController,
          builder: (context, child) {
            return LinearProgressIndicator(
              value: 1 - _timerController.value,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: _timerColorAnimation,
              minHeight: 8,
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Text(
        currentQuestionData!['question'],
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAnswerButtons() {
    final answers = currentQuestionData!['answers'] as List<String>;
    
    return Column(
      children: answers.asMap().entries.map((entry) {
        final index = entry.key;
        final answer = entry.value;
        final isSelected = selectedAnswer == index;
        final isCorrect = index == currentQuestionData!['correct'];
        
        Color buttonColor;
        if (hasAnswered) {
          if (isSelected && isCorrect) {
            buttonColor = Colors.green;
          } else if (isSelected && !isCorrect) {
            buttonColor = Colors.red;
          } else if (isCorrect) {
            buttonColor = Colors.green;
          } else {
            buttonColor = Colors.white.withOpacity(0.1);
          }
        } else {
          buttonColor = isSelected 
              ? Colors.cyan.withOpacity(0.3)
              : Colors.white.withOpacity(0.1);
        }
        
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _selectAnswer(index),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: buttonColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.cyan : Colors.white.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + index), // A, B, C, D
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        answer,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (hasAnswered && isCorrect)
                      const Icon(Icons.check_circle, color: Colors.white),
                    if (hasAnswered && isSelected && !isCorrect)
                      const Icon(Icons.cancel, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 0: return Colors.amber; // Gold
      case 1: return Colors.grey[400]!; // Silver
      case 2: return Colors.brown[400]!; // Bronze
      default: return Colors.blue[400]!;
    }
  }
}

// Particle class for background animation
class Particle {
  double x;
  double y;
  double speed;
  double size;
  double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.opacity,
  });
}

// Custom painter for animated background
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;

  ParticlePainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (final particle in particles) {
      // Update particle position
      particle.y = (particle.y + particle.speed * 0.01) % 1.0;
      
      final x = particle.x * size.width;
      final y = particle.y * size.height;
      
      paint.color = Colors.cyan.withOpacity(particle.opacity * 0.5);
      canvas.drawCircle(Offset(x, y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
