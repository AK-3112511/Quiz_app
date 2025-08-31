import 'package:flutter/material.dart';
import 'package:second_app/txt.dart';

class Summary extends StatelessWidget {
  const Summary(this.summaryData,{super.key});

  final List<Map<String,Object>> summaryData;

  @override
  Widget build(context) {
    return SizedBox(
      height:300,
      child:SingleChildScrollView(
        child:Column(
          children:summaryData.map((data){
            final bool isCorrect=
              data['user_answer']==data['correct_answer'];
            return Container(
              margin: const EdgeInsets.symmetric(vertical:8),
              padding: const EdgeInsets.all(12),
              decoration:BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCorrect?const Color.fromARGB(255, 10, 228, 17):const Color.fromARGB(255, 190, 22, 10),
                  width:3,
                ),
              ),
              child:Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: isCorrect?const Color.fromARGB(255, 10, 228, 17):const Color.fromARGB(255, 190, 22, 10),
                    radius:18,
                    child:Txt(((data['question_index'] as int) +1).toString(),Colors.white,18),
                  ),
                  const SizedBox(width:12), 
                  Expanded(
                    child:Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Txt(data['question']as String,Colors.black,18),
                        SizedBox(height:5),
                        Txt("Your Answer:${data['user_answer']}",isCorrect?const Color.fromARGB(255, 10, 228, 17):const Color.fromARGB(255, 190, 22, 10),18),
                        SizedBox(height:3),
                        if(!isCorrect)
                          Txt("Correct Answer:${data['correct_answer']}",const Color.fromARGB(255, 10, 228, 17),18),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}