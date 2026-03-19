part of 'crypto_bloc.dart';

abstract class CryptoState extends Equatable {
  const CryptoState();
  @override
  List<Object?> get props => [];
}

class CryptoInitial extends CryptoState {
  const CryptoInitial();
}

class CryptoLoading extends CryptoState {
  const CryptoLoading();
}

class CryptoLoaded extends CryptoState {
  const CryptoLoaded({
    required this.tickers,
    required this.lastUpdated,
    this.selectedKlines,
    this.selectedSymbol,
  });
  final List<BinanceTicker> tickers;
  final DateTime lastUpdated;
  final List<double>? selectedKlines;
  final String? selectedSymbol;
  @override
  List<Object?> get props =>
      [tickers, lastUpdated, selectedKlines, selectedSymbol];
}

class CryptoError extends CryptoState {
  const CryptoError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
