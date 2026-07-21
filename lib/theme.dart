import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette reprise à l'identique du frontend web (css/styles.css).
class AppColors {
  AppColors._();

  static const bg = Color(0xFF0C0C0C);
  static const surface = Color(0xFF161616);
  static const raised = Color(0xFF1E1E1E);
  static const border = Color(0xFF2C2C2C);
  static const muted = Color(0xFF494949);
  static const sub = Color(0xFF888888);
  static const text = Color(0xFFE0DDD8);
  static const bright = Color(0xFFF0EDE8);
  static const accent = Color(0xFFC8A96E); // or
  static const accent2 = Color(0xFFA08040);
  static const danger = Color(0xFFD94F4F);
  static const pink = Color(0xFFD4608A); // formules filles
  static const lime = Color(0xFF88CC88);
}

/// Rayon de bordure global (le web utilise 3px, très anguleux).
const double kRadius = 4;

class AppTheme {
  AppTheme._();

  /// Barlow Condensed : titres en capitales.
  static TextStyle heading({
    double size = 24,
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.bright,
    double letterSpacing = 0.4,
    double? height,
  }) {
    return GoogleFonts.barlowCondensed(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height ?? 1.02,
    );
  }

  /// Petite étiquette mono en capitales (dates, meta).
  static TextStyle mono({
    double size = 11,
    Color color = AppColors.sub,
    FontWeight weight = FontWeight.w600,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      color: color,
      fontWeight: weight,
      letterSpacing: 1.1,
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.bright,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      canvasColor: AppColors.bg,
      textTheme: textTheme,
      colorScheme: base.colorScheme.copyWith(
        surface: AppColors.surface,
        primary: AppColors.accent,
        secondary: AppColors.pink,
        error: AppColors.danger,
        onPrimary: Colors.black,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg.withValues(alpha: 0.96),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.bright),
        titleTextStyle: heading(size: 20, letterSpacing: 0.6),
      ),
      dividerColor: AppColors.border,
      cardColor: AppColors.surface,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.raised,
        hintStyle: const TextStyle(color: AppColors.muted),
        labelStyle: const TextStyle(color: AppColors.sub),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadius),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadius),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadius),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.black,
          disabledBackgroundColor: AppColors.muted,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadius),
          ),
          textStyle: GoogleFonts.barlowCondensed(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.bright,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadius),
          ),
          textStyle: GoogleFonts.barlowCondensed(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.sub,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.raised,
        contentTextStyle: const TextStyle(color: AppColors.text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadius),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
