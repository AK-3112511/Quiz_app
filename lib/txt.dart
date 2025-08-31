import  'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Txt extends StatelessWidget {
  const Txt (this.text,this.color,this.size,{super.key});

  final String text;
  final Color color;
  final double size;

  @override
  Widget build(context) {
    return Text(
      text,
      textAlign:TextAlign.center,
      style:GoogleFonts.lato(
        color: color,
        fontSize:size,
        fontWeight:FontWeight.bold, 
      ),
    );
  }
}