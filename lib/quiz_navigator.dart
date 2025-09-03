// lib/screens/quiz_navigator.dart

import 'package:flutter/material.dart';
import 'package:Quiz_app/screens/start_screen.dart';
import 'package:Quiz_app/screens/login_screen.dart';
import 'package:Quiz_app/screens/language_selection_screen.dart';
import 'package:Quiz_app/screens/quiz_screen.dart';
import 'package:Quiz_app/screens/result_screen.dart';

class QuizNavigator extends StatefulWidget {
  const QuizNavigator({super.key});

  @override
  State<QuizNavigator> createState() => _QuizNavigatorState();
}

class _QuizNavigatorState extends State<QuizNavigator> {
  late Widget currentScreen;
  String? selectedLanguage;
  String? userName;

  @override
  void initState() {
    super.initState();
    // Initially, show the StartScreen and pass it the showLogin method
    currentScreen = StartScreen(startQuiz: showLogin);
  }

  void showLogin() {
    setState(() {
      // When startQuiz is called from StartScreen, switch to LoginScreen
      currentScreen = LoginScreen(onLoginComplete: showLanguageSelection);
    });
  }

  void showLanguageSelection(String name) {
    setState(() {
      userName = name;
      // When login is complete, switch to LanguageSelectionScreen
      currentScreen = LanguageSelectionScreen(onLanguageSelected: startQuiz);
    });
  }

  void startQuiz(String language) {
    setState(() {
      selectedLanguage = language;
      // When language is selected, switch to the QuizScreen with selected language
      currentScreen = QuizScreen(
        selectedLanguage: language,
        onQuizComplete: showResults,
      );
    });
  }

  void showResults(int score, int totalQuestions, int missed) {
    setState(() {
      // When the quiz is complete, switch to the ResultScreen
      currentScreen = ResultScreen(
        score: score, 
        totalQuestions: totalQuestions, 
        missed: missed,
        userName: userName!, // Pass the user name for leaderboard
        onRestart: restartQuiz
      );
    });
  }

  void restartQuiz() {
    setState(() {
      selectedLanguage = null;
      // Keep userName so user doesn't need to login again
      // When restart is called, go back to the LanguageSelectionScreen
      currentScreen = LanguageSelectionScreen(onLanguageSelected: startQuiz);
    });
  }

  @override
  Widget build(BuildContext context) {
    // AnimatedSwitcher smoothly animates the transition between screens
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 800),
        child: currentScreen,
      ),
    );
  }
}