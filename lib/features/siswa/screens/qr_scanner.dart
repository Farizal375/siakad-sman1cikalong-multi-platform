// File: lib/features/siswa/screens/qr_scanner.dart
// ===========================================
// QR SCANNER – Absensi Siswa
// Translated from QRScanner.tsx
// Camera view simulasi + animated scan line + success modal
// ===========================================

import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class QRScanner extends StatefulWidget {
  const QRScanner({super.key});

  @override
  State<QRScanner> createState() => _QRScannerState();
}

class _QRScannerState extends State<QRScanner> with SingleTickerProviderStateMixin {
  bool _isScanning = true;
  bool _showSuccess = false;
  late AnimationController _animCtrl;
  late Animation<double> _scanAnim;

  static const _session = {
    'mapel': 'Fisika',
    'kelas': 'XII-1',
    'guru': 'Dr. Siti Nurhaliza, M.Pd',
    'jam': '09:15 - 10:45',
  };

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _scanAnim = Tween<double>(begin: 0, end: 1).animate(_animCtrl);
    _animCtrl.repeat();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _handleScan() {
    setState(() {
      _isScanning = false;
      _showSuccess = true;
    });
    _animCtrl.stop();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isScanning = true;
          _showSuccess = false;
        });
        _animCtrl.repeat();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text('Absensi QR Code', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.primary)),
                const SizedBox(height: 8),
                const Text('Pindai QR Code yang ditampilkan oleh guru untuk absensi', style: TextStyle(color: AppColors.gray600)),
                const SizedBox(height: 24),

                // Session Info
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_session['mapel']} - ${_session['kelas']}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
                            const SizedBox(height: 2),
                            Text(_session['jam']!, style: const TextStyle(color: AppColors.gray600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline, size: 16, color: AppColors.gray500),
                      const SizedBox(width: 6),
                      Text('Guru: ${_session['guru']}', style: const TextStyle(fontSize: 13, color: AppColors.gray700)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // QR Scanner Area
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF111827), Color(0xFF1F2937)],
                            ),
                          ),
                        ),

                        // Camera viewport blur overlay
                        Container(color: const Color(0x4D374151)),

                        // Corner Frame
                        Center(
                          child: SizedBox(
                            width: 260, height: 260,
                            child: Stack(
                              children: [
                                // Top-Left corner
                                Positioned(top: 0, left: 0, child: _corner(left: true, top: true)),
                                // Top-Right corner
                                Positioned(top: 0, right: 0, child: _corner(left: false, top: true)),
                                // Bottom-Left corner
                                Positioned(bottom: 0, left: 0, child: _corner(left: true, top: false)),
                                // Bottom-Right corner
                                Positioned(bottom: 0, right: 0, child: _corner(left: false, top: false)),

                                // Scan Line
                                if (_isScanning)
                                  AnimatedBuilder(
                                    animation: _scanAnim,
                                    builder: (context, _) {
                                      return Positioned(
                                        top: _scanAnim.value * 260,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          height: 3,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [Colors.transparent, AppColors.accent, Colors.transparent],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                // Center QR Icon
                                Center(
                                  child: Container(
                                    width: 90, height: 90,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(Icons.qr_code_2, color: AppColors.accent, size: 48),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Bottom Text
                        Positioned(
                          bottom: 32, left: 0, right: 0,
                          child: Column(
                            children: [
                              const Text('Pindai QR Code di layar Guru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text('Posisikan QR code di dalam frame', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                            ],
                          ),
                        ),

                        // Camera Badge
                        Positioned(
                          top: 16, right: 16,
                          child: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Scan Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleScan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Simulasi Scan QR (Demo)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Success Modal
        if (_showSuccess)
          Container(
            color: Colors.black54,
            child: Center(
              child: Container(
                width: 360,
                padding: const EdgeInsets.all(32),
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                      child: const Icon(Icons.check_circle_outline, color: Colors.white, size: 48),
                    ),
                    const SizedBox(height: 24),
                    const Text('Absensi Berhasil Dicatat!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    const SizedBox(height: 8),
                    Text('${_session['mapel']} - ${_session['kelas']}', style: const TextStyle(color: AppColors.gray600)),
                    const SizedBox(height: 4),
                    Text('Waktu: ${TimeOfDay.now().format(context)}', style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: const Center(
                        child: Text('Status: HADIR', style: TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _corner({required bool left, required bool top}) {
    return Container(
      width: 32, height: 32,
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
