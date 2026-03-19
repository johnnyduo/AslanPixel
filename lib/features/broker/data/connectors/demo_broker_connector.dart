import 'package:aslan_pixel/features/broker/data/connectors/broker_connector.dart';
import 'package:aslan_pixel/features/broker/data/models/portfolio_snapshot_model.dart';

class DemoBrokerConnector implements BrokerConnector {
  bool _connected = false;

  @override
  String get connectorId => 'demo';

  @override
  String get displayName => 'Demo Account';

  @override
  bool get isConnected => _connected;

  @override
  Future<bool> connect(Map<String, String> credentials) async {
    _connected = true;
    return true;
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
  }

  @override
  Future<PortfolioSnapshotModel> getPortfolio() async {
    if (!_connected) {
      throw StateError('DemoBrokerConnector is not connected.');
    }

    // Demo portfolio representing a Thai retail investor's diversified
    // portfolio across SET blue-chips and US tech stocks.
    // Total ≈ ฿500,000 at a simulated exchange rate.
    return PortfolioSnapshotModel(
      totalValue: 500_240.75,
      dailyPnl: 4_820.50,
      dailyPnlPercent: 0.97,
      positions: const [
        // Thai SET stocks
        PositionModel(
          symbol: 'PTT',
          qty: 2000.0,
          avgCost: 34.50,
          currentPrice: 36.25,
          unrealizedPnl: 3_500.0,
        ),
        PositionModel(
          symbol: 'KBANK',
          qty: 500.0,
          avgCost: 140.00,
          currentPrice: 145.50,
          unrealizedPnl: 2_750.0,
        ),
        PositionModel(
          symbol: 'SCB',
          qty: 800.0,
          avgCost: 95.00,
          currentPrice: 97.75,
          unrealizedPnl: 2_200.0,
        ),
        PositionModel(
          symbol: 'AOT',
          qty: 1000.0,
          avgCost: 62.00,
          currentPrice: 60.50,
          unrealizedPnl: -1_500.0,
        ),
        PositionModel(
          symbol: 'CPALL',
          qty: 1500.0,
          avgCost: 55.00,
          currentPrice: 57.25,
          unrealizedPnl: 3_375.0,
        ),
        // US tech stocks (USD × ~36 THB conversion in display)
        PositionModel(
          symbol: 'AAPL',
          qty: 10.0,
          avgCost: 7_200.0,
          currentPrice: 8_067.0,
          unrealizedPnl: 8_670.0,
        ),
        PositionModel(
          symbol: 'NVDA',
          qty: 5.0,
          avgCost: 28_000.0,
          currentPrice: 31_698.0,
          unrealizedPnl: 18_490.0,
        ),
        PositionModel(
          symbol: 'TSLA',
          qty: 8.0,
          avgCost: 6_800.0,
          currentPrice: 6_202.0,
          unrealizedPnl: -4_784.0,
        ),
        // Crypto (THB pairs)
        PositionModel(
          symbol: 'BTC/THB',
          qty: 0.25,
          avgCost: 1_440_000.0,
          currentPrice: 1_519_200.0,
          unrealizedPnl: 19_800.0,
        ),
        PositionModel(
          symbol: 'ETH/THB',
          qty: 1.5,
          avgCost: 108_000.0,
          currentPrice: 115_560.0,
          unrealizedPnl: 11_340.0,
        ),
      ],
      snapshotAt: DateTime.now(),
    );
  }
}
