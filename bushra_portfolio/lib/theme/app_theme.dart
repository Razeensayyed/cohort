import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF12121A);
  static const Color card = Color(0xFF1A1A26);
  static const Color accent = Color(0xFF6C63FF);
  static const Color accentSecondary = Color(0xFF00D4AA);
  static const Color accentTertiary = Color(0xFFFF6B6B);
  static const Color textPrimary = Color(0xFFEEEEEE);
  static const Color textSecondary = Color(0xFF9A9AB0);
  static const Color border = Color(0xFF2A2A3E);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C63FF), Color(0xFF00D4AA)],
  );

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accentSecondary,
        surface: surface,
        background: background,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 64,
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -2,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -1,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: textSecondary,
          height: 1.7,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: textSecondary,
          height: 1.6,
        ),
      ),
    );
  }
}
