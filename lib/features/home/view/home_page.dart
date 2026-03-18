import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aslan_pixel/features/home/view/prediction_card.dart';
import 'package:aslan_pixel/features/home/view/market_ticker_tile.dart';
import 'package:aslan_pixel/features/inventory/bloc/economy_bloc.dart';
import 'package:aslan_pixel/shared/widgets/animated_coin_counter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aslan_pixel/shared/widgets/daily_streak_widget.dart';
import 'package:aslan_pixel/shared/widgets/streak_warning_banner.dart';
import 'package:aslan_pixel/shared/widgets/xp_progress_bar.dart';

// ---------------------------------------------------------------------------
// Color constants
// ---------------------------------------------------------------------------
const Color _navy = Color(0xFF0A1628);
const Color _surface = Color(0xFF0F2040);
const Color _neonGreen = Color(0xFF00F5A0);
const Color _gold = Color(0xFFF5C518);
const Color _cyberPurple = Color(0xFF7B2FFF);
const Color _textWhite = Color(0xFFE8F4F8);
const Color _cyberBlue = Color(0xFF00D9FF);
// ignore: unused_element — used by MarketTickerTile for loss color
const Color _red = Color(0xFFFF4757);

// ---------------------------------------------------------------------------
// HomePage
// ---------------------------------------------------------------------------

