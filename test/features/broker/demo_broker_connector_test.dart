import 'package:aslan_pixel/features/broker/data/connectors/demo_broker_connector.dart';
import 'package:aslan_pixel/features/broker/data/models/portfolio_snapshot_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DemoBrokerConnector', () {
    late DemoBrokerConnector connector;

    setUp(() {
      connector = DemoBrokerConnector();
    });

    test('connectorId is "demo"', () {
      expect(connector.connectorId, 'demo');
    });

    test('displayName is "Demo Account"', () {
      expect(connector.displayName, 'Demo Account');
    });

    test('initially not connected', () {
      expect(connector.isConnected, isFalse);
    });

    test('connect() sets isConnected to true', () async {
      final result = await connector.connect({});
      expect(result, isTrue);
      expect(connector.isConnected, isTrue);
    });

    test('disconnect() sets isConnected to false', () async {
      await connector.connect({});
      expect(connector.isConnected, isTrue);

      await connector.disconnect();
      expect(connector.isConnected, isFalse);
    });

    group('getPortfolio()', () {
      test('throws StateError when not connected', () {
        expect(
          () => connector.getPortfolio(),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            'DemoBrokerConnector is not connected.',
          )),
        );
      });

      group('when connected', () {
        late PortfolioSnapshotModel portfolio;

        setUp(() async {
          await connector.connect({});
          portfolio = await connector.getPortfolio();
        });

        test('returns totalValue of 500240.75', () {
          expect(portfolio.totalValue, 500240.75);
        });

        test('returns dailyPnl of 4820.50', () {
          expect(portfolio.dailyPnl, 4820.50);
        });

        test('returns dailyPnlPercent of 0.97', () {
          expect(portfolio.dailyPnlPercent, 0.97);
        });

        test('returns exactly 10 positions', () {
          expect(portfolio.positions.length, 10);
        });

        test('contains expected Thai SET symbols', () {
          final symbols =
              portfolio.positions.map((p) => p.symbol).toList();
          expect(symbols, contains('PTT'));
          expect(symbols, contains('KBANK'));
          expect(symbols, contains('SCB'));
          expect(symbols, contains('AOT'));
          expect(symbols, contains('CPALL'));
        });

        test('contains expected US tech symbols', () {
          final symbols =
              portfolio.positions.map((p) => p.symbol).toList();
          expect(symbols, contains('AAPL'));
          expect(symbols, contains('NVDA'));
          expect(symbols, contains('TSLA'));
        });

        test('contains expected crypto symbols', () {
          final symbols =
              portfolio.positions.map((p) => p.symbol).toList();
          expect(symbols, contains('BTC/THB'));
          expect(symbols, contains('ETH/THB'));
        });

        test('AOT has negative unrealizedPnl', () {
          final aot = portfolio.positions
              .firstWhere((p) => p.symbol == 'AOT');
          expect(aot.unrealizedPnl, isNegative);
          expect(aot.unrealizedPnl, -1500.0);
        });

        test('TSLA has negative unrealizedPnl', () {
          final tsla = portfolio.positions
              .firstWhere((p) => p.symbol == 'TSLA');
          expect(tsla.unrealizedPnl, isNegative);
          expect(tsla.unrealizedPnl, -4784.0);
        });

        test('PTT has positive unrealizedPnl', () {
          final ptt = portfolio.positions
              .firstWhere((p) => p.symbol == 'PTT');
          expect(ptt.unrealizedPnl, isPositive);
          expect(ptt.unrealizedPnl, 3500.0);
        });

        test('snapshotAt is set to a recent DateTime', () {
          expect(portfolio.snapshotAt, isA<DateTime>());
          // Should be within the last few seconds
          final now = DateTime.now();
          expect(
            now.difference(portfolio.snapshotAt).inSeconds.abs(),
            lessThan(5),
          );
        });
      });
    });
  });
}
