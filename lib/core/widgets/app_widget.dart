import 'package:attendence/core/widgets/text_widget.dart';
import 'package:flutter/material.dart';

class AppWidget {
  static Widget listTile(String? title, String? text) {
    return Row(
      children: [
        const SizedBox(width: 16),
        TextWidget(text: text!)
      ],
    );
  }
}