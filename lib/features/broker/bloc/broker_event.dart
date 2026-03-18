import 'package:equatable/equatable.dart';

abstract class BrokerEvent extends Equatable {
  const BrokerEvent();

  @override
  List<Object?> get props => [];
}

/// Request connection to a broker using the given [connectorId] and [credentials].
class BrokerConnectRequested extends BrokerEvent {
  const BrokerConnectRequested({
    required this.connectorId,
    required this.credentials,
  });

  final String connectorId;
  final Map<String, String> credentials;

  @override
  List<Object?> get props => [connectorId, credentials];
}

/// Re-fetch the portfolio from the currently active connector.
class BrokerPortfolioRefreshed extends BrokerEvent {
  const BrokerPortfolioRefreshed();
}

/// Disconnect from the active broker.
class BrokerDisconnectRequested extends BrokerEvent {
  const BrokerDisconnectRequested();
}
