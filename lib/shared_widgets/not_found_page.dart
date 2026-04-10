// File: lib/shared_widgets/not_found_page.dart
// ===========================================
// 404 NOT FOUND PAGE
// Translated from NotFound.tsx
// ===========================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24), // p-6
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 404 Number
              Text(
                '404',
                style: TextStyle(
                  fontSize: 120,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary.withValues(alpha: 0.1),
                  height: 1,
                ),
              ),
              const SizedBox(height: 16), // gap-4

              // Icon
              Container(
                width: 80, // w-20
                height: 80, // h-20
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(20), // rounded-2xl
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24), // gap-6

              // Title
              const Text(
                'Halaman Tidak Ditemukan',
                style: TextStyle(
                  fontSize: 30, // text-3xl
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8), // gap-2

              // Description
              Text(
                'Maaf, halaman yang Anda cari tidak tersedia atau telah dipindahkan.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.foreground.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32), // gap-8

              // Back to Home Button
              ElevatedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                label: const Text('Kembali ke Beranda'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12), // rounded-xl
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
