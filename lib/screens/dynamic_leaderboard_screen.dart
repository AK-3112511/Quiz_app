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
  late AnimationController _countdownController;
  
  late Animation<double> _timerAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _countdownAnimation;
  
  Timer? _autoCloseTimer;
  Timer? _updateTimer;
  int _currentUserRank = -1;
  int _totalParticipants = 0;
  int _remainingSeconds = 8;
  bool _isClosing = false;
  StreamSubscription<QuerySnapshot>? _leaderboardSubscription;

  @override
  void initState() {
    super.initState();
    
    _timerController = AnimationController(duration: const Duration(seconds: 8), vsync: this);
    _fadeController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _slideController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _pulseController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    _countdownController = AnimationController(duration: const Duration(seconds: 1), vsync: this);
    
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
    _countdownAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _countdownController, curve: Curves.elasticOut)
    );

    _startAnimations();
    _getUserRank();
    _setupLeaderboardListener();
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

    // Auto-close timer with countdown
    _autoCloseTimer = Timer(const Duration(seconds: 8), () {
      _closeLeaderboard();
    });

    // Update countdown every second
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
        
        // Pulse animation for countdown
        if (_remainingSeconds <= 3) {
          _countdownController.reset();
          _countdownController.forward();
        }
      }
      
      if (_remainingSeconds <= 0) {
        timer.cancel();
      }
    });
  }

  void _setupLeaderboardListener() {
    // Listen to real-time updates
    _leaderboardSubscription = LeaderboardServices.getTopPlayers(15)
        .listen((snapshot) {
      if (mounted) {
        // Update participant count
        final activeCount = snapshot.docs.length;
        if (_totalParticipants != activeCount) {
          setState(() {
            _totalParticipants = activeCount;
          });
        }
      }
    }, onError: (error) {
      print('Error in leaderboard stream: $error');
    });
  }

  void _getUserRank() async {
    try {
      final rank = await LeaderboardServices.getUserRank(widget.currentUserId);
      final count = await LeaderboardServices.getActiveParticipantsCount();
      
      if (mounted) {
        setState(() {
          _currentUserRank = rank;
          _totalParticipants = count;
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
    if (_isClosing || !mounted) return;
    
    setState(() {
      _isClosing = true;
    });
    
    _autoCloseTimer?.cancel();
    _updateTimer?.cancel();
    _leaderboardSubscription?.cancel();
    
    // Smooth exit animation
    _fadeController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _updateTimer?.cancel();
    _leaderboardSubscription?.cancel();
    _timerController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _countdownController.dispose();
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
                          // Enhanced Header with timer and close button
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
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.live_tv,
                                              color: Colors.red.shade400,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 6),
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
                                          ],
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
                                        if (_totalParticipants > 0) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            '$_totalParticipants active players',
                                            style: TextStyle(
                                              color: Colors.green.shade400,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    
                                    // Countdown and close button
                                    Column(
                                      children: [
                                        GestureDetector(
                                          onTap: _isClosing ? null : _closeLeaderboard,
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(0.2),
                                                width: 1,
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.close,
                                              color: _isClosing ? Colors.grey : Colors.white70,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        AnimatedBuilder(
                                          animation: _countdownAnimation,
                                          builder: (context, child) {
                                            return Transform.scale(
                                              scale: _remainingSeconds <= 3 ? _countdownAnimation.value : 1.0,
                                              child: Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: _remainingSeconds <= 3 
                                                      ? Colors.red.withOpacity(0.2)
                                                      : const Color(0xFF1976D2).withOpacity(0.15),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: _remainingSeconds <= 3
                                                        ? Colors.red.shade400
                                                        : const Color(0xFF1976D2),
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    '$_remainingSeconds',
                                                    style: TextStyle(
                                                      color: _remainingSeconds <= 3
                                                          ? Colors.red.shade400
                                                          : const Color(0xFF1976D2),
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                
                                // Enhanced Timer bar with segments
                                Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade800,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: AnimatedBuilder(
                                    animation: _timerAnimation,
                                    builder: (context, child) {
                                      return Stack(
                                        children: [
                                          // Main progress bar
                                          FractionallySizedBox(
                                            alignment: Alignment.centerLeft,
                                            widthFactor: _timerAnimation.value.clamp(0.0, 1.0),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    _timerAnimation.value > 0.5
                                                        ? const Color(0xFF1976D2)
                                                        : _timerAnimation.value > 0.25
                                                            ? const Color(0xFFFF9800)
                                                            : const Color(0xFFFF5722),
                                                    _timerAnimation.value > 0.5
                                                        ? const Color(0xFF00BCD4)
                                                        : _timerAnimation.value > 0.25
                                                            ? const Color(0xFFFFB74D)
                                                            : const Color(0xFFFF8A65),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(4),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: (_timerAnimation.value > 0.5
                                                        ? const Color(0xFF1976D2)
                                                        : _timerAnimation.value > 0.25
                                                            ? const Color(0xFFFF9800)
                                                            : const Color(0xFFFF5722)).withOpacity(0.4),
                                                    blurRadius: 4,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          // Pulsing effect for last 3 seconds
                                          if (_timerAnimation.value < 0.375) // Last 3 seconds
                                            AnimatedBuilder(
                                              animation: _pulseAnimation,
                                              builder: (context, child) {
                                                return Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.withOpacity(
                                                      0.2 * (2.0 - _pulseAnimation.value)
                                                    ),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                );
                                              },
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AnimatedBuilder(
                                  animation: _timerAnimation,
                                  builder: (context, child) {
                                    return Text(
                                      _remainingSeconds > 0 
                                          ? 'Continuing in $_remainingSeconds seconds...'
                                          : 'Loading next question...',
                                      style: TextStyle(
                                        color: _remainingSeconds <= 3
                                            ? Colors.red.shade400
                                            : Colors.white.withOpacity(0.6),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          // Top Players Leaderboard with enhanced design
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
                                        'TOP PERFORMERS',
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
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1976D2).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: const Color(0xFF1976D2).withOpacity(0.4),
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Text(
                                          'REAL-TIME',
                                          style: const TextStyle(
                                            color: Color(0xFF1976D2),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: StreamBuilder<QuerySnapshot>(
                                      stream: LeaderboardServices.getTopPlayers(15),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData) {
                                          return const Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                CircularProgressIndicator(
                                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                                                  strokeWidth: 2.5,
                                                ),
                                                SizedBox(height: 16),
                                                Text(
                                                  'Loading live rankings...',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }

                                        if (snapshot.hasError) {
                                          return Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.cloud_off_rounded,
                                                  color: Colors.red.withOpacity(0.7),
                                                  size: 48,
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  'Connection Lost',
                                                  style: TextStyle(
                                                    color: Colors.white.withOpacity(0.8),
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Unable to load leaderboard data',
                                                  style: TextStyle(
                                                    color: Colors.grey.withOpacity(0.7),
                                                    fontSize: 14,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          );
                                        }

                                        final topPlayers = snapshot.data!.docs;
                                        
                                        if (topPlayers.isEmpty) {
                                          return Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.people_outline,
                                                  color: Colors.grey.withOpacity(0.5),
                                                  size: 64,
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  'No participants yet',
                                                  style: TextStyle(
                                                    color: Colors.white.withOpacity(0.6),
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Be the first to answer!',
                                                  style: TextStyle(
                                                    color: Colors.grey.withOpacity(0.7),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                        
                                        return ListView.builder(
                                          physics: const BouncingScrollPhysics(),
                                          itemCount: min(topPlayers.length, 15),
                                          itemBuilder: (context, index) {
                                            final player = topPlayers[index];
                                            final isCurrentUser = player['uid'] == widget.currentUserId;
                                            final rankPosition = index + 1;
                                            
                                            return Container(
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
                                                  // Rank Badge
                                                  Container(
                                                    width: 40,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      gradient: _getRankGradient(rankPosition),
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: _getRankColor(rankPosition),
                                                        width: 1.5,
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: _getRankIcon(rankPosition) ??
                                                          Text(
                                                            '$rankPosition',
                                                            style: TextStyle(
                                                              color: _getRankColor(rankPosition),
                                                              fontSize: 16,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  
                                                  // Player Info
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                player['name'] ?? 'Anonymous Player',
                                                                style: TextStyle(
                                                                  color: isCurrentUser
                                                                      ? const Color(0xFF1976D2)
                                                                      : Colors.white.withOpacity(0.9),
                                                                  fontSize: 16,
                                                                  fontWeight: FontWeight.w600,
                                                                ),
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                            if (isCurrentUser)
                                                              Container(
                                                                padding: const EdgeInsets.symmetric(
                                                                  horizontal: 6, 
                                                                  vertical: 2
                                                                ),
                                                                decoration: BoxDecoration(
                                                                  color: const Color(0xFF1976D2).withOpacity(0.2),
                                                                  borderRadius: BorderRadius.circular(4),
                                                                  border: Border.all(
                                                                    color: const Color(0xFF1976D2).withOpacity(0.5),
                                                                    width: 0.5,
                                                                  ),
                                                                ),
                                                                child: Text(
                                                                  'YOU',
                                                                  style: TextStyle(
                                                                    color: const Color(0xFF1976D2),
                                                                    fontSize: 9,
                                                                    fontWeight: FontWeight.bold,
                                                                    letterSpacing: 1,
                                                                  ),
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 2),
                                                        if (player['answered'] != null)
                                                          Text(
                                                            '${player['answered']} questions answered',
                                                            style: TextStyle(
                                                              color: Colors.white.withOpacity(0.5),
                                                              fontSize: 10,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                  
                                                  // Score Display
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: _getRankColor(rankPosition).withOpacity(0.15),
                                                      borderRadius: BorderRadius.circular(10),
                                                      border: Border.all(
                                                        color: _getRankColor(rankPosition).withOpacity(0.4),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Column(
                                                      children: [
                                                        Text(
                                                          '${player['score'] ?? 0}',
                                                          style: TextStyle(
                                                            color: _getRankColor(rankPosition),
                                                            fontSize: 18,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                        Text(
                                                          'points',
                                                          style: TextStyle(
                                                            color: _getRankColor(rankPosition).withOpacity(0.7),
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
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
        return const Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 20);
      case 2:
        return const Icon(Icons.military_tech, color: Color(0xFFC0C0C0), size: 18);
      case 3:
        return const Icon(Icons.emoji_events, color: Color(0xFFCD7F32), size: 18);
      default:
        return null;
    }
  }
}