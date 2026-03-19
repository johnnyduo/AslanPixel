import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aslan_pixel/data/services/binance_service.dart';
import 'package:aslan_pixel/data/services/binance_ticker.dart';

part 'crypto_event.dart';
part 'crypto_state.dart';

class CryptoBloc extends Bloc<CryptoEvent, CryptoState> {
  CryptoBloc({BinanceService? service})
      : _service = service ?? BinanceService(),
        super(const CryptoInitial()) {
    on<CryptoLoadRequested>(_onLoadRequested);
    on<CryptoRefreshRequested>(_onRefreshRequested);
    on<CryptoKlineRequested>(_onKlineRequested);
  }

  final BinanceService _service;
  Timer? _autoRefreshTimer;

  /// Default symbols -- top crypto pairs popular in Thailand.
  static const defaultSymbols = [
    'BTCUSDT',
    'ETHUSDT',
    'BNBUSDT',
    'SOLUSDT',
    'XRPUSDT',
    'DOGEUSDT',
    'ADAUSDT',
    'AVAXUSDT',
    'DOTUSDT',
    'MATICUSDT',
    'LINKUSDT',
    'UNIUSDT',
    'ATOMUSDT',
    'NEARUSDT',
    'OPUSDT',
  ];

  Future<void> _onLoadRequested(
    CryptoLoadRequested event,
    Emitter<CryptoState> emit,
  ) async {
    emit(const CryptoLoading());
    final tickers =
        await _service.get24hrTickers(event.symbols ?? defaultSymbols);
    if (tickers.isEmpty) {
      emit(const CryptoError(
          '\u0e44\u0e21\u0e48\u0e2a\u0e32\u0e21\u0e32\u0e23\u0e16\u0e42\u0e2b\u0e25\u0e14\u0e02\u0e49\u0e2d\u0e21\u0e39\u0e25\u0e04\u0e23\u0e34\u0e1b\u0e42\u0e15\u0e44\u0e14\u0e49'));
      return;
    }
    emit(CryptoLoaded(tickers: tickers, lastUpdated: DateTime.now()));

    // Auto-refresh every 30 seconds
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!isClosed) add(CryptoRefreshRequested(symbols: event.symbols));
    });
  }

  Future<void> _onRefreshRequested(
    CryptoRefreshRequested event,
    Emitter<CryptoState> emit,
  ) async {
    final current = state;
    final tickers =
        await _service.get24hrTickers(event.symbols ?? defaultSymbols);
    if (tickers.isEmpty && current is CryptoLoaded) return; // keep old data
    if (tickers.isNotEmpty) {
      emit(CryptoLoaded(tickers: tickers, lastUpdated: DateTime.now()));
    }
  }

  Future<void> _onKlineRequested(
    CryptoKlineRequested event,
    Emitter<CryptoState> emit,
  ) async {
    final klines = await _service.getKlines(
      symbol: event.symbol,
      interval: event.interval,
      limit: event.limit,
    );
    final current = state;
    if (current is CryptoLoaded) {
      emit(CryptoLoaded(
        tickers: current.tickers,
        lastUpdated: current.lastUpdated,
        selectedKlines: klines,
        selectedSymbol: event.symbol,
      ));
    }
  }

  @override
  Future<void> close() {
    _autoRefreshTimer?.cancel();
    _service.dispose();
    return super.close();
  }
}
