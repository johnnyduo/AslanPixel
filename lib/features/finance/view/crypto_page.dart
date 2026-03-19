import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aslan_pixel/data/services/binance_ticker.dart';
import 'package:aslan_pixel/features/finance/bloc/crypto_bloc.dart';
import 'package:aslan_pixel/shared/widgets/sparkline_chart.dart';

// ---------------------------------------------------------------------------
// Color constants (dark theme)
// ---------------------------------------------------------------------------

const Color _navy = Color(0xFF0A1628);
const Color _surface = Color(0xFF0F2040);
const Color _surfaceElevated = Color(0xFF162040);
const Color _neonGreen = Color(0xFF00F5A0);
const Color _textWhite = Color(0xFFE8F4F8);
const Color _textMuted = Color(0xFF6B8AAB);
const Color _loss = Color(0xFFFF4D4F);
const Color _border = Color(0xFF1E3050);

// ---------------------------------------------------------------------------
// CryptoPage
// ---------------------------------------------------------------------------

class CryptoPage extends StatelessWidget {
  const CryptoPage({super.key});

  static const String routeName = '/crypto';

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CryptoBloc>(
      create: (_) => CryptoBloc()..add(const CryptoLoadRequested()),
      child: const _CryptoPageBody(),
    );
  }
}

