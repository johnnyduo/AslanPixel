part of 'manual_order_bloc.dart';

// ---------------------------------------------------------------------------
// ManualOrderEvent
// ---------------------------------------------------------------------------

abstract class ManualOrderEvent extends Equatable {
  const ManualOrderEvent();

  @override
  List<Object?> get props => [];
}

/// User typed or selected a symbol.
class ManualOrderSymbolChanged extends ManualOrderEvent {
  const ManualOrderSymbolChanged(this.symbol);

  final String symbol;

  @override
  List<Object?> get props => [symbol];
}

/// User toggled buy / sell side.
class ManualOrderSideChanged extends ManualOrderEvent {
  const ManualOrderSideChanged(this.side);

  final OrderSide side;

  @override
  List<Object?> get props => [side];
}

/// User changed lot size.
class ManualOrderLotChanged extends ManualOrderEvent {
  const ManualOrderLotChanged(this.lots);

  final String lots;

  @override
  List<Object?> get props => [lots];
}

/// User changed stop-loss price.
class ManualOrderSlChanged extends ManualOrderEvent {
  const ManualOrderSlChanged(this.sl);

  final String sl;

  @override
  List<Object?> get props => [sl];
}

/// User changed take-profit price.
class ManualOrderTpChanged extends ManualOrderEvent {
  const ManualOrderTpChanged(this.tp);

  final String tp;

  @override
  List<Object?> get props => [tp];
}

/// User tapped the submit button — validate and move to confirmation.
class ManualOrderSubmitted extends ManualOrderEvent {
  const ManualOrderSubmitted();
}

/// User confirmed the order in the confirmation dialog.
class ManualOrderConfirmed extends ManualOrderEvent {
  const ManualOrderConfirmed();
}

/// Reset the form back to initial state.
class ManualOrderReset extends ManualOrderEvent {
  const ManualOrderReset();
}
