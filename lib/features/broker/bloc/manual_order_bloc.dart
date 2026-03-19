import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'manual_order_event.dart';
part 'manual_order_state.dart';

class ManualOrderBloc extends Bloc<ManualOrderEvent, ManualOrderState> {
  ManualOrderBloc() : super(const ManualOrderInitial()) {
    on<ManualOrderSymbolChanged>(_onSymbolChanged);
    on<ManualOrderSideChanged>(_onSideChanged);
    on<ManualOrderLotChanged>(_onLotChanged);
    on<ManualOrderSlChanged>(_onSlChanged);
    on<ManualOrderTpChanged>(_onTpChanged);
    on<ManualOrderSubmitted>(_onSubmitted);
    on<ManualOrderConfirmed>(_onConfirmed);
    on<ManualOrderReset>(_onReset);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  ManualOrderEditing _currentEditing() {
    final s = state;
    if (s is ManualOrderEditing) return s;
    return const ManualOrderEditing();
  }

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  void _onSymbolChanged(
    ManualOrderSymbolChanged event,
    Emitter<ManualOrderState> emit,
  ) {
    emit(_currentEditing().copyWith(
      symbol: event.symbol.toUpperCase().trim(),
      validationErrors: {},
    ));
  }

  void _onSideChanged(
    ManualOrderSideChanged event,
    Emitter<ManualOrderState> emit,
  ) {
    emit(_currentEditing().copyWith(
      side: event.side,
      validationErrors: {},
    ));
  }

  void _onLotChanged(
    ManualOrderLotChanged event,
    Emitter<ManualOrderState> emit,
  ) {
    emit(_currentEditing().copyWith(
      lots: event.lots,
      validationErrors: {},
    ));
  }

  void _onSlChanged(
    ManualOrderSlChanged event,
    Emitter<ManualOrderState> emit,
  ) {
    emit(_currentEditing().copyWith(
      sl: event.sl,
      validationErrors: {},
    ));
  }

  void _onTpChanged(
    ManualOrderTpChanged event,
    Emitter<ManualOrderState> emit,
  ) {
    emit(_currentEditing().copyWith(
      tp: event.tp,
      validationErrors: {},
    ));
  }

  void _onSubmitted(
    ManualOrderSubmitted event,
    Emitter<ManualOrderState> emit,
  ) {
    final editing = _currentEditing();
    final errors = <String, String>{};

    // Validate symbol
    if (editing.symbol.isEmpty) {
      errors['symbol'] = 'กรุณาระบุสัญลักษณ์';
    }

    // Validate lots
    final lotsValue = double.tryParse(editing.lots);
    if (editing.lots.isEmpty || lotsValue == null || lotsValue <= 0) {
      errors['lots'] = 'กรุณาระบุจำนวน lot ที่ถูกต้อง';
    }

    // Validate optional SL
    if (editing.sl.isNotEmpty) {
      final slValue = double.tryParse(editing.sl);
      if (slValue == null || slValue <= 0) {
        errors['sl'] = 'ค่า Stop Loss ไม่ถูกต้อง';
      }
    }

    // Validate optional TP
    if (editing.tp.isNotEmpty) {
      final tpValue = double.tryParse(editing.tp);
      if (tpValue == null || tpValue <= 0) {
        errors['tp'] = 'ค่า Take Profit ไม่ถูกต้อง';
      }
    }

    if (errors.isNotEmpty) {
      emit(editing.copyWith(validationErrors: errors));
      return;
    }

    // Move to confirmation
    emit(ManualOrderConfirming(
      symbol: editing.symbol,
      side: editing.side,
      lots: lotsValue!,
      sl: editing.sl.isNotEmpty ? double.parse(editing.sl) : null,
      tp: editing.tp.isNotEmpty ? double.parse(editing.tp) : null,
    ));
  }

  Future<void> _onConfirmed(
    ManualOrderConfirmed event,
    Emitter<ManualOrderState> emit,
  ) async {
    final s = state;
    if (s is! ManualOrderConfirming) return;

    emit(const ManualOrderSubmitting());

    // TODO: Call Cloud Function to place real order via broker API.
    // For now, simulate a short delay and succeed.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    emit(ManualOrderSuccess(
      symbol: s.symbol,
      side: s.side,
      lots: s.lots,
    ));
  }

  void _onReset(
    ManualOrderReset event,
    Emitter<ManualOrderState> emit,
  ) {
    emit(const ManualOrderInitial());
  }
}
