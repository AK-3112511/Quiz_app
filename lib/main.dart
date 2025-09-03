// lib/main.dart

import 'package:flutter/material.dart';
import 'package:Quiz_app/quiz_navigator.dart';

void main() {
  runApp(const QuizApp());
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cyber Quiz Matrix',
      theme: ThemeData.dark(),
      home: const QuizNavigator(),
      debugShowCheckedModeBanner: false,
    );
  }
}