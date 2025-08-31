import 'package:flutter/material.dart';

class AnswerButton extends StatelessWidget {
  const AnswerButton(this.answerText,this.onTap,{super.key});

  final String answerText;
  final void Function() onTap;

  @override

  Widget build(context) {
    return ElevatedButton(
            onPressed:onTap,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 10,
              ),
              backgroundColor: Colors.amberAccent,
              foregroundColor: Colors.black,
              shape:RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
            ),
            child: Text(answerText),
          );
  }
}