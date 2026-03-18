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
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
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
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isSelected ? colors.accent : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundColor: isSelected
                              ? colors.accent.withValues(alpha: 0.2)
                              : colors.surface,
                          child: Text(
                            id,
                            style: TextStyle(
                              color: isSelected
                                  ? colors.accent
                                  : colors.textSecondary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
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
