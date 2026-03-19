import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aslan_pixel/core/config/app_colors.dart';
import 'package:aslan_pixel/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:aslan_pixel/features/onboarding/view/pixel_avatar_painter.dart';

// ---------------------------------------------------------------------------
// Avatar metadata — names and sprite asset paths
// ---------------------------------------------------------------------------

class _AvatarMeta {
  const _AvatarMeta({
    required this.id,
    required this.name,
    required this.role,
    required this.spriteAsset,
    required this.painterIndex,
  });

  final String id;
  final String name;
  final String role;
  final String spriteAsset;
  final int painterIndex;
}

const List<_AvatarMeta> _avatars = [
  _AvatarMeta(
    id: 'A1',
    name: 'Nexus',
    role: 'Analyst',
    spriteAsset: 'assets/sprites/avatars/avatar_a1_nexus_front.png',
    painterIndex: 0,
  ),
  _AvatarMeta(
    id: 'A2',
    name: 'Valen',
    role: 'Scout',
    spriteAsset: 'assets/sprites/avatars/avatar_a2_valen_front.png',
    painterIndex: 1,
  ),
  _AvatarMeta(
    id: 'A3',
    name: 'Lyra',
    role: 'Trader',
    spriteAsset: 'assets/sprites/avatars/avatar_a3_lyra_front.png',
    painterIndex: 2,
  ),
  _AvatarMeta(
    id: 'A4',
    name: 'Sora',
    role: 'Hacker',
    spriteAsset: 'assets/sprites/avatars/avatar_a4_sora_front.png',
    painterIndex: 3,
  ),
  _AvatarMeta(
    id: 'A5',
    name: 'Riven',
    role: 'Influencer',
    spriteAsset: 'assets/sprites/avatars/avatar_a5_riven_front.png',
    painterIndex: 4,
  ),
  _AvatarMeta(
    id: 'A6',
    name: 'Kai',
    role: 'Wizard',
    spriteAsset: 'assets/sprites/avatars/avatar_a6_kai_front.png',
    painterIndex: 5,
  ),
  _AvatarMeta(
    id: 'A7',
    name: 'Specter',
    role: 'Agent',
    spriteAsset: 'assets/sprites/avatars/avatar_a7_specter_front.png',
    painterIndex: 6,
  ),
  _AvatarMeta(
    id: 'A8',
    name: 'Drako',
    role: 'Tycoon',
    spriteAsset: 'assets/sprites/avatars/avatar_a8_drako_front.png',
    painterIndex: 7,
  ),
];

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  static const routeName = '/onboarding';

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next(BuildContext context) {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } else {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      context.read<OnboardingBloc>().add(OnboardingCompleted(uid));
    }
  }

  void _skip(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    context.read<OnboardingBloc>().add(OnboardingCompleted(uid));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingBloc(),
      child: _OnboardingView(
        pageController: _pageController,
        currentPage: _currentPage,
        onPageChanged: (page) => setState(() => _currentPage = page),
        onNext: _next,
        onSkip: _skip,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// View shell
// ---------------------------------------------------------------------------

class _OnboardingView extends StatelessWidget {
  const _OnboardingView({
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
    required this.onNext,
    required this.onSkip,
  });

  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final void Function(BuildContext context) onNext;
  final void Function(BuildContext context) onSkip;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return BlocListener<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        if (state is OnboardingDone) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      },
      child: Scaffold(
        backgroundColor: colors.scaffoldBackground,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top bar: dots + skip ──────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    _ProgressDots(currentPage: currentPage, colors: colors),
                    const Spacer(),
                    if (currentPage < 2)
                      GestureDetector(
                        onTap: () => onSkip(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Text(
                            'ข้าม',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Pages ─────────────────────────────────────────────────
              Expanded(
                child: PageView(
                  controller: pageController,
                  onPageChanged: onPageChanged,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [
                    _IntroStep(),
                    _AvatarStep(),
                    _UsernameStep(),
                  ],
                ),
              ),

              // ── Next / Start button ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                child: BlocBuilder<OnboardingBloc, OnboardingState>(
                  builder: (context, state) {
                    final isSubmitting = state is OnboardingSubmitting;
                    final label = currentPage == 0
                        ? 'เริ่มต้น'
                        : currentPage == 1
                            ? 'เลือกแล้ว!'
                            : 'เข้าสู่โลก';
                    return SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed:
                            isSubmitting ? null : () => onNext(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.textOnPrimary,
                          disabledBackgroundColor:
                              colors.primary.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: isSubmitting
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: colors.textOnPrimary,
                                ),
                              )
                            : Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Progress Dots
// ---------------------------------------------------------------------------

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({
    required this.currentPage,
    required this.colors,
  });

  final int currentPage;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? colors.primary : colors.border,
            borderRadius: BorderRadius.circular(4),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.45),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 1: Intro
// ---------------------------------------------------------------------------

class _IntroStep extends StatefulWidget {
  const _IntroStep();

  @override
  State<_IntroStep> createState() => _IntroStepState();
}

class _IntroStepState extends State<_IntroStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _glow;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _glow = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulse,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 2),

          // ── Animated logo ──
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeIn.value,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: _glow.value * 0.55),
                        blurRadius: 40 + _glow.value * 30,
                        spreadRadius: 4 + _glow.value * 8,
                      ),
                      BoxShadow(
                        color: colors.cyber.withValues(alpha: _glow.value * 0.25),
                        blurRadius: 60,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: child,
                ),
              );
            },
            child: Center(
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    const Color(0xFF00f5a0),
                    const Color(0xFF7b2fff),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Text(
                  'AP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 48),

          // ── App name ──
          Text(
            'Aslan Pixel',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 12),

          // ── Thai tagline ──
          Text(
            'เครือข่ายการเงินสังคม\nและโลกพิกเซลที่รอคุณ',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 17,
              height: 1.55,
              letterSpacing: 0.2,
            ),
          ),

          const SizedBox(height: 40),

          // ── Feature chips ──
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _FeatureChip(
                icon: Icons.auto_graph_rounded,
                label: 'วิเคราะห์พอร์ต',
                colors: colors,
              ),
              _FeatureChip(
                icon: Icons.gamepad_rounded,
                label: 'โลกพิกเซล',
                colors: colors,
              ),
              _FeatureChip(
                icon: Icons.people_alt_rounded,
                label: 'Social Feed',
                colors: colors,
              ),
              _FeatureChip(
                icon: Icons.smart_toy_rounded,
                label: 'AI Agents',
                colors: colors,
              ),
            ],
          ),

          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.colors,
  });

  final IconData icon;
  final String label;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colors.primary, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2: Avatar Picker
