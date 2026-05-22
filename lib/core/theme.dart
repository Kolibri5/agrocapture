import 'package:flutter/material.dart';

/// Agrocapture design-system theme.
///
/// Swap seed color or brightness to restyle the entire app.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF2E7D32), // deep green
      brightness: Brightness.light,
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF2E7D32),
      brightness: Brightness.dark,
    );
  }
}
