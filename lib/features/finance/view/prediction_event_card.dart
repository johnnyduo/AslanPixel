import 'package:flutter/material.dart';
import 'package:aslan_pixel/features/finance/bloc/prediction_bloc.dart';
import 'package:aslan_pixel/features/finance/bloc/prediction_event.dart';
import 'package:aslan_pixel/features/finance/data/models/prediction_event_model.dart';

// ---------------------------------------------------------------------------
// Color constants
// ---------------------------------------------------------------------------

const Color _surface = Color(0xFF0F2040);
const Color _neonGreen = Color(0xFF00F5A0);
const Color _gold = Color(0xFFF5C518);
const Color _cyan = Color(0xFF00D9FF);
const Color _textWhite = Color(0xFFE8F4F8);

// ---------------------------------------------------------------------------
// PredictionEventCard
// ---------------------------------------------------------------------------

class PredictionEventCard extends StatelessWidget {
  const PredictionEventCard({
    super.key,
    required this.event,
    required this.uid,
    required this.bloc,
  });

  final PredictionEventModel event;
  final String uid;
  final PredictionBloc bloc;

  // ------ helpers -----------------------------------------------------------

  String _countdownLabel() {
    final diff = event.settlementAt.difference(DateTime.now());
    if (diff.isNegative) return 'หมดเวลา';
    final hours = diff.inHours;
    if (hours >= 24) {
      final days = diff.inDays;
      return 'เหลือ $days วัน';
    }
    if (hours > 0) return 'เหลือ $hours ชั่วโมง';
    final minutes = diff.inMinutes;
    return 'เหลือ $minutes นาที';
  }

  void _onOptionTap(BuildContext context, PredictionOption option) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _neonGreen, width: 1),
        ),
        title: const Text(
          'ยืนยันการเข้าร่วม',
          style: TextStyle(color: _textWhite, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'ใช้ ${event.coinCost} เหรียญเพื่อเข้าร่วม?\n'
          'ตัวเลือก: ${option.labelTh}',
          style: TextStyle(color: _textWhite.withValues(alpha: 0.85)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              'ยกเลิก',
              style: TextStyle(color: _textWhite.withValues(alpha: 0.6)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _neonGreen,
              foregroundColor: const Color(0xFF0A1628),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              bloc.add(
                PredictionEventEntered(
                  eventId: event.eventId,
                  uid: uid,
                  selectedOptionId: option.optionId,
                  coinStaked: event.coinCost,
                ),
              );
            },
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _neonGreen.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: symbol chip + title
          Row(
            children: [
              _SymbolChip(symbol: event.symbol),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  event.titleTh,
                  style: const TextStyle(
                    color: _textWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Countdown
          Row(
            children: [
              const Icon(Icons.access_time_rounded, color: _cyan, size: 14),
              const SizedBox(width: 4),
              Text(
                _countdownLabel(),
                style: const TextStyle(
                  color: _cyan,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Coin cost badge
              const Icon(Icons.monetization_on_rounded, color: _gold, size: 15),
              const SizedBox(width: 3),
              Text(
                '${event.coinCost}',
                style: const TextStyle(
                  color: _gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Options row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: event.options
                .map(
                  (option) => _OptionButton(
                    label: option.labelTh,
                    onTap: () => _onOptionTap(context, option),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SymbolChip
// ---------------------------------------------------------------------------

class _SymbolChip extends StatelessWidget {
  const _SymbolChip({required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _gold,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        symbol,
        style: const TextStyle(
          color: Color(0xFF0A1628),
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _OptionButton
// ---------------------------------------------------------------------------

class _OptionButton extends StatelessWidget {
  const _OptionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: _textWhite,
        side: const BorderSide(color: _neonGreen, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _textWhite,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
