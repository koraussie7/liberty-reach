/// App theme (colors, typography, glassmorphism)
import 'package:flutter/material.dart';

class AppTheme {
  // --- Colors ---
  static const Color primary = Color(0xFF6C63FF);
  static const Color accent = Color(0xFF00D9FF);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color background = Color(0xFF0F0F23);
  static const Color card = Color(0xFF16213E);

  // --- Glass Effect ---
  static final BoxDecoration glassDecoration = BoxDecoration(
    color: Colors.white.withOpacity(0.05),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.white.withOpacity(0.1)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.3),
        blurRadius: 20,
        spreadRadius: 2,
      ),
    ],
  );

  static final Decoration strongGlass = BoxDecoration(
    color: Colors.white.withOpacity(0.08),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.white.withOpacity(0.15)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.4),
        blurRadius: 30,
        spreadRadius: 5,
      ),
      BoxShadow(
        color: primary.withOpacity(0.15),
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
