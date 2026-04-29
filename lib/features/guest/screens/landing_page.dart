// File: lib/features/guest/screens/landing_page.dart
// ===========================================
// LANDING PAGE (Guest / Public)
// Sections: Header, Hero, News, Achievements, Videos, Footer
// With working navbar, card animations, and consistent card sizes
// ===========================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _heroKey = GlobalKey();
  final GlobalKey _newsKey = GlobalKey();
  final GlobalKey _achievementsKey = GlobalKey();
  final GlobalKey _videoKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _HeaderBar(
            onLoginTap: () => context.go('/login'),
            onNavTap: (index) {
              switch (index) {
                case 0: _scrollToSection(_heroKey); break;
                case 1: _scrollToSection(_newsKey); break;
                case 2: _scrollToSection(_newsKey); break;
                case 3: _scrollToSection(_newsKey); break;
                case 4: _scrollToSection(_achievementsKey); break;
              }
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  _HeroSection(
                    key: _heroKey,
                    onLearnMore: () => _scrollToSection(_newsKey),
                  ),
                  _NewsSection(key: _newsKey),
                  _AchievementsSection(key: _achievementsKey),
                  _VideoSection(key: _videoKey),
                  const _Footer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// HEADER BAR — sticky top with working nav & mobile drawer
// ═══════════════════════════════════════════════
class _HeaderBar extends StatelessWidget {
  final VoidCallback onLoginTap;
  final void Function(int index) onNavTap;
  const _HeaderBar({required this.onLoginTap, required this.onNavTap});

  static const List<String> _navLinks = [
    'Beranda',
    'Tentang Kami',
    'Akademik',
    'Berita & Acara',
    'Prestasi',
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      color: AppColors.primary,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    padding: const EdgeInsets.all(4),
                    child: Image.asset('assets/images/logoSekolah.png', fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'SMA NEGERI 1 CIKALONG',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Desktop nav links with hover
                  if (screenWidth >= 768) ...[
                    const SizedBox(width: 32),
                    ...List.generate(_navLinks.length, (i) => _NavLinkButton(
                      label: _navLinks[i],
                      onTap: () => onNavTap(i),
                    )),
                  ],

                  // Mobile hamburger
                  if (screenWidth < 768)
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: AppColors.primary,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (_) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 8),
                                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(2))),
                                const SizedBox(height: 16),
                                ...List.generate(_navLinks.length, (i) => ListTile(
                                  title: Text(_navLinks[i], style: const TextStyle(color: Colors.white, fontSize: 16)),
                                  leading: const Icon(Icons.chevron_right, color: AppColors.accent),
                                  onTap: () { Navigator.pop(context); onNavTap(i); },
                                )),
                                const Divider(color: Colors.white24),
                                ListTile(
                                  title: const Text('Login Akademik', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600, fontSize: 16)),
                                  leading: const Icon(Icons.login, color: AppColors.accent),
                                  onTap: () { Navigator.pop(context); onLoginTap(); },
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  if (screenWidth >= 768) ...[
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: onLoginTap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Login Akademik', style: TextStyle(fontWeight: FontWeight.w500)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Nav link with hover underline effect
class _NavLinkButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _NavLinkButton({required this.label, required this.onTap});

  @override
  State<_NavLinkButton> createState() => _NavLinkButtonState();
}

class _NavLinkButtonState extends State<_NavLinkButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.label, style: TextStyle(
                color: _hovered ? AppColors.accent : Colors.white,
                fontSize: 14, fontWeight: _hovered ? FontWeight.w600 : FontWeight.w400,
              )),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 2,
                width: _hovered ? 24 : 0,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// HERO SECTION — Full viewport height, bg image overlay
// ═══════════════════════════════════════════════
class _HeroSection extends StatelessWidget {
  final VoidCallback onLearnMore;
  const _HeroSection({super.key, required this.onLearnMore});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height - 64; // calc(100vh - 4rem)

    return SizedBox(
      height: screenHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/images/heroImage.jpeg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          // Gradient overlay (from-black/70 to-black/40)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.black.withValues(alpha: 0.4),
                ],
              ),
            ),
          ),

          // Content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 896), // max-w-4xl
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title with accent span
                    AnimatedOpacity(
                      opacity: 1,
                      duration: const Duration(milliseconds: 800),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Selamat Datang di SMA NEGERI 1 CIKALONG\n',
                              style: TextStyle(
                                fontSize: 48, // text-4xl sm:text-5xl md:text-6xl
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                            TextSpan(
                              text: 'Membina Keunggulan dalam Pendidikan',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent, // text-[#F59E0B]
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24), // mb-6 mapped to hero spacing

                    // Subtitle
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 672), // max-w-2xl
                      child: const Text(
                        'Institusi modern yang berdedikasi untuk pertumbuhan akademik dan pengembangan holistik',
                        style: TextStyle(
                          fontSize: 20, // text-lg sm:text-xl
                          color: Color(0xFFE5E7EB), // text-gray-200
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32), // mb-8

                    // CTA Button
                    ElevatedButton(
                      onPressed: onLearnMore,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent, // bg-[#F59E0B]
                        foregroundColor: AppColors.foreground, // text-[#0F172A]
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ), // px-8 py-4
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8), // rounded-lg
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18, // text-lg
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Selengkapnya'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// NEWS SECTION — py-20, 3-column grid
// ═══════════════════════════════════════════════
class _NewsSection extends StatelessWidget {
  const _NewsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            children: [
              const Text(
                'Berita & Pengumuman Terbaru',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.primary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth >= 1024 ? 3 : constraints.maxWidth >= 768 ? 2 : 1;
                  return Wrap(
                    spacing: 32, runSpacing: 32,
                    children: List.generate(_newsData.length, (i) {
                      final cardWidth = (constraints.maxWidth - (crossAxisCount - 1) * 32) / crossAxisCount;
                      return SizedBox(width: cardWidth, child: _NewsCard(news: _newsData[i], index: i));
                    }),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsCard extends StatefulWidget {
  final Map<String, String> news;
  final int index;
  const _NewsCard({required this.news, required this.index});

  @override
  State<_NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<_NewsCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: 150 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            transform: Matrix4.diagonal3Values(_hovered ? 1.03 : 1.0, _hovered ? 1.03 : 1.0, 1.0),
            transformAlignment: Alignment.center,
            height: 420,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _hovered ? const Color(0x30000000) : const Color(0x15000000),
                  blurRadius: _hovered ? 20 : 10,
                  offset: Offset(0, _hovered ? 8 : 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 192, width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: widget.news['image']!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppColors.gray200),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.gray200,
                      child: const Icon(Icons.image, size: 48, color: AppColors.gray400),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.news['title']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: AppColors.foreground), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Text(widget.news['excerpt']!, style: const TextStyle(fontSize: 14, color: AppColors.gray600), maxLines: 3, overflow: TextOverflow.ellipsis),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(widget.news['date']!, style: const TextStyle(fontSize: 14, color: AppColors.gray500)),
                            InkWell(
                              onTap: () {},
                              child: const Row(children: [
                                Text('Baca Selengkapnya', style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.accent, fontSize: 14)),
                                SizedBox(width: 4),
                                Text('→', style: TextStyle(color: AppColors.accent)),
                              ]),
                            ),
                          ],
                        ),
                      ],
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
}

