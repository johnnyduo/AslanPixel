import 'package:flutter/material.dart';
import 'package:aslan_pixel/shared/widgets/chart/animated_sparkline.dart';

// ---------------------------------------------------------------------------
// Color constants
// ---------------------------------------------------------------------------

const Color _navy = Color(0xFF0A1628);
const Color _surface = Color(0xFF0F2040);
const Color _neonGreen = Color(0xFF00F5A0);
const Color _gold = Color(0xFFf5c518);
const Color _textWhite = Color(0xFFE8F4F8);
const Color _grey = Color(0xFF7A9BB5);
const Color _border = Color(0xFF1e3050);

// ---------------------------------------------------------------------------
// Mock data helpers — 90-day history
// ---------------------------------------------------------------------------

// 90-day mock portfolio values — starts ~100k THB, ends ~128k (realistic)
const List<double> _portfolio90 = [
  100000, 101200, 99800, 102500, 104300, 103100, 105800, 107200, 106400, 108900,
  110100, 108700, 111500, 113200, 111800, 114600, 116300, 115000, 117800, 119400,
  117900, 120600, 122100, 120800, 123400, 125000, 123700, 126200, 127800, 126300,
  128900, 130400, 129000, 131600, 133100, 131700, 134200, 135800, 134300, 136900,
  138400, 137000, 139500, 141000, 139600, 142100, 143600, 142200, 144700, 146200,
  144800, 147300, 148800, 147400, 149900, 151400, 150000, 152500, 154000, 152600,
  155100, 156600, 155200, 157700, 159200, 157800, 160300, 161800, 160400, 162900,
  164400, 163000, 165500, 167000, 165600, 168100, 169600, 168200, 170700, 172200,
  170800, 173300, 174800, 173400, 175900, 177400, 176000, 178500, 180000, 178700,
];

// 90-day mock SET index values — starts ~1400, ends ~1428 (modest gain)
const List<double> _set90 = [
  1400, 1402, 1398, 1405, 1410, 1407, 1413, 1416, 1412, 1419,
  1423, 1419, 1425, 1428, 1424, 1430, 1433, 1429, 1435, 1438,
  1434, 1440, 1443, 1439, 1445, 1448, 1444, 1450, 1453, 1449,
  1455, 1458, 1454, 1460, 1463, 1459, 1465, 1468, 1464, 1470,
  1473, 1469, 1475, 1478, 1474, 1480, 1483, 1479, 1485, 1488,
  1484, 1490, 1493, 1489, 1495, 1498, 1494, 1500, 1503, 1499,
  1505, 1508, 1504, 1510, 1513, 1509, 1515, 1518, 1514, 1520,
  1523, 1519, 1525, 1528, 1524, 1530, 1433, 1429, 1435, 1428,
  1430, 1433, 1429, 1435, 1428, 1430, 1433, 1429, 1435, 1428,
];

// ---------------------------------------------------------------------------
// Period enum
// ---------------------------------------------------------------------------

enum _ChartPeriod {
  oneWeek,
  oneMonth,
  threeMonths;

  String get label {
    switch (this) {
      case _ChartPeriod.oneWeek:
        return '1W';
      case _ChartPeriod.oneMonth:
        return '1M';
      case _ChartPeriod.threeMonths:
        return '3M';
    }
  }

  int get days {
    switch (this) {
      case _ChartPeriod.oneWeek:
        return 7;
      case _ChartPeriod.oneMonth:
        return 30;
      case _ChartPeriod.threeMonths:
        return 90;
    }
  }
}

// ---------------------------------------------------------------------------
// PortfolioChartCard
// ---------------------------------------------------------------------------

/// Displays a two-line portfolio vs. SET benchmark chart with period selector.
///
/// Portfolio line is neon green; SET benchmark is gold.
/// Animates on period switch via [AnimatedSparkline].
class PortfolioChartCard extends StatefulWidget {
  const PortfolioChartCard({super.key});