class _CryptoPageBody extends StatelessWidget {
  const _CryptoPageBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _textWhite, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            const Icon(Icons.currency_bitcoin, color: _neonGreen, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Crypto Market',
              style: TextStyle(
                color: _textWhite,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const Spacer(),
            BlocBuilder<CryptoBloc, CryptoState>(
              builder: (ctx, state) {
                if (state is CryptoLoading) {
                  return const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: _neonGreen,
                      strokeWidth: 2,
                    ),
                  );
                }
                return const Icon(Icons.circle, color: _neonGreen, size: 8);
              },
            ),
          ],
        ),
        titleSpacing: 0,
      ),
      body: BlocBuilder<CryptoBloc, CryptoState>(
        builder: (ctx, state) {
          if (state is CryptoLoading || state is CryptoInitial) {
            return const Center(
              child: CircularProgressIndicator(color: _neonGreen),
            );
          }

          if (state is CryptoError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off,
                      color: _textWhite.withValues(alpha: 0.3), size: 48),
                  const SizedBox(height: 12),
                  Text(
                    state.message,
                    style: const TextStyle(color: _loss, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => ctx
                        .read<CryptoBloc>()
                        .add(const CryptoLoadRequested()),
                    icon: const Icon(Icons.refresh, color: _neonGreen),
                    label: const Text('Retry',
                        style: TextStyle(color: _neonGreen)),
                  ),
                ],
              ),
            );
          }

          if (state is CryptoLoaded) {
            return _CryptoLoadedView(state: state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _CryptoLoadedView
// ---------------------------------------------------------------------------

class _CryptoLoadedView extends StatelessWidget {
  const _CryptoLoadedView({required this.state});

  final CryptoLoaded state;

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(state.lastUpdated).inSeconds;
    final timeAgo = elapsed < 5
        ? '\u0e40\u0e21\u0e37\u0e48\u0e2d\u0e2a\u0e31\u0e01\u0e04\u0e23\u0e39\u0e48'
        : '$elapsed \u0e27\u0e34\u0e19\u0e32\u0e17\u0e35\u0e17\u0e35\u0e48\u0e41\u0e25\u0e49\u0e27';

    return RefreshIndicator(
      color: _neonGreen,
      backgroundColor: _surface,
      onRefresh: () async {
        context.read<CryptoBloc>().add(const CryptoRefreshRequested());
        // Give the BLoC a moment to emit new state
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: Column(
        children: [
          // Updated timestamp
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: _surface.withValues(alpha: 0.5),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: _textMuted, size: 14),
                const SizedBox(width: 6),
                Text(
                  '\u0e2d\u0e31\u0e1b\u0e40\u0e14\u0e15\u0e25\u0e48\u0e32\u0e2a\u0e38\u0e14: $timeAgo',
                  style: const TextStyle(color: _textMuted, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  'Binance',
                  style: TextStyle(
                    color: _neonGreen.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Kline sparkline detail (if selected)
          if (state.selectedKlines != null &&
              state.selectedKlines!.isNotEmpty &&
              state.selectedSymbol != null)
            _KlineDetailCard(
              symbol: state.selectedSymbol!,
              klines: state.selectedKlines!,
            ),

          // Ticker list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.tickers.length,
              separatorBuilder: (_, __) => Divider(
                color: _border.withValues(alpha: 0.5),
                height: 1,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (ctx, i) => _CryptoTickerRow(
                ticker: state.tickers[i],
                isSelected: state.selectedSymbol == state.tickers[i].symbol,
                onTap: () => ctx.read<CryptoBloc>().add(
                      CryptoKlineRequested(symbol: state.tickers[i].symbol),
                    ),
              ),
            ),
          ),

          // Disclaimer
          Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 4),
            child: Text(
              '\u0e02\u0e49\u0e2d\u0e21\u0e39\u0e25\u0e40\u0e1e\u0e37\u0e48\u0e2d\u0e01\u0e32\u0e23\u0e28\u0e36\u0e01\u0e29\u0e32\u0e40\u0e17\u0e48\u0e32\u0e19\u0e31\u0e49\u0e19 \u0e44\u0e21\u0e48\u0e43\u0e0a\u0e48\u0e04\u0e33\u0e41\u0e19\u0e30\u0e19\u0e33\u0e01\u0e32\u0e23\u0e25\u0e07\u0e17\u0e38\u0e19',
              style: TextStyle(
                color: _textWhite.withValues(alpha: 0.3),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _KlineDetailCard — sparkline chart for selected symbol
// ---------------------------------------------------------------------------

class _KlineDetailCard extends StatelessWidget {
  const _KlineDetailCard({required this.symbol, required this.klines});

  final String symbol;
  final List<double> klines;

  @override
  Widget build(BuildContext context) {
    final isUp =
        klines.length >= 2 ? klines.last >= klines.first : true;
    final changeColor = isUp ? _neonGreen : _loss;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: changeColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                symbol.replaceAll('USDT', '/USDT'),
                style: const TextStyle(
                  color: _textWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: changeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '24h',
                  style: TextStyle(color: changeColor, fontSize: 11),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: _textMuted, size: 18),
                onPressed: () {
                  // Deselect by refreshing without kline
                  context
                      .read<CryptoBloc>()
                      .add(const CryptoRefreshRequested());
                },
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: SparklineChart(
              values: klines,
              lineColor: changeColor,
              width: MediaQuery.of(context).size.width - 80,
              height: 80,
              strokeWidth: 2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Low: ${klines.reduce((a, b) => a < b ? a : b).toStringAsFixed(2)}',
                style: const TextStyle(color: _textMuted, fontSize: 11),
              ),
              Text(
                'High: ${klines.reduce((a, b) => a > b ? a : b).toStringAsFixed(2)}',
                style: const TextStyle(color: _textMuted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _CryptoTickerRow — single crypto ticker row
// ---------------------------------------------------------------------------

class _CryptoTickerRow extends StatelessWidget {
  const _CryptoTickerRow({
    required this.ticker,
    required this.isSelected,
    required this.onTap,
  });

  final BinanceTicker ticker;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final changeColor = ticker.isPositive ? _neonGreen : _loss;
    final changeSign = ticker.isPositive ? '+' : '';

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isSelected
            ? _surfaceElevated.withValues(alpha: 0.5)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Symbol + volume
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticker.displaySymbol,
                    style: const TextStyle(
                      color: _textWhite,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Vol ${ticker.formattedVolume}',
                    style: const TextStyle(color: _textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),

            // Price
            Expanded(
              flex: 3,
              child: Text(
                '\$${ticker.formattedPrice}',
                style: const TextStyle(
                  color: _textWhite,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                textAlign: TextAlign.right,
              ),
            ),

            const SizedBox(width: 12),

            // Change badge
            Container(
              width: 80,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: changeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$changeSign${ticker.priceChangePercent.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: changeColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
