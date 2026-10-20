import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Palette - Deep Royal Blue & Vibrant Cyan
  static const Color primary = Color(0xFF1565C0); // Rich Royal Blue
  static const Color primaryDark = Color(0xFF0D47A1); // Deep Navy
  static const Color primaryLight = Color(0xFF42A5F5); // Soft Sky Blue
  static const Color primaryContainer = Color(0xFFE3F2FD); // Light Blue tint

  // Accent / Secondary Palette - Bright Cyan
  static const Color accent = Color(0xFF00B4D8); // Bright Turquoise Cyan
  static const Color accentDark = Color(0xFF0096C7);
  static const Color accentLight = Color(0xFF90E0EF);
  static const Color accentContainer = Color(0xFFE0F7FA);

  // Neutral Background & Surface
  static const Color background = Color(0xFFF8FAFC); // Clean crisp slate-50
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color cardColor = Colors.white;

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textTertiary = Color(0xFF94A3B8); // Slate 400
  static const Color textWhite = Colors.white;

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color borderFocused = Color(0xFF1565C0);
  static const Color divider = Color(0xFFEDF2F7);

  // Status & Feedback Colors
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444); // Crimson
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0D47A1),
      Color(0xFF1976D2),
      Color(0xFF00B4D8),
    ],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white,
      Color(0xFFF8FAFC),
    ],
  );
}
