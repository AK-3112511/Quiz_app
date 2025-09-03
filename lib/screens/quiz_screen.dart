// lib/screens/quiz_screen.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:Quiz_app/data/quiz_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'leaderboard_screen.dart';
import 'dynamic_leaderboard_screen.dart';
import 'package:Quiz_app/data/participant.dart';
import 'package:Quiz_app/data/leaderboard_service.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({
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
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  int currentQuestionIndex = 0;
  int score = 0;
  int missed = 0;
  bool answered = false;
  int? selectedAnswer;
  Timer? _questionTimer;
  Timer? _leaderboardTimer;
  late List<Map<String, dynamic>> questions;
  bool _isTransitioning = false;
  bool _isCompleting = false;
  bool _showingLeaderboard = false;
  bool _waitingForLeaderboard = false;

  late AnimationController _timerController;
  late AnimationController _questionController;
  late AnimationController _backgroundController;
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late AnimationController _scoreController;
  late AnimationController _transitionController;
  
  late Animation<double> _questionAnimation;
  late Animation<double> _questionSlideAnimation;
  late Animation<Color?> _timerColorAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scoreAnimation;
  late Animation<double> _transitionAnimation;

  List<Particle> particles = [];
  List<GridLine> gridLines = [];

  @override
  void initState() {
    super.initState();
    
    List<Map<String, dynamic>> originalQuestions = QuizData.getQuestionsByLanguage(widget.selectedLanguage);
    questions = _randomizeQuestions(originalQuestions);
    
    _timerController = AnimationController(duration: const Duration(seconds: 15), vsync: this);
    _questionController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _backgroundController = AnimationController(duration: const Duration(seconds: 12), vsync: this);
    _particleController = AnimationController(duration: const Duration(seconds: 10), vsync: this);
    _pulseController = AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _scoreController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _transitionController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    
    _questionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _questionController, curve: Curves.easeOutCubic)
    );
    _questionSlideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _questionController, curve: Curves.easeOutCubic)
    );
    _timerColorAnimation = ColorTween(
      begin: const Color(0xFF1E88E5), 
      end: const Color(0xFFE53935)
    ).animate(_timerController);
    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_backgroundController);
    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_particleController);
    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
    );
    _scoreAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scoreController, curve: Curves.elasticOut)
    );
    _transitionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _transitionController, curve: Curves.easeInOut)
    );

    _initializeParticles();
    _initializeGridLines();
    
    _backgroundController.repeat();
    _particleController.repeat();
    _pulseController.repeat(reverse: true);
    _startQuestion();
  }

  void _initializeParticles() {
    final random = Random();
    particles.clear();
    for (int i = 0; i < 40; i++) {
      particles.add(Particle(
        x: random.nextDouble(),
        y: random.nextDouble(),
        speed: 0.3 + random.nextDouble() * 1.0,
        size: 1 + random.nextDouble() * 2,
        opacity: 0.2 + random.nextDouble() * 0.4,
      ));
    }
  }

  void _initializeGridLines() {
    gridLines.clear();
    for (int i = 0; i < 15; i++) {
      gridLines.add(GridLine(
        isHorizontal: i % 2 == 0,
        position: i / 15,
        speed: 0.1 + Random().nextDouble() * 0.5,
        opacity: 0.05 + Random().nextDouble() * 0.15,
      ));
    }
  }

  List<Map<String, dynamic>> _randomizeQuestions(List<Map<String, dynamic>> originalQuestions) {
    List<Map<String, dynamic>> randomizedQuestions = [];
    
    for (var question in originalQuestions) {
      Map<String, dynamic> randomizedQuestion = _randomizeAnswers(Map<String, dynamic>.from(question));
      randomizedQuestions.add(randomizedQuestion);
    }
    
    randomizedQuestions.shuffle(Random());
    return randomizedQuestions;
  }

  Map<String, dynamic> _randomizeAnswers(Map<String, dynamic> question) {
    List<String> answers = List<String>.from(question['answers']);
    int correctAnswerIndex = question['correct'];
    String correctAnswer = answers[correctAnswerIndex];
    
    answers.shuffle(Random());
    int newCorrectIndex = answers.indexOf(correctAnswer);
    
    return {
      'question': question['question'],
      'answers': answers,
      'correct': newCorrectIndex,
    };
  }

  void _startQuestion() {
    if (_isCompleting || _showingLeaderboard) return;
    
    setState(() {
      _isTransitioning = false;
      _waitingForLeaderboard = false;
      answered = false;
      selectedAnswer = null;
    });
    
    _questionController.reset();
    _questionController.forward();
    _timerController.reset();
    _timerController.forward();

    _questionTimer?.cancel();
    
    _questionTimer = Timer(const Duration(seconds: 15), () {
      if (mounted && !answered && !_isTransitioning && !_isCompleting && !_showingLeaderboard) {
        setState(() {
          missed++;
          _waitingForLeaderboard = true;
        });
        _waitForLeaderboardTimer();
      }
    });
  }

  void _selectAnswer(int answerIndex) async {
    if (answered || _isTransitioning || _isCompleting || _showingLeaderboard) return;

    _questionTimer?.cancel();
    _timerController.stop();

    setState(() {
      answered = true;
      selectedAnswer = answerIndex;
      _waitingForLeaderboard = true;

      if (answerIndex == questions[currentQuestionIndex]['correct']) {
        score++;
        _scoreController.reset();
        _scoreController.forward();
      }
    });

    // Update score in Firebase if answer is correct
    if (answerIndex == questions[currentQuestionIndex]['correct']) {
      try {
        await LeaderboardServices.updateScore(widget.userId, widget.userName, score);
      } catch (e) {
        print('Error updating score: $e');
      }
    }

    // Wait for the remaining time before showing leaderboard
    _waitForLeaderboardTimer();
  }

  void _waitForLeaderboardTimer() {
    // Calculate remaining time until 15 seconds are up
    int remainingTime = (15000 - (_timerController.value * 15000)).round();
    if (remainingTime < 0) remainingTime = 0;

    _leaderboardTimer = Timer(Duration(milliseconds: remainingTime), () {
      if (mounted && !_isCompleting) {
        _showLeaderboard();
      }
    });
  }

  void _nextQuestion() {
    if (_isTransitioning || _isCompleting || _showingLeaderboard) return;
    
    setState(() {
      _isTransitioning = true;
    });

    if (currentQuestionIndex < questions.length - 1) {
      // Continue to next question after leaderboard closes
      setState(() {
        _showingLeaderboard = false;
        currentQuestionIndex++;
      });
      
      _transitionController.reset();
      _startQuestion();
    } else {
      // Quiz completed
      setState(() {
        _isCompleting = true;
      });
      
      _transitionController.forward().then((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            widget.onQuizComplete(score, questions.length, missed);
          }
        });
      });
    }
  }

  void _showLeaderboard() async {
    if (!mounted || _isCompleting) return;
    
    setState(() {
      _showingLeaderboard = true;
    });

    // Navigate to leaderboard overlay for 8 seconds
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => DynamicLeaderboardScreen(
          currentUserId: widget.userId,
          questionNumber: currentQuestionIndex + 1,
          totalQuestions: questions.length,
        ),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, -1.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            ),
          );
        },
      ),
    );

    // Continue to next question after leaderboard
    if (mounted && !_isCompleting) {
      _nextQuestion();
    }
  }

  Widget _buildNeonButton({
    required Widget child,
    required VoidCallback? onTap,
    Color glowColor = const Color(0xFF1976D2),
    bool isSelected = false,
    bool isCorrect = false,
    bool isWrong = false,
  }) {
    Color primaryColor = glowColor;
    Color backgroundColor = const Color(0xFF0A0A0A).withOpacity(0.6);
    
    if (answered) {
      if (isCorrect) {
        primaryColor = const Color(0xFF388E3C);
        backgroundColor = const Color(0xFF388E3C).withOpacity(0.1);
      } else if (isWrong) {
        primaryColor = const Color(0xFFD32F2F);
        backgroundColor = const Color(0xFFD32F2F).withOpacity(0.1);
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: primaryColor.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                primaryColor.withOpacity(0.08),
                Colors.transparent,
                primaryColor.withOpacity(0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildWaitingIndicator() {
    if (!_waitingForLeaderboard) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1976D2).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF1976D2).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF1976D2)),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Waiting for all players to finish...',
            style: TextStyle(
              color: const Color(0xFF1976D2),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _questionTimer?.cancel();
    _leaderboardTimer?.cancel();
    _timerController.dispose();
    _questionController.dispose();
    _backgroundController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    _scoreController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleting) {
      return AnimatedBuilder(
        animation: _transitionAnimation,
        builder: (context, child) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF000000), Color(0xFF1A1A1A), Color(0xFF000000)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                CustomPaint(
                  painter: BackgroundPainter(
                    particles: particles,
                    gridLines: gridLines,
                    animationValue: _particleAnimation.value,
                  ),
                  size: Size.infinite,
                ),
                Center(
                  child: Transform.scale(
                    scale: 1.0 - (_transitionAnimation.value * 0.1),
                    child: Opacity(
                      opacity: 1.0 - _transitionAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0A0A).withOpacity(0.8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF1976D2).withOpacity(0.3), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1976D2).withOpacity(0.2),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF1976D2)),
                              strokeWidth: 2.5,
                              backgroundColor: Colors.grey.shade800,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Calculating Results...',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    final question = questions[currentQuestionIndex];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF000000), Color(0xFF1A1A1A), Color(0xFF000000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: BackgroundPainter(
                  particles: particles,
                  gridLines: gridLines,
                  animationValue: _particleAnimation.value,
                ),
                size: Size.infinite,
              ),
            ),
            
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A0A0A).withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF1976D2).withOpacity(0.3), width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Question ${currentQuestionIndex + 1}/${questions.length}',
                                style: const TextStyle(
                                  color: Color(0xFF1976D2),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6A1B9A).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF6A1B9A).withOpacity(0.4), width: 0.5),
                                ),
                                child: Text(
                                  widget.selectedLanguage.toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFF9C27B0),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        AnimatedBuilder(
                          animation: _scoreAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _scoreAnimation.isAnimating ? 
                                     (1.0 + _scoreAnimation.value * 0.2) : 1.0,
                              child: AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0A0A0A).withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFFF6F00).withOpacity(0.4), width: 1),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.stars_rounded,
                                            color: Color(0xFFFF6F00),
                                            size: 16,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Score: $score',
                                            style: const TextStyle(
                                              color: Color(0xFFFF6F00),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Timer
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0A).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
                      ),
                      child: AnimatedBuilder(
                        animation: _timerController,
                        builder: (context, child) {
                          return LinearProgressIndicator(
                            value: 1.0 - _timerController.value,
                            backgroundColor: const Color(0xFF212121),
                            valueColor: _timerColorAnimation,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Question Container
                    Expanded(
                      flex: 2,
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_questionController, _transitionController]),
                        builder: (context, child) {
                          double opacity;
                          double translateX;
                          
                          if (_isTransitioning) {
                            opacity = 1.0 - _transitionAnimation.value;
                            translateX = MediaQuery.of(context).size.width * _transitionAnimation.value;
                          } else {
                            opacity = _questionAnimation.value;
                            translateX = MediaQuery.of(context).size.width * _questionSlideAnimation.value;
                          }
                              
                          return Transform.translate(
                            offset: Offset(translateX, 0),
                            child: Transform.scale(
                              scale: 0.8 + (opacity * 0.2),
                              child: Opacity(
                                opacity: opacity.clamp(0.0, 1.0),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0A0A0A).withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFF1976D2).withOpacity(0.25), width: 1),
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF1976D2).withOpacity(0.06),
                                        Colors.transparent,
                                        const Color(0xFF6A1B9A).withOpacity(0.06),
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      question['question'],
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Answer Options
                    Expanded(
                      flex: 3,
                      child: AnimatedBuilder(
                        animation: Listenable.merge([_questionController, _transitionController]),
                        builder: (context, child) {
                          double opacity;
                          double animationProgress;
                          
                          if (_isTransitioning) {
                            opacity = 1.0 - _transitionAnimation.value;
                            animationProgress = _transitionAnimation.value;
                          } else {
                            opacity = _questionAnimation.value;
                            animationProgress = 1.0 - _questionAnimation.value;
                          }
                              
                          return Opacity(
                            opacity: opacity.clamp(0.0, 1.0),
                            child: Column(
                              children: [
                                Expanded(
                                  child: ListView.builder(
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: question['answers'].length,
                                    itemBuilder: (context, index) {
                                      final answer = question['answers'][index];
                                      final isCorrect = index == question['correct'];
                                      final isSelected = selectedAnswer == index;
                                      final isWrong = isSelected && !isCorrect;
                                      
                                      return Transform.translate(
                                        offset: Offset(
                                          animationProgress * 120 * (index % 2 == 0 ? -1 : 1),
                                          0,
                                        ),
                                        child: _buildNeonButton(
                                          onTap: (answered || _isTransitioning) ? null : () => _selectAnswer(index),
                                          isCorrect: answered && isCorrect,
                                          isWrong: answered && isWrong,
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 45,
                                                height: 45,
                                                decoration: BoxDecoration(
                                                  color: answered && isCorrect 
                                                      ? const Color(0xFF388E3C).withOpacity(0.15)
                                                      : answered && isWrong
                                                          ? const Color(0xFFD32F2F).withOpacity(0.15)
                                                          : const Color(0xFF1976D2).withOpacity(0.15),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: answered && isCorrect 
                                                        ? const Color(0xFF388E3C)
                                                        : answered && isWrong
                                                            ? const Color(0xFFD32F2F)
                                                            : const Color(0xFF1976D2),
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    String.fromCharCode(65 + index),
                                                    style: TextStyle(
                                                      color: answered && isCorrect 
                                                          ? const Color(0xFF388E3C)
                                                          : answered && isWrong
                                                              ? const Color(0xFFD32F2F)
                                                              : const Color(0xFF1976D2),
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 18),
                                              Expanded(
                                                child: Text(
                                                  answer,
                                                  style: TextStyle(
                                                    color: answered && isCorrect 
                                                        ? const Color(0xFF388E3C)
                                                        : answered && isWrong
                                                            ? const Color(0xFFD32F2F)
                                                            : Colors.white.withOpacity(0.9),
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              if (answered && isCorrect)
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF388E3C).withOpacity(0.15),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.check_circle_outline,
                                                    color: Color(0xFF388E3C),
                                                    size: 22,
                                                  ),
                                                ),
                                              if (answered && isWrong)
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFD32F2F).withOpacity(0.15),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.cancel_outlined,
                                                    color: Color(0xFFD32F2F),
                                                    size: 22,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                _buildWaitingIndicator(),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Keep existing Particle, GridLine, and BackgroundPainter classes unchanged
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

class GridLine {
  bool isHorizontal;
  double position;
  double speed;
  double opacity;

  GridLine({
    required this.isHorizontal,
    required this.position,
    required this.speed,
    required this.opacity,
  });
}

class BackgroundPainter extends CustomPainter {
  final List<Particle> particles;
  final List<GridLine> gridLines;
  final double animationValue;

  BackgroundPainter({
    required this.particles,
    required this.gridLines,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw subtle grid lines
    final gridPaint = Paint()
      ..strokeWidth = 0.3
      ..style = PaintingStyle.stroke;

    for (var line in gridLines) {
      gridPaint.color = const Color(0xFF1976D2).withOpacity(line.opacity * 0.4);
      
      double animatedPosition = (line.position + animationValue * line.speed) % 1.0;
      
      if (line.isHorizontal) {
        canvas.drawLine(
          Offset(0, animatedPosition * size.height),
          Offset(size.width, animatedPosition * size.height),
          gridPaint,
        );
      } else {
        canvas.drawLine(
          Offset(animatedPosition * size.width, 0),
          Offset(animatedPosition * size.width, size.height),
          gridPaint,
        );
      }
    }

    // Draw floating particles
    final particlePaint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles) {
      double animatedY = (particle.y + animationValue * particle.speed) % 1.0;
      double animatedX = (particle.x + animationValue * particle.speed * 0.2) % 1.0;
      
      particlePaint.color = Color.lerp(
        const Color(0xFF1976D2),
        const Color(0xFF6A1B9A),
        sin(animationValue * pi + particle.x * 8),
      )!.withOpacity(particle.opacity * 0.4);

      canvas.drawCircle(
        Offset(animatedX * size.width, animatedY * size.height),
        particle.size,
        particlePaint,
      );
    }

    // Draw subtle connecting lines
    final linePaint = Paint()
      ..strokeWidth = 0.3
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < particles.length; i++) {
      for (int j = i + 1; j < particles.length; j++) {
        double x1 = (particles[i].x + animationValue * particles[i].speed * 0.2) % 1.0 * size.width;
        double y1 = (particles[i].y + animationValue * particles[i].speed) % 1.0 * size.height;
        double x2 = (particles[j].x + animationValue * particles[j].speed * 0.2) % 1.0 * size.width;
        double y2 = (particles[j].y + animationValue * particles[j].speed) % 1.0 * size.height;

        double distance = sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2));
        
        if (distance < 80) {
          linePaint.color = const Color(0xFF1976D2).withOpacity(
            (1.0 - distance / 80) * 0.1
          );
          canvas.drawLine(Offset(x1, y1), Offset(x2, y2), linePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}