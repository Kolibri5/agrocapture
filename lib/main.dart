import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Make the status bar transparent so the app feels edge-to-edge.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const AgrocaptureApp());
}

class AgrocaptureApp extends StatelessWidget {
  const AgrocaptureApp({super.key});

  // ── Design palette — extracted from the colour reference ────────
  //
  // Primary greens  (dark → light)
  //   #0E5135  #186B4C  #1B6E3C  #279169  #3BA07E  #69C49E  #C5E8D8  #E3F5EC
  //
  // Secondary (indigo)
  //   #1C2340  #252D4A  #2E3654  #3D4568  #35407A  #5B6499  #C5C9DC
  //
  // Monochrome
  //   #0A0F14  #1A2028  #2E3640  #6B7680  #BCC3C9  #E4E8EC

  static const Color _primary = Color(0xFF1B6E3C);
  static const Color _primaryDark = Color(0xFF0E5135);
  static const Color _secondary = Color(0xFF2E3654);
  static const Color _surface = Color(0xFFF8FAF8);
  static const Color _onSurface = Color(0xFF0A0F14);

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.light,
      primary: _primary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFC5E8D8),
      onPrimaryContainer: _primaryDark,
      secondary: _secondary,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFC5C9DC),
      onSecondaryContainer: const Color(0xFF1C2340),
      surface: _surface,
      onSurface: _onSurface,
      surfaceContainerHighest: const Color(0xFFE4E8EC),
      outline: const Color(0xFFBCC3C9),
    );

    return MaterialApp(
      title: 'Agrocapture',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: scheme.surface,
        appBarTheme: AppBarTheme(
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        fontFamily: 'Roboto',
      ),
      home: const MainScreen(),
    );
  }
}
