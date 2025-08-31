import 'package:flutter/material.dart';
import 'package:second_app/txt.dart';

class StartScreen  extends StatelessWidget{
  const StartScreen(this.startQuiz,{super.key});

  final void Function() startQuiz;

  @override
  Widget build(context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children:[
          Image.asset(
            'assets/images/quiz_logo.png',
            width:300,
          ),
          const SizedBox(height:80),
          const Txt('Learn Flutter',Colors.orangeAccent,36),

          const SizedBox(height:30),
          OutlinedButton.icon(
            onPressed:startQuiz, 
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 200, 214, 8),
            ),
            icon: const Icon(
              Icons.lightbulb_circle_outlined,
              color: Color.fromARGB(255, 236, 21, 5),
              size: 18,
            ),
            label:const Txt('Start Quiz',Color.fromARGB(47, 2, 105, 7),24),
          ),
        ],
      ),
    );
  }
}