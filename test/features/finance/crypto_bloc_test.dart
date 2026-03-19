import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aslan_pixel/data/services/binance_service.dart';
import 'package:aslan_pixel/data/services/binance_ticker.dart';
import 'package:aslan_pixel/features/finance/bloc/crypto_bloc.dart';

class MockBinanceService extends Mock implements BinanceService {}

void main() {
  late MockBinanceService mockService;

  setUp(() {
    mockService = MockBinanceService();
  });

  CryptoBloc buildBloc() => CryptoBloc(service: mockService);

  final sampleTickers = [
    const BinanceTicker(
      symbol: 'BTCUSDT',
      lastPrice: 67500.0,
      priceChangePercent: 2.34,
      highPrice: 68000.0,
      lowPrice: 66000.0,
      volume: 12345.0,
      quoteVolume: 834000000.0,
    ),
    const BinanceTicker(
      symbol: 'ETHUSDT',
      lastPrice: 3210.0,
      priceChangePercent: -0.54,
      highPrice: 3300.0,
      lowPrice: 3150.0,
      volume: 55000.0,
      quoteVolume: 176000000.0,
    ),
  ];

  group('CryptoBloc - initial state', () {
    test('initial state is CryptoInitial', () {
      final bloc = buildBloc();
      expect(bloc.state, isA<CryptoInitial>());
      bloc.close();
    });
  });

  group('CryptoLoadRequested', () {
    test('emits [CryptoLoading, CryptoLoaded] on success', () async {
      when(() => mockService.get24hrTickers(any()))
          .thenAnswer((_) async => sampleTickers);

      final bloc = buildBloc();
      bloc.add(const CryptoLoadRequested());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<CryptoLoading>(),
          isA<CryptoLoaded>(),
        ]),
      );

      final loaded = bloc.state as CryptoLoaded;
      expect(loaded.tickers.length, 2);
      expect(loaded.tickers.first.symbol, 'BTCUSDT');

      await bloc.close();
    });

    test('emits [CryptoLoading, CryptoError] when service returns empty',
        () async {
      when(() => mockService.get24hrTickers(any()))
          .thenAnswer((_) async => []);

      final bloc = buildBloc();
      bloc.add(const CryptoLoadRequested());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<CryptoLoading>(),
          isA<CryptoError>(),
        ]),
      );

      final error = bloc.state as CryptoError;
      // Thai error message
      expect(error.message, contains('\u0e44\u0e21\u0e48\u0e2a\u0e32\u0e21\u0e32\u0e23\u0e16'));

      await bloc.close();
    });
  });

  group('CryptoRefreshRequested', () {
    test('updates tickers when new data available', () async {
      when(() => mockService.get24hrTickers(any()))
          .thenAnswer((_) async => sampleTickers);

      final bloc = buildBloc();
      // First load
      bloc.add(const CryptoLoadRequested());
      await Future.delayed(const Duration(milliseconds: 100));

      final updatedTickers = [
        const BinanceTicker(
          symbol: 'BTCUSDT',
          lastPrice: 68000.0,
          priceChangePercent: 3.0,
          highPrice: 69000.0,
          lowPrice: 67000.0,
          volume: 13000.0,
          quoteVolume: 900000000.0,
        ),
      ];

      when(() => mockService.get24hrTickers(any()))
          .thenAnswer((_) async => updatedTickers);

      bloc.add(const CryptoRefreshRequested());
      await Future.delayed(const Duration(milliseconds: 100));

      final loaded = bloc.state as CryptoLoaded;
      expect(loaded.tickers.length, 1);
      expect(loaded.tickers.first.lastPrice, 68000.0);

      await bloc.close();
    });

    test('keeps old data when refresh returns empty', () async {
      when(() => mockService.get24hrTickers(any()))
          .thenAnswer((_) async => sampleTickers);

      final bloc = buildBloc();
      bloc.add(const CryptoLoadRequested());
      await Future.delayed(const Duration(milliseconds: 100));

      when(() => mockService.get24hrTickers(any()))
          .thenAnswer((_) async => []);

      bloc.add(const CryptoRefreshRequested());
      await Future.delayed(const Duration(milliseconds: 100));

      final loaded = bloc.state as CryptoLoaded;
      expect(loaded.tickers.length, 2); // still has old data

      await bloc.close();
    });
  });

  group('CryptoKlineRequested', () {
    test('adds kline data to CryptoLoaded state', () async {
      when(() => mockService.get24hrTickers(any()))
          .thenAnswer((_) async => sampleTickers);
      when(() => mockService.getKlines(
            symbol: any(named: 'symbol'),
            interval: any(named: 'interval'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => [65000, 66000, 67000, 67500]);

      final bloc = buildBloc();
      bloc.add(const CryptoLoadRequested());
      await Future.delayed(const Duration(milliseconds: 100));

      bloc.add(const CryptoKlineRequested(symbol: 'BTCUSDT'));
      await Future.delayed(const Duration(milliseconds: 100));

      final loaded = bloc.state as CryptoLoaded;
      expect(loaded.selectedSymbol, 'BTCUSDT');
      expect(loaded.selectedKlines, isNotNull);
      expect(loaded.selectedKlines!.length, 4);

      await bloc.close();
    });
  });

  group('Auto-refresh timer', () {
    test('timer is cancelled on close', () async {
      when(() => mockService.get24hrTickers(any()))
          .thenAnswer((_) async => sampleTickers);
      when(() => mockService.dispose()).thenReturn(null);

      final bloc = buildBloc();
      bloc.add(const CryptoLoadRequested());
      await Future.delayed(const Duration(milliseconds: 100));

      // close should not throw — timer is properly cancelled
      await bloc.close();
    });
  });
}
