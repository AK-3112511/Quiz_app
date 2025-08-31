import 'package:flutter/material.dart';
import 'package:second_app/start_screen.dart';
import 'package:second_app/quiz_screen.dart';
import 'package:second_app/data/question.dart';
import 'package:second_app/result_screen.dart';


class Quiz extends StatefulWidget {
  const Quiz({super.key});

  @override
  State<Quiz> createState() {
    return _QuizState();
  }
}

class _QuizState extends State<Quiz> {

  List<String> selectedAnswers=[];

  Widget? activeScreen;

  @override
  void initState() {
    activeScreen=StartScreen(switchScreen);
    super.initState();
  }

  void switchScreen() {
    setState(() {
      activeScreen = QuestionScreen(choosedAnswer);
    });
  }

  void choosedAnswer(String answer) {
    selectedAnswers.add(answer);

    if(selectedAnswers.length==question.length)
    {
      setState((){
        activeScreen=ResultScreen(selectedAnswers,restartQuiz);
      });
    }
  }

  void restartQuiz(){
    setState((){
      selectedAnswers=[];
      activeScreen=StartScreen(switchScreen);
    });
  }

  @override
  Widget build(context) {
    return MaterialApp(
      home: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors:[
                Colors.blueAccent,
                Colors.deepPurpleAccent,
              ],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: activeScreen,
        ),
      ),
    );
  }
}