// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLoginComplete});

  final void Function(String userName) onLoginComplete;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _glowController;
  late AnimationController _particleController;
  late AnimationController _scanlineController;
  late AnimationController _buttonController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _scanlineAnimation;
  late Animation<double> _buttonAnimation;
  late Animation<Color?> _buttonColorAnimation;

  final TextEditingController _nameController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _slideController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _glowController = AnimationController(duration: const Duration(milliseconds: 2500), vsync: this);
    _particleController = AnimationController(duration: const Duration(seconds: 15), vsync: this);
    _scanlineController = AnimationController(duration: const Duration(milliseconds: 3000), vsync: this);
    _buttonController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn)
    );
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack)
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut)
    );
    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_particleController);
    _scanlineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanlineController, curve: Curves.linear)
    );
    _buttonAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut)
    );
    _buttonColorAnimation = ColorTween(
      begin: const Color(0xFF00aaff),
      end: const Color(0xFF00ffff)
    ).animate(_buttonController);

    _startAnimations();
  }

  void _startAnimations() {
    _fadeController.forward();
    _glowController.repeat(reverse: true);
    _particleController.repeat();
    _scanlineController.repeat();
    
    Future.delayed(const Duration(milliseconds: 300), () {
      _slideController.forward();
    });
  }

  void _validateAndProceed() {
    final name = _nameController.text.trim();
    
    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your name to continue';
      });
      HapticFeedback.mediumImpact();
      return;
    }
    
    if (name.length < 2) {
      setState(() {
        _errorMessage = 'Name must be at least 2 characters';
      });
      HapticFeedback.mediumImpact();
      return;
    }
    
    if (name.length > 20) {
      setState(() {
        _errorMessage = 'Name must be less than 20 characters';
      });
      HapticFeedback.mediumImpact();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    HapticFeedback.heavyImpact();
    _buttonController.forward();

    // Simulate login process
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        widget.onLoginComplete(name);
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    _scanlineController.dispose();
    _buttonController.dispose();
    _nameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        resizeToAvoidBottomInset: true, // Allow keyboard adjustment
        body: Stack(
          children: [
            // Animated background particles
            AnimatedBuilder(
              animation: _particleAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticlePainter(animationValue: _particleAnimation.value),
                  size: Size.infinite,
                );
              },
            ),

            // Scanning line effect
            AnimatedBuilder(
              animation: _scanlineAnimation,
              builder: (context, child) {
                return Positioned(
                  top: MediaQuery.of(context).size.height * _scanlineAnimation.value - 2,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.cyanAccent.withOpacity(0.6),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            SafeArea(
              child: SingleChildScrollView( // Added scrollable container
                padding: const EdgeInsets.all(24),
                child: AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height - 
                                   MediaQuery.of(context).padding.top - 
                                   MediaQuery.of(context).padding.bottom - 48, // Account for padding
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 40), // Reduced from 60

                            // Header Section
                            AnimatedBuilder(
                              animation: _slideAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _slideAnimation.value),
                                  child: AnimatedBuilder(
                                    animation: _glowAnimation,
                                    builder: (context, child) {
                                      return Container(
                                        padding: const EdgeInsets.all(24), // Reduced from 32
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(20),
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.black.withOpacity(0.8),
                                              const Color(0xFF1a1a2e).withOpacity(0.6),
                                              Colors.black.withOpacity(0.8)
                                            ],
                                          ),
                                          border: Border.all(
                                            color: Colors.cyanAccent.withOpacity(_glowAnimation.value * 0.8),
                                            width: 2
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.cyanAccent.withOpacity(_glowAnimation.value * 0.3),
                                              blurRadius: 25,
                                              spreadRadius: 5
                                            )
                                          ],
                                        ),
                                        child: Column(
                                          children: [
                                            Container(
                                              width: 70, // Reduced from 80
                                              height: 70, // Reduced from 80
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: RadialGradient(
                                                  colors: [
                                                    Colors.cyanAccent.withOpacity(0.3),
                                                    Colors.cyanAccent.withOpacity(0.1),
                                                    Colors.transparent,
                                                  ],
                                                ),
                                                border: Border.all(
                                                  color: Colors.cyanAccent.withOpacity(_glowAnimation.value),
                                                  width: 2
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.person_add_alt_1,
                                                color: Colors.cyanAccent.withOpacity(_glowAnimation.value),
                                                size: 35, // Reduced from 40
                                              ),
                                            ),
                                            const SizedBox(height: 16), // Reduced from 20
                                            Text(
                                              'ACCESS',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.cyanAccent.withOpacity(_glowAnimation.value),
                                                fontSize: 22, // Reduced from 24
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 4,
                                              ),
                                            ),
                                            const SizedBox(height: 6), // Reduced from 8
                                            Text(
                                              'TERMINAL',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.cyanAccent,
                                                fontSize: 32, // Reduced from 36
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 5,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.cyanAccent.withOpacity(0.8),
                                                    blurRadius: 15,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 12), // Reduced from 15
                                            Text(
                                              'Enter your identity to access the quiz system',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.grey.shade300,
                                                fontSize: 15, // Reduced from 16
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 50), // Reduced from 80

                            // Input Section
                            AnimatedBuilder(
                              animation: _slideAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _slideAnimation.value * 1.5),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Name Input Field
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(15),
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.black.withOpacity(0.6),
                                              const Color(0xFF1a1a2e).withOpacity(0.4),
                                            ],
                                          ),
                                          border: Border.all(
                                            color: _focusNode.hasFocus 
                                                ? Colors.cyanAccent.withOpacity(0.8)
                                                : Colors.grey.withOpacity(0.3),
                                            width: 2,
                                          ),
                                          boxShadow: _focusNode.hasFocus ? [
                                            BoxShadow(
                                              color: Colors.cyanAccent.withOpacity(0.2),
                                              blurRadius: 15,
                                              spreadRadius: 2,
                                            ),
                                          ] : [],
                                        ),
                                        child: TextField(
                                          controller: _nameController,
                                          focusNode: _focusNode,
                                          enabled: !_isLoading,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Enter your name...',
                                            hintStyle: TextStyle(
                                              color: Colors.grey.shade400,
                                              fontSize: 16,
                                            ),
                                            prefixIcon: Icon(
                                              Icons.account_circle_outlined,
                                              color: _focusNode.hasFocus 
                                                  ? Colors.cyanAccent
                                                  : Colors.grey.shade400,
                                              size: 24,
                                            ),
                                            border: InputBorder.none,
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 18
                                            ),
                                          ),
                                          textInputAction: TextInputAction.done,
                                          onSubmitted: (_) => _validateAndProceed(),
                                          onChanged: (_) {
                                            if (_errorMessage.isNotEmpty) {
                                              setState(() {
                                                _errorMessage = '';
                                              });
                                            }
                                          },
                                        ),
                                      ),

                                      // Error Message
                                      if (_errorMessage.isNotEmpty)
                                        Container(
                                          margin: const EdgeInsets.only(top: 12),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16, 
                                            vertical: 10
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade900.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: Colors.red.shade600.withOpacity(0.5),
                                              width: 1
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.error_outline,
                                                color: Colors.red.shade400,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  _errorMessage,
                                                  style: TextStyle(
                                                    color: Colors.red.shade300,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                      const SizedBox(height: 30), // Reduced from 40

                                      // Continue Button
                                      AnimatedBuilder(
                                        animation: Listenable.merge([_buttonAnimation, _buttonColorAnimation]),
                                        builder: (context, child) {
                                          return Transform.scale(
                                            scale: _buttonAnimation.value,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(50),
                                                gradient: LinearGradient(
                                                  colors: [
                                                    _buttonColorAnimation.value!.withOpacity(_isLoading ? 0.5 : 1.0),
                                                    const Color(0xFF0077cc).withOpacity(_isLoading ? 0.5 : 1.0),
                                                    const Color(0xFF004499).withOpacity(_isLoading ? 0.5 : 1.0),
                                                  ],
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: _buttonColorAnimation.value!.withOpacity(_isLoading ? 0.2 : 0.5),
                                                    blurRadius: 20,
                                                    spreadRadius: 3,
                                                  ),
                                                ],
                                              ),
                                              child: ElevatedButton.icon(
                                                onPressed: _isLoading ? null : _validateAndProceed,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.transparent,
                                                  shadowColor: Colors.transparent,
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 40, 
                                                    vertical: 16
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(50)
                                                  ),
                                                ),
                                                icon: _isLoading
                                                    ? const SizedBox(
                                                        width: 24,
                                                        height: 24,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                        ),
                                                      )
                                                    : const Icon(
                                                        Icons.arrow_forward_rounded,
                                                        color: Colors.white,
                                                        size: 28,
                                                      ),
                                                label: Text(
                                                  _isLoading ? 'ACCESSING...' : 'CONTINUE',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),

                                      const SizedBox(height: 30), // Reduced from 40

                                      // Info Section
                                      Container(
                                        padding: const EdgeInsets.all(18), // Reduced from 20
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.grey.withOpacity(0.2),
                                            width: 1
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              color: Colors.amberAccent.withOpacity(0.8),
                                              size: 24,
                                            ),
                                            const SizedBox(width: 15),
                                            Expanded(
                                              child: Text(
                                                'Your name will be used for the leaderboard and progress tracking',
                                                style: TextStyle(
                                                  color: Colors.grey.shade300,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 20), // Bottom padding
                                    ],
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final double animationValue;
  
  ParticlePainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    for (int i = 0; i < 30; i++) {
      final x = (size.width * (i / 30) + animationValue * 50) % size.width;
      final y = (size.height * ((i * 0.7) % 1) + sin(animationValue * 2 * pi + i) * 20) % size.height;
      
      paint.color = [
        Colors.cyanAccent,
        Colors.blueAccent,
        Colors.pinkAccent
      ][i % 3].withOpacity(0.1 + sin(animationValue * pi + i) * 0.1);
      
      canvas.drawCircle(
        Offset(x, y),
        1 + sin(animationValue * 2 * pi + i) * 0.5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}