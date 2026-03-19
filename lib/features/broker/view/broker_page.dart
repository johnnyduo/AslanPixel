import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aslan_pixel/features/broker/bloc/broker_bloc.dart';
import 'package:aslan_pixel/features/broker/bloc/broker_event.dart';
import 'package:aslan_pixel/features/broker/bloc/broker_state.dart';
import 'package:aslan_pixel/features/broker/data/models/portfolio_snapshot_model.dart';
import 'package:aslan_pixel/shared/widgets/sparkline_chart.dart';

// ---------------------------------------------------------------------------
// Color constants
// ---------------------------------------------------------------------------

const Color _navy = Color(0xFF0A1628);
const Color _surface = Color(0xFF0F2040);
const Color _neonGreen = Color(0xFF00F5A0);
const Color _gold = Color(0xFFF5C518);
const Color _textWhite = Color(0xFFE8F4F8);
const Color _red = Color(0xFFFF4757);

// ---------------------------------------------------------------------------
// BrokerPage
// ---------------------------------------------------------------------------

class BrokerPage extends StatefulWidget {
  const BrokerPage({super.key});

  static const String routeName = '/broker';

  @override
  State<BrokerPage> createState() => _BrokerPageState();
}

class _BrokerPageState extends State<BrokerPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<BrokerBloc>(
      create: (_) => BrokerBloc(),
      child: Scaffold(
        backgroundColor: _navy,
        appBar: AppBar(
          backgroundColor: _surface,
          elevation: 0,
          title: const Text(
            'Broker',
            style: TextStyle(
              color: _textWhite,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: BlocBuilder<BrokerBloc, BrokerState>(
          builder: (ctx, state) {
            if (state is BrokerInitial || state is BrokerDisconnected) {
              return _ConnectCard(
                onConnectDemo: () => ctx.read<BrokerBloc>().add(
                      const BrokerConnectRequested(
                        connectorId: 'demo',
                        credentials: {},
                      ),
                    ),
              );
            }

            if (state is BrokerConnecting) {
              return const Center(
                child: CircularProgressIndicator(color: _neonGreen),
              );
            }

            if (state is BrokerConnected) {
              return _PortfolioDashboard(
                portfolio: state.portfolio,
                isRefreshing: false,
                onRefresh: () =>
                    ctx.read<BrokerBloc>().add(const BrokerPortfolioRefreshed()),
                onDisconnect: () =>
                    ctx.read<BrokerBloc>().add(const BrokerDisconnectRequested()),
              );
            }

            if (state is BrokerRefreshing) {
              return _PortfolioDashboard(
                portfolio: state.lastPortfolio,
                isRefreshing: true,
                onRefresh: () {},
                onDisconnect: () {},
              );
            }

            if (state is BrokerError) {
              return _ErrorCard(
                message: state.message,
                onRetry: () => ctx.read<BrokerBloc>().add(
                      const BrokerConnectRequested(
                        connectorId: 'demo',
                        credentials: {},
                      ),
                    ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ConnectCard
// ---------------------------------------------------------------------------

class _ConnectCard extends StatelessWidget {
  const _ConnectCard({required this.onConnectDemo});

  final VoidCallback onConnectDemo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _neonGreen.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_balance_outlined, color: _neonGreen, size: 44),
              const SizedBox(height: 16),
              const Text(
                'เชื่อมต่อ Broker',
                style: TextStyle(
                  color: _textWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'เชื่อมต่อพอร์ตโฟลิโอของคุณเพื่อดูข้อมูลแบบ real-time',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textWhite.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),

              // Demo broker button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onConnectDemo,
                  icon: const Icon(Icons.play_circle_outline_rounded),
                  label: const Text('Demo Account'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _neonGreen,
                    foregroundColor: _navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Connect Real Broker — disabled (coming soon)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.link_rounded),
                  label: const Text('เชื่อมต่อ Broker จริง (เร็วๆ นี้)'),
                  style: OutlinedButton.styleFrom(
                    disabledForegroundColor: _textWhite.withValues(alpha: 0.35),
                    side: BorderSide(
                      color: _textWhite.withValues(alpha: 0.15),
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                'ข้อมูลเพื่อการศึกษา ไม่ใช่คำแนะนำทางการเงิน',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
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
// _PortfolioDashboard
// ---------------------------------------------------------------------------

class _PortfolioDashboard extends StatelessWidget {
  const _PortfolioDashboard({
    required this.portfolio,
    required this.isRefreshing,
    required this.onRefresh,
    required this.onDisconnect,
  });

  final PortfolioSnapshotModel portfolio;
  final bool isRefreshing;
  final VoidCallback onRefresh;
  final VoidCallback onDisconnect;

  Color get _pnlColor => portfolio.dailyPnl >= 0 ? _neonGreen : _red;
  String get _pnlSign => portfolio.dailyPnl >= 0 ? '+' : '';

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: _neonGreen,
      backgroundColor: _surface,
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Total value header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _neonGreen.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'มูลค่าพอร์ตรวม',
                  style: TextStyle(
                    color: _textWhite.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '\$${portfolio.totalValue.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: _textWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      portfolio.dailyPnl >= 0
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      color: _pnlColor,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_pnlSign\$${portfolio.dailyPnl.toStringAsFixed(2)} '
                      '($_pnlSign${portfolio.dailyPnlPercent.toStringAsFixed(2)}%)',
                      style: TextStyle(
                        color: _pnlColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    if (isRefreshing)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: _neonGreen,
                          strokeWidth: 2,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Portfolio sparkline chart — 30-day simulated performance
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _neonGreen.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ประสิทธิภาพ 30 วัน',
                  style: TextStyle(
                    color: _textWhite.withValues(alpha: 0.55),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (_, constraints) => SparklineChart(
                    values: const [
                      468000, 471500, 469200, 475800, 473000, 478400,
                      480100, 477600, 483200, 481900, 488700, 486500,
                      491300, 489800, 494500, 492100, 497600, 495400,
                      498900, 496200, 500100, 498700, 502400, 500800,
                      503600, 501200, 504900, 502300, 500241,
                    ],
                    width: constraints.maxWidth,
                    height: 56,
                    strokeWidth: 2,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Positions header
          Text(
            'สถานะการลงทุน',
            style: TextStyle(
              color: _textWhite.withValues(alpha: 0.75),
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),

          // Position tiles
          ...portfolio.positions.map(
            (pos) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _PositionTile(position: pos),
            ),
          ),

          const SizedBox(height: 24),

          // Disconnect button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onDisconnect,
              icon: const Icon(Icons.link_off_rounded, size: 18),
              label: const Text('ยกเลิกการเชื่อมต่อ'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _red,
                side: BorderSide(color: _red.withValues(alpha: 0.5), width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _PositionTile
// ---------------------------------------------------------------------------

class _PositionTile extends StatelessWidget {
  const _PositionTile({required this.position});

  final PositionModel position;

  Color get _pnlColor => position.unrealizedPnl >= 0 ? _neonGreen : _red;
  String get _pnlSign => position.unrealizedPnl >= 0 ? '+' : '';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _pnlColor.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Symbol + qty
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  position.symbol,
                  style: const TextStyle(
                    color: _textWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Qty ${position.qty} · Avg \$${position.avgCost.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: _textWhite.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Current price + unrealized PnL
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${position.currentPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: _textWhite,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$_pnlSign\$${position.unrealizedPnl.toStringAsFixed(2)}',
                style: TextStyle(
                  color: _pnlColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ErrorCard
// ---------------------------------------------------------------------------

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _red.withValues(alpha: 0.5), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: _red, size: 40),
              const SizedBox(height: 12),
              const Text(
                'เกิดข้อผิดพลาด',
                style: TextStyle(
                  color: _textWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textWhite.withValues(alpha: 0.65),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('ลองใหม่'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _red,
                  foregroundColor: _textWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
