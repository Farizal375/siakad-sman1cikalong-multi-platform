// File: lib/core/theme/app_theme.dart
// ===========================================
// APP THEME CONFIGURATION
// Enforces design system: Inter font, custom ColorScheme
// ===========================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,

      // ── Color Scheme ──
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: AppColors.foreground,
        surface: AppColors.surface,
        onSurface: AppColors.foreground,
        error: AppColors.destructive,
        onError: Colors.white,
        outline: AppColors.border,
      ),

      // ── Typography ──
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(
          color: AppColors.foreground,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: baseTextTheme.displayMedium?.copyWith(
          color: AppColors.foreground,
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(
          color: AppColors.foreground,
          fontWeight: FontWeight.w700,
          fontSize: 30, // text-3xl
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          color: AppColors.foreground,
          fontWeight: FontWeight.w700,
          fontSize: 24, // text-2xl
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          color: AppColors.foreground,
          fontWeight: FontWeight.w600,
          fontSize: 20, // text-xl
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          color: AppColors.foreground,
          fontWeight: FontWeight.w600,
          fontSize: 18, // text-lg
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          color: AppColors.foreground,
          fontWeight: FontWeight.w500,
          fontSize: 16, // text-base
        ),
        titleSmall: baseTextTheme.titleSmall?.copyWith(
          color: AppColors.foreground,
          fontWeight: FontWeight.w500,
          fontSize: 14, // text-sm
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: AppColors.foreground,
          fontSize: 16,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: AppColors.foreground,
          fontSize: 14,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          color: AppColors.foreground,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        labelMedium: baseTextTheme.labelMedium?.copyWith(
          color: AppColors.foreground,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        labelSmall: baseTextTheme.labelSmall?.copyWith(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
      ),

      // ── App Bar ──
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),

      // ── Card ──
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // rounded-2xl
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Elevated Button ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // rounded-xl
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Outlined Button ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.borderMedium, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // ── Text Button ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // ── Input Decoration ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), // rounded-xl
          borderSide: const BorderSide(color: AppColors.borderMedium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderMedium),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.destructive),
        ),
        hintStyle: GoogleFonts.inter(
          color: AppColors.textMuted,
          fontSize: 16,
        ),
        labelStyle: GoogleFonts.inter(
          color: AppColors.foreground,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // ── Divider ──
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 0,
      ),

      // ── Bottom Navigation (for mobile Siswa) ──
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),

      // ── Dialog ──
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), // rounded-3xl
        ),
        backgroundColor: AppColors.surface,
      ),

      // ── Tooltip ──
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.foreground,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
    );
  }
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
    
    const darkBg = Color(0xFF111827); // gray900
    const darkSurface = Color(0xFF1F2937); // gray800
    const darkBorder = Color(0xFF374151); // gray700

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,

      // ── Color Scheme ──
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryLight, // Lighter for contrast in dark mode
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        surface: darkSurface,
        onSurface: Colors.white,
        error: AppColors.destructive,
        onError: Colors.white,
        outline: darkBorder,
      ),

      // ── Typography ──
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        displayMedium: baseTextTheme.displayMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        headlineLarge: baseTextTheme.headlineLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 30),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 24),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20),
        titleLarge: baseTextTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18),
        titleMedium: baseTextTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 16),
        titleSmall: baseTextTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: Colors.white, fontSize: 16),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: Colors.white, fontSize: 14),
        bodySmall: baseTextTheme.bodySmall?.copyWith(color: AppColors.gray400, fontSize: 12),
        labelLarge: baseTextTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 16),
        labelMedium: baseTextTheme.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
        labelSmall: baseTextTheme.labelSmall?.copyWith(color: AppColors.gray400, fontSize: 12),
      ),

      // ── App Bar ──
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
      ),

      // ── Card ──
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Elevated Button ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // ── Outlined Button ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          side: const BorderSide(color: AppColors.primaryLight, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),

      // ── Text Button ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      // ── Input Decoration ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: darkBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: darkBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryLight, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.destructive)),
        hintStyle: GoogleFonts.inter(color: AppColors.gray500, fontSize: 16),
        labelStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
      ),

      // ── Divider ──
      dividerTheme: const DividerThemeData(color: darkBorder, thickness: 1, space: 0),

      // ── Bottom Navigation ──
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.gray400,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400),
      ),

      // ── Dialog ──
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: darkSurface,
      ),

      // ── Tooltip ──
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.inter(color: darkBg, fontSize: 12),
      ),
    );
  }
}
