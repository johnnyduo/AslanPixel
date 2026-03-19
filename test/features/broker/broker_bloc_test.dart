import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aslan_pixel/features/broker/bloc/broker_bloc.dart';
import 'package:aslan_pixel/features/broker/bloc/broker_event.dart';
import 'package:aslan_pixel/features/broker/bloc/broker_state.dart';

void main() {
  BrokerBloc build() => BrokerBloc();

  // ── Initial state ─────────────────────────────────────────────────────────

  group('BrokerBloc initial state', () {
    test('starts as BrokerInitial', () {
      expect(build().state, isA<BrokerInitial>());
    });
  });

  // ── BrokerConnectRequested — demo connector ───────────────────────────────

  group('BrokerConnectRequested with demo connector', () {
    blocTest<BrokerBloc, BrokerState>(
      'emits [BrokerConnecting, BrokerConnected] on successful demo connect',
      build: build,
      act: (bloc) => bloc.add(const BrokerConnectRequested(
        connectorId: 'demo',
        credentials: {},
      )),
      expect: () => [
        isA<BrokerConnecting>(),
        isA<BrokerConnected>()
            .having((s) => s.connectorId, 'connectorId', 'demo'),
      ],
    );

    blocTest<BrokerBloc, BrokerState>(
      'BrokerConnected includes a non-empty portfolio',
      build: build,
      act: (bloc) => bloc.add(const BrokerConnectRequested(
        connectorId: 'demo',
        credentials: {},
      )),
      expect: () => [
        isA<BrokerConnecting>(),
        isA<BrokerConnected>().having(
          (s) => s.portfolio.positions.isNotEmpty,
          'has positions',
          isTrue,
        ),
      ],
    );

    blocTest<BrokerBloc, BrokerState>(
      'emits BrokerError for unknown connectorId',
      build: build,
      act: (bloc) => bloc.add(const BrokerConnectRequested(
        connectorId: 'unknown_broker',
        credentials: {},
      )),
      expect: () => [isA<BrokerError>()],
    );
  });

  // ── BrokerPortfolioRefreshed ──────────────────────────────────────────────

  group('BrokerPortfolioRefreshed', () {
    blocTest<BrokerBloc, BrokerState>(
      'emits BrokerError when called before connecting',
      build: build,
      act: (bloc) => bloc.add(const BrokerPortfolioRefreshed()),
      expect: () => [isA<BrokerError>()],
    );

    blocTest<BrokerBloc, BrokerState>(
      'emits [BrokerRefreshing, BrokerConnected] after a successful connect',
      build: build,
      act: (bloc) async {
        bloc.add(const BrokerConnectRequested(
          connectorId: 'demo',
          credentials: {},
        ));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const BrokerPortfolioRefreshed());
      },
      expect: () => [
        isA<BrokerConnecting>(),
        isA<BrokerConnected>(),
        isA<BrokerRefreshing>(),
        isA<BrokerConnected>(),
      ],
    );
  });

  // ── BrokerDisconnectRequested ─────────────────────────────────────────────

  group('BrokerDisconnectRequested', () {
    blocTest<BrokerBloc, BrokerState>(
      'emits BrokerDisconnected after being connected',
      build: build,
      act: (bloc) async {
        bloc.add(const BrokerConnectRequested(
          connectorId: 'demo',
          credentials: {},
        ));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const BrokerDisconnectRequested());
      },
      expect: () => [
        isA<BrokerConnecting>(),
        isA<BrokerConnected>(),
        isA<BrokerDisconnected>(),
      ],
    );

    blocTest<BrokerBloc, BrokerState>(
      'emits BrokerDisconnected even when called without connecting',
      build: build,
      act: (bloc) => bloc.add(const BrokerDisconnectRequested()),
      expect: () => [isA<BrokerDisconnected>()],
    );

    blocTest<BrokerBloc, BrokerState>(
      'portfolio refresh emits BrokerError after disconnect',
      build: build,
      act: (bloc) async {
        bloc.add(const BrokerConnectRequested(
          connectorId: 'demo',
          credentials: {},
        ));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const BrokerDisconnectRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const BrokerPortfolioRefreshed());
      },
      expect: () => [
        isA<BrokerConnecting>(),
        isA<BrokerConnected>(),
        isA<BrokerDisconnected>(),
        isA<BrokerError>(),
      ],
    );
  });
}
