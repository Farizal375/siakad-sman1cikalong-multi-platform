// File: lib/shared_widgets/delete_confirmation_modal.dart
// ===========================================
// DELETE CONFIRMATION MODAL
// Translated from DeleteConfirmationModal.tsx
// ===========================================

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class DeleteConfirmationModal extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const DeleteConfirmationModal({
    super.key,
    this.title = 'Konfirmasi Hapus',
    this.message = 'Apakah Anda yakin ingin menghapus item ini? Tindakan ini tidak dapat dibatalkan.',
    required this.onConfirm,
    required this.onCancel,
  });

  /// Show the delete confirmation dialog
  static Future<bool?> show(
    BuildContext context, {
    String title = 'Konfirmasi Hapus',
    String? message,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DeleteConfirmationModal(
        title: title,
        message: message ??
            'Apakah Anda yakin ingin menghapus item ini? Tindakan ini tidak dapat dibatalkan.',
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24), // rounded-3xl
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24), // p-6
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Icon
              Container(
                width: 64, // w-16
                height: 64, // h-16
                decoration: BoxDecoration(
                  color: AppColors.destructiveBg,
                  borderRadius: BorderRadius.circular(16), // rounded-2xl
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 32,
                  color: AppColors.destructive,
                ),
              ),
              const SizedBox(height: 16), // gap-4

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20, // text-xl
                  fontWeight: FontWeight.w700,
                  color: AppColors.foreground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8), // gap-2

              // Message
              Text(
                message,
                style: TextStyle(
                  fontSize: 14, // text-sm
                  color: AppColors.foreground.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24), // gap-6

              // Action Buttons
              Row(
                children: [
                  // Cancel
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.borderMedium),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.foreground,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Confirm Delete
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.destructive,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Hapus',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
