import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF10B981); // Vibrant Emerald
  static const Color secondary = Color(0xFF059669);
  static const Color background = Color(0xFF0F172A); // Very deep slate
  static const Color surface = Color(0xFF1E293B);
  static const Color textBody = Color(0xFF94A3B8);
  static const Color textHeading = Colors.white;
  
  static const Color statusStable = Color(0xFF10B981);
  static const Color statusTripped = Color(0xFFEF4444);
  static const Color accent = Color(0xFF3B82F6); // Soft blue accent
  
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF34D399)],
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
        fontWeight: FontWeight.w700,
        fontSize: 28,
        letterSpacing: -0.5,
      ),
      bodyLarge: GoogleFonts.outfit(
        color: Colors.white,
        fontSize: 16,
      ),
      bodyMedium: GoogleFonts.outfit(
        color: AppColors.textBody,
      ),
    ),
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.statusTripped,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 18),
      ),
    ),
  );
}
