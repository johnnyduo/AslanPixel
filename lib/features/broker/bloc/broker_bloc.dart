import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aslan_pixel/core/utils/analytics_service.dart';
import 'package:aslan_pixel/features/broker/bloc/broker_event.dart';
import 'package:aslan_pixel/features/broker/bloc/broker_state.dart';
import 'package:aslan_pixel/features/broker/data/connectors/broker_connector.dart';
import 'package:aslan_pixel/features/broker/data/connectors/demo_broker_connector.dart';
import 'package:aslan_pixel/features/broker/data/models/portfolio_snapshot_model.dart';

class BrokerBloc extends Bloc<BrokerEvent, BrokerState> {
  BrokerBloc() : super(const BrokerInitial()) {
    on<BrokerConnectRequested>(_onConnectRequested);
    on<BrokerPortfolioRefreshed>(_onPortfolioRefreshed);
    on<BrokerDisconnectRequested>(_onDisconnectRequested);
  }

  final Map<String, BrokerConnector> _connectors = {
    'demo': DemoBrokerConnector(),
  };

  String? _activeConnectorId;

  BrokerConnector? get _active =>
      _activeConnectorId != null ? _connectors[_activeConnectorId] : null;

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  Future<void> _onConnectRequested(
    BrokerConnectRequested event,
    Emitter<BrokerState> emit,
  ) async {
    final connector = _connectors[event.connectorId];
    if (connector == null) {
      emit(BrokerError('Unknown connector: ${event.connectorId}'));
      return;
    }

    emit(const BrokerConnecting());
    try {
      final success = await connector.connect(event.credentials);
      if (!success) {
        emit(const BrokerError('การเชื่อมต่อล้มเหลว กรุณาตรวจสอบข้อมูลประจำตัว'));
        return;
      }
      _activeConnectorId = event.connectorId;
      final portfolio = await connector.getPortfolio();
      emit(BrokerConnected(
        portfolio: portfolio,
        connectorId: event.connectorId,
      ));
      unawaited(AnalyticsService.logBrokerConnected(connectorId: event.connectorId));
    } catch (e) {
      emit(BrokerError(e.toString()));
    }
  }

  Future<void> _onPortfolioRefreshed(
    BrokerPortfolioRefreshed event,
    Emitter<BrokerState> emit,
  ) async {
    final connector = _active;
    if (connector == null || !connector.isConnected) {
      emit(const BrokerError('ไม่ได้เชื่อมต่อ Broker'));
      return;
    }

    // Keep the last portfolio visible during refresh
    PortfolioSnapshotModel? lastPortfolio;
    final current = state;
    if (current is BrokerConnected) lastPortfolio = current.portfolio;
    if (current is BrokerRefreshing) lastPortfolio = current.lastPortfolio;

    if (lastPortfolio != null) {
      emit(BrokerRefreshing(lastPortfolio: lastPortfolio));
    }

    try {
      final portfolio = await connector.getPortfolio();
      emit(BrokerConnected(
        portfolio: portfolio,
        connectorId: _activeConnectorId!,
      ));
    } catch (e) {
      emit(BrokerError(e.toString()));
    }
  }

  Future<void> _onDisconnectRequested(
    BrokerDisconnectRequested event,
    Emitter<BrokerState> emit,
  ) async {
    final connector = _active;
    if (connector != null) {
      await connector.disconnect();
    }
    _activeConnectorId = null;
    emit(const BrokerDisconnected());
  }
}
