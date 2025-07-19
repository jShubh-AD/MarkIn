import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TextWidget extends StatelessWidget {
  const TextWidget(
      {super.key,
        this.fontSize = 15,
        required this.text,
        this.fontWeight,
        this.color = Colors.black,
        this.textAlign,
        this.maxLines,
        this.overflow,
        this.decoration,
        this.letterSpacing = 0});

  final double? fontSize;
  final String text;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextDecoration? decoration;
  final double? letterSpacing;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        style: GoogleFonts.poppins(
            textStyle: TextStyle(
                letterSpacing: letterSpacing,
                color: color,
                fontSize: fontSize,
                fontWeight: fontWeight,
                decoration: decoration)));
  }
}
