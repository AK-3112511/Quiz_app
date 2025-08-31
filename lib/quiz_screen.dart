import 'package:flutter/material.dart';
import 'package:second_app/txt.dart';
import 'package:second_app/answer_button.dart';
import 'package:second_app/data/question.dart';

class QuestionScreen extends StatefulWidget{
  const QuestionScreen(this.onSelectAnswer,{super.key});

  final void Function(String answer) onSelectAnswer;

  @override
  State<QuestionScreen> createState() {
    return  _QuizScreenState();
  }
}

class _QuizScreenState extends State<QuestionScreen> {

  var currentQuestionIndex=0;

  void questionAnswered(String selectedAnswer) {
    widget.onSelectAnswer(selectedAnswer);
    setState((){
      currentQuestionIndex++;
    });
  }

  @override
  Widget build(context) {
    final currentQuestion=question[currentQuestionIndex];
    
    return SizedBox(
      width: double.infinity,
      child:Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children:[
          Txt(currentQuestion.text,Color.fromARGB(255, 87, 35, 31),28),
          const SizedBox(height:40),
          ...currentQuestion.getShuffledAnswers().map((answer){
            return AnswerButton(answer,(){questionAnswered(answer);});
          }),
        ],
      ),
    );
  }
}