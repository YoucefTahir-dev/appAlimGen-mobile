import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();
  static const _green = Color(0xFF11734B);
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: _green,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF5F7F8),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
