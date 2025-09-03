import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:Quiz_app/data/quiz_data.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key, required this.startQuiz});

  final VoidCallback startQuiz;

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _rotateController;
  late AnimationController _floatController;
  late AnimationController _sparkleController;
  late AnimationController _hologramController;
  late AnimationController _scanlineController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _sparkleAnimation;
  late Animation<double> _hologramAnimation;
  late Animation<double> _scanlineAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    _glowController = AnimationController(duration: const Duration(milliseconds: 2500), vsync: this);
    _rotateController = AnimationController(duration: const Duration(seconds: 20), vsync: this);
    _floatController = AnimationController(duration: const Duration(milliseconds: 3000), vsync: this);
    _sparkleController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
    _hologramController = AnimationController(duration: const Duration(milliseconds: 4000), vsync: this);
    _scanlineController = AnimationController(duration: const Duration(milliseconds: 2000), vsync: this);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _glowAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));
    _rotateAnimation = Tween<double>(begin: 0.0, end: 2 * pi).animate(CurvedAnimation(parent: _rotateController, curve: Curves.linear));
    _floatAnimation = Tween<double>(begin: -15.0, end: 15.0).animate(CurvedAnimation(parent: _floatController, curve: Curves.easeInOut));
    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut));
    _hologramAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _hologramController, curve: Curves.easeInOut));
    _scanlineAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _scanlineController, curve: Curves.linear));

    _pulseController.repeat(reverse: true);
    _glowController.repeat(reverse: true);
    _rotateController.repeat();
    _floatController.repeat(reverse: true);
    _sparkleController.repeat();
    _hologramController.repeat(reverse: true);
    _scanlineController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _rotateController.dispose();
    _floatController.dispose();
    _sparkleController.dispose();
    _hologramController.dispose();
    _scanlineController.dispose();
    super.dispose();
  }

  void _onStartPressed() {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.click);
    
    _pulseController.forward().then((_) {
      widget.startQuiz();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Your custom image background goes here
      decoration: const BoxDecoration(
        image: DecorationImage(
          // TODO: Add your image path here. For example: AssetImage('assets/images/background.jpg')
          image: AssetImage('assets/images/IOTA_logo.png'), 
          fit: BoxFit.contain,
        ),
      ),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _scanlineAnimation,
            builder: (context, child) {
              return Positioned(
                top: MediaQuery.of(context).size.height * _scanlineAnimation.value - 2,
                left: 0,
                right: 0,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        Colors.transparent,
                        Colors.cyanAccent.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(height: 60),

                  Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      AnimatedBuilder(
                        animation: _hologramAnimation,
                        builder: (context, child) {
                          return Container(
                            width: 300,
                            height: 300,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: <Color>[
                                  Colors.transparent,
                                  Colors.cyanAccent.withOpacity(_hologramAnimation.value * 0.1),
                                  Colors.pinkAccent.withOpacity(_hologramAnimation.value * 0.1),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      ...List<Widget>.generate(20, (int index) => _CyberSparkle(
                        index: index,
                        sparkleAnimation: _sparkleAnimation,
                        rotateAnimation: _rotateAnimation,
                        glowAnimation: _glowAnimation,
                      )),
                      AnimatedBuilder(
                        animation: _floatController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _floatAnimation.value),
                            child: AnimatedBuilder(
                              animation: _rotateController,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _rotateAnimation.value * 0.05,
                                  child: AnimatedBuilder(
                                    animation: _pulseAnimation,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _pulseAnimation.value,
                                        child: Container(
                                          width: 180,
                                          height: 180,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: RadialGradient(
                                              colors: <Color>[
                                                const Color(0xFF00ffff).withOpacity(0.8),
                                                const Color(0xFF0080ff).withOpacity(0.6),
                                                const Color(0xFF8000ff).withOpacity(0.4),
                                                Colors.transparent,
                                              ],
                                            ),
                                            border: Border.all(
                                              color: Colors.cyanAccent.withOpacity(_glowAnimation.value),
                                              width: 3,
                                            ),
                                            boxShadow: <BoxShadow>[
                                              BoxShadow(
                                                color: Colors.cyanAccent.withOpacity(_glowAnimation.value),
                                                blurRadius: 50,
                                                spreadRadius: 15,
                                              ),
                                            ],
                                          ),
                                          child: const Center(
                                            child: Icon(Icons.quiz, size: 80, color: Colors.white),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 60),

                  AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          gradient: LinearGradient(
                            colors: <Color>[Colors.black.withOpacity(0.8), const Color(0xFF1a1a2e).withOpacity(0.6), Colors.black.withOpacity(0.8)],
                          ),
                          border: Border.all(color: Colors.cyanAccent.withOpacity(_glowAnimation.value * 0.8), width: 2),
                          boxShadow: <BoxShadow>[BoxShadow(color: Colors.cyanAccent.withOpacity(_glowAnimation.value * 0.4), blurRadius: 30, spreadRadius: 10)],
                        ),
                        child: Text(
                          // The new title you requested
                          'Android Quiz',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.cyanAccent.withOpacity(_glowAnimation.value),
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            shadows: <Shadow>[
                              Shadow(color: Colors.cyanAccent.withOpacity(0.8), blurRadius: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.black.withOpacity(0.4),
                      border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
                    ),
                    child: Column(
                      children: <Widget>[
                        Icon(Icons.security, color: Colors.amberAccent.withOpacity(0.8), size: 32),
                        const SizedBox(height: 15),
                        const Text('Enter to the Android World!', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Text(
                          '${QuizData.generalQuestions.length} Questions • 15 Seconds Each\nTest Your Knowledge in the APP Realm',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade300, fontSize: 16, height: 1.4),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 60),

                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            gradient: LinearGradient(
                              colors: <Color>[
                                const Color(0xFF00aaff).withOpacity(_glowAnimation.value),
                                const Color(0xFF0077cc).withOpacity(_glowAnimation.value),
                                const Color(0xFF004499).withOpacity(_glowAnimation.value),
                              ],
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: const Color(0xFF00aaff).withOpacity(_glowAnimation.value * 0.8),
                                blurRadius: 30,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _onStartPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                            ),
                            icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                            label: const Text(
                              'INITIALIZE',
                              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper widget for sparkle effect
class _CyberSparkle extends StatelessWidget {
  final int index;
  final Animation<double> sparkleAnimation;
  final Animation<double> rotateAnimation;
  final Animation<double> glowAnimation;

  const _CyberSparkle({
    required this.index,
    required this.sparkleAnimation,
    required this.rotateAnimation,
    required this.glowAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final angle = (index / 20) * 2 * pi + rotateAnimation.value;
    final radius = 120 + sin(sparkleAnimation.value * 2 * pi) * 20;
    
    return Positioned(
      left: 150 + cos(angle) * radius - 3,
      top: 150 + sin(angle) * radius - 3,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: [Colors.cyanAccent, Colors.pinkAccent, Colors.amberAccent, Colors.greenAccent][index % 4].withOpacity(sparkleAnimation.value * glowAnimation.value),
          boxShadow: [
            BoxShadow(
              color: [Colors.cyanAccent, Colors.pinkAccent, Colors.amberAccent, Colors.greenAccent][index % 4].withOpacity(sparkleAnimation.value * 0.8),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}