import 'package:flutter/material.dart';
import 'package:second_app/txt.dart';
import 'package:second_app/data/question.dart';
import 'package:second_app/summary.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen(this.choosedAnswers,this.onRestart,{super.key});

  final List<String> choosedAnswers;
  final void Function() onRestart;

  List<Map<String,Object>> getSummaryData() {
    final List<Map<String,Object>> summary=[];

    for(var i=0;i<choosedAnswers.length;i++) {
      summary.add({
        'question_index':i,
        'question':question[i].text,
        'correct_answer':question[i].answers[0],
        'user_answer':choosedAnswers[i],
      });
    }

    return summary;
  }

  @override
  Widget build(context) {

    final summaryData = getSummaryData();
    final X=summaryData.where((data){
      return data['user_answer']==data['correct_answer'];
    }).length;
    final Y=question.length;

    return SizedBox(
      width:double.infinity,
      child: Container(
        margin: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:[
            Txt('You answered $X out $Y questions correctly!',const Color.fromARGB(255, 8, 86, 5),28),
            const SizedBox(height:30),
            Summary(summaryData),
            const SizedBox(height:30),
            TextButton(
              onPressed:onRestart,
              child:Txt('Restart Quiz!',const Color.fromARGB(213, 1, 39, 41),32),
            ),
          ],
        ),
      ),
    );
  }

}