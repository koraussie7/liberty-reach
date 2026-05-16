import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const String _fontFamily = 'Inter';

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
      backgroundColor: const Color(0xFF0A0A0A).withOpacity(0.95),
      indicatorColor: Colors.deepPurpleAccent.withOpacity(0.3),
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
      backgroundColor: Colors.white.withOpacity(0.95),
      indicatorColor: Colors.deepPurple.withOpacity(0.15),
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

  static BoxDecoration glassDecoration = BoxDecoration(
    color: Colors.white.withOpacity(0.08),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 20,
        spreadRadius: -10,
      ),
    ],
  );

  static BoxDecoration strongGlass = BoxDecoration(
    color: Colors.white.withOpacity(0.12),
    borderRadius: BorderRadius.circular(28),
    border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.8),
    boxShadow: [
      BoxShadow(
        color: Colors.deepPurple.withOpacity(0.3),
        blurRadius: 30,
        spreadRadius: -8,
      ),
    ],
  );
}