// ═══════════════════════════════════════════════
// ACHIEVEMENTS SECTION — py-20, 4-column grid
// ═══════════════════════════════════════════════
class _AchievementsSection extends StatelessWidget {
  const _AchievementsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            children: [
              const Text('Prestasi yang Membanggakan', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.primary), textAlign: TextAlign.center),
              const SizedBox(height: 48),
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth >= 1024 ? 4 : constraints.maxWidth >= 768 ? 2 : 1;
                  return Wrap(
                    spacing: 24, runSpacing: 24,
                    children: List.generate(_achievementsData.length, (i) {
                      final cardWidth = (constraints.maxWidth - (crossAxisCount - 1) * 24) / crossAxisCount;
                      return SizedBox(width: cardWidth, child: _AchievementCard(data: _achievementsData[i], index: i));
                    }),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievementCard extends StatefulWidget {
  final Map<String, String> data;
  final int index;
  const _AchievementCard({required this.data, required this.index});

  @override
  State<_AchievementCard> createState() => _AchievementCardState();
}

class _AchievementCardState extends State<_AchievementCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: 120 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            transform: Matrix4.diagonal3Values(_hovered ? 1.05 : 1.0, _hovered ? 1.05 : 1.0, 1.0),
            transformAlignment: Alignment.center,
            height: 260,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _hovered ? const Color(0x30000000) : const Color(0x15000000),
                  blurRadius: _hovered ? 20 : 10,
                  offset: Offset(0, _hovered ? 8 : 4),
                ),
              ],
              border: const Border(left: BorderSide(color: AppColors.accent, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.accent, AppColors.accentHover]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: widget.data['icon']!, fit: BoxFit.cover,
                      placeholder: (_, __) => const Icon(Icons.emoji_events, color: Colors.white, size: 32),
                      errorWidget: (_, __, ___) => const Icon(Icons.emoji_events, color: Colors.white, size: 32),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(widget.data['title']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.foreground)),
                const SizedBox(height: 8),
                Expanded(child: Text(widget.data['description']!, style: const TextStyle(fontSize: 14, color: AppColors.gray600))),
                Text(widget.data['year']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.accent)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// VIDEO SECTION — py-20, 3-column grid
