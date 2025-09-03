// lib/screens/language_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key, required this.onLanguageSelected});

  final void Function(String selectedLanguage) onLanguageSelected;

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  String? selectedLanguage;
  
  final List<Map<String, dynamic>> languages = [
    {
      'name': 'Flutter',
      'icon': Icons.flutter_dash,
      'color': Colors.blueAccent,
      'description': 'Cross-platform UI toolkit',
    },
    {
      'name': 'Kotlin',
      'icon': Icons.android,
      'color': Colors.greenAccent,
      'description': 'Modern Android development',
    },
    {
      'name': 'Python',
      'icon': Icons.code,
      'color': Colors.amberAccent,
      'description': 'Versatile programming language',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _slideController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn)
    );
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack)
    );

    _startAnimations();
  }

  void _startAnimations() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
  }

  void _selectLanguage(String language) {
    HapticFeedback.mediumImpact();
    setState(() {
      selectedLanguage = language;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      widget.onLanguageSelected(language);
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    
                    // Header
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.8),
                            const Color(0xFF1a1a2e).withOpacity(0.6),
                            Colors.black.withOpacity(0.8)
                          ],
                        ),
                        border: Border.all(color: Colors.cyanAccent.withOpacity(0.8), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyanAccent.withOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: 10
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'SELECT YOUR',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.cyanAccent.withOpacity(0.8),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'EXPERTISE',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                              shadows: [
                                Shadow(
                                  color: Colors.cyanAccent.withOpacity(0.8),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            'Choose your preferred technology to customize your quiz experience',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade300,
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Language Options
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _slideAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _slideAnimation.value),
                            child: ListView.builder(
                              itemCount: languages.length,
                              itemBuilder: (context, index) {
                                final language = languages[index];
                                final isSelected = selectedLanguage == language['name'];
                                
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 20),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: LinearGradient(
                                        colors: isSelected 
                                          ? [
                                              language['color'].withOpacity(0.3),
                                              language['color'].withOpacity(0.1),
                                            ]
                                          : [
                                              Colors.grey.shade900.withOpacity(0.8),
                                              Colors.black.withOpacity(0.6),
                                            ],
                                      ),
                                      border: Border.all(
                                        color: isSelected 
                                          ? language['color']
                                          : Colors.grey.shade600,
                                        width: isSelected ? 3 : 2,
                                      ),
                                      boxShadow: isSelected 
                                        ? [
                                            BoxShadow(
                                              color: language['color'].withOpacity(0.5),
                                              blurRadius: 20,
                                              spreadRadius: 5,
                                            ),
                                          ]
                                        : [],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: () => _selectLanguage(language['name']),
                                        child: Padding(
                                          padding: const EdgeInsets.all(25),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 60,
                                                height: 60,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: language['color'].withOpacity(0.2),
                                                  border: Border.all(
                                                    color: language['color'],
                                                    width: 2,
                                                  ),
                                                ),
                                                child: Icon(
                                                  language['icon'],
                                                  color: language['color'],
                                                  size: 30,
                                                ),
                                              ),
                                              const SizedBox(width: 20),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      language['name'],
                                                      style: TextStyle(
                                                        color: isSelected 
                                                          ? language['color']
                                                          : Colors.white,
                                                        fontSize: 24,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 5),
                                                    Text(
                                                      language['description'],
                                                      style: TextStyle(
                                                        color: Colors.grey.shade400,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (isSelected)
                                                Container(
                                                  width: 30,
                                                  height: 30,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: language['color'],
                                                  ),
                                                  child: const Icon(
                                                    Icons.check,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Info text
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
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
                              'Select your preferred technology to get customized questions',
                              style: TextStyle(
                                color: Colors.grey.shade300,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}