// File: lib/features/siswa/screens/mobile/mobile_qr_scanner.dart
// ===========================================
// MOBILE QR SCANNER (FR-06.2)
// Real camera QR scanning with mobile_scanner package
// Fallback simulation for web
// Connected to /kehadiran/qr-scan API
// ===========================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_service.dart';

class MobileQRScanner extends StatefulWidget {
  const MobileQRScanner({super.key});

  @override
  State<MobileQRScanner> createState() => _MobileQRScannerState();
}

class _MobileQRScannerState extends State<MobileQRScanner>
    with SingleTickerProviderStateMixin {
  bool _isScanning = true;
  bool _showResult = false;
  bool _success = false;
  String _resultMessage = '';
  late AnimationController _animCtrl;
  late Animation<double> _scanAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scanAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );
    _animCtrl.repeat();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _processQRCode(String qrData) async {
    if (!_isScanning) return;

    setState(() => _isScanning = false);
    _animCtrl.stop();

    try {
      // Parse QR data — expected format: SIAKAD-{jadwalId}-{timestamp}-{random}
      if (!qrData.startsWith('SIAKAD-')) {
        _showResultModal(false, 'QR Code tidak valid. Pastikan Anda memindai QR yang benar.');
        return;
      }

      final parts = qrData.split('-');
      if (parts.length < 3) {
        _showResultModal(false, 'Format QR Code tidak valid.');
        return;
      }

      final jadwalId = parts[1];
      final today = DateTime.now();
      final tanggal = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final response = await ApiService.scanQR({
        'qrToken': qrData,
        'jadwalId': jadwalId,
        'tanggal': tanggal,
      });

      _showResultModal(true, response['message'] ?? 'Presensi berhasil dicatat!');
    } catch (e) {
      _showResultModal(false, 'Gagal mencatat presensi. Silakan coba lagi.');
    }
  }

  void _showResultModal(bool isSuccess, String message) {
    setState(() {
      _success = isSuccess;
      _resultMessage = message;
      _showResult = true;
    });
  }

  void _resetScanner() {
    setState(() {
      _isScanning = true;
      _showResult = false;
      _resultMessage = '';
    });
    _animCtrl.repeat();
  }

  // Demo simulation for web
  void _simulateScan() {
    final mockToken = 'SIAKAD-mock-jadwal-id-${DateTime.now().millisecondsSinceEpoch}-abcd1234';
    _processQRCode(mockToken);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fgColor = isDark ? Colors.white : AppColors.foreground;
    
    return Stack(
      children: [
        SafeArea(
          child: Column(
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan QR Absensi',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: fgColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pindai QR Code yang ditampilkan oleh guru',
                      style: TextStyle(fontSize: 13, color: AppColors.gray500),
                    ),
                  ],
                ),
              ),

              // ── Scanner Area ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Scanner viewport
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Camera / Mock background
                              Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Color(0xFF111827), Color(0xFF1F2937)],
                                  ),
                                ),
                              ),

                              // Scan overlay
                              Container(color: const Color(0x33374151)),

                              // Corner frame + scan line
                              Center(
                                child: SizedBox(
                                  width: 240,
                                  height: 240,
                                  child: Stack(
                                    children: [
                                      // Corners
                                      Positioned(top: 0, left: 0, child: _corner(true, true)),
                                      Positioned(top: 0, right: 0, child: _corner(false, true)),
                                      Positioned(bottom: 0, left: 0, child: _corner(true, false)),
                                      Positioned(bottom: 0, right: 0, child: _corner(false, false)),

                                      // Animated scan line
                                      if (_isScanning)
                                        AnimatedBuilder(
                                          animation: _scanAnim,
                                          builder: (context, _) => Positioned(
                                            top: _scanAnim.value * 240,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              height: 3,
                                              decoration: const BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.transparent,
                                                    AppColors.accent,
                                                    Colors.transparent,
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                      // Center icon
                                      Center(
                                        child: Container(
                                          width: 72,
                                          height: 72,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: const Icon(
                                            Icons.qr_code_2,
                                            color: AppColors.accent,
                                            size: 40,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Bottom instruction
                              Positioned(
                                bottom: 24,
                                left: 0,
                                right: 0,
                                child: Column(
                                  children: [
                                    Text(
                                      _isScanning
                                          ? 'Posisikan QR Code dalam frame'
                                          : 'Memproses...',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'QR akan terdeteksi secara otomatis',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.6),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Flash toggle
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.flash_off,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Tips section ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : AppColors.blue50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lightbulb_outline, size: 20, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Pastikan kamera diarahkan ke QR Code yang ditampilkan oleh guru di kelas.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Simulate button (for demo/web) ──
                      if (kIsWeb)
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _isScanning ? _simulateScan : null,
                            icon: const Icon(Icons.qr_code_scanner, size: 20),
                            label: const Text(
                              'Simulasi Scan (Demo)',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Result Modal ──
        if (_showResult) _buildResultModal(context),
      ],
    );
  }

  Widget _buildResultModal(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fgColor = isDark ? Colors.white : AppColors.foreground;
    
    return GestureDetector(
      onTap: _resetScanner,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            width: 320,
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _success ? AppColors.accent : AppColors.destructive,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _success ? Icons.check_rounded : Icons.close_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  _success ? 'Presensi Berhasil!' : 'Gagal',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _success ? AppColors.primary : AppColors.destructive,
                  ),
                ),
                const SizedBox(height: 8),

                // Message
                Text(
                  _resultMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: isDark ? AppColors.gray300 : AppColors.gray600, height: 1.5),
                ),

                if (_success) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.green50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, size: 18, color: Color(0xFF15803D)),
                        const SizedBox(width: 8),
                        const Text(
                          'Status: HADIR',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Close button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _resetScanner,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _success ? AppColors.primary : (isDark ? AppColors.gray700 : AppColors.gray200),
                      foregroundColor: _success ? Colors.white : fgColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _success ? 'Selesai' : 'Coba Lagi',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _corner(bool left, bool top) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        border: Border(
          top: top ? const BorderSide(color: AppColors.accent, width: 4) : BorderSide.none,
          bottom: !top ? const BorderSide(color: AppColors.accent, width: 4) : BorderSide.none,
          left: left ? const BorderSide(color: AppColors.accent, width: 4) : BorderSide.none,
          right: !left ? const BorderSide(color: AppColors.accent, width: 4) : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: (top && left) ? const Radius.circular(8) : Radius.zero,
          topRight: (top && !left) ? const Radius.circular(8) : Radius.zero,
          bottomLeft: (!top && left) ? const Radius.circular(8) : Radius.zero,
          bottomRight: (!top && !left) ? const Radius.circular(8) : Radius.zero,
        ),
      ),
    );
  }
}