// ═══════════════════════════════════════════════
class _VideoSection extends StatelessWidget {
  const _VideoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            children: [
              const Text('Video Unggulan & Kehidupan Kampus', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.primary), textAlign: TextAlign.center),
              const SizedBox(height: 48),
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth >= 1024 ? 3 : constraints.maxWidth >= 768 ? 2 : 1;
                  return Wrap(
                    spacing: 32, runSpacing: 32,
                    children: List.generate(_videoData.length, (i) {
                      final cardWidth = (constraints.maxWidth - (crossAxisCount - 1) * 32) / crossAxisCount;
                      return SizedBox(width: cardWidth, child: _VideoCard(data: _videoData[i], index: i));
                    }),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoCard extends StatefulWidget {
  final Map<String, String> data;
  final int index;
  const _VideoCard({required this.data, required this.index});

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: 150 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            transform: Matrix4.diagonal3Values(_hovered ? 1.03 : 1.0, _hovered ? 1.03 : 1.0, 1.0),
            transformAlignment: Alignment.center,
            height: 340,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _hovered ? const Color(0x30000000) : const Color(0x15000000),
                  blurRadius: _hovered ? 20 : 10,
                  offset: Offset(0, _hovered ? 8 : 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 224, width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: widget.data['thumbnail']!, fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: AppColors.gray900),
                        errorWidget: (_, __, ___) => Container(color: AppColors.gray900),
                      ),
                      Container(color: Colors.black.withValues(alpha: 0.3)),
                      Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: _hovered ? 72 : 64,
                          height: _hovered ? 72 : 64,
                          decoration: BoxDecoration(
                            color: _hovered ? AppColors.accentHover : AppColors.accent,
                            shape: BoxShape.circle,
                            boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 15, offset: Offset(0, 4))],
                          ),
                          child: const Icon(Icons.play_arrow, size: 32, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.data['title']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.foreground)),
                        const Spacer(),
                        Text(widget.data['duration']!, style: const TextStyle(fontSize: 14, color: AppColors.gray500)),
                      ],
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
}

