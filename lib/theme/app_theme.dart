import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF2E7D6B);
  static const Color takenColor = Color(0xFF4CAF50);
  static const Color missedColor = Color(0xFFE53935);

  static ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: Colors.white,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      bodyMedium: TextStyle(fontSize: 16),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
  );
}