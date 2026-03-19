part of 'manual_order_bloc.dart';

// ---------------------------------------------------------------------------
// OrderSide enum
// ---------------------------------------------------------------------------

enum OrderSide { buy, sell }

// ---------------------------------------------------------------------------
// ManualOrderState
// ---------------------------------------------------------------------------

abstract class ManualOrderState extends Equatable {
  const ManualOrderState();

  @override
  List<Object?> get props => [];
}

/// Initial empty form.
class ManualOrderInitial extends ManualOrderState {
  const ManualOrderInitial();
}

/// User is editing the order form.
class ManualOrderEditing extends ManualOrderState {
  const ManualOrderEditing({
    this.symbol = '',
    this.side = OrderSide.buy,
    this.lots = '',
    this.sl = '',
    this.tp = '',
    this.validationErrors = const {},
  });

  final String symbol;
  final OrderSide side;
  final String lots;
  final String sl;
  final String tp;

  /// Field name → error message (Thai).
  final Map<String, String> validationErrors;

  ManualOrderEditing copyWith({
    String? symbol,
    OrderSide? side,
    String? lots,
    String? sl,
    String? tp,
    Map<String, String>? validationErrors,
  }) {
    return ManualOrderEditing(
      symbol: symbol ?? this.symbol,
      side: side ?? this.side,
      lots: lots ?? this.lots,
      sl: sl ?? this.sl,
      tp: tp ?? this.tp,
      validationErrors: validationErrors ?? this.validationErrors,
    );
  }

  @override
  List<Object?> get props => [symbol, side, lots, sl, tp, validationErrors];
}

/// Awaiting user confirmation in the dialog.
class ManualOrderConfirming extends ManualOrderState {
  const ManualOrderConfirming({
    required this.symbol,
    required this.side,
    required this.lots,
    this.sl,
    this.tp,
  });

  final String symbol;
  final OrderSide side;
  final double lots;
  final double? sl;
  final double? tp;

  @override
  List<Object?> get props => [symbol, side, lots, sl, tp];
}

/// Order is being sent to the backend.
class ManualOrderSubmitting extends ManualOrderState {
  const ManualOrderSubmitting();
}

/// Order submitted successfully.
class ManualOrderSuccess extends ManualOrderState {
  const ManualOrderSuccess({
    required this.symbol,
    required this.side,
    required this.lots,
  });

  final String symbol;
  final OrderSide side;
  final double lots;

  @override
  List<Object?> get props => [symbol, side, lots];
}

/// An error occurred during order submission.
class ManualOrderError extends ManualOrderState {
  const ManualOrderError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