// ═══════════════════════════════════════════════
// FOOTER — bg-[#0F172A], 4-column grid
// ═══════════════════════════════════════════════
class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.foreground, // bg-[#0F172A]
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16), // py-12
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            children: [
              // 4-column grid
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 768) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildSchoolInfo()),
                        Expanded(child: _buildQuickLinks()),
                        Expanded(child: _buildContactInfo()),
                        Expanded(child: _buildSocialMedia()),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSchoolInfo(),
                      const SizedBox(height: 32),
                      _buildQuickLinks(),
                      const SizedBox(height: 32),
                      _buildContactInfo(),
                      const SizedBox(height: 32),
                      _buildSocialMedia(),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32), // mb-8

              // Bottom border + copyright
              Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.gray700, width: 1),
                  ),
                ),
                padding: const EdgeInsets.only(top: 32), // pt-8
                child: const Center(
                  child: Text(
                    '© 2026 SMA Negeri 1 Cikalong. Hak Cipta Dilindungi.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSchoolInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              padding: const EdgeInsets.all(4),
              child: Image.asset('assets/images/logoSekolah.png', fit: BoxFit.contain),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: const Text(
                'SMA NEGERI 1 CIKALONG',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Membangun pemimpin masa depan melalui keunggulan dalam pendidikan dan pengembangan karakter.',
          style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
        ),
      ],
    );
  }

  Widget _buildQuickLinks() {
    const links = ['Tentang Kami', 'Akademik', 'Pendaftaran', 'Kontak'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tautan Cepat',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 16),
        ...links.map((link) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(link, style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
            )),
      ],
    );
  }

  Widget _buildContactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hubungi Kami',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 16),
        _contactRow(Icons.location_on, 'Jl. Raya Cikalong, Kec. Cikalong, Kab. Bandung Barat'),
        const SizedBox(height: 12),
        _contactRow(Icons.phone, '(022) 123-4567'),
        const SizedBox(height: 12),
        _contactRow(Icons.email, 'info@sman1cikalong.sch.id'),
      ],
    );
  }

  Widget _contactRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
        ),
      ],
    );
  }

  Widget _buildSocialMedia() {
    final socialIcons = [Icons.facebook, Icons.close, Icons.camera_alt, Icons.play_circle];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ikuti Kami',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 16),
        Row(
          children: socialIcons
              .map(
                (icon) => Padding(
                  padding: const EdgeInsets.only(right: 12), // gap-3
                  child: Container(
                    width: 40, // w-10
                    height: 40, // h-10
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 20, color: Colors.white),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════
// STATIC DATA — Translated from React const arrays
// ═══════════════════════════════════════════════
const List<Map<String, String>> _newsData = [
  {
    'title': 'Pemenang Pameran Sains Tahunan Diumumkan',
    'excerpt':
        'Selamat kepada siswa-siswa berbakat kami yang menampilkan proyek-proyek inovatif pada pameran sains tahun ini, meraih penghargaan tertinggi di berbagai kategori.',
    'date': '28 Maret 2026',
    'image':
        'https://images.unsplash.com/photo-1606761568499-6d2451b23c66?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=800',
  },
  {
    'title': 'Laboratorium STEM Baru Dibuka',
    'excerpt':
        'Laboratorium STEM berteknologi canggih kini terbuka untuk siswa, dilengkapi peralatan mutakhir dan ruang pembelajaran kolaboratif.',
    'date': '15 Maret 2026',
    'image':
        'https://images.unsplash.com/photo-1654366698665-e6d611a9aaa9?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=800',
  },
  {
    'title': 'Hasil Kejuaraan Olahraga Musim Semi',
    'excerpt':
        'Tim atletik kami telah membawa pulang berbagai kejuaraan musim ini, menunjukkan keunggulan baik di dalam maupun di luar lapangan.',
    'date': '5 Maret 2026',
    'image':
        'https://images.unsplash.com/photo-1759922378123-a1f4f1e39bae?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=800',
  },
];

const List<Map<String, String>> _achievementsData = [
  {
    'title': 'Olimpiade Sains Nasional',
    'description': 'Juara pertama dalam kompetisi Olimpiade Sains Nasional',
    'year': '2026',
    'icon':
        'https://images.unsplash.com/photo-1770482228588-270b08d2d376?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=200',
  },
  {
    'title': 'Penghargaan Keunggulan Akademik',
    'description': 'Sekolah berprestasi terbaik di wilayah untuk pencapaian akademik',
    'year': '2025-2026',
    'icon':
        'https://images.unsplash.com/photo-1762345127396-ac4a970436c3?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=200',
  },
  {
    'title': 'Kejuaraan Robotika',
    'description': 'Juara regional dalam kompetisi robotika tahunan',
    'year': '2026',
    'icon':
        'https://images.unsplash.com/photo-1773314963888-6ecec50555a6?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=200',
  },
  {
    'title': 'Sertifikasi Sekolah Hijau',
    'description': 'Penghargaan untuk keunggulan dalam praktik keberlanjutan lingkungan',
    'year': '2025',
    'icon':
        'https://images.unsplash.com/photo-1764408721535-2dcb912db83e?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=200',
  },
];

const List<Map<String, String>> _videoData = [
  {
    'title': 'Sorotan Hari Olahraga Tahunan',
    'duration': '5:32',
    'thumbnail':
        'https://images.unsplash.com/photo-1769430886896-dc30842be5a3?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=800',
  },
  {
    'title': 'Pameran Sains 2026 - Inovasi Siswa',
    'duration': '8:15',
    'thumbnail':
        'https://images.unsplash.com/photo-1775049668193-38ec1678009a?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=800',
  },
  {
    'title': 'Tur Kampus - Panduan Virtual',
    'duration': '12:40',
    'thumbnail':
        'https://images.unsplash.com/photo-1764025851527-78f9d7c52bc5?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&w=800',
  },
];
