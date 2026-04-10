// File: lib/shared_widgets/success_toast.dart
// ===========================================
// SUCCESS TOAST
// Translated from SuccessToast.tsx
// ===========================================

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class SuccessToast extends StatefulWidget {
  final String message;
  final VoidCallback? onDismiss;

  const SuccessToast({
    super.key,
    required this.message,
    this.onDismiss,
  });

  @override
  State<SuccessToast> createState() => _SuccessToastState();
}

class _SuccessToastState extends State<SuccessToast> {
  double _opacity = 0;

  @override
  void initState() {
    super.initState();
    // Fade in
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) setState(() => _opacity = 1);
    });
    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _opacity = 0);
        Future.delayed(const Duration(milliseconds: 300), () {
          widget.onDismiss?.call();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: _opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.green500,
          borderRadius: BorderRadius.circular(12), // rounded-xl
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 15,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              widget.message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
