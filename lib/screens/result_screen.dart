// lib/screens/result_screen.dart

import 'package:flutter/material.dart';
import 'dart:math';

class ResultScreen extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final int missed;
  final String userName; // Added userName parameter
  final VoidCallback onRestart;

  const ResultScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.missed,
    required this.userName, // Added userName parameter
    required this.onRestart,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with TickerProviderStateMixin {
  late AnimationController _scoreController;
  late AnimationController _statsController;
  late AnimationController _celebrationController;
  late AnimationController _pulseController;

  late Animation<double> _scoreAnimation;
  late Animation<double> _statsAnimation;
  late Animation<double> _celebrationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _scoreController = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this);
    _statsController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    _celebrationController = AnimationController(duration: const Duration(milliseconds: 3000), vsync: this);
    _pulseController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);

    _scoreAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scoreController, curve: Curves.elasticOut)
    );
    _statsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _statsController, curve: Curves.easeOutBack)
    );
    _celebrationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.easeInOut)
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
    );

    _startAnimations();
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 300), () {
      _scoreController.forward();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      _statsController.forward();
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      _celebrationController.forward();
    });
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _statsController.dispose();
    _celebrationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _getPerformanceMessage() {
    double percentage = (widget.score / widget.totalQuestions) * 100;
    if (percentage >= 90) return "EXCEPTIONAL!";
    if (percentage >= 80) return "EXCELLENT!";
    if (percentage >= 70) return "GREAT JOB!";
    if (percentage >= 60) return "GOOD WORK!";
    if (percentage >= 50) return "NOT BAD!";
    return "KEEP TRYING!";
  }

  Color _getPerformanceColor() {
    double percentage = (widget.score / widget.totalQuestions) * 100;
    if (percentage >= 80) return Colors.greenAccent;
    if (percentage >= 60) return Colors.amberAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (widget.score / widget.totalQuestions) * 100;
    final incorrect = widget.totalQuestions - widget.score - widget.missed;

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/IOTA_logo.png'),
          fit: BoxFit.contain,
        ),
        gradient: LinearGradient(
          colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Compact User Info Box
                AnimatedBuilder(
                  animation: _scoreAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scoreAnimation.value,
                      child: Opacity(
                        opacity: _scoreAnimation.value,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.cyanAccent.withOpacity(0.08),
                                Colors.blueAccent.withOpacity(0.04),
                                Colors.cyanAccent.withOpacity(0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.cyanAccent.withOpacity(0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyanAccent.withOpacity(0.15),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 45,
                                height: 45,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.cyanAccent.withOpacity(0.25),
                                      Colors.cyanAccent.withOpacity(0.08),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: Colors.cyanAccent.withOpacity(0.5),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.account_circle,
                                  color: Colors.cyanAccent,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'PLAYER',
                                      style: TextStyle(
                                        color: Colors.cyanAccent.withOpacity(0.7),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      widget.userName.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getPerformanceColor().withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _getPerformanceColor().withOpacity(0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  'DONE',
                                  style: TextStyle(
                                    color: _getPerformanceColor(),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Header
                AnimatedBuilder(
                  animation: _scoreAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scoreAnimation.value,
                      child: Opacity(
                        opacity: _scoreAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            children: [
                              Text(
                                'QUIZ COMPLETED',
                                style: TextStyle(
                                  color: Colors.cyanAccent,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2.5,
                                  shadows: [
                                    Shadow(
                                      color: Colors.cyanAccent.withOpacity(0.4),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getPerformanceMessage(),
                                style: TextStyle(
                                  color: _getPerformanceColor(),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Score Circle
                Container(
                  height: 280,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  child: AnimatedBuilder(
                    animation: _celebrationController,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer completion ring
                          AnimatedBuilder(
                            animation: _celebrationAnimation,
                            builder: (context, child) {
                              return Container(
                                width: 260,
                                height: 260,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _getPerformanceColor().withOpacity(_celebrationAnimation.value * 0.5),
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _getPerformanceColor().withOpacity(_celebrationAnimation.value * 0.3),
                                      blurRadius: 15,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          
                          // Main score circle
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  width: 220,
                                  height: 220,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        _getPerformanceColor().withOpacity(0.25),
                                        _getPerformanceColor().withOpacity(0.08),
                                        Colors.transparent,
                                      ],
                                    ),
                                    border: Border.all(
                                      color: _getPerformanceColor(),
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _getPerformanceColor().withOpacity(0.4),
                                        blurRadius: 25,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AnimatedBuilder(
                                        animation: _scoreAnimation,
                                        builder: (context, child) {
                                          return Text(
                                            '${(_scoreAnimation.value * widget.score).toInt()}',
                                            style: TextStyle(
                                              color: _getPerformanceColor(),
                                              fontSize: 52,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        },
                                      ),
                                      Text(
                                        '/ ${widget.totalQuestions}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      AnimatedBuilder(
                                        animation: _scoreAnimation,
                                        builder: (context, child) {
                                          return Text(
                                            '${(_scoreAnimation.value * percentage).toInt()}%',
                                            style: TextStyle(
                                              color: _getPerformanceColor(),
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // Statistics
                AnimatedBuilder(
                  animation: _statsAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, (1 - _statsAnimation.value) * 50),
                      child: Opacity(
                        opacity: _statsAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.grey.shade900.withOpacity(0.7),
                                Colors.black.withOpacity(0.5),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.cyanAccent.withOpacity(0.25),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'DETAILED STATISTICS',
                                style: TextStyle(
                                  color: Colors.cyanAccent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _StatCard(
                                      icon: Icons.check_circle,
                                      value: widget.score,
                                      label: 'CORRECT',
                                      color: Colors.greenAccent,
                                      animation: _statsAnimation,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: _StatCard(
                                      icon: Icons.cancel,
                                      value: incorrect,
                                      label: 'WRONG',
                                      color: Colors.redAccent,
                                      animation: _statsAnimation,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: _StatCard(
                                      icon: Icons.access_time,
                                      value: widget.missed,
                                      label: 'MISSED',
                                      color: Colors.orangeAccent,
                                      animation: _statsAnimation,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Action Buttons
                AnimatedBuilder(
                  animation: _statsAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _statsAnimation.value,
                      child: Opacity(
                        opacity: _statsAnimation.value,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00aaff), Color(0xFF0077cc)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00aaff).withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: widget.onRestart,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                            icon: const Icon(Icons.refresh, color: Colors.white, size: 26),
                            label: const Text(
                              'PLAY AGAIN',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;
  final Animation<double> animation;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Text(
                '${(animation.value * value).toInt()}',
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}