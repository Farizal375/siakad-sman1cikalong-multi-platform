// File: lib/features/siswa/screens/mobile/mobile_qr_scanner.dart
// ===========================================
// MOBILE QR SCANNER (FR-06.2)
// Real camera QR scanning with mobile_scanner package
// Used by both mobile and web student presensi flows
// Connected to /kehadiran/qr-scan API with colored feedback
// ===========================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:dio/dio.dart';
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
  bool _isProcessing = false;

  // Result state
  String _resultMessage = '';
  int _resultHttpStatus = 0;

  late AnimationController _animCtrl;
  late Animation<double> _scanAnim;

  // Camera controller
  MobileScannerController? _cameraController;
  bool _cameraInitialized = false;
  bool _flashOn = false;

  // Debounce: prevent rapid re-scans
  DateTime? _lastScanTime;
  static const _scanDebounceMs = 3000;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scanAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut));
    _animCtrl.repeat();

    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    _cameraInitialized = true;
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  // ── QR Processing ──────────────────────────────────────────────
  Future<void> _processQRCode(String qrData) async {
    if (!_isScanning || _isProcessing) return;

    // Debounce check
    final now = DateTime.now();
    if (_lastScanTime != null &&
        now.difference(_lastScanTime!).inMilliseconds < _scanDebounceMs) {
      return;
    }
    _lastScanTime = now;

    setState(() {
      _isScanning = false;
      _isProcessing = true;
    });
    _animCtrl.stop();
    _cameraController?.stop();

    try {
      // Parse QR data — expected JSON: { "token": "...", "jadwalId": "...", "tanggal": "..." }
      Map<String, dynamic> qrPayload;
      try {
        qrPayload = jsonDecode(qrData) as Map<String, dynamic>;
      } catch (_) {
        _showFeedback(
          400,
          'QR_INVALID',
          'QR Code tidak valid. Pastikan Anda memindai QR yang benar dari layar guru.',
        );
        return;
      }

      final token = qrPayload['token'] as String?;
      final jadwalId = qrPayload['jadwalId'] as String?;
      final tanggal = qrPayload['tanggal'] as String?;

      if (token == null || jadwalId == null || tanggal == null) {
        _showFeedback(400, 'QR_INVALID', 'Format QR Code tidak lengkap.');
        return;
      }

      // Call backend API
      final response = await ApiService.scanQR({
        'qrToken': token,
        'jadwalId': jadwalId,
        'tanggal': tanggal,
      });

      _showFeedback(
        200,
        response['code'] ?? 'SUCCESS',
        response['message'] ?? 'Presensi berhasil dicatat!',
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode ?? 500;
      final data = e.response?.data;
      final message = data is Map
          ? (data['message'] ?? 'Terjadi kesalahan')
          : 'Gagal menghubungi server';
      final code = data is Map ? (data['code'] ?? 'ERROR') : 'ERROR';
      _showFeedback(statusCode, code, message);
    } catch (e) {
      _showFeedback(
        500,
        'ERROR',
        'Gagal memproses QR Code. Silakan coba lagi.',
      );
    }
  }

  void _showFeedback(int httpStatus, String _, String message) {
    setState(() {
      _resultHttpStatus = httpStatus;
      _resultMessage = message;
      _showResult = true;
      _isProcessing = false;
    });
  }

  void _resetScanner() {
    setState(() {
      _isScanning = true;
      _showResult = false;
      _resultMessage = '';
      _resultHttpStatus = 0;
      _isProcessing = false;
    });
    _animCtrl.repeat();
    _cameraController?.start();
  }

  void _toggleFlash() {
    _cameraController?.toggleTorch();
    setState(() => _flashOn = !_flashOn);
  }

  // ── Feedback Colors ────────────────────────────────────────────
  Color get _feedbackColor {
    switch (_resultHttpStatus) {
      case 200:
        return const Color(0xFF059669); // Green — success
      case 409:
        return const Color(0xFFD97706); // Yellow/amber — already attended
      case 410:
        return const Color(0xFFDC2626); // Red — expired
      case 403:
        return const Color(0xFFDC2626); // Red — not enrolled
      default:
        return const Color(0xFFDC2626); // Red — error
    }
  }

  Color get _feedbackBgColor {
    switch (_resultHttpStatus) {
      case 200:
        return const Color(0xFFECFDF5); // Green bg
      case 409:
        return const Color(0xFFFFFBEB); // Yellow bg
      case 410:
        return const Color(0xFFFEE2E2); // Red bg
      case 403:
        return const Color(0xFFFEE2E2); // Red bg
      default:
        return const Color(0xFFFEE2E2); // Red bg
    }
  }

  IconData get _feedbackIcon {
    switch (_resultHttpStatus) {
      case 200:
        return Icons.check_rounded;
      case 409:
        return Icons.info_outline_rounded;
      case 410:
        return Icons.timer_off_rounded;
      case 403:
        return Icons.block_rounded;
      default:
        return Icons.close_rounded;
    }
  }

  String get _feedbackTitle {
    switch (_resultHttpStatus) {
      case 200:
        return 'Presensi Berhasil!';
      case 409:
        return 'Sudah Absen';
      case 410:
        return 'QR Expired';
      case 403:
        return 'Akses Ditolak';
      default:
        return 'Gagal';
    }
  }

  String get _feedbackStatusLabel {
    switch (_resultHttpStatus) {
      case 200:
        return 'Status: HADIR';
      case 409:
        return 'Sudah tercatat di sesi ini';
      case 410:
        return 'Minta guru refresh QR Code';
      case 403:
        return 'Anda tidak terdaftar di kelas ini';
      default:
        return 'Silakan coba lagi';
    }
  }

  Color get _feedbackStatusColor {
    switch (_resultHttpStatus) {
      case 200:
        return const Color(0xFF15803D);
      case 409:
        return const Color(0xFFB45309);
      default:
        return const Color(0xFFB91C1C);
    }
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
                              // Camera view or mock background
                              if (_cameraInitialized && _isScanning)
                                MobileScanner(
                                  controller: _cameraController!,
                                  onDetect: (capture) {
                                    final barcodes = capture.barcodes;
                                    if (barcodes.isNotEmpty &&
                                        barcodes.first.rawValue != null) {
                                      _processQRCode(barcodes.first.rawValue!);
                                    }
                                  },
                                )
                              else
                                Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0xFF111827),
                                        Color(0xFF1F2937),
                                      ],
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
                                      Positioned(
                                        top: 0,
                                        left: 0,
                                        child: _corner(true, true),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: _corner(false, true),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        child: _corner(true, false),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: _corner(false, false),
                                      ),

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

                                      // Processing indicator
                                      if (_isProcessing)
                                        const Center(
                                          child: CircularProgressIndicator(
                                            color: AppColors.accent,
                                            strokeWidth: 3,
                                          ),
                                        ),

                                      // Center icon only after scanning pauses.
                                      if (!_isScanning)
                                        Center(
                                          child: Container(
                                            width: 72,
                                            height: 72,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: 0.12,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
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
                                      _isProcessing
                                          ? 'Memproses absensi...'
                                          : _isScanning
                                          ? 'Posisikan QR Code dalam frame'
                                          : 'Selesai',
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
                                        color: Colors.white.withValues(
                                          alpha: 0.6,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Flash toggle (only for native)
                              if (!kIsWeb)
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: GestureDetector(
                                    onTap: _toggleFlash,
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: _flashOn
                                            ? AppColors.accent.withValues(
                                                alpha: 0.8,
                                              )
                                            : Colors.white.withValues(
                                                alpha: 0.2,
                                              ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        _flashOn
                                            ? Icons.flash_on
                                            : Icons.flash_off,
                                        color: Colors.white,
                                        size: 20,
                                      ),
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
                          color: isDark
                              ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                              : AppColors.blue50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 20,
                              color: AppColors.primary,
                            ),
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

  // ── Result Modal with Colored Feedback ──────────────────────────
  Widget _buildResultModal(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fgColor = isDark ? Colors.white : AppColors.foreground;
    final isSuccess = _resultHttpStatus == 200;
    final isDuplicate = _resultHttpStatus == 409;

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
                // Icon with colored background
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: _feedbackColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_feedbackIcon, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  _feedbackTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _feedbackColor,
                  ),
                ),
                const SizedBox(height: 8),

                // Message
                Text(
                  _resultMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.gray300 : AppColors.gray600,
                    height: 1.5,
                  ),
                ),

                // Status badge
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _feedbackBgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _feedbackColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSuccess
                            ? Icons.check_circle
                            : isDuplicate
                            ? Icons.info
                            : Icons.warning,
                        size: 18,
                        color: _feedbackStatusColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _feedbackStatusLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _feedbackStatusColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _resetScanner,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSuccess
                          ? AppColors.primary
                          : (isDark ? AppColors.gray700 : AppColors.gray200),
                      foregroundColor: isSuccess ? Colors.white : fgColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isSuccess ? 'Selesai' : 'Coba Lagi',
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
          top: top
              ? const BorderSide(color: AppColors.accent, width: 4)
              : BorderSide.none,
          bottom: !top
              ? const BorderSide(color: AppColors.accent, width: 4)
              : BorderSide.none,
          left: left
              ? const BorderSide(color: AppColors.accent, width: 4)
              : BorderSide.none,
          right: !left
              ? const BorderSide(color: AppColors.accent, width: 4)
              : BorderSide.none,
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
