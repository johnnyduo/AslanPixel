import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aslan_pixel/features/finance/bloc/prediction_bloc.dart';
import 'package:aslan_pixel/features/finance/bloc/prediction_event.dart';
import 'package:aslan_pixel/features/finance/bloc/prediction_state.dart';
import 'package:aslan_pixel/features/finance/data/models/prediction_event_model.dart';

// ---------------------------------------------------------------------------
// Color constants
// ---------------------------------------------------------------------------

const Color _surface = Color(0xFF0F2040);
const Color _neonGreen = Color(0xFF00F5A0);
const Color _gold = Color(0xFFF5C518);
const Color _cyan = Color(0xFF00D9FF);
const Color _textWhite = Color(0xFFE8F4F8);
const Color _red = Color(0xFFFF4757);

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

          // Bull/Bear vote section (shown when event has bull+bear options)
          _BullBearVoteSection(
            event: event,
            uid: uid,
            bloc: bloc,
            onOptionTap: _onOptionTap,
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

// ---------------------------------------------------------------------------
// _BullBearVoteSection
// ---------------------------------------------------------------------------
// Shows Bull 📈 / Bear 📉 vote buttons + percentage bar when the event has
// exactly 2 options whose optionId contains 'bull'/'bear'.
// Falls back to generic option chips for all other event types.
// Votes are stored in Firestore: predictionEvents/{eventId}/votes/{uid}
// ---------------------------------------------------------------------------

class _BullBearVoteSection extends StatefulWidget {
  const _BullBearVoteSection({
    required this.event,
    required this.uid,
    required this.bloc,
    required this.onOptionTap,
  });

  final PredictionEventModel event;
  final String uid;
  final PredictionBloc bloc;
  final void Function(BuildContext, PredictionOption) onOptionTap;

  @override
  State<_BullBearVoteSection> createState() => _BullBearVoteSectionState();
}

class _BullBearVoteSectionState extends State<_BullBearVoteSection> {
  // Local optimistic state
  String? _myVote; // 'bull' | 'bear' | null
  int _bullCount = 0;
  int _bearCount = 0;
  bool _isLoading = true;

  PredictionOption? get _bullOption => widget.event.options
      .where((o) => o.optionId.toLowerCase().contains('bull'))
      .firstOrNull;

  PredictionOption? get _bearOption => widget.event.options
      .where((o) => o.optionId.toLowerCase().contains('bear'))
      .firstOrNull;

  bool get _isBullBearEvent => _bullOption != null && _bearOption != null;

  @override
  void initState() {
    super.initState();
    if (_isBullBearEvent) {
      widget.bloc.add(PredictionVotesLoaded(
        eventId: widget.event.eventId,
        uid: widget.uid,
      ));
    }
  }

  void _castVote(String side, PredictionOption option) {
    if (_myVote != null) return; // already voted

    // Optimistic update
    setState(() {
      _myVote = side;
      if (side == 'bull') {
        _bullCount++;
      } else {
        _bearCount++;
      }
    });

    widget.bloc.add(PredictionVoteCasted(
      eventId: widget.event.eventId,
      uid: widget.uid,
      side: side,
      selectedOptionId: option.optionId,
      coinStaked: widget.event.coinCost,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (!_isBullBearEvent) {
      // Fallback: generic option chips
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: widget.event.options
            .map(
              (option) => _OptionButton(
                label: option.labelTh,
                onTap: () => widget.onOptionTap(context, option),
              ),
            )
            .toList(),
      );
    }

    return BlocListener<PredictionBloc, PredictionState>(
      bloc: widget.bloc,
      listener: (context, state) {
        if (state is PredictionVotesData &&
            state.eventId == widget.event.eventId) {
          setState(() {
            _bullCount = state.bullCount;
            _bearCount = state.bearCount;
            _myVote = state.myVote;
            _isLoading = false;
          });
        } else if (state is PredictionVoteCastedSuccess) {
          final label = state.side == 'bull' ? 'Bull 📈' : 'Bear 📉';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'บันทึกการโหวต $label เรียบร้อย!',
                style: const TextStyle(color: Color(0xFF0A1628)),
              ),
              backgroundColor: _neonGreen,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is PredictionVoteCastError) {
          // Rollback on error
          setState(() {
            if (_myVote == 'bull') _bullCount--;
            if (_myVote == 'bear') _bearCount--;
            _myVote = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: ${state.message}'),
              backgroundColor: _red,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    final total = _bullCount + _bearCount;
    final bullPct = total > 0 ? _bullCount / total : 0.5;
    final bearPct = total > 0 ? _bearCount / total : 0.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vote buttons row
        if (_isLoading)
          const SizedBox(
            height: 40,
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: _neonGreen,
                  strokeWidth: 2,
                ),
              ),
            ),
          )
        else
          Row(
            children: [
              // Bull button
              Expanded(
                child: _VoteButton(
                  label: 'Bull 📈',
                  color: _neonGreen,
                  isSelected: _myVote == 'bull',
                  isLocked: _myVote != null,
                  onTap: _myVote == null
                      ? () => _castVote('bull', _bullOption!)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              // Bear button
              Expanded(
                child: _VoteButton(
                  label: 'Bear 📉',
                  color: _red,
                  isSelected: _myVote == 'bear',
                  isLocked: _myVote != null,
                  onTap: _myVote == null
                      ? () => _castVote('bear', _bearOption!)
                      : null,
                ),
              ),
            ],
          ),

        const SizedBox(height: 10),

        // Percentage bar
        _VotePercentBar(
          bullPct: bullPct,
          bearPct: bearPct,
          total: total,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _VoteButton
// ---------------------------------------------------------------------------

class _VoteButton extends StatelessWidget {
  const _VoteButton({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.isLocked,
    this.onTap,
  });

  final String label;
  final Color color;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: OutlinedButton(
        onPressed: isLocked ? null : onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? color.withValues(alpha: 0.18) : Colors.transparent,
          foregroundColor: isSelected ? color : _textWhite,
          side: BorderSide(
            color: isSelected ? color : color.withValues(alpha: 0.4),
            width: isSelected ? 1.8 : 1.0,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 10),
          disabledForegroundColor: isSelected ? color : _textWhite.withValues(alpha: 0.3),
          disabledBackgroundColor: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _VotePercentBar
// ---------------------------------------------------------------------------

class _VotePercentBar extends StatelessWidget {
  const _VotePercentBar({
    required this.bullPct,
    required this.bearPct,
    required this.total,
  });

  final double bullPct;
  final double bearPct;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Labels
        Row(
          children: [
            Text(
              'Bull ${(bullPct * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                color: _neonGreen,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              total > 0 ? '$total โหวต' : 'ยังไม่มีโหวต',
              style: TextStyle(
                color: _textWhite.withValues(alpha: 0.4),
                fontSize: 10,
              ),
            ),
            const Spacer(),
            Text(
              'Bear ${(bearPct * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                color: _red,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 6,
            child: Row(
              children: [
                Expanded(
                  flex: (bullPct * 100).round().clamp(1, 99),
                  child: Container(color: _neonGreen.withValues(alpha: 0.8)),
                ),
                Expanded(
                  flex: (bearPct * 100).round().clamp(1, 99),
                  child: Container(color: _red.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
