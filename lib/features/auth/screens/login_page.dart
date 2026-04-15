// File: lib/features/auth/screens/login_page.dart
// ===========================================
// LOGIN PAGE
// Exact translation from LoginPage.tsx
// Split-screen layout: left brand panel, right login form
// StatefulWidget: email, password, error, showCredentials
// ===========================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/models/user.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _error = '';
  bool _showCredentials = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    setState(() => _error = '');

    final success = await ref
        .read(authProvider.notifier)
        .login(_emailController.text, _passwordController.text);

    if (success && mounted) {
      final user = ref.read(authProvider).valueOrNull;
      if (user != null) {
        _navigateByRole(user.role);
      }
    } else if (mounted) {
      setState(() {
        _error = 'Email atau password salah. Silakan coba lagi.';
      });
    }
  }

  void _handleGoogleLogin() async {
    // Simulate Google login as admin
    final adminUser = const User(
      id: '1',
      email: 'admin@sman1cikalong.sch.id',
      password: '',
      name: 'Administrator',
      role: UserRole.admin,
    );
    await ref.read(authProvider.notifier).loginAsUser(adminUser);
    if (mounted) context.go('/dashboard');
  }

  void _navigateByRole(UserRole role) {
    switch (role) {
      case UserRole.curriculum:
        context.go('/curriculum/dashboard');
      case UserRole.admin:
        context.go('/dashboard');
      case UserRole.teacher:
        context.go('/guru/dashboard');
      case UserRole.student:
        context.go('/siswa/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // ── Left Side: Brand Panel (hidden on small screens) ──
          if (MediaQuery.of(context).size.width >= 1024)
            Expanded(child: _buildBrandPanel()),

          // ── Right Side: Login Form ──
          Expanded(child: _buildLoginPanel(context)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // LEFT PANEL — Brand/Visual (lg:w-1/2)
  // ═══════════════════════════════════════════
  Widget _buildBrandPanel() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        CachedNetworkImage(
          imageUrl:
              'https://images.unsplash.com/photo-1660128357926-bce1e0a9c294?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=1920',
          fit: BoxFit.cover,
          placeholder: (_, __) =>
              Container(color: AppColors.primary),
          errorWidget: (_, __, ___) =>
              Container(color: AppColors.primary),
        ),

        // Blue overlay (bg-[#1E3A8A]/80)
        Container(color: AppColors.primary.withValues(alpha: 0.8)),

        // Content
        Center(
          child: Padding(
            padding: const EdgeInsets.all(48), // p-12
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // School Logo (w-20 h-20)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16), // rounded-2xl
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 25,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(8), // p-2
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset('assets/images/logoSekolah.png', fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 32), // mb-8

                // Title
                const Text(
                  'SMA NEGERI 1 CIKALONG',
                  style: TextStyle(
                    fontSize: 40, // text-4xl md:text-5xl
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24), // mb-6

                // Quote
                const Text(
                  '"Pendidikan adalah senjata paling ampuh yang dapat Anda gunakan untuk mengubah dunia."',
                  style: TextStyle(
                    fontSize: 20, // text-xl md:text-2xl
                    fontWeight: FontWeight.w300,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16), // mt-4

                Text(
                  '— Nelson Mandela',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // RIGHT PANEL — Login Form (w-full lg:w-1/2)
  // ═══════════════════════════════════════════
  Widget _buildLoginPanel(BuildContext context) {
    return Container(
      color: AppColors.background, // bg-[#F8FAFC]
      child: Stack(
        children: [
          // Back to Home button (absolute top-6 left-6)
          Positioned(
            top: 24,
            left: 24,
            child: InkWell(
              onTap: () => context.go('/'),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8), // gap-2
                    const Text(
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

          // Center content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48), // p-6 sm:p-12
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 448), // max-w-md
                child: AnimatedOpacity(
                  opacity: 1,
                  duration: const Duration(milliseconds: 600),
                  child: Column(
                    children: [
                      // Mobile logo (lg:hidden)
                      if (MediaQuery.of(context).size.width < 1024) ...[
                        Center(
                          child: Container(
                            width: 64, // w-16
                            height: 64, // h-16
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12), // rounded-xl
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x30000000),
                                  blurRadius: 15,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset('assets/images/logoSekolah.png', fit: BoxFit.contain),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32), // mb-8
                      ],

                      // Login Card (bg-white rounded-3xl shadow-lg p-8 sm:p-10)
                      Container(
                        padding: const EdgeInsets.all(40), // p-8 sm:p-10
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24), // rounded-3xl
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
                            // School Logo inside card (w-20 h-20)
                            Center(
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: AppColors.gray100, width: 2),
                                  borderRadius: BorderRadius.circular(16),
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
                                  child: Image.asset('assets/images/logoSekolah.png', fit: BoxFit.contain),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24), // mb-6

                            // Headlines (text-center mb-8)
                            const Text(
                              'Portal Login Akademik',
                              style: TextStyle(
                                fontSize: 30, // text-3xl
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8), // mb-2
                            Text(
                              'Akses aman untuk siswa, guru, dan staf',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.foreground.withValues(alpha: 0.75),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32), // mb-8

                            // Demo Credentials Toggle (mb-4)
                            _buildDemoCredentials(),
                            const SizedBox(height: 16),

                            // Google SSO Button (mb-6)
                            _buildGoogleButton(),
                            const SizedBox(height: 24),

                            // Divider "atau"
                            _buildDivider(),
                            const SizedBox(height: 24),

                            // Error Message
                            if (_error.isNotEmpty) ...[
                              _buildErrorMessage(),
                              const SizedBox(height: 16),
                            ],

                            // Login Form (space-y-5)
                            _buildLoginForm(),

                            const SizedBox(height: 24), // mt-6

                            // Security Warning
                            _buildSecurityWarning(),

                            const SizedBox(height: 24), // mt-6

                            // Footer Links
                            _buildFooterLinks(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24), // mt-6

                      // Copyright
                      const Text(
                        '© 2026 SMA Negeri 1 Cikalong. Hak Cipta Dilindungi.',
                        style: TextStyle(fontSize: 14, color: AppColors.gray500),
                        textAlign: TextAlign.center,
                      ),
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

  // ── Demo Credentials ──
  Widget _buildDemoCredentials() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _showCredentials = !_showCredentials),
          child: Text(
            '${_showCredentials ? "Sembunyikan" : "Lihat"} Akun Demo',
            style: const TextStyle(
              fontSize: 14, // text-sm
              fontWeight: FontWeight.w500,
              color: AppColors.accent,
            ),
          ),
        ),
        if (_showCredentials) ...[
          const SizedBox(height: 12), // mt-3
          Container(
            padding: const EdgeInsets.all(16), // p-4
            decoration: BoxDecoration(
              color: AppColors.blue50,
              borderRadius: BorderRadius.circular(8), // rounded-lg
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Akun Demo:',
                  style: TextStyle(
                    fontSize: 12, // text-xs
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8), // space-y-2
                ..._demoAccounts.map((account) => Padding(
                      padding: const EdgeInsets.only(bottom: 4), // space-y-1
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 12, color: AppColors.foreground),
                          children: [
                            TextSpan(
                              text: '${account['role']}: ',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            TextSpan(text: account['credentials']),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static const List<Map<String, String>> _demoAccounts = [
    {'role': 'Admin', 'credentials': 'admin@sman1cikalong.sch.id / admin123'},
    {'role': 'Kurikulum', 'credentials': 'kurikulum@sman1cikalong.sch.id / kurikulum123'},
    {'role': 'Guru', 'credentials': 'guru@sman1cikalong.sch.id / guru123'},
    {'role': 'Siswa', 'credentials': 'siswa@sman1cikalong.sch.id / siswa123'},
  ];

  // ── Google SSO Button ──
  Widget _buildGoogleButton() {
    return OutlinedButton(
      onPressed: _handleGoogleLogin,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24), // py-3.5 px-6
        side: const BorderSide(color: AppColors.borderMedium, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // rounded-xl
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Google "G" icon
          Image.network(
            'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
            width: 20,
            height: 20,
            errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 24),
          ),
          const SizedBox(width: 12), // gap-3
          const Text(
            'Masuk dengan Google',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.foreground,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // ── Divider ──
  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.borderMedium)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16), // gap-4
          child: Text(
            'atau',
            style: TextStyle(fontSize: 14, color: AppColors.gray500),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.borderMedium)),
      ],
    );
  }

  // ── Error Message ──
  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12), // p-3
      decoration: BoxDecoration(
        color: AppColors.red50,
        border: Border.all(color: AppColors.red200),
        borderRadius: BorderRadius.circular(8), // rounded-lg
      ),
      child: Text(
        _error,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFFDC2626), // text-red-600
        ),
      ),
    );
  }

  // ── Login Form ──
  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Email field
        const Text(
          'ID Sekolah / Email',
          style: TextStyle(
            fontSize: 14, // text-sm
            fontWeight: FontWeight.w500,
            color: AppColors.foreground,
          ),
        ),
        const SizedBox(height: 8), // mb-2
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            hintText: 'Masukkan ID atau email Anda',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20), // space-y-5

        // Password field
        const Text(
          'Kata Sandi',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.foreground,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          decoration: const InputDecoration(
            hintText: 'Masukkan kata sandi Anda',
          ),
          obscureText: true,
        ),
        const SizedBox(height: 20),

        // Submit button
        SizedBox(
          height: 52, // py-3.5
          child: ElevatedButton(
            onPressed: _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // rounded-xl
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('Masuk'),
          ),
        ),
      ],
    );
  }

  // ── Security Warning ──
  Widget _buildSecurityWarning() {
    return Container(
      padding: const EdgeInsets.all(16), // p-4
      decoration: BoxDecoration(
        color: AppColors.red50,
        borderRadius: BorderRadius.circular(8), // rounded-lg
        border: const Border(
          left: BorderSide(color: AppColors.destructive, width: 4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2), // mt-0.5
            child: Icon(Icons.warning_amber, size: 20, color: AppColors.destructive),
          ),
          const SizedBox(width: 12), // gap-3
          const Expanded(
            child: Text(
              'Akses tidak sah dilarang keras dan akan dilaporkan kepada pihak berwenang.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.destructive,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer Links ──
  Widget _buildFooterLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          onTap: () {},
          child: Row(
            children: [
              Icon(Icons.help_outline, size: 16, color: AppColors.gray600),
              const SizedBox(width: 4),
              Text('Butuh Bantuan?', style: TextStyle(fontSize: 14, color: AppColors.gray600)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24), // gap-6
          child: Text('|', style: TextStyle(color: AppColors.borderMedium)),
        ),
        InkWell(
          onTap: () {},
          child: Row(
            children: [
              Icon(Icons.shield_outlined, size: 16, color: AppColors.gray600),
              const SizedBox(width: 4),
              Text('Kebijakan Privasi', style: TextStyle(fontSize: 14, color: AppColors.gray600)),
            ],
          ),
        ),
      ],
    );
  }
}