  @override
  State<PortfolioChartCard> createState() => _PortfolioChartCardState();
}

class _PortfolioChartCardState extends State<PortfolioChartCard> {
  _ChartPeriod _period = _ChartPeriod.oneMonth;

  List<double> get _portfolioSlice {
    final src = _portfolio90;
    return src.length >= _period.days
        ? src.sublist(src.length - _period.days)
        : src;
  }

  List<double> get _setSlice {
    final src = _set90;
    return src.length >= _period.days
        ? src.sublist(src.length - _period.days)
        : src;
  }

  double get _portfolioGainPct {
    if (_portfolioSlice.length < 2) return 0;
    final first = _portfolioSlice.first;
    final last = _portfolioSlice.last;
    if (first == 0) return 0;
    return (last - first) / first * 100;
  }

  double get _setGainPct {
    if (_setSlice.length < 2) return 0;
    final first = _setSlice.first;
    final last = _setSlice.last;
    if (first == 0) return 0;
    return (last - first) / first * 100;
  }

  @override
  Widget build(BuildContext context) {
    final pGain = _portfolioGainPct;
    final sGain = _setGainPct;
    final pIsUp = pGain >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'พอร์ตโฟลิโอ',
                style: TextStyle(
                  color: _textWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              // Period tabs
              ..._ChartPeriod.values.map(
                (p) => _PeriodTab(
                  label: p.label,
                  selected: _period == p,
                  onTap: () => setState(() => _period = p),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Gain/loss headline
          Row(
            children: [
              Icon(
                pIsUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                color: pIsUp ? _neonGreen : const Color(0xFFFF4757),
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                '${pIsUp ? '+' : ''}${pGain.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: pIsUp ? _neonGreen : const Color(0xFFFF4757),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'ช่วง ${_period.label}',
                style: const TextStyle(color: _grey, fontSize: 12),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Chart area — two overlaid sparklines
          SizedBox(
            height: 90,
            child: Stack(
              children: [
                // SET benchmark (gold, behind)
                Positioned.fill(
                  child: AnimatedSparkline(
                    key: ValueKey('set_${_period.name}'),
                    values: _normalise(_setSlice),
                    lineColor: _gold.withValues(alpha: 0.6),
                    fillColor: _navy,
                    height: 90,
                    strokeWidth: 1.2,
                  ),
                ),
                // Portfolio (neon green, in front)
                Positioned.fill(
                  child: AnimatedSparkline(
                    key: ValueKey('portfolio_${_period.name}'),
                    values: _normalise(_portfolioSlice),
                    lineColor: _neonGreen,
                    height: 90,
                    strokeWidth: 2.0,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Legend
          Row(
            children: [
              _LegendDot(color: _neonGreen),
              const SizedBox(width: 4),
              const Text(
                'พอร์ตของฉัน',
                style: TextStyle(color: _grey, fontSize: 11),
              ),
              const SizedBox(width: 16),
              _LegendDot(color: _gold.withValues(alpha: 0.7)),
              const SizedBox(width: 4),
              Text(
                'SET  ${sGain >= 0 ? '+' : ''}${sGain.toStringAsFixed(2)}%',
                style: const TextStyle(color: _grey, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Normalise a series to [0..100] so both lines share the same Y axis scale.
  List<double> _normalise(List<double> src) {
    if (src.isEmpty) return src;
    final min = src.reduce((a, b) => a < b ? a : b);
    final max = src.reduce((a, b) => a > b ? a : b);
    final range = max - min;
    if (range < 1e-9) return src.map((_) => 50.0).toList();
    return src.map((v) => (v - min) / range * 100).toList();
  }
}

// ---------------------------------------------------------------------------
// _PeriodTab
// ---------------------------------------------------------------------------

class _PeriodTab extends StatelessWidget {
  const _PeriodTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? _neonGreen.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _neonGreen : _border,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? _neonGreen : _grey,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _LegendDot
// ---------------------------------------------------------------------------

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
