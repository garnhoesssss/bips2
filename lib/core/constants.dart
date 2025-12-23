import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ============================================
/// BIPOL TRACKER - DESIGN SYSTEM CONSTANTS
/// ============================================

class AppColors {
  // Primary Brand Colors
  static const Color primary = Color(0xFFFFC107); // Golden Yellow
  static const Color primaryDark = Color(0xFFFFB300);
  
  // Background Colors
  static const Color background = Color(0xFFFAFAFA); // Soft White
  static const Color backgroundGrey = Color(0xFFF5F5F5);
  static const Color cardBackground = Colors.white;
  
  // Text Colors
  static const Color textDark = Color(0xFF212121);
  static const Color textMedium = Color(0xFF616161);
  static const Color textLight = Color(0xFF9E9E9E);
  
  // Route Colors
  static const Color morningRoute = Color(0xFFBF1E2E); // Deep Red
  static const Color afternoonRoute = Color(0xFF159BB3); // Cyan/Teal
  
  // Status Colors
  static const Color statusOnline = Color(0xFF4CAF50); // Green
  static const Color statusOffline = Color(0xFF9E9E9E); // Grey
  static const Color statusDelayed = Color(0xFFFF5722); // Orange-Red
  static const Color statusAtStop = Color(0xFF2196F3); // Blue
  
  // Air Quality Colors
  static const Color airSafe = Color(0xFFE8F5E9); // Light Green BG
  static const Color airSafeText = Color(0xFF2E7D32); // Dark Green
  static const Color airDanger = Color(0xFFFFEBEE); // Light Red BG
  static const Color airDangerText = Color(0xFFC62828); // Dark Red
  
  // UI Element Colors
  static const Color shadow = Color(0x1A000000);
  static const Color divider = Color(0xFFE0E0E0);
}

class AppTextStyles {
  static TextStyle get heading1 => GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );
  
  static TextStyle get heading2 => GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );
  
  static TextStyle get heading3 => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );
  
  static TextStyle get bodyLarge => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textMedium,
  );
  
  static TextStyle get bodyMedium => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textMedium,
  );
  
  static TextStyle get bodySmall => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textLight,
  );
  
  static TextStyle get labelBold => GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );
  
  static TextStyle get statValue => GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );
  
  static TextStyle get statLabel => GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textLight,
  );
}

class AppShadows {
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];
  
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: AppColors.shadow.withAlpha(25),
      blurRadius: 8,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];
  
  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: AppColors.shadow.withAlpha(40),
      blurRadius: 16,
      offset: const Offset(0, 6),
      spreadRadius: 0,
    ),
  ];
}

class AppDimensions {
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 24.0;
  
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
}