/// Home dashboard — live coin balance via EconomyBloc.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final EconomyBloc _economyBloc;

  @override
  void initState() {
    super.initState();
    _economyBloc = EconomyBloc();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      _economyBloc.add(EconomyWatchStarted(uid));
    }
  }

  @override
  void dispose() {
    _economyBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _economyBloc,
      child: Scaffold(
        backgroundColor: _navy,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverSafeArea(
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  const _WelcomeBanner(),
                  // ── Streak warning + streak widget (from SharedPreferences) ─
                  const _StreakSection(),
                  // ── XP progress bar ──────────────────────────────────────
                  BlocBuilder<EconomyBloc, EconomyState>(
                    builder: (context, econState) {
                      if (econState is! EconomyLoaded) {
                        return const SizedBox(height: 8);
                      }
                      return XpProgressBar(
                        level: econState.level,
                        currentXp: econState.xp % EconomyLoaded.xpForNextLevel,
                        maxXp: EconomyLoaded.xpForNextLevel,
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  const _AgentStatusRow(),
                  const SizedBox(height: 8),
                  const _PredictionSection(),
                  const SizedBox(height: 8),
                  const _MarketSummarySection(),
                  const SizedBox(height: 8),
                  const _RankingTeaser(),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _WelcomeBanner
// ---------------------------------------------------------------------------

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_navy, _surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _neonGreen.withValues(alpha: 0.2), width: 1),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Neon green accent line on left edge
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: _neonGreen,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'สวัสดี, Trader!',
                      style: TextStyle(
                        color: _textWhite,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ยินดีต้อนรับสู่ Aslan Pixel',
                      style: TextStyle(
                        color: _textWhite.withValues(alpha: 0.55),
                        fontSize: 13,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Live coin balance + level badge
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: BlocBuilder<EconomyBloc, EconomyState>(
                builder: (context, state) {
                  final coins = state is EconomyLoaded ? state.coins : 0;
                  final level = state is EconomyLoaded ? state.level : 1;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AnimatedCoinCounter(
                        toAmount: coins,
                        fontSize: 14,
                        showIcon: true,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _gold.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          'Lv $level',
                          style: const TextStyle(
                            color: _gold,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _AgentStatusRow
// ---------------------------------------------------------------------------

class _AgentStatusRow extends StatelessWidget {
  const _AgentStatusRow();

  static const _agents = [
    _AgentInfo(name: 'Analyst', color: _neonGreen),
    _AgentInfo(name: 'Scout', color: _gold),
    _AgentInfo(name: 'Risk', color: _cyberPurple),
    _AgentInfo(name: 'Social', color: _cyberBlue),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'เหล่า Agents',
            style: TextStyle(
              color: _textWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _agents
                .map(
                  (agent) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _AgentChip(agent: agent),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _AgentInfo {
  const _AgentInfo({required this.name, required this.color});
  final String name;
  final Color color;
}

class _AgentChip extends StatelessWidget {
  const _AgentChip({required this.agent});

  final _AgentInfo agent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: agent.color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: agent.color.withValues(alpha: 0.18),
              border: Border.all(color: agent.color, width: 1.5),
            ),
            child: Icon(
              Icons.smart_toy_outlined,
              color: agent.color,
              size: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            agent.name,
            style: const TextStyle(
              color: _textWhite,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            'ว่าง',
            style: TextStyle(
              color: _textWhite.withValues(alpha: 0.45),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _PredictionSection
// ---------------------------------------------------------------------------

class _PredictionSection extends StatelessWidget {
  const _PredictionSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + "ดูทั้งหมด" link
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Prediction Events',
                style: TextStyle(
                  color: _textWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'ดูทั้งหมด',
                  style: TextStyle(
                    color: _neonGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Card 1
          const PredictionCard(
            symbol: 'BTC/USD',
            questionTh: 'Bitcoin จะทะลุ \$100,000 ภายในสิ้นเดือนนี้หรือไม่?',
            coinCost: 50,
          ),
          const SizedBox(height: 10),
          // Card 2
          const PredictionCard(
            symbol: 'SET Index',
            questionTh: 'ดัชนี SET จะปิดบวกในสัปดาห์นี้หรือไม่?',
            coinCost: 20,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _MarketSummarySection
// ---------------------------------------------------------------------------

class _MarketSummarySection extends StatelessWidget {
  const _MarketSummarySection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Market Snapshot',
            style: TextStyle(
              color: _textWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          MarketTickerTile(
            symbol: 'BTC/USD',
            changePercent: 2.4,
            price: '\$67,240',
          ),
          SizedBox(height: 8),
          MarketTickerTile(
            symbol: 'ETH/USD',
            changePercent: -1.1,
            price: '\$3,480',
          ),
          SizedBox(height: 8),
          MarketTickerTile(
            symbol: 'SET',
            changePercent: 0.3,
            price: '1,342.5',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _RankingTeaser
// ---------------------------------------------------------------------------

class _RankingTeaser extends StatelessWidget {
  const _RankingTeaser();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'อันดับของคุณ',
            style: TextStyle(
              color: _textWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _gold.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Trophy icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _gold.withValues(alpha: 0.12),
                    border: Border.all(color: _gold.withValues(alpha: 0.35), width: 1.5),
                  ),
                  child: const Icon(
                    Icons.emoji_events_outlined,
                    color: _gold,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'อันดับ #--',
                        style: TextStyle(
                          color: _textWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'เริ่มทำ Quest เพื่อขึ้นอันดับ',
                        style: TextStyle(
                          color: _textWhite.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: _textWhite.withValues(alpha: 0.3),
                  size: 22,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _StreakSection
// ---------------------------------------------------------------------------

/// Reads the login streak from [SharedPreferences] and renders
/// [StreakWarningBanner] + [DailyStreakWidget].
///
/// Uses `login_streak_days` (int) and `last_login_date` (String YYYY-MM-DD).
class _StreakSection extends StatefulWidget {
  const _StreakSection();

  @override
  State<_StreakSection> createState() => _StreakSectionState();
}

class _StreakSectionState extends State<_StreakSection> {
  int _streakDays = 0;

  @override
  void initState() {
    super.initState();
    _loadStreak();
  }

  Future<void> _loadStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final days = prefs.getInt('login_streak_days') ?? 0;
    if (mounted) setState(() => _streakDays = days);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StreakWarningBanner(streakDays: _streakDays),
        DailyStreakWidget(streakDays: _streakDays),
      ],
    );
  }
}
