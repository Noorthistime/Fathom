import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF2F58CD);
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color royalPurple = Color(0xFF8B5CF6);
  static const Color sunsetOrange = Color(0xFFF97316);

  static const List<Color> accentColors = [
    primaryBlue,
    emeraldGreen,
    royalPurple,
    sunsetOrange,
    Colors.pinkAccent,
    Colors.teal,
  ];

  static ThemeData getLightTheme(Color accentColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: accentColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: Brightness.light,
        background: const Color(0xFFF9F9FB),
        surface: const Color(0xFFFFFFFF),
        surfaceVariant: const Color(0xFFF1F1F4),
        onSurfaceVariant: const Color(0xFF434653),
      ),
      scaffoldBackgroundColor: const Color(0xFFF9F9FB),
      fontFamily: 'Inter',
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    );
  }

  static ThemeData getDarkTheme(Color accentColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: accentColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: Brightness.dark,
        background: const Color(0xFF11131A),
        surface: const Color(0xFF1E1F27),
        surfaceVariant: const Color(0xFF33343C),
        onSurfaceVariant: const Color(0xFFC4C5D6),
        primary: const Color(0xFFB6C4FF),
        secondary: const Color(0xFF4EDEA3),
      ),
      scaffoldBackgroundColor: const Color(0xFF11131A),
      fontFamily: 'Inter',
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
    );
  }
}
