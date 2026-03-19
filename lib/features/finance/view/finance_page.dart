import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aslan_pixel/data/services/cached_ai_service.dart';
import 'package:aslan_pixel/data/services/gemini_ai_service.dart';
import 'package:aslan_pixel/features/finance/bloc/ai_insight_bloc.dart';
import 'package:aslan_pixel/features/finance/bloc/ai_insight_event.dart';
import 'package:aslan_pixel/features/finance/bloc/ai_insight_state.dart';
import 'package:aslan_pixel/features/finance/bloc/prediction_bloc.dart';
import 'package:aslan_pixel/features/finance/bloc/prediction_event.dart';
import 'package:aslan_pixel/features/finance/bloc/prediction_state.dart';
import 'package:aslan_pixel/features/finance/data/datasources/firestore_ai_insight_datasource.dart';
import 'package:aslan_pixel/features/finance/data/datasources/firestore_prediction_datasource.dart';
import 'package:aslan_pixel/features/finance/view/market_insight_card.dart';
import 'package:aslan_pixel/features/finance/view/portfolio_chart_card.dart';
import 'package:aslan_pixel/features/finance/view/prediction_event_card.dart';
import 'package:aslan_pixel/features/home/view/market_ticker_tile.dart';

// ---------------------------------------------------------------------------
// Color constants
// ---------------------------------------------------------------------------

const Color _navy = Color(0xFF0A1628);
const Color _surface = Color(0xFF0F2040);
const Color _neonGreen = Color(0xFF00F5A0);
const Color _textWhite = Color(0xFFE8F4F8);

// ---------------------------------------------------------------------------
// FinancePage
// ---------------------------------------------------------------------------

class FinancePage extends StatelessWidget {
  const FinancePage({super.key});

  static const String routeName = '/finance';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _navy,
        appBar: AppBar(
          backgroundColor: _surface,
          elevation: 0,
          title: const Text(
            'Finance',
            style: TextStyle(
              color: _textWhite,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          bottom: const TabBar(
            indicatorColor: _neonGreen,
            indicatorWeight: 2.5,
            labelColor: _textWhite,
            unselectedLabelColor: Color(0xFF7A9BB5),
            labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
            tabs: [
              Tab(text: 'Predictions'),
              Tab(text: 'Market'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PredictionsTab(),
            _MarketTab(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _PredictionsTab
// ---------------------------------------------------------------------------

class _PredictionsTab extends StatelessWidget {
  const _PredictionsTab();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PredictionBloc>(
      create: (_) => PredictionBloc(
        repository: FirestorePredictionDatasource(),
      )..add(const PredictionWatchStarted()),
      child: BlocBuilder<PredictionBloc, PredictionState>(
        builder: (ctx, state) {
          if (state is PredictionLoading || state is PredictionInitial) {
            return const Center(
              child: CircularProgressIndicator(color: _neonGreen),
            );
          }

          if (state is PredictionError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'เกิดข้อผิดพลาด: ${state.message}',
                  style: const TextStyle(color: Color(0xFFFF4757)),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (state is PredictionLoaded && state.events.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_note_outlined,
                    color: _textWhite.withValues(alpha: 0.3),
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'ยังไม่มีกิจกรรมพยากรณ์ในขณะนี้',
                    style: TextStyle(
                      color: _textWhite.withValues(alpha: 0.5),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          final bloc = ctx.read<PredictionBloc>();
          final events =
              state is PredictionLoaded ? state.events : const [];

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: events.length,
            itemBuilder: (_, i) => PredictionEventCard(
              event: events[i],
              uid: FirebaseAuth.instance.currentUser?.uid ?? 'anonymous',
              bloc: bloc,
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _MarketTab
// ---------------------------------------------------------------------------

class _MarketTab extends StatelessWidget {
  const _MarketTab();

  // Thai-relevant symbols with realistic mock prices and ±2% variance seed
  static const _mockTickers = [
    _MockTicker(symbol: 'SET',     price: '1,412',      change:  0.43),
    _MockTicker(symbol: 'BTC/USD', price: '\$84,200',   change:  1.82),
    _MockTicker(symbol: 'ETH/USD', price: '\$3,210',    change: -0.54),
    _MockTicker(symbol: 'AAPL',    price: '\$224.15',   change:  0.91),
    _MockTicker(symbol: 'TSLA',    price: '\$172.30',   change: -1.47),
    _MockTicker(symbol: 'NVDA',    price: '\$880.50',   change:  2.08),
  ];

  static const String _insightSymbols = 'SET BTC ETH AAPL TSLA NVDA';

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return BlocProvider<AiInsightBloc>(
      create: (_) => AiInsightBloc(
        aiService: CachedAiService(GeminiAiService()),
        repository: FirestoreAiInsightDatasource(),
      )..add(
          AiInsightRequested(
            uid: uid,
            type: 'market_summary',
            context: _insightSymbols,
          ),
        ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Portfolio performance chart
          const PortfolioChartCard(),

          const SizedBox(height: 16),

          // AI Market Insight card
          BlocBuilder<AiInsightBloc, AiInsightState>(
            builder: (ctx, state) {
              final isLoading =
                  state is AiInsightLoading || state is AiInsightInitial;
              final insight =
                  state is AiInsightLoaded && state.insights.isNotEmpty
                      ? state.insights.first
                      : null;

              return MarketInsightCard(
                insight: insight,
                isLoading: isLoading,
                onRefresh: () => ctx.read<AiInsightBloc>().add(
                      AiInsightForceRefreshRequested(
                        uid: uid,
                        type: 'market_summary',
                        symbols: _insightSymbols,
                      ),
                    ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Section label
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'ตลาดโลก',
              style: TextStyle(
                color: _textWhite,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.3,
              ),
            ),
          ),

          // Market tickers — 6 Thai-relevant symbols
          ...List.generate(_mockTickers.length, (i) {
            final t = _mockTickers[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MarketTickerTile(
                symbol: t.symbol,
                price: t.price,
                changePercent: t.change,
              ),
            );
          }),

          // Disclaimer footer
          const SizedBox(height: 8),
          Text(
            'ข้อมูลเพื่อการศึกษาเท่านั้น ไม่ใช่คำแนะนำการลงทุน',
            style: TextStyle(
              color: _textWhite.withValues(alpha: 0.3),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _MockTicker — internal data holder
// ---------------------------------------------------------------------------

class _MockTicker {
  const _MockTicker({
    required this.symbol,
    required this.price,
    required this.change,
  });

  final String symbol;
  final String price;
  final double change;
}
