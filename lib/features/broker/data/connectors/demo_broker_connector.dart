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

    return PortfolioSnapshotModel(
      totalValue: 125_430.50,
      dailyPnl: 2_150.00,
      dailyPnlPercent: 1.74,
      positions: const [
        PositionModel(
          symbol: 'BTC/USD',
          qty: 0.5,
          avgCost: 40_000.0,
          currentPrice: 42_000.0,
          unrealizedPnl: 1_000.0,
        ),
        PositionModel(
          symbol: 'ETH/USD',
          qty: 2.0,
          avgCost: 2_200.0,
          currentPrice: 2_350.0,
          unrealizedPnl: 300.0,
        ),
        PositionModel(
          symbol: 'SET50',
          qty: 100.0,
          avgCost: 850.0,
          currentPrice: 862.0,
          unrealizedPnl: 1_200.0,
        ),
      ],
      snapshotAt: DateTime.now(),
    );
  }
}
