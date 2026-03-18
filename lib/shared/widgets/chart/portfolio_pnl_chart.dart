import 'package:flutter/material.dart';

import 'package:aslan_pixel/shared/widgets/chart/animated_sparkline.dart';

/// Displays portfolio P&L as a large number + sparkline with period selector.
///
/// Shows a 7-day / 30-day / all-time chip selector.
/// If [pnlHistory] is empty, falls back to a mock upward-trend dataset.
class PortfolioPnlChart extends StatefulWidget {
  const PortfolioPnlChart({
    super.key,
    required this.pnlHistory,
    required this.totalPnl,
  });

  final List<double> pnlHistory;
  final double totalPnl;

  @override
  State<PortfolioPnlChart> createState() => _PortfolioPnlChartState();
}

class _PortfolioPnlChartState extends State<PortfolioPnlChart> {
  _Period _selected = _Period.week;

  static const _neonGreen = Color(0xFF00f5a0);
  static const _loss = Color(0xFFff4d4f);

  List<double> get _mockData {
    // 30-point gentle upward trend with noise
    const base = [
      100.0, 102.0, 98.0, 103.0, 107.0, 105.0, 110.0, 108.0, 113.0, 115.0,
      112.0, 118.0, 120.0, 116.0, 122.0, 125.0, 121.0, 128.0, 130.0, 127.0,
      133.0, 136.0, 132.0, 138.0, 141.0, 139.0, 145.0, 148.0, 144.0, 150.0,
    ];
    return base;
  }

  List<double> get _displayValues {
    final src = widget.pnlHistory.isEmpty ? _mockData : widget.pnlHistory;
    switch (_selected) {
      case _Period.week:
        return src.length > 7 ? src.sublist(src.length - 7) : src;
      case _Period.month:
        return src.length > 30 ? src.sublist(src.length - 30) : src;
      case _Period.all:
        return src;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProfit = widget.totalPnl >= 0;
    final pnlColor = isProfit ? _neonGreen : _loss;
    final sign = isProfit ? '+' : '';
    final pnlText = '$sign${widget.totalPnl.toStringAsFixed(2)}';

    return SizedBox(
      height: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── P&L value ──────────────────────────────────────────────────────
          Row(
            children: [
              Icon(
                isProfit
                    ? Icons.arrow_drop_up_rounded
                    : Icons.arrow_drop_down_rounded,
                color: pnlColor,
                size: 28,
              ),
              Text(
                pnlText,
                style: TextStyle(
                  color: pnlColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          // ── Sparkline ──────────────────────────────────────────────────────
          Expanded(
            child: AnimatedSparkline(
              values: _displayValues,
              lineColor: pnlColor,
              strokeWidth: 1.8,
            ),
          ),
          // ── Period selector ────────────────────────────────────────────────
          Row(
            children: _Period.values.map((p) => _PeriodChip(
              label: p.label,
              selected: _selected == p,
              onTap: () => setState(() => _selected = p),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

enum _Period {
  week,
  month,
  all;

  String get label {
    switch (this) {
      case _Period.week:
        return '7 วัน';
      case _Period.month:
        return '30 วัน';
      case _Period.all:
        return 'ทั้งหมด';
    }
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _neonGreen = Color(0xFF00f5a0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _neonGreen : const Color(0xFF1e3050),
            width: selected ? 1.5 : 1.0,
          ),
          color: selected
              ? _neonGreen.withValues(alpha: 0.12)
              : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? _neonGreen : const Color(0xFF6b8aab),
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
