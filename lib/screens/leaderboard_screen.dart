// lib/screens/leaderboard_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Quiz_app/data/participant.dart';
import 'package:Quiz_app/data/leaderboard_service.dart';

class LeaderboardScreen extends StatefulWidget {
  final String currentUserId;
  final bool showBackButton;

  const LeaderboardScreen({
    super.key,
    required this.currentUserId,
    this.showBackButton = false,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _refreshController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _refreshAnimation;
  
  int _currentUserRank = -1;
  int _totalParticipants = 0;
  bool _isRefreshing = false;
  Map<String, dynamic>? _currentUserData;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _slideController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _pulseController = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this);
    _refreshController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut)
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic)
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
    );
    _refreshAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _refreshController, curve: Curves.easeInOut)
    );

    _startAnimations();
    _getUserRank();
  }

  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _slideController.forward();
      }
    });
    _pulseController.repeat(reverse: true);
  }

  Future<void> _getUserRank() async {
    try {
      final rank = await LeaderboardServices.getUserRank(widget.currentUserId);
      final userData = await LeaderboardServices.getUserData(widget.currentUserId);
      final snapshot = await FirebaseFirestore.instance
          .collection('leaderboard')
          .orderBy('score', descending: true)
          .get();
      
      if (mounted) {
        setState(() {
          _currentUserRank = rank;
          _totalParticipants = snapshot.docs.length;
          _currentUserData = userData;
        });
      }
    } catch (e) {
      print('Error getting user rank: $e');
      if (mounted) {
        setState(() {
          _currentUserRank = -1;
          _totalParticipants = 0;
          _currentUserData = null;
        });
      }
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing || !mounted) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      _refreshController.reset();
      _refreshController.forward();
      
      await _getUserRank();
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      print('Error refreshing leaderboard data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh leaderboard: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        _refreshController.reverse();
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: widget.showBackButton
            ? AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
                ),
                title: AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: const Text(
                        "Final Leaderboard",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
                actions: [
                  AnimatedBuilder(
                    animation: _refreshAnimation,
                    builder: (context, child) {
                      return IconButton(
                        onPressed: _isRefreshing ? null : _refreshData,
                        icon: Transform.rotate(
                          angle: _refreshAnimation.value * 6.28,
                          child: Icon(
                            Icons.refresh,
                            color: _isRefreshing ? Colors.grey : Colors.white70,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              )
            : null,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Column(
                  children: [
                    if (!widget.showBackButton)
                      Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFFD700).withOpacity(0.15),
                              const Color(0xFFFF8F00).withOpacity(0.10),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFFD700).withOpacity(0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.2),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.emoji_events,
                              color: Color(0xFFFFD700),
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'FINAL LEADERBOARD',
                                    style: TextStyle(
                                      color: const Color(0xFFFFD700),
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                      shadows: [
                                        Shadow(
                                          color: const Color(0xFFFFD700).withOpacity(0.4),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Complete Rankings',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AnimatedBuilder(
                              animation: _refreshAnimation,
                              builder: (context, child) {
                                return GestureDetector(
                                  onTap: _isRefreshing ? null : _refreshData,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Transform.rotate(
                                      angle: _refreshAnimation.value * 6.28,
                                      child: Icon(
                                        Icons.refresh,
                                        color: _isRefreshing ? Colors.grey : Colors.white70,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                    // Main Leaderboard
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _slideAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, (1 - _slideAnimation.value) * 30),
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
                                        Icons.leaderboard,
                                        color: Color(0xFF1976D2),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'ALL PARTICIPANTS',
                                        style: TextStyle(
                                          color: const Color(0xFF1976D2),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                          shadows: [
                                            Shadow(
                                              color: const Color(0xFF1976D2).withOpacity(0.3),
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
                                          '$_totalParticipants Players',
                                          style: const TextStyle(
                                            color: Color(0xFF1976D2),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('leaderboard')
                                          .orderBy('score', descending: true)
                                          .snapshots(),
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
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.error_outline,
                                                  color: Colors.red.withOpacity(0.7),
                                                  size: 48,
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  'Error loading leaderboard',
                                                  style: TextStyle(
                                                    color: Colors.white.withOpacity(0.8),
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                ElevatedButton(
                                                  onPressed: _refreshData,
                                                  child: const Text('Retry'),
                                                ),
                                              ],
                                            ),
                                          );
                                        }

                                        final allPlayers = snapshot.data!.docs;
                                        
                                        if (allPlayers.isEmpty) {
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
                                                  'Be the first to complete a quiz!',
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
                                          itemCount: allPlayers.length,
                                          itemBuilder: (context, index) {
                                            final player = allPlayers[index];
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
                                                        Container(
                                                          width: 40,
                                                          height: 40,
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
                                                                    fontSize: 16,
                                                                    fontWeight: FontWeight.bold,
                                                                  ),
                                                                ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 16),
                                                        
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
                                                                  fontSize: 16,
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
                                                              if (player['lastUpdated'] != null)
                                                                Text(
                                                                  'Last active',
                                                                  style: TextStyle(
                                                                    color: Colors.white.withOpacity(0.5),
                                                                    fontSize: 10,
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                        
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 6,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: _getRankColor(index + 1).withOpacity(0.15),
                                                            borderRadius: BorderRadius.circular(10),
                                                            border: Border.all(
                                                              color: _getRankColor(index + 1).withOpacity(0.4),
                                                              width: 1,
                                                            ),
                                                          ),
                                                          child: Column(
                                                            children: [
                                                              Text(
                                                                '${player['score'] ?? 0}',
                                                                style: TextStyle(
                                                                  color: _getRankColor(index + 1),
                                                                  fontSize: 18,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                              Text(
                                                                'points',
                                                                style: TextStyle(
                                                                  color: _getRankColor(index + 1).withOpacity(0.7),
                                                                  fontSize: 10,
                                                                  fontWeight: FontWeight.w500,
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
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Current User Summary (if not visible in list or for confirmation)
                    if (_currentUserRank > 0)
                      Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _currentUserRank <= 10
                                ? [
                                    const Color(0xFF4CAF50).withOpacity(0.15),
                                    const Color(0xFF4CAF50).withOpacity(0.05),
                                  ]
                                : [
                                    const Color(0xFFFF6F00).withOpacity(0.15),
                                    const Color(0xFFFF6F00).withOpacity(0.05),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _currentUserRank <= 10
                                ? const Color(0xFF4CAF50).withOpacity(0.4)
                                : const Color(0xFFFF6F00).withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _currentUserRank <= 10 ? Icons.stars : Icons.my_location,
                                  color: _currentUserRank <= 10
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFFFF6F00),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Your Final Rank: $_currentUserRank / $_totalParticipants',
                                  style: TextStyle(
                                    color: _currentUserRank <= 10
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFFFF6F00),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            if (_currentUserData != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Final Score: ${_currentUserData!['score'] ?? 0} points',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
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