part of 'crypto_bloc.dart';

abstract class CryptoEvent extends Equatable {
  const CryptoEvent();
  @override
  List<Object?> get props => [];
}

class CryptoLoadRequested extends CryptoEvent {
  const CryptoLoadRequested({this.symbols});
  final List<String>? symbols;
  @override
  List<Object?> get props => [symbols];
}

class CryptoRefreshRequested extends CryptoEvent {
  const CryptoRefreshRequested({this.symbols});
  final List<String>? symbols;
  @override
  List<Object?> get props => [symbols];
}

class CryptoKlineRequested extends CryptoEvent {
  const CryptoKlineRequested({
    required this.symbol,
    this.interval = '1h',
    this.limit = 24,
  });
  final String symbol;
  final String interval;
  final int limit;
  @override
  List<Object?> get props => [symbol, interval, limit];
}
