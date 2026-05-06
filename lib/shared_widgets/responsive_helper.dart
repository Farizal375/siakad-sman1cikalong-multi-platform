// File: lib/shared_widgets/responsive_helper.dart
// ===========================================
// RESPONSIVE HELPER
// Breakpoint: < 768px = mobile, >= 768px = desktop
// ===========================================

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Breakpoint tunggal yang digunakan seluruh layout SIAKAD.
/// Dibawah 768px dianggap mobile (smartphone atau tablet kecil).
const double kMobileBreakpoint = 768;

/// Web browser dipaksa tetap desktop sampai benar-benar sempit.
/// Ini menjaga tampilan desktop tetap stabil seperti panel admin.
const double kWebMobileBreakpoint = 600;

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  bool get isMobile =>
      screenWidth < (kIsWeb ? kWebMobileBreakpoint : kMobileBreakpoint);
  bool get isDesktop => !isMobile;
}

/// Widget avatar inisial standar untuk AppBar mobile & header desktop.
class UserAvatar extends StatelessWidget {
  final String initials;
  final double size;
  const UserAvatar({super.key, required this.initials, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        ),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.38,
          ),
        ),
      ),
    );
  }
}
