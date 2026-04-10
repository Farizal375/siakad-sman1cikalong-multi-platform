// File: lib/shared_widgets/toast_notification.dart
// ===========================================
// TOAST NOTIFICATION SYSTEM
// Translated from Toast.tsx
// ===========================================

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum ToastType { success, error, warning, info }

class ToastData {
  final String id;
  final String message;
  final ToastType type;
  final Duration duration;

  const ToastData({
    required this.id,
    required this.message,
    this.type = ToastType.info,
    this.duration = const Duration(seconds: 3),
  });
}

/// Show a toast notification using ScaffoldMessenger
void showAppToast(
  BuildContext context, {
  required String message,
  ToastType type = ToastType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final Color bgColor;
  final Color textColor;
  final IconData icon;

  switch (type) {
    case ToastType.success:
      bgColor = AppColors.green500;
      textColor = Colors.white;
      icon = Icons.check_circle_rounded;
    case ToastType.error:
      bgColor = AppColors.destructive;
      textColor = Colors.white;
      icon = Icons.error_rounded;
    case ToastType.warning:
      bgColor = AppColors.accent;
      textColor = AppColors.foreground;
      icon = Icons.warning_amber_rounded;
    case ToastType.info:
      bgColor = AppColors.primary;
      textColor = Colors.white;
      icon = Icons.info_rounded;
  }

  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: bgColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // rounded-xl
      ),
      margin: const EdgeInsets.all(16),
      duration: duration,
      action: SnackBarAction(
        label: '✕',
        textColor: textColor,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    ),
  );
}
