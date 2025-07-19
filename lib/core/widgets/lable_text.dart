import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LabeledText extends StatelessWidget {
  final String label;
  final String value;
  final double labelFontSize;
  final double valueFontSize;
  final FontWeight labelWeight;
  final FontWeight valueWeight;
  final Color? labelColor;
  final Color? valueColor;

  const LabeledText({
    Key? key,
    required this.label,
    required this.value,
    this.labelFontSize = 16,
    this.valueFontSize = 15,
    this.labelWeight = FontWeight.bold,
    this.valueWeight = FontWeight.normal,
    this.labelColor,
    this.valueColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final defaultColor = DefaultTextStyle.of(context).style.color;

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: GoogleFonts.poppins(
              fontSize: labelFontSize,
              fontWeight: labelWeight,
              color: labelColor ?? defaultColor,
            ),
          ),
          TextSpan(
            text: value,
            style: GoogleFonts.poppins(
              fontSize: valueFontSize,
              fontWeight: valueWeight,
              color: valueColor ?? defaultColor,
            ),
          ),
        ],
      ),
    );
  }
}
