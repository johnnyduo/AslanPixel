import 'package:equatable/equatable.dart';
import 'package:aslan_pixel/features/broker/data/models/portfolio_snapshot_model.dart';

abstract class BrokerState extends Equatable {
  const BrokerState();

  @override
  List<Object?> get props => [];
}

class BrokerInitial extends BrokerState {
  const BrokerInitial();
}

class BrokerConnecting extends BrokerState {
  const BrokerConnecting();
}

class BrokerConnected extends BrokerState {
  const BrokerConnected({
    required this.portfolio,
    required this.connectorId,
  });

  final PortfolioSnapshotModel portfolio;
  final String connectorId;

  @override
  List<Object?> get props => [portfolio, connectorId];
}

class BrokerRefreshing extends BrokerState {
  const BrokerRefreshing({required this.lastPortfolio});

  final PortfolioSnapshotModel lastPortfolio;

  @override
  List<Object?> get props => [lastPortfolio];
}

class BrokerDisconnected extends BrokerState {
  const BrokerDisconnected();
}

class BrokerError extends BrokerState {
  const BrokerError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
