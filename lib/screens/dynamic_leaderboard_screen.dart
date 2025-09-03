// lib/screens/dynamic_leaderboard_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:math';
import 'package:Quiz_app/data/leaderboard_service.dart';

class DynamicLeaderboardScreen extends StatefulWidget {
  final String currentUserId;
  final int questionNumber;
  final int totalQuestions;

  const DynamicLeaderboardScreen({
    super.key,
    required this.currentUserId,
    required this.questionNumber,
    required this.totalQuestions,
  });

  @override
  State<DynamicLeaderboardScreen> createState() => _DynamicLeaderboardScreenState();
}

class _DynamicLeaderboardScreenState extends State<DynamicLeaderboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _timerController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  
  late Animation<double> _timerAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  
  Timer? _autoCloseTimer;
  int _currentUserRank = -1;
  int _totalParticipants = 0;

  @override
  void initState() {
    super.initState();
    
    _timerController = AnimationController(duration: const Duration(seconds: 8), vsync: this);
    _fadeController = AnimationController(duration: const Duration(milliseconds: 400), vsync: this);
    _slideController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _pulseController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    
    _timerAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _timerController, curve: Curves.linear)
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut)
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack)
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
    );

    _startAnimations();
    _getUserRank();
  }

  void _startAnimations() {
    _fadeController.forward();
    
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _slideController.forward();
        _timerController.forward();
        _pulseController.repeat(reverse: true);
      }
    });

    _autoCloseTimer = Timer(const Duration(seconds: 8), () {
      _closeLeaderboard();
    });
  }

  void _getUserRank() async {
    try {
      final rank = await LeaderboardServices.getUserRank(widget.currentUserId);
      final snapshot = await FirebaseFirestore.instance
          .collection('leaderboard')
          .orderBy('score', descending: true)
          .get();
      
      if (mounted) {
        setState(() {
          _currentUserRank = rank;
          _totalParticipants = snapshot.docs.length;
        });
      }
    } catch (e) {
      print('Error getting user rank: $e');
      if (mounted) {
        setState(() {
          _currentUserRank = -1;
          _totalParticipants = 0;
        });
      }
    }
  }

  void _closeLeaderboard() {
    _autoCloseTimer?.cancel();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _timerController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF0F0F0F).withOpacity(0.95 * _fadeAnimation.value),
                const Color(0xFF1A1A1A).withOpacity(0.98 * _fadeAnimation.value),
                const Color(0xFF0F0F0F).withOpacity(0.95 * _fadeAnimation.value),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: AnimatedBuilder(
                animation: _slideAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, (1 - _slideAnimation.value) * -50),
                    child: Opacity(
                      opacity: _slideAnimation.value.clamp(0.0, 1.0),
                      child: Column(
                        children: [
                          // Header with timer
                          Container(
                            margin: const EdgeInsets.all(20),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF1976D2).withOpacity(0.15),
                                  const Color(0xFF6A1B9A).withOpacity(0.10),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF1976D2).withOpacity(0.4),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1976D2).withOpacity(0.2),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'LIVE LEADERBOARD',
                                          style: TextStyle(
                                            color: const Color(0xFF1976D2),
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2,
                                            shadows: [
                                              Shadow(
                                                color: const Color(0xFF1976D2).withOpacity(0.4),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'After Question ${widget.questionNumber}/${widget.totalQuestions}',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.8),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    GestureDetector(
                                      onTap: _closeLeaderboard,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white70,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                // Timer bar
                                Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade800,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: AnimatedBuilder(
                                    animation: _timerAnimation,
                                    builder: (context, child) {
                                      return FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: _timerAnimation.value.clamp(0.0, 1.0),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFF1976D2),
                                                _timerAnimation.value > 0.3
                                                    ? const Color(0xFF00BCD4)
                                                    : const Color(0xFFFF5722),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AnimatedBuilder(
                                  animation: _timerAnimation,
                                  builder: (context, child) {
                                    return Text(
                                      'Continuing in ${(_timerAnimation.value * 8).ceil()} seconds...',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          // Top 10 Leaderboard
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withOpacity(0.6),
                                    Colors.grey.shade900.withOpacity(0.4),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFF1976D2).withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.emoji_events,
                                        color: Color(0xFFFFD700),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'TOP 10 PLAYERS',
                                        style: TextStyle(
                                          color: const Color(0xFFFFD700),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                          shadows: [
                                            Shadow(
                                              color: const Color(0xFFFFD700).withOpacity(0.3),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: StreamBuilder<QuerySnapshot>(
                                      stream: LeaderboardServices.getTopPlayers(10),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData) {
                                          return const Center(
                                            child: CircularProgressIndicator(
                                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                                            ),
                                          );
                                        }

                                        if (snapshot.hasError) {
                                          return Center(
                                            child: Text(
                                              'Error loading leaderboard',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.6),
                                                fontSize: 16,
                                              ),
                                            ),
                                          );
                                        }

                                        final topPlayers = snapshot.data!.docs;
                                        
                                        if (topPlayers.isEmpty) {
                                          return Center(
                                            child: Text(
                                              'No participants yet',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.6),
                                                fontSize: 16,
                                              ),
                                            ),
                                          );
                                        }
                                        
                                        return ListView.builder(
                                          physics: const BouncingScrollPhysics(),
                                          itemCount: topPlayers.length,
                                          itemBuilder: (context, index) {
                                            final player = topPlayers[index];
                                            final isCurrentUser = player['uid'] == widget.currentUserId;
                                            
                                            return AnimatedBuilder(
                                              animation: _pulseAnimation,
                                              builder: (context, child) {
                                                return Transform.scale(
                                                  scale: isCurrentUser ? _pulseAnimation.value : 1.0,
                                                  child: Container(
                                                    margin: const EdgeInsets.only(bottom: 8),
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: isCurrentUser
                                                            ? [
                                                                const Color(0xFF1976D2).withOpacity(0.3),
                                                                const Color(0xFF1976D2).withOpacity(0.1),
                                                              ]
                                                            : [
                                                                Colors.white.withOpacity(0.05),
                                                                Colors.white.withOpacity(0.02),
                                                              ],
                                                      ),
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(
                                                        color: isCurrentUser
                                                            ? const Color(0xFF1976D2).withOpacity(0.6)
                                                            : Colors.white.withOpacity(0.1),
                                                        width: isCurrentUser ? 1.5 : 0.5,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        // Rank
                                                        Container(
                                                          width: 32,
                                                          height: 32,
                                                          decoration: BoxDecoration(
                                                            gradient: _getRankGradient(index + 1),
                                                            shape: BoxShape.circle,
                                                            border: Border.all(
                                                              color: _getRankColor(index + 1),
                                                              width: 1.5,
                                                            ),
                                                          ),
                                                          child: Center(
                                                            child: _getRankIcon(index + 1) ??
                                                                Text(
                                                                  '${index + 1}',
                                                                  style: TextStyle(
                                                                    color: _getRankColor(index + 1),
                                                                    fontSize: 14,
                                                                    fontWeight: FontWeight.bold,
                                                                  ),
                                                                ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 12),
                                                        
                                                        // Player info
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                player['name'] ?? 'Player',
                                                                style: TextStyle(
                                                                  color: isCurrentUser
                                                                      ? const Color(0xFF1976D2)
                                                                      : Colors.white.withOpacity(0.9),
                                                                  fontSize: 15,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                              if (isCurrentUser)
                                                                Text(
                                                                  'YOU',
                                                                  style: TextStyle(
                                                                    color: const Color(0xFF1976D2).withOpacity(0.8),
                                                                    fontSize: 10,
                                                                    fontWeight: FontWeight.bold,
                                                                    letterSpacing: 1,
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                        
                                                        // Score
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: _getRankColor(index + 1).withOpacity(0.15),
                                                            borderRadius: BorderRadius.circular(8),
                                                            border: Border.all(
                                                              color: _getRankColor(index + 1).withOpacity(0.4),
                                                              width: 0.5,
                                                            ),
                                                          ),
                                                          child: Text(
                                                            '${player['score'] ?? 0}',
                                                            style: TextStyle(
                                                              color: _getRankColor(index + 1),
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Current User Rank (if not in top 10)
                          if (_currentUserRank > 10)
                            Container(
                              margin: const EdgeInsets.all(20),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFFF6F00).withOpacity(0.15),
                                    const Color(0xFFFF6F00).withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFF6F00).withOpacity(0.4),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.my_location,
                                    color: Color(0xFFFF6F00),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Your Rank: $_currentUserRank / $_totalParticipants',
                                    style: const TextStyle(
                                      color: Color(0xFFFF6F00),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  LinearGradient _getRankGradient(int rank) {
    switch (rank) {
      case 1:
        return LinearGradient(
          colors: [
            const Color(0xFFFFD700).withOpacity(0.3),
            const Color(0xFFFFD700).withOpacity(0.1),
          ],
        );
      case 2:
        return LinearGradient(
          colors: [
            const Color(0xFFC0C0C0).withOpacity(0.3),
            const Color(0xFFC0C0C0).withOpacity(0.1),
          ],
        );
      case 3:
        return LinearGradient(
          colors: [
            const Color(0xFFCD7F32).withOpacity(0.3),
            const Color(0xFFCD7F32).withOpacity(0.1),
          ],
        );
      default:
        return LinearGradient(
          colors: [
            const Color(0xFF1976D2).withOpacity(0.15),
            const Color(0xFF1976D2).withOpacity(0.05),
          ],
        );
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return const Color(0xFF1976D2);
    }
  }

  Widget? _getRankIcon(int rank) {
    switch (rank) {
      case 1:
        return const Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 18);
      case 2:
        return const Icon(Icons.military_tech, color: Color(0xFFC0C0C0), size: 16);
      case 3:
        return const Icon(Icons.emoji_events, color: Color(0xFFCD7F32), size: 16);
      default:
        return null;
    }
  }
}