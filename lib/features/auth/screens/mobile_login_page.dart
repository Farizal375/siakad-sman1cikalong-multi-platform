import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/models/user.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';

class MobileLoginPage extends ConsumerStatefulWidget {
  const MobileLoginPage({super.key});

  @override
  ConsumerState<MobileLoginPage> createState() => _MobileLoginPageState();
}

class _MobileLoginPageState extends ConsumerState<MobileLoginPage> {
  static const bool _enableSso = bool.fromEnvironment(
    'ENABLE_SSO',
    defaultValue: false,
  );
  static const bool _enableEmailOtp = bool.fromEnvironment(
    'ENABLE_EMAIL_OTP',
    defaultValue: false,
  );

  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  String _error = '';
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLocalLogin() async {
    if (_identifierController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() => _error = 'Email/username dan password wajib diisi.');
      return;
    }

    setState(() {
      _error = '';
      _loading = true;
    });

    final success = await ref
        .read(authProvider.notifier)
        .login(_identifierController.text.trim(), _passwordController.text);

    if (!mounted) return;

    if (!success) {
      setState(() {
        _error = 'Email/username atau password salah. Silakan coba lagi.';
        _loading = false;
      });
      return;
    }

    setState(() => _loading = false);
  }

  Future<void> _handleSsoLogin() async {
    setState(() {
      _error = '';
      _loading = true;
    });

    final started = await ref.read(authProvider.notifier).loginWithSso();
    if (!mounted) return;

    if (!started) {
      setState(() {
        _loading = false;
        _error = SupabaseConfig.isConfigured
            ? 'Login SSO gagal dimulai. Silakan coba lagi.'
            : 'Konfigurasi SSO belum tersedia untuk environment ini.';
      });
      return;
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) async {
      final user = next.valueOrNull;
      if (user == null || !mounted) return;

      if (user.role == UserRole.student) {
        context.go('/siswa/dashboard');
        return;
      }

      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        setState(() {
          _error = 'Aplikasi mobile ini hanya untuk akun siswa.';
        });
      }
    });

    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  screenHeight -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                _buildBranding(),
                const SizedBox(height: 40),
                _buildLoginCard(),
                const SizedBox(height: 32),
                Text(
                  'SMA Negeri 1 Cikalong',
                  style: TextStyle(fontSize: 12, color: AppColors.gray400),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBranding() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/logoSekolah.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.school, size: 40, color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'SIAKAD',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Portal Siswa',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.gray500,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Masuk ke Akun Siswa',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.foreground,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Gunakan akun sekolah yang sudah terdaftar',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.gray500),
          ),
          const SizedBox(height: 24),
          if (_error.isNotEmpty) ...[
            _buildErrorMessage(),
            const SizedBox(height: 16),
          ],
          _buildLocalLoginForm(),
          if (_enableSso) ...[
            const SizedBox(height: 18),
            _buildDivider(),
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _handleSsoLogin,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.login),
                label: Text(
                  _loading ? 'Menghubungkan...' : 'Login dengan Akun Sekolah',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withValues(
                    alpha: 0.6,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.red50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.red200),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            size: 18,
            color: AppColors.destructive,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.destructive,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Email / Username / Nomor Induk',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.foreground,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _identifierController,
          style: const TextStyle(color: AppColors.foreground),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: 'Email atau NISN/NIP',
            prefixIcon: const Icon(
              Icons.person_outline,
              size: 20,
              color: AppColors.gray400,
            ),
            filled: true,
            fillColor: AppColors.gray50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.gray200),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Password',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.foreground,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          style: const TextStyle(color: AppColors.foreground),
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _loading ? null : _handleLocalLogin(),
          decoration: InputDecoration(
            hintText: 'Masukkan password',
            prefixIcon: const Icon(
              Icons.lock_outline,
              size: 20,
              color: AppColors.gray400,
            ),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: AppColors.gray400,
              ),
            ),
            filled: true,
            fillColor: AppColors.gray50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.gray200),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _loading ? null : _handleLocalLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text('Masuk'),
          ),
        ),
        if (_enableEmailOtp) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: _loading ? null : () => context.go('/forgot-password'),
            child: const Text('Lupa password?'),
          ),
        ] else ...[
          const SizedBox(height: 12),
          const Text(
            'Lupa password? Hubungi admin sekolah.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.gray500),
          ),
        ],
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.borderMedium)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'atau',
            style: TextStyle(fontSize: 13, color: AppColors.gray500),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.borderMedium)),
      ],
    );
  }
}
