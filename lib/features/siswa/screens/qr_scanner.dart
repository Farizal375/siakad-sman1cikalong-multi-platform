// File: lib/features/siswa/screens/qr_scanner.dart
// ===========================================
// QR SCANNER - Web wrapper
// Reuses the mobile scanner implementation so QR processing uses the same
// /kehadiran/qr-scan backend contract on every platform.
// ===========================================

import 'package:flutter/material.dart';

import 'mobile/mobile_qr_scanner.dart';

class QRScanner extends StatelessWidget {
  /// Callback dipanggil saat presensi berhasil dicatat.
  final VoidCallback? onSuccess;

  const QRScanner({super.key, this.onSuccess});

  @override
  Widget build(BuildContext context) {
    return MobileQRScanner(onSuccess: onSuccess);
  }
}
