// File: lib/core/theme/app_colors.dart
// ===========================================
// DESIGN SYSTEM COLORS
// Mapped 1:1 from SIAKAD theme.css
// ===========================================

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary Palette ──
  static const Color primary = Color(0xFF1E3A8A);        // DarkDeepBlue
  static const Color primaryLight = Color(0xFF2563EB);    // Lighter blue
  static const Color primaryHover = Color(0xFF1E40AF);    // Hover state

  // ── Accent ──
  static const Color accent = Color(0xFFF59E0B);          // GoldYellow
  static const Color accentHover = Color(0xFFD97706);      // Darker gold

  // ── Background & Surface ──
  static const Color background = Color(0xFFF8FAFC);      // LightGrey
  static const Color surface = Color(0xFFFFFFFF);          // White cards
  static const Color inputBackground = Color(0xFFF3F3F5);  // Input bg

  // ── Text ──
  static const Color foreground = Color(0xFF0F172A);       // Main text
  static const Color textSecondary = Color(0xFF717182);    // Muted text
  static const Color textMuted = Color(0xFF6B7280);        // Gray-500
  static const Color textLight = Color(0xFF9CA3AF);        // Gray-400

  // ── Semantic ──
  static const Color destructive = Color(0xFFB91C1C);     // Red-700
  static const Color destructiveBg = Color(0xFFFEF2F2);   // Red-50
  static const Color success = Color(0xFF22C55E);          // Green-500
  static const Color successDark = Color(0xFF16A34A);      // Green-600

  // ── Border ──
  static const Color border = Color(0x1A000000);           // rgba(0,0,0,0.1)
  static const Color borderLight = Color(0xFFE5E7EB);      // Gray-200
  static const Color borderMedium = Color(0xFFD1D5DB);     // Gray-300

  // ── Sidebar ──
  static const Color sidebarBg = Color(0xFF1E3A8A);        // Same as primary
  static const Color sidebarText = Color(0xCCFFFFFF);      // white/80
  static const Color sidebarHover = Color(0x1AFFFFFF);     // white/10
  static const Color sidebarBorder = Color(0x1AFFFFFF);    // white/10

  // ── Chart Colors ──
  static const Color chart1 = Color(0xFFEA580C);
  static const Color chart2 = Color(0xFF0D9488);
  static const Color chart3 = Color(0xFF334155);
  static const Color chart4 = Color(0xFFCA8A04);
  static const Color chart5 = Color(0xFFC2410C);

  // ── Status Colors (for info cards) ──
  static const Color green500 = Color(0xFF22C55E);
  static const Color green600 = Color(0xFF16A34A);
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color blue600 = Color(0xFF2563EB);
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color amber600 = Color(0xFFD97706);
  static const Color amber50 = Color(0xFFFFFBEB);
  static const Color amber200 = Color(0xFFFDE68A);
  static const Color blue50 = Color(0xFFEFF6FF);
  static const Color red50 = Color(0xFFFEF2F2);
  static const Color red200 = Color(0xFFFECACA);
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray900 = Color(0xFF111827);
}
