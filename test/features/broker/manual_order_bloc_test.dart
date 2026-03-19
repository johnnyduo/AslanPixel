import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aslan_pixel/features/broker/bloc/manual_order_bloc.dart';

void main() {
  ManualOrderBloc build() => ManualOrderBloc();

  // ── Initial state ───────────────────────────────────────────────────────

  group('ManualOrderBloc initial state', () {
    test('starts as ManualOrderInitial', () {
      expect(build().state, isA<ManualOrderInitial>());
    });
  });

  // ── Symbol changed ──────────────────────────────────────────────────────

  group('ManualOrderSymbolChanged', () {
    blocTest<ManualOrderBloc, ManualOrderState>(
      'emits ManualOrderEditing with uppercase symbol',
      build: build,
      act: (bloc) => bloc.add(const ManualOrderSymbolChanged('xauusd')),
      expect: () => [
        isA<ManualOrderEditing>()
            .having((s) => s.symbol, 'symbol', 'XAUUSD'),
      ],
    );
  });

  // ── Side changed ────────────────────────────────────────────────────────

  group('ManualOrderSideChanged', () {
    blocTest<ManualOrderBloc, ManualOrderState>(
      'emits ManualOrderEditing with sell side',
      build: build,
      act: (bloc) => bloc.add(
        const ManualOrderSideChanged(OrderSide.sell),
      ),
      expect: () => [
        isA<ManualOrderEditing>()
            .having((s) => s.side, 'side', OrderSide.sell),
      ],
    );
  });

  // ── Lot changed ─────────────────────────────────────────────────────────

  group('ManualOrderLotChanged', () {
    blocTest<ManualOrderBloc, ManualOrderState>(
      'emits ManualOrderEditing with lot value',
      build: build,
      act: (bloc) => bloc.add(const ManualOrderLotChanged('0.10')),
      expect: () => [
        isA<ManualOrderEditing>()
            .having((s) => s.lots, 'lots', '0.10'),
      ],
    );
  });

  // ── Submit with valid data → Confirming ────────────────────────────────

  group('ManualOrderSubmitted with valid data', () {
    blocTest<ManualOrderBloc, ManualOrderState>(
      'transitions to ManualOrderConfirming',
      build: build,
      act: (bloc) {
        bloc.add(const ManualOrderSymbolChanged('EURUSD'));
        bloc.add(const ManualOrderLotChanged('0.50'));
        bloc.add(const ManualOrderSubmitted());
      },
      expect: () => [
        // SymbolChanged → Editing
        isA<ManualOrderEditing>(),
        // LotChanged → Editing
        isA<ManualOrderEditing>(),
        // Submitted → Confirming
        isA<ManualOrderConfirming>()
            .having((s) => s.symbol, 'symbol', 'EURUSD')
            .having((s) => s.lots, 'lots', 0.50)
            .having((s) => s.side, 'side', OrderSide.buy),
      ],
    );

    blocTest<ManualOrderBloc, ManualOrderState>(
      'includes SL/TP when provided',
      build: build,
      act: (bloc) {
        bloc.add(const ManualOrderSymbolChanged('XAUUSD'));
        bloc.add(const ManualOrderLotChanged('0.01'));
        bloc.add(const ManualOrderSlChanged('1900.00'));
        bloc.add(const ManualOrderTpChanged('2100.00'));
        bloc.add(const ManualOrderSubmitted());
      },
      expect: () => [
        isA<ManualOrderEditing>(),
        isA<ManualOrderEditing>(),
        isA<ManualOrderEditing>(),
        isA<ManualOrderEditing>(),
        isA<ManualOrderConfirming>()
            .having((s) => s.sl, 'sl', 1900.00)
            .having((s) => s.tp, 'tp', 2100.00),
      ],
    );
  });

  // ── Submit with invalid data → Editing with errors ─────────────────────

  group('ManualOrderSubmitted with invalid data', () {
    blocTest<ManualOrderBloc, ManualOrderState>(
      'emits Editing with errors when symbol is empty',
      build: build,
      act: (bloc) {
        bloc.add(const ManualOrderLotChanged('0.10'));
        bloc.add(const ManualOrderSubmitted());
      },
      expect: () => [
        isA<ManualOrderEditing>(),
        isA<ManualOrderEditing>().having(
          (s) => s.validationErrors.containsKey('symbol'),
          'has symbol error',
          isTrue,
        ),
      ],
    );

    blocTest<ManualOrderBloc, ManualOrderState>(
      'emits Editing with errors when lot is invalid',
      build: build,
      act: (bloc) {
        bloc.add(const ManualOrderSymbolChanged('XAUUSD'));
        bloc.add(const ManualOrderLotChanged('abc'));
        bloc.add(const ManualOrderSubmitted());
      },
      expect: () => [
        isA<ManualOrderEditing>(),
        isA<ManualOrderEditing>(),
        isA<ManualOrderEditing>().having(
          (s) => s.validationErrors.containsKey('lots'),
          'has lots error',
          isTrue,
        ),
      ],
    );

    blocTest<ManualOrderBloc, ManualOrderState>(
      'emits Editing with errors when lot is zero',
      build: build,
      act: (bloc) {
        bloc.add(const ManualOrderSymbolChanged('EURUSD'));
        bloc.add(const ManualOrderLotChanged('0'));
        bloc.add(const ManualOrderSubmitted());
      },
      expect: () => [
        isA<ManualOrderEditing>(),
        isA<ManualOrderEditing>(),
        isA<ManualOrderEditing>().having(
          (s) => s.validationErrors.containsKey('lots'),
          'has lots error',
          isTrue,
        ),
      ],
    );

    blocTest<ManualOrderBloc, ManualOrderState>(
      'emits Editing with errors when SL is invalid',
      build: build,
      act: (bloc) {
        bloc.add(const ManualOrderSymbolChanged('XAUUSD'));
        bloc.add(const ManualOrderLotChanged('0.01'));
        bloc.add(const ManualOrderSlChanged('abc'));
        bloc.add(const ManualOrderSubmitted());
      },
      expect: () => [
        isA<ManualOrderEditing>(),
        isA<ManualOrderEditing>(),
        isA<ManualOrderEditing>(),
        isA<ManualOrderEditing>().having(
          (s) => s.validationErrors.containsKey('sl'),
          'has sl error',
          isTrue,
        ),
      ],
    );
  });

  // ── Confirm → Success ──────────────────────────────────────────────────

  group('ManualOrderConfirmed', () {
    blocTest<ManualOrderBloc, ManualOrderState>(
      'transitions Confirming → Submitting → Success',
      build: build,
      act: (bloc) async {
        bloc.add(const ManualOrderSymbolChanged('EURUSD'));
        bloc.add(const ManualOrderLotChanged('1.00'));
        bloc.add(const ManualOrderSubmitted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ManualOrderConfirmed());
      },
      wait: const Duration(seconds: 2),
      expect: () => [
        isA<ManualOrderEditing>(),
        isA<ManualOrderEditing>(),
        isA<ManualOrderConfirming>(),
        isA<ManualOrderSubmitting>(),
        isA<ManualOrderSuccess>()
            .having((s) => s.symbol, 'symbol', 'EURUSD')
            .having((s) => s.lots, 'lots', 1.00),
      ],
    );
  });

  // ── Reset ──────────────────────────────────────────────────────────────

  group('ManualOrderReset', () {
    blocTest<ManualOrderBloc, ManualOrderState>(
      'returns to ManualOrderInitial from Editing',
      build: build,
      act: (bloc) {
        bloc.add(const ManualOrderSymbolChanged('XAUUSD'));
        bloc.add(const ManualOrderReset());
      },
      expect: () => [
        isA<ManualOrderEditing>(),
        isA<ManualOrderInitial>(),
      ],
    );
  });
}
