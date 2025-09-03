// lib/screens/quiz_screen.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:Quiz_app/data/quiz_data.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key, 
    required this.onQuizComplete,
    required this.selectedLanguage,
  });

  final void Function(int score, int totalQuestions, int missed) onQuizComplete;
  final String selectedLanguage;

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
  late List<Map<String, dynamic>> questions;
  bool _isTransitioning = false; // Add this to prevent flickering

  late AnimationController _timerController;
  late AnimationController _questionController;
  late Animation<double> _questionAnimation;
  late Animation<Color?> _timerColorAnimation;

  @override
  void initState() {
    super.initState();
    
    // Get questions based on selected language and randomize them
    List<Map<String, dynamic>> originalQuestions = QuizData.getQuestionsByLanguage(widget.selectedLanguage);
    questions = _randomizeQuestions(originalQuestions);
    
    _timerController = AnimationController(duration: const Duration(seconds: 15), vsync: this);
    _questionController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _questionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _questionController, curve: Curves.easeInOut));
    _timerColorAnimation = ColorTween(begin: Colors.green, end: Colors.red).animate(_timerController);

    _startQuestion();
  }

  // Function to randomize questions while keeping all 15 questions
  List<Map<String, dynamic>> _randomizeQuestions(List<Map<String, dynamic>> originalQuestions) {
    List<Map<String, dynamic>> randomizedQuestions = [];
    
    for (var question in originalQuestions) {
      // Create a copy of the question with randomized answers
      Map<String, dynamic> randomizedQuestion = _randomizeAnswers(Map<String, dynamic>.from(question));
      randomizedQuestions.add(randomizedQuestion);
    }
    
    // Shuffle the questions order
    randomizedQuestions.shuffle(Random());
    return randomizedQuestions;
  }

  // Function to randomize answers for a question
  Map<String, dynamic> _randomizeAnswers(Map<String, dynamic> question) {
    List<String> answers = List<String>.from(question['answers']);
    int correctAnswerIndex = question['correct'];
    String correctAnswer = answers[correctAnswerIndex];
    
    // Shuffle the answers
    answers.shuffle(Random());
    
    // Find the new position of the correct answer
    int newCorrectIndex = answers.indexOf(correctAnswer);
    
    return {
      'question': question['question'],
      'answers': answers,
      'correct': newCorrectIndex,
    };
  }

  void _startQuestion() {
    _questionController.reset();
    _questionController.forward();
    _timerController.reset();
    _timerController.forward();

    // Cancel any existing timer
    _questionTimer?.cancel();
    
    // Start the 15-second timer
    _questionTimer = Timer(const Duration(seconds: 15), () {
      if (mounted && !answered && !_isTransitioning) {
        // Time's up - count as missed
        setState(() {
          missed++;
        });
        _nextQuestion();
      }
    });

    setState(() {
      answered = false;
      selectedAnswer = null;
      _isTransitioning = false;
    });
  }

  void _selectAnswer(int answerIndex) {
    if (answered || _isTransitioning) return;

    // Cancel the timer since user answered
    _questionTimer?.cancel();
    _timerController.stop();

    setState(() {
      answered = true;
      selectedAnswer = answerIndex;

      if (answerIndex == questions[currentQuestionIndex]['correct']) {
        score++;
      }
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _nextQuestion();
      }
    });
  }

  void _nextQuestion() {
    if (_isTransitioning) return; // Prevent multiple calls
    
    setState(() {
      _isTransitioning = true;
    });

    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
      _startQuestion();
    } else {
      // Add a small delay before completing quiz to prevent flickering
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          // Quiz completed - pass score, total questions, and missed count
          widget.onQuizComplete(score, questions.length, missed);
        }
      });
    }
  }

  @override
  void dispose() {
    _questionTimer?.cancel();
    _timerController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isTransitioning && currentQuestionIndex >= questions.length) {
      // Show loading indicator during transition to prevent flickering
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0F0F), Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
          ),
        ),
      );
    }

    final question = questions[currentQuestionIndex];

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Question ${currentQuestionIndex + 1}/${questions.length}',
                        style: const TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.2),
                          border: Border.all(color: Colors.blueAccent, width: 1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.selectedLanguage.toUpperCase(),
                          style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.pinkAccent, width: 2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Score: $score',
                      style: const TextStyle(color: Colors.pinkAccent, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AnimatedBuilder(
                animation: _timerController,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: 1.0 - _timerController.value,
                    backgroundColor: Colors.grey.shade800,
                    valueColor: _timerColorAnimation,
                    minHeight: 8,
                  );
                },
              ),
              const SizedBox(height: 40),
              AnimatedBuilder(
                animation: _questionAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _questionAnimation.value,
                    child: Opacity(
                      opacity: _questionAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.cyanAccent.withOpacity(0.1),
                              Colors.transparent,
                              Colors.pinkAccent.withOpacity(0.1),
                            ],
                          ),
                          border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          question['question'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, height: 1.4),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              Expanded(
                child: ListView.builder(
                  itemCount: question['answers'].length,
                  itemBuilder: (context, index) {
                    final answer = question['answers'][index];
                    final isCorrect = index == question['correct'];
                    final isSelected = selectedAnswer == index;
                    Color buttonColor = Colors.transparent;
                    Color borderColor = Colors.grey.shade600;
                    Color textColor = Colors.white;

                    if (answered) {
                      if (isCorrect) {
                        buttonColor = Colors.green.withOpacity(0.3);
                        borderColor = Colors.green;
                        textColor = Colors.green;
                      } else if (isSelected) {
                        buttonColor = Colors.red.withOpacity(0.3);
                        borderColor = Colors.red;
                        textColor = Colors.red;
                      }
                    }
                    
                    return AnimatedBuilder(
                      animation: _questionAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset((1.0 - _questionAnimation.value) * 100 * (index % 2 == 0 ? -1 : 1), 0),
                          child: Opacity(
                            opacity: _questionAnimation.value,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              child: ElevatedButton(
                                onPressed: (answered || _isTransitioning) ? null : () => _selectAnswer(index),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: buttonColor,
                                  padding: const EdgeInsets.all(20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    side: BorderSide(color: borderColor, width: 2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: borderColor, width: 2),
                                      ),
                                      child: Center(
                                        child: Text(
                                          String.fromCharCode(65 + index),
                                          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      child: Text(
                                        answer,
                                        style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    if (answered && isCorrect)
                                      const Icon(Icons.check_circle, color: Colors.green, size: 30),
                                    if (answered && isSelected && !isCorrect)
                                      const Icon(Icons.cancel, color: Colors.red, size: 30),
                                  ],
                                ),
                              ),
                            ),
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
    );
  }
}