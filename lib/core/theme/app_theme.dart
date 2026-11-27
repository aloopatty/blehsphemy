import 'package:flutter/material.dart';

class AppTheme {
  static const background = Color(0xFF080B14);
  static const surface = Color(0xFF111827);
  static const violet = Color(0xFF9B8CFF);
  static const cyan = Color(0xFF63D9E8);
  static const pink = Color(0xFFED8AB7);

  static ThemeData dark() => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: violet, secondary: cyan, surface: surface,

    ),
    useMaterial3: true,
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -1),
      titleLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -.3),
      bodyMedium: TextStyle(height: 1.45),
    ),
  );

  static ThemeData light() => ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF4F5FA),
    colorScheme: ColorScheme.fromSeed(seedColor: violet, brightness: Brightness.light),
    useMaterial3: true,
  );
}
