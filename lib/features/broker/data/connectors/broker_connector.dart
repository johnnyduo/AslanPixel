import 'package:aslan_pixel/features/broker/data/models/portfolio_snapshot_model.dart';

/// Abstract interface for a broker data connector.
///
/// Each concrete implementation provides live or mock portfolio data from a
/// specific broker / exchange API.
abstract class BrokerConnector {
  /// Unique identifier for this connector (e.g. 'demo', 'bitkub', 'set').
  String get connectorId;

  /// Human-readable display name shown in the UI.
  String get displayName;

  /// Returns [true] when the connector holds an active session / API key.
  bool get isConnected;

  /// Establish a connection using the provided [credentials] map.
  ///
  /// Returns [true] on success. Implementations should persist the credentials
  /// securely and update [isConnected].
  Future<bool> connect(Map<String, String> credentials);

  /// Terminate the active connection and clear cached credentials.
  Future<void> disconnect();

  /// Fetch the latest portfolio snapshot.
  ///
  /// Throws if the connector is not connected.
  Future<PortfolioSnapshotModel> getPortfolio();
}
