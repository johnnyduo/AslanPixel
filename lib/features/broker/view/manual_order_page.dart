import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aslan_pixel/features/broker/bloc/manual_order_bloc.dart';

// ---------------------------------------------------------------------------
// Color constants (matches broker_page.dart)
// ---------------------------------------------------------------------------

const Color _navy = Color(0xFF0A1628);
const Color _surface = Color(0xFF0F2040);
const Color _neonGreen = Color(0xFF00F5A0);
const Color _gold = Color(0xFFF5C518);
const Color _textWhite = Color(0xFFE8F4F8);
const Color _red = Color(0xFFFF4757);
const Color _inputBg = Color(0xFF0D1F3C);
const Color _borderColor = Color(0xFF1E3050);

// ---------------------------------------------------------------------------
// ManualOrderPage
// ---------------------------------------------------------------------------

class ManualOrderPage extends StatelessWidget {
  const ManualOrderPage({super.key});

  static const String routeName = '/manual-order';

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ManualOrderBloc>(
      create: (_) => ManualOrderBloc(),
      child: Scaffold(
        backgroundColor: _navy,
        appBar: AppBar(
          backgroundColor: _surface,
          elevation: 0,
          title: const Text(
            'Manual Order',
            style: TextStyle(
              color: _textWhite,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          iconTheme: const IconThemeData(color: _textWhite),
        ),
        body: const _ManualOrderBody(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ManualOrderBody
// ---------------------------------------------------------------------------

class _ManualOrderBody extends StatelessWidget {
  const _ManualOrderBody();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ManualOrderBloc, ManualOrderState>(
      listener: (ctx, state) {
        if (state is ManualOrderConfirming) {
          _showConfirmationDialog(ctx, state);
        }
        if (state is ManualOrderSuccess) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              backgroundColor: _neonGreen,
              content: Text(
                'คำสั่ง ${state.side == OrderSide.buy ? "ซื้อ" : "ขาย"} '
                '${state.symbol} ${state.lots} lots สำเร็จ',
                style: const TextStyle(
                  color: _navy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
          ctx.read<ManualOrderBloc>().add(const ManualOrderReset());
        }
        if (state is ManualOrderError) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              backgroundColor: _red,
              content: Text(
                state.message,
                style: const TextStyle(color: _textWhite),
              ),
            ),
          );
        }
      },
      builder: (ctx, state) {
        if (state is ManualOrderSubmitting) {
          return const Center(
            child: CircularProgressIndicator(color: _neonGreen),
          );
        }

        // Extract current field values
        String symbol = '';
        OrderSide side = OrderSide.buy;
        String lots = '';
        String sl = '';
        String tp = '';
        Map<String, String> errors = {};

        if (state is ManualOrderEditing) {
          symbol = state.symbol;
          side = state.side;
          lots = state.lots;
          sl = state.sl;
          tp = state.tp;
          errors = state.validationErrors;
        }

        return _OrderForm(
          symbol: symbol,
          side: side,
          lots: lots,
          sl: sl,
          tp: tp,
          errors: errors,
        );
      },
    );
  }

  void _showConfirmationDialog(
    BuildContext context,
    ManualOrderConfirming state,
  ) {
    final isBuy = state.side == OrderSide.buy;
    final sideLabel = isBuy ? 'ซื้อ (BUY)' : 'ขาย (SELL)';
    final sideColor = isBuy ? _neonGreen : _red;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: sideColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          title: Column(
            children: [
              // Warning badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _gold.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: const Text(
                  'คำสั่งจริง',
                  style: TextStyle(
                    color: _gold,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'ยืนยันคำสั่ง${isBuy ? "ซื้อ" : "ขาย"}',
                style: const TextStyle(
                  color: _textWhite,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ConfirmRow(label: 'สัญลักษณ์', value: state.symbol),
              _ConfirmRow(
                label: 'ประเภท',
                value: sideLabel,
                valueColor: sideColor,
              ),
              _ConfirmRow(
                label: 'จำนวน Lot',
                value: state.lots.toStringAsFixed(2),
              ),
              if (state.sl != null)
                _ConfirmRow(
                  label: 'Stop Loss',
                  value: state.sl!.toStringAsFixed(2),
                ),
              if (state.tp != null)
                _ConfirmRow(
                  label: 'Take Profit',
                  value: state.tp!.toStringAsFixed(2),
                ),
              const SizedBox(height: 8),
              Text(
                'ข้อมูลเพื่อการศึกษา ไม่ใช่คำแนะนำทางการเงิน',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _gold.withValues(alpha: 0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                context
                    .read<ManualOrderBloc>()
                    .add(const ManualOrderReset());
              },
              child: Text(
                'ยกเลิก',
                style: TextStyle(
                  color: _textWhite.withValues(alpha: 0.6),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogCtx).pop();
                context
                    .read<ManualOrderBloc>()
                    .add(const ManualOrderConfirmed());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: sideColor,
                foregroundColor: _navy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'ยืนยัน $sideLabel',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _ConfirmRow — a label-value row in the confirmation dialog
// ---------------------------------------------------------------------------

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: _textWhite.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? _textWhite,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _OrderForm
// ---------------------------------------------------------------------------

class _OrderForm extends StatefulWidget {
  const _OrderForm({
    required this.symbol,
    required this.side,
    required this.lots,
    required this.sl,
    required this.tp,
    required this.errors,
  });

  final String symbol;
  final OrderSide side;
  final String lots;
  final String sl;
  final String tp;
  final Map<String, String> errors;

  @override
  State<_OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends State<_OrderForm> {
  late final TextEditingController _symbolCtl;
  late final TextEditingController _lotsCtl;
  late final TextEditingController _slCtl;
  late final TextEditingController _tpCtl;

  @override
  void initState() {
    super.initState();
    _symbolCtl = TextEditingController(text: widget.symbol);
    _lotsCtl = TextEditingController(text: widget.lots);
    _slCtl = TextEditingController(text: widget.sl);
    _tpCtl = TextEditingController(text: widget.tp);
  }

  @override
  void didUpdateWidget(covariant _OrderForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync controllers when BLoC resets the form
    if (widget.symbol.isEmpty && _symbolCtl.text.isNotEmpty) {
      _symbolCtl.clear();
      _lotsCtl.clear();
      _slCtl.clear();
      _tpCtl.clear();
    }
  }

  @override
  void dispose() {
    _symbolCtl.dispose();
    _lotsCtl.dispose();
    _slCtl.dispose();
    _tpCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ManualOrderBloc>();
    final isBuy = widget.side == OrderSide.buy;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Symbol field
        _buildLabel('สัญลักษณ์ (Symbol)'),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _symbolCtl,
          hint: 'เช่น XAUUSD, EURUSD',
          errorText: widget.errors['symbol'],
          textCapitalization: TextCapitalization.characters,
          onChanged: (v) => bloc.add(ManualOrderSymbolChanged(v)),
        ),

        const SizedBox(height: 20),

        // Buy / Sell toggle
        _buildLabel('ประเภทคำสั่ง'),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _SideButton(
                label: 'BUY (ซื้อ)',
                isSelected: isBuy,
                color: _neonGreen,
                onTap: () => bloc.add(
                  const ManualOrderSideChanged(OrderSide.buy),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SideButton(
                label: 'SELL (ขาย)',
                isSelected: !isBuy,
                color: _red,
                onTap: () => bloc.add(
                  const ManualOrderSideChanged(OrderSide.sell),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Lot size
        _buildLabel('จำนวน Lot'),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _lotsCtl,
          hint: '0.01',
          errorText: widget.errors['lots'],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) => bloc.add(ManualOrderLotChanged(v)),
        ),

        const SizedBox(height: 20),

        // Stop Loss (optional)
        _buildLabel('Stop Loss (ไม่บังคับ)'),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _slCtl,
          hint: 'ราคา SL',
          errorText: widget.errors['sl'],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) => bloc.add(ManualOrderSlChanged(v)),
        ),

        const SizedBox(height: 20),

        // Take Profit (optional)
        _buildLabel('Take Profit (ไม่บังคับ)'),
        const SizedBox(height: 6),
        _buildTextField(
          controller: _tpCtl,
          hint: 'ราคา TP',
          errorText: widget.errors['tp'],
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) => bloc.add(ManualOrderTpChanged(v)),
        ),

        const SizedBox(height: 32),

        // Submit button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => bloc.add(const ManualOrderSubmitted()),
            style: ElevatedButton.styleFrom(
              backgroundColor: isBuy ? _neonGreen : _red,
              foregroundColor: _navy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            child: Text(isBuy ? 'ส่งคำสั่งซื้อ' : 'ส่งคำสั่งขาย'),
          ),
        ),

        const SizedBox(height: 16),

        // Disclaimer
        const Text(
          'ข้อมูลเพื่อการศึกษา ไม่ใช่คำแนะนำทางการเงิน',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _gold,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Shared builders ──────────────────────────────────────────────────────

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: _textWhite.withValues(alpha: 0.75),
        fontWeight: FontWeight.w600,
        fontSize: 13,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
    String? errorText,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          style: const TextStyle(color: _textWhite, fontSize: 15),
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: _textWhite.withValues(alpha: 0.3),
              fontSize: 14,
            ),
            filled: true,
            fillColor: _inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: errorText != null
                    ? _red.withValues(alpha: 0.6)
                    : _borderColor,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: errorText != null ? _red : _neonGreen,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: const TextStyle(
              color: _red,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _SideButton — Buy / Sell toggle chip
// ---------------------------------------------------------------------------

class _SideButton extends StatelessWidget {
  const _SideButton({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : _inputBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : _borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : _textWhite.withValues(alpha: 0.5),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
