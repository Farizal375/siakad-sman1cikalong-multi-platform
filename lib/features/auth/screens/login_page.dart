import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
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
      setState(() {
        _error = 'Email/username dan password wajib diisi.';
      });
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
        _loading = false;
        _error = 'Email/username atau password salah. Silakan coba lagi.';
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
    ref.listen(authProvider, (previous, next) {
      final user = next.valueOrNull;
      if (user != null && mounted) {
        context.go(getDashboardRouteByRole(user.role));
      }
    });

    return Scaffold(
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width >= 1024)
            Expanded(child: _buildBrandPanel()),
          Expanded(child: _buildLoginPanel(context)),
        ],
      ),
    );
  }

  Widget _buildBrandPanel() {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl:
              'https://images.unsplash.com/photo-1660128357926-bce1e0a9c294?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=1920',
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(color: AppColors.primary),
          errorWidget: (_, __, ___) => Container(color: AppColors.primary),
        ),
        Container(color: AppColors.primary.withValues(alpha: 0.82)),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo(size: 84, radius: 18),
                const SizedBox(height: 32),
                const Text(
                  'SMA NEGERI 1 CIKALONG',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  'Portal akademik terpadu untuk siswa, guru, dan staf sekolah.',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withValues(alpha: 0.92),
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginPanel(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Stack(
        children: [
          Positioned(
            top: 24,
            left: 24,
            child: InkWell(
              onTap: () => context.go('/'),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, size: 20, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Kembali ke Beranda',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 448),
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x15000000),
                        blurRadius: 15,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(child: _buildLogo(size: 80, radius: 16)),
                      const SizedBox(height: 24),
                      const Text(
                        'Portal Login Akademik',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Akses aman dengan akun sekolah',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.foreground.withValues(alpha: 0.75),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      if (_error.isNotEmpty) ...[
                        _buildErrorMessage(),
                        const SizedBox(height: 16),
                      ],
                      _buildLocalLoginForm(),
                      if (_enableSso) ...[
                        const SizedBox(height: 20),
                        _buildDivider(),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _loading ? null : _handleSsoLogin,
                            icon: _loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.login),
                            label: Text(
                              _loading
                                  ? 'Menghubungkan...'
                                  : 'Login dengan Akun Sekolah',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppColors.primary
                                  .withValues(alpha: 0.65),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      _buildSecurityWarning(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo({required double size, required double radius}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.gray100, width: 2),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x15000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          'assets/images/logoSekolah.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.red50,
        border: Border.all(color: AppColors.red200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _error,
        style: const TextStyle(fontSize: 14, color: AppColors.destructive),
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
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.foreground,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _identifierController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            hintText: 'contoh: admin@siakad.sch.id atau NISN/NIP',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Password',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.foreground,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _loading ? null : _handleLocalLogin(),
          decoration: InputDecoration(
            hintText: 'Masukkan password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
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
              disabledBackgroundColor: AppColors.primary.withValues(
                alpha: 0.65,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
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
            style: TextStyle(fontSize: 13, color: AppColors.gray500),
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'atau',
            style: TextStyle(fontSize: 14, color: AppColors.gray500),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.borderMedium)),
      ],
    );
  }

  Widget _buildSecurityWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.red50,
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: AppColors.destructive, width: 4),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.warning_amber,
              size: 20,
              color: AppColors.destructive,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Akses tidak sah dilarang keras dan akan dicatat oleh sistem.',
              style: TextStyle(fontSize: 14, color: AppColors.destructive),
            ),
          ),
        ],
      ),
    );
  }
}
