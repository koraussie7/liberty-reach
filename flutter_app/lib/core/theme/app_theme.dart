/// App theme (colors, typography, glassmorphism)
import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const String _fontFamily = 'Inter';

  // --- Colors ---
  static const Color primary = Color(0xFF6C63FF);
  static const Color accent = Color(0xFF00D9FF);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color background = Color(0xFF0F0F23);
  static const Color card = Color(0xFF16213E);

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0A0A0A),
    fontFamily: _fontFamily,
    primaryColor: Colors.deepPurple,
    colorScheme: const ColorScheme.dark(
      primary: Colors.deepPurpleAccent,
      secondary: Colors.purpleAccent,
      surface: Color(0xFF1A1A1A),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white70),
      titleTextStyle: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF0A0A0A).withValues(alpha: 0.95),
      indicatorColor: Colors.deepPurpleAccent.withValues(alpha: 0.3),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: Colors.deepPurpleAccent, size: 24);
        }
        return const IconThemeData(color: Colors.grey, size: 24);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.deepPurpleAccent,
          );
        }
        return const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.grey,
        );
      }),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      },
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: _fontFamily, fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white,
      ),
      headlineMedium: TextStyle(fontFamily: _fontFamily, fontSize: 24, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontFamily: _fontFamily, fontSize: 20, fontWeight: FontWeight.w600),
    ),
  );

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF8F9FA),
    fontFamily: _fontFamily,
    primaryColor: Colors.deepPurple,
    colorScheme: const ColorScheme.light(
      primary: Colors.deepPurple,
      secondary: Colors.purple,
      surface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.black87),
      titleTextStyle: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white.withValues(alpha: 0.95),
      indicatorColor: Colors.deepPurple.withValues(alpha: 0.15),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: Colors.deepPurple, size: 24);
        }
        return const IconThemeData(color: Colors.grey, size: 24);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.deepPurple,
          );
        }
        return const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.grey,
        );
      }),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      },
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: _fontFamily, fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87,
      ),
      headlineMedium: TextStyle(fontFamily: _fontFamily, fontSize: 24, fontWeight: FontWeight.w600),
      titleLarge: TextStyle(fontFamily: _fontFamily, fontSize: 20, fontWeight: FontWeight.w600),
    ),
  );

  // --- Glass Effect ---
  static final BoxDecoration glassDecoration = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.05),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.3),
        blurRadius: 20,
        spreadRadius: 2,
      ),
    ],
  );

  static final Decoration strongGlass = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.4),
        blurRadius: 30,
        spreadRadius: 5,
      ),
      BoxShadow(
        color: primary.withValues(alpha: 0.15),
        blurRadius: 40,
        spreadRadius: -10,
      ),
    ],
  );

  // --- Typography ---
  static const TextStyle heading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: Colors.white70,
  );
}
