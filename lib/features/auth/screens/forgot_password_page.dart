import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_service.dart';
import '../../../core/theme/app_colors.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  static const bool _enableEmailOtp = bool.fromEnvironment(
    'ENABLE_EMAIL_OTP',
    defaultValue: false,
  );

  final _identifierController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _otpRequested = false;
  bool _obscurePassword = true;
  String _message = '';
  String _error = '';

  @override
  void dispose() {
    _identifierController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    final identifier = _identifierController.text.trim();
    if (identifier.isEmpty) {
      setState(() => _error = 'Email/username/nomor induk wajib diisi.');
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
      _message = '';
    });

    try {
      final response = await ApiService.requestPasswordReset(identifier);
      if (!mounted) return;
      setState(() {
        _otpRequested = true;
        _message = response['message'] ?? 'Jika akun valid, OTP akan dikirim.';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _otpRequested = true;
        _message = 'Jika akun valid, OTP akan dikirim.';
        _loading = false;
      });
    }
  }

  Future<void> _confirmReset() async {
    final identifier = _identifierController.text.trim();
    final otp = _otpController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty || otp.isEmpty || password.isEmpty) {
      setState(
        () => _error = 'Identifier, OTP, dan password baru wajib diisi.',
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
      _message = '';
    });

    try {
      await ApiService.confirmPasswordReset(
        identifier: identifier,
        otp: otp,
        password: password,
      );
      if (!mounted) return;
      setState(() {
        _message = 'Password berhasil direset. Silakan login kembali.';
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'OTP tidak valid atau sudah kadaluarsa.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_enableEmailOtp) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.admin_panel_settings_outlined,
                    size: 48,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Reset Password Manual',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Untuk sementara, reset password dilakukan oleh admin sekolah.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.gray600),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Kembali ke login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Reset Password',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'OTP dikirim ke email pribadi yang sudah diverifikasi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.gray600),
                  ),
                  const SizedBox(height: 24),
                  if (_error.isNotEmpty) _statusBox(_error, false),
                  if (_message.isNotEmpty) _statusBox(_message, true),
                  if (_error.isNotEmpty || _message.isNotEmpty)
                    const SizedBox(height: 16),
                  TextField(
                    controller: _identifierController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email / Username / Nomor Induk',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_otpRequested) ...[
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: 'Kode OTP',
                        counterText: '',
                        prefixIcon: Icon(Icons.pin_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _loading ? null : _confirmReset(),
                      decoration: InputDecoration(
                        labelText: 'Password Baru',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _loading ? null : _confirmReset,
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Reset Password'),
                    ),
                    TextButton(
                      onPressed: _loading ? null : _requestOtp,
                      child: const Text('Kirim ulang OTP'),
                    ),
                  ] else ...[
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _loading ? null : _requestOtp,
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Kirim OTP'),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Kembali ke login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBox(String text, bool success) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: success ? const Color(0xFFEFFDF4) : AppColors.red50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: success ? const Color(0xFF86EFAC) : AppColors.red200,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: success ? const Color(0xFF166534) : AppColors.destructive,
        ),
      ),
    );
  }
}