// ---------------------------------------------------------------------------

class _AvatarStep extends StatelessWidget {
  const _AvatarStep();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'เลือกตัวละครของคุณ',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'ตัวละครนี้จะปรากฏในโลกพิกเซลของคุณ',
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BlocBuilder<OnboardingBloc, OnboardingState>(
              builder: (context, state) {
                final selectedId =
                    state is OnboardingInProgress ? state.avatarId : null;

                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.72, // portrait cards taller than wide
                  ),
                  itemCount: _avatars.length,
                  itemBuilder: (context, index) {
                    final meta = _avatars[index];
                    final isSelected = selectedId == meta.id;

                    return _AvatarCard(
                      meta: meta,
                      isSelected: isSelected,
                      colors: colors,
                      onTap: () => context
                          .read<OnboardingBloc>()
                          .add(OnboardingAvatarSelected(meta.id)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarCard extends StatelessWidget {
  const _AvatarCard({
    required this.meta,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  final _AvatarMeta meta;
  final bool isSelected;
  final AppColorScheme colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transformAlignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          isSelected ? 1.05 : 1.0,
          isSelected ? 1.05 : 1.0,
          1.0,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          // Gradient border via outer container + inner padding trick
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF00f5a0), Color(0xFFf5c518)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : colors.border,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.accent.withValues(alpha: 0.35),
                    blurRadius: 16,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.25),
                    blurRadius: 24,
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        padding: EdgeInsets.all(isSelected ? 2.0 : 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.08)
                : colors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 6),
              // Avatar image: try PNG sprite, fall back to CustomPainter
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _AvatarImage(
                    meta: meta,
                    isSelected: isSelected,
                    colors: colors,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Character name
              Text(
                meta.name,
                style: TextStyle(
                  color: isSelected ? colors.primary : colors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              // Role subtitle
              Text(
                meta.role,
                style: TextStyle(
                  color: isSelected
                      ? colors.accent.withValues(alpha: 0.9)
                      : colors.textDisabled,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 5),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({
    required this.meta,
    required this.isSelected,
    required this.colors,
  });

  final _AvatarMeta meta;
  final bool isSelected;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      meta.spriteAsset,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.none, // pixel-art: no blurring
      errorBuilder: (context, error, stackTrace) {
        // Fallback to CustomPainter if sprite not loaded
        return LayoutBuilder(
          builder: (context, constraints) => CustomPaint(
            painter: PixelAvatarPainter(avatarIndex: meta.painterIndex),
            size: Size(constraints.maxWidth, constraints.maxHeight),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Step 3: Username Input
// ---------------------------------------------------------------------------

class _UsernameStep extends StatefulWidget {
  const _UsernameStep();

  @override
  State<_UsernameStep> createState() => _UsernameStepState();
}

class _UsernameStepState extends State<_UsernameStep> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        final selectedId =
            state is OnboardingInProgress ? state.avatarId : null;
        final meta = selectedId != null
            ? _avatars.firstWhere(
                (a) => a.id == selectedId,
                orElse: () => _avatars.first,
              )
            : _avatars.first;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),

              Text(
                'ตั้งชื่อตัวละคร',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'ชื่อที่คนอื่นในโลกพิกเซลจะเห็น',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 32),

              // ── Avatar preview ──────────────────────────────────────
              _AvatarPreviewCard(meta: meta, colors: colors),

              const SizedBox(height: 32),

              // ── Username field ───────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: colors.inputBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.inputBorder, width: 1.5),
                ),
                child: TextField(
                  controller: _controller,
                  maxLength: 20,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                  decoration: InputDecoration(
                    hintText: 'เช่น PixelTrader99',
                    hintStyle: TextStyle(
                      color: colors.textDisabled,
                      fontSize: 15,
                    ),
                    counterText: '',
                    prefixIcon: Icon(
                      Icons.alternate_email_rounded,
                      color: colors.textTertiary,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  onChanged: (value) => context
                      .read<OnboardingBloc>()
                      .add(OnboardingUsernameChanged(value.trim())),
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'ไม่ต้องห่วง — แก้ไขได้ภายหลังในโปรไฟล์',
                style: TextStyle(
                  color: colors.textDisabled,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _AvatarPreviewCard extends StatelessWidget {
  const _AvatarPreviewCard({
    required this.meta,
    required this.colors,
  });

  final _AvatarMeta meta;
  final AppColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      height: 160,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00f5a0), Color(0xFFf5c518)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.4),
            blurRadius: 24,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: colors.accent.withValues(alpha: 0.2),
            blurRadius: 40,
            spreadRadius: -4,
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(17),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(
              child: Image.asset(
                meta.spriteAsset,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.none,
                errorBuilder: (context, error, stackTrace) =>
                    LayoutBuilder(
                  builder: (context, constraints) => CustomPaint(
                    painter:
                        PixelAvatarPainter(avatarIndex: meta.painterIndex),
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              meta.name,
              style: TextStyle(
                color: colors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              meta.role,
              style: TextStyle(
                color: colors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
