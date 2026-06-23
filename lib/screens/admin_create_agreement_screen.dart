import 'package:flutter/material.dart';

class AppTheme {
  static const Color terracotta = Color(0xFFCD5C5C);
  static const Color parchment = Color(0xFFFFF8F0);
  static const Color ink = Color(0xFF1A1A1A);
  static const Color border = Color(0xFFE8E0D8);
  static const Color textSecondary = Color(0xFF757575);
  static const Color sage = Color(0xFF6B8F71);
  static const Color sageLight = Color(0xFFE8F0E6);
  static const Color cardSurface = Color(0xFFFFFFFF);

  static TextStyle display({double fontSize = 16, Color color = Colors.black}) {
    return TextStyle(fontSize: fontSize, color: color, fontWeight: FontWeight.w600);
  }

  static TextStyle body({double fontSize = 14, Color color = Colors.black, FontWeight fontWeight = FontWeight.normal}) {
    return TextStyle(fontSize: fontSize, color: color, fontWeight: fontWeight);
  }
}
