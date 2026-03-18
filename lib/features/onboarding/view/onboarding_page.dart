import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/app_colors.dart';
import '../bloc/onboarding_bloc.dart';

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
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      context.read<OnboardingBloc>().add(OnboardingCompleted(uid));
    }
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
      ),
    );
  }
}

class _OnboardingView extends StatelessWidget {
  const _OnboardingView({
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
    required this.onNext,
  });

  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final void Function(BuildContext context) onNext;

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
              const SizedBox(height: 24),
              _ProgressDots(currentPage: currentPage, colors: colors),
              const SizedBox(height: 24),
              Expanded(
                child: PageView(
                  controller: pageController,
                  onPageChanged: onPageChanged,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [
                    _AvatarStep(),
                    _MarketFocusStep(),
                    _RiskStyleStep(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: BlocBuilder<OnboardingBloc, OnboardingState>(
                  builder: (context, state) {
                    final isSubmitting = state is OnboardingSubmitting;
                    return SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : () => onNext(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.textOnPrimary,
                          disabledBackgroundColor:
                              colors.primary.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                                currentPage < 2 ? 'Next' : 'Start',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
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

// ── Progress Dots ────────────────────────────────────────────────────────────

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
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? colors.primary : colors.border,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ── Step 1: Avatar Picker ────────────────────────────────────────────────────

class _AvatarStep extends StatelessWidget {
  const _AvatarStep();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Your Avatar',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This is how you appear in the Pixel World.',
            style: TextStyle(color: colors.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: BlocBuilder<OnboardingBloc, OnboardingState>(
              builder: (context, state) {
                final selected =
                    state is OnboardingInProgress ? state.avatarId : null;

                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: 8,
                  itemBuilder: (context, index) {
                    final id = 'A${index + 1}';
                    final isSelected = selected == id;
                    return GestureDetector(
                      onTap: () => context
                          .read<OnboardingBloc>()
                          .add(OnboardingAvatarSelected(id)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.primary.withValues(alpha: 0.15)
                              : colors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? colors.primary
                                : colors.border,
                            width: isSelected ? 2.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color:
                                        colors.primary.withValues(alpha: 0.25),
                                    blurRadius: 12,
                                    spreadRadius: 1,
                                  )
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 52,
                              height: 52,
                              child: CustomPaint(
                                painter: _PixelAvatarPainter(
                                  avatarIndex: index,
                                  primaryColor: isSelected
                                      ? colors.primary
                                      : colors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              id,
                              style: TextStyle(
                                color: isSelected
                                    ? colors.primary
                                    : colors.textDisabled,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
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

// ── Pixel Avatar Painter ──────────────────────────────────────────────────────
//
// 8 unique 9×12 pixel-art characters drawn with CustomPainter.
// Each character has: head, eyes, body, arms, legs — distinct colors per avatar.

class _PixelAvatarPainter extends CustomPainter {
  const _PixelAvatarPainter({
    required this.avatarIndex,
    required this.primaryColor,
  });

  final int avatarIndex;
  final Color primaryColor;

  // 8 avatar designs: each is a list of (col, row, colorIndex) pixels
  // colorIndex: 0=skin, 1=hair/hat, 2=body, 3=accent, 4=eyes/detail
  static const List<List<List<int>>> _avatars = [
    // A1 — Analyst: suit + glasses
    [
      [3,0,1],[4,0,1],[5,0,1],
      [2,1,1],[3,1,0],[4,1,0],[5,1,0],[6,1,1],
      [2,2,0],[3,2,0],[4,2,0],[5,2,0],[6,2,0],
      [3,3,4],[5,3,4], // eyes
      [3,4,4],[4,4,0],[5,4,4], // glasses bridge
      [4,5,0], // mouth
      [2,6,2],[3,6,2],[4,6,2],[5,6,2],[6,6,2],
      [2,7,2],[3,7,2],[4,7,2],[5,7,2],[6,7,2],
      [1,6,3],[7,6,3], // arms
      [1,7,3],[7,7,3],
      [3,8,2],[5,8,2],
      [3,9,3],[5,9,3],
      [3,10,3],[5,10,3],
      [2,11,1],[3,11,1],[5,11,1],[6,11,1],
    ],
    // A2 — Scout: hoodie + cap
    [
      [4,0,1],[5,0,1],
      [3,1,1],[4,1,1],[5,1,1],[6,1,1],
      [2,2,0],[3,2,0],[4,2,0],[5,2,0],[6,2,0],
      [3,3,4],[5,3,4],
      [4,5,0],
      [2,6,3],[3,6,3],[4,6,3],[5,6,3],[6,6,3],
      [2,7,3],[3,7,3],[4,7,3],[5,7,3],[6,7,3],
      [1,6,2],[7,6,2],
      [1,7,2],[7,7,2],
      [3,8,3],[5,8,3],
      [3,9,2],[5,9,2],
      [3,10,2],[5,10,2],
      [3,11,1],[4,11,1],[5,11,1],
    ],
    // A3 — Trader: tie + briefcase
    [
      [3,0,1],[4,0,1],[5,0,1],[6,0,1],
      [2,1,0],[3,1,0],[4,1,0],[5,1,0],[6,1,0],[7,1,0],
      [2,2,0],[3,2,0],[4,2,0],[5,2,0],[6,2,0],
      [3,3,4],[5,3,4],
      [4,4,3],[4,5,3],
      [2,6,2],[3,6,2],[4,6,2],[5,6,2],[6,6,2],
      [2,7,2],[3,7,2],[4,7,2],[5,7,2],[6,7,2],
      [1,6,0],[7,6,0],
      [1,7,3],[7,7,3],[8,7,3],[1,8,3],[8,8,3],
      [3,8,2],[5,8,2],
      [3,9,2],[5,9,2],
      [3,10,2],[5,10,2],
      [3,11,0],[4,11,0],[5,11,0],
    ],
    // A4 — Risk: dark hood
    [
      [3,0,1],[4,0,1],[5,0,1],
      [2,1,1],[3,1,0],[4,1,0],[5,1,0],[6,1,1],
      [2,2,1],[3,2,0],[4,2,0],[5,2,0],[6,2,1],
      [3,3,4],[5,3,4],
      [4,5,4],
      [2,6,1],[3,6,1],[4,6,2],[5,6,1],[6,6,1],
      [2,7,1],[3,7,2],[4,7,2],[5,7,2],[6,7,1],
      [1,6,1],[7,6,1],
      [1,7,1],[7,7,1],
      [3,8,2],[5,8,2],
      [3,9,1],[5,9,1],
      [3,10,1],[5,10,1],
      [3,11,1],[4,11,1],[5,11,1],
    ],
    // A5 — Social: bright shirt + headband
    [
      [4,0,3],[5,0,3],
      [3,1,0],[4,1,0],[5,1,0],[6,1,0],
      [2,2,0],[3,2,0],[4,2,0],[5,2,0],[6,2,0],
      [3,3,4],[5,3,4],
      [3,4,0],[4,4,3],[5,4,0],
      [4,5,0],
      [2,6,3],[3,6,3],[4,6,3],[5,6,3],[6,6,3],
      [2,7,3],[3,7,3],[4,7,3],[5,7,3],[6,7,3],
      [1,6,0],[7,6,0],
      [1,7,0],[7,7,0],
      [3,8,3],[5,8,3],
      [3,9,3],[5,9,3],
      [3,10,3],[5,10,3],
      [2,11,0],[3,11,0],[5,11,0],[6,11,0],
    ],
    // A6 — Pixel Wizard: robe + staff suggestion
    [
      [4,0,3],[5,0,3],
      [3,1,1],[4,1,1],[5,1,1],[6,1,1],
      [2,2,0],[3,2,0],[4,2,0],[5,2,0],[6,2,0],
      [3,3,4],[5,3,4],
      [4,5,0],
      [2,6,1],[3,6,2],[4,6,2],[5,6,2],[6,6,1],
      [2,7,2],[3,7,2],[4,7,2],[5,7,2],[6,7,2],
      [1,6,3],[7,6,3],
      [1,7,2],[7,7,2],[0,6,3],[8,6,3],
      [3,8,2],[5,8,2],
      [3,9,1],[5,9,1],
      [3,10,1],[5,10,1],
      [3,11,2],[4,11,2],[5,11,2],
    ],
    // A7 — Cyber: visor + tech suit
    [
      [3,0,2],[4,0,2],[5,0,2],[6,0,2],
      [2,1,2],[3,1,0],[4,1,0],[5,1,0],[6,1,0],[7,1,2],
      [2,2,0],[3,2,0],[4,2,0],[5,2,0],[6,2,0],
      [3,3,3],[4,3,3],[5,3,3], // visor
      [4,5,0],
      [2,6,2],[3,6,2],[4,6,2],[5,6,2],[6,6,2],
      [2,7,2],[3,7,2],[4,7,2],[5,7,2],[6,7,2],
      [1,6,3],[7,6,3],
      [1,7,3],[7,7,3],
      [3,8,3],[5,8,3],
      [3,9,2],[5,9,2],
      [3,10,2],[5,10,2],
      [2,11,3],[3,11,3],[5,11,3],[6,11,3],
    ],
    // A8 — Gold VIP: crown + cape
    [
      [3,0,3],[4,0,3],[5,0,3],
      [3,1,3],[4,1,0],[5,1,0],[5,1,3],
      [2,2,0],[3,2,0],[4,2,0],[5,2,0],[6,2,0],
      [3,3,4],[5,3,4],
      [4,4,3],
      [4,5,0],
      [2,6,3],[3,6,2],[4,6,2],[5,6,2],[6,6,3],
      [1,7,3],[2,7,3],[3,7,2],[4,7,2],[5,7,2],[6,7,3],[7,7,3],
      [1,6,3],[7,6,3],
      [3,8,2],[5,8,2],
      [3,9,3],[5,9,3],
      [3,10,3],[5,10,3],
      [3,11,0],[4,11,0],[5,11,0],
    ],
  ];

  // Per-avatar color palettes: [skin, hair, body, accent, detail]
  static const List<List<Color>> _palettes = [
    [Color(0xFFf5c5a3), Color(0xFF3d2b1f), Color(0xFF1a3a5c), Color(0xFF4fc3f7), Color(0xFF1a1a2e)], // A1
    [Color(0xFFf5c5a3), Color(0xFF7b3f00), Color(0xFF2d6a4f), Color(0xFF52b788), Color(0xFF1a1a2e)], // A2
    [Color(0xFFf5c5a3), Color(0xFF2c2c54), Color(0xFF1e3050), Color(0xFFf5c518), Color(0xFF1a1a2e)], // A3
    [Color(0xFFd4a090), Color(0xFF1a1a2e), Color(0xFF2d2d44), Color(0xFF7b2fff), Color(0xFF00f5a0)], // A4
    [Color(0xFFfde4c8), Color(0xFFc77dff), Color(0xFFe63946), Color(0xFFff9f1c), Color(0xFF1a1a2e)], // A5
    [Color(0xFFf0d4b0), Color(0xFF4a0e8f), Color(0xFF6a0dad), Color(0xFF00f5a0), Color(0xFFffd700)], // A6
    [Color(0xFFc8e6f0), Color(0xFF0a1628), Color(0xFF162040), Color(0xFF00f5a0), Color(0xFF4fc3f7)], // A7
    [Color(0xFFfde4c8), Color(0xFFf5c518), Color(0xFF8b0000), Color(0xFFf5c518), Color(0xFF1a1a2e)], // A8
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (avatarIndex >= _avatars.length) return;

    final pixels = _avatars[avatarIndex];
    final palette = _palettes[avatarIndex];

    // Grid is 9 cols × 12 rows
    final cellW = size.width / 9;
    final cellH = size.height / 12;

    for (final pixel in pixels) {
      final col = pixel[0];
      final row = pixel[1];
      final colorIdx = pixel[2];

      // Use primaryColor tint for non-skin pixels when selected
      final baseColor = colorIdx < palette.length ? palette[colorIdx] : palette[0];
      final paint = Paint()
        ..color = colorIdx == 0
            ? baseColor // skin always original
            : Color.lerp(baseColor, primaryColor, 0.15)!;

      final rect = Rect.fromLTWH(
        col * cellW,
        row * cellH,
        cellW - 0.5,
        cellH - 0.5,
      );
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_PixelAvatarPainter old) =>
      old.avatarIndex != avatarIndex || old.primaryColor != primaryColor;
}

// ── Step 2: Market Focus ─────────────────────────────────────────────────────

class _MarketFocusStep extends StatelessWidget {
  const _MarketFocusStep();

  static const _options = [
    _MarketOption(id: 'crypto', label: 'Crypto', icon: Icons.currency_bitcoin),
    _MarketOption(
        id: 'fx', label: 'Forex', icon: Icons.currency_exchange),
    _MarketOption(id: 'stocks', label: 'Stocks', icon: Icons.trending_up),
    _MarketOption(id: 'mixed', label: 'Mixed', icon: Icons.pie_chart),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Market Focus',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your agents will prioritize this market.',
            style: TextStyle(color: colors.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 32),
          BlocBuilder<OnboardingBloc, OnboardingState>(
            builder: (context, state) {
              final selected =
                  state is OnboardingInProgress ? state.marketFocus : null;

              return Column(
                children: _options.map((option) {
                  final isSelected = selected == option.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SelectionCard(
                      label: option.label,
                      icon: option.icon,
                      isSelected: isSelected,
                      selectedColor: colors.primary,
                      onTap: () => context
                          .read<OnboardingBloc>()
                          .add(OnboardingMarketFocusSelected(option.id)),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MarketOption {
  const _MarketOption({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

// ── Step 3: Risk Style ───────────────────────────────────────────────────────

class _RiskStyleStep extends StatelessWidget {
  const _RiskStyleStep();

  static const _options = [
    _RiskOption(
      id: 'calm',
      emoji: '🐢',
      label: 'Calm',
      description: 'Low risk, steady gains. Capital preservation first.',
    ),
    _RiskOption(
      id: 'balanced',
      emoji: '⚖️',
      label: 'Balanced',
      description: 'Moderate risk. A mix of growth and stability.',
    ),
    _RiskOption(
      id: 'bold',
      emoji: '🚀',
      label: 'Bold',
      description: 'High risk, high reward. You live for the thrill.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Risk Style',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How does your inner trader roll?',
            style: TextStyle(color: colors.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 32),
          BlocBuilder<OnboardingBloc, OnboardingState>(
            builder: (context, state) {
              final selected =
                  state is OnboardingInProgress ? state.riskStyle : null;

              return Column(
                children: _options.map((option) {
                  final isSelected = selected == option.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RiskCard(
                      option: option,
                      isSelected: isSelected,
                      colors: colors,
                      onTap: () => context
                          .read<OnboardingBloc>()
                          .add(OnboardingRiskStyleSelected(option.id)),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RiskOption {
  const _RiskOption({
    required this.id,
    required this.emoji,
    required this.label,
    required this.description,
  });

  final String id;
  final String emoji;
  final String label;
  final String description;
}

class _RiskCard extends StatelessWidget {
  const _RiskCard({
    required this.option,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  final _RiskOption option;
  final bool isSelected;
  final AppColorScheme colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.08)
              : colors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(option.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: TextStyle(
                      color: isSelected ? colors.primary : colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    option.description,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: colors.primary, size: 22),
          ],
        ),
      ),
    );
  }
}

// ── Shared Selection Card (Market Focus) ────────────────────────────────────

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor.withValues(alpha: 0.08)
              : colors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? selectedColor : colors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? selectedColor : colors.textSecondary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? selectedColor : colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: selectedColor, size: 22),
          ],
        ),
      ),
    );
  }
}
