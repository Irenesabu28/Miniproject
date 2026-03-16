import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF6366F1);
  static const Color secondary = Color(0xFF818CF8);
  static const Color background = Color(0xFF0F172A);
  static const Color surface = Color(0xFF1E293B);
  static const Color textBody = Color(0xFF94A3B8);
  static const Color textHeading = Colors.white;
  
  static const Color statusStable = Color(0xFF10B981);
  static const Color statusTripped = Color(0xFFEF4444);
  static const Color accent = Color(0xFFF59E0B);
  
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
      displayLarge: GoogleFonts.outfit(
        color: AppColors.textHeading,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: GoogleFonts.outfit(
        color: AppColors.textHeading,
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: GoogleFonts.outfit(
        color: AppColors.textBody,
      ),
    ),
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
    ),
  );
}
