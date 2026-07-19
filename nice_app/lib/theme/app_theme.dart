// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

/// Central color palette for the Nice app.
/// Keep every screen pulling from here so the theme stays consistent
/// if the palette ever needs to change.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFE17B44); // warm terracotta accent
  static const Color primaryDark = Color(0xFFB85E31); // pressed / shadow tone
  static const Color primarySoft =
      Color(0xFFFBE7D8); // light tint for icon chips, active states
  static const Color background = Color(0xFFF6F1EA); // warm off-white body
  static const Color white = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF261F18); // soft warm near-black

  static const Color paidGreen = Color(0xFF2F9E68);
  static const Color unpaidRed = Color(0xFFE5484D);

  static Color textFaded = textColor.withValues(alpha: 0.55);
  static Color textFadedLight = textColor.withValues(alpha: 0.35);

  // Soft neutral border for white inputs sitting directly on the
  // off-white background, so their edges read even where shadows are subtle.
  static const Color border = Color(0xFFEDE4D8);

  static const Color paidSoft =
      Color(0xFFE1F1E8); // light green tint for paid chips
  static const Color unpaidSoft =
      Color(0xFFFBE1E1); // light red tint for unpaid chips
}

/// Shared visual tokens so the "polished" look stays consistent: one place
/// for the accent gradient, the soft card gradient, and the two shadow
/// weights used across cards and floating surfaces.
class AppStyle {
  AppStyle._();

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEE9457), AppColors.primary, AppColors.primaryDark],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.white, Color(0xFFFDF9F4)],
  );

  /// Subtle lift for resting cards.
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: AppColors.primaryDark.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  /// Stronger, warmer shadow for accent / floating surfaces.
  static List<BoxShadow> accentShadow(Color base) => [
        BoxShadow(
          color: base.withValues(alpha: 0.30),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];

  static const double radius = 18;
  static const double radiusSmall = 14;
}

class AppTheme {
  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.white,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textColor,
        displayColor: AppColors.textColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        labelStyle: TextStyle(color: AppColors.textFaded, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Reusable text styles so headings/labels stay consistent across screens.
class AppText {
  AppText._();

  static const TextStyle headerTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textColor,
  );

  static const TextStyle headerSubtitle = TextStyle(
    fontSize: 14,
    color: AppColors.textColor,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textColor,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textColor,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 13,
    color: Colors.black54,
  );

  static const TextStyle amount = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textColor,
  );
}
