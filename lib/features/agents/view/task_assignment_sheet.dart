import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aslan_pixel/core/enums/agent_type.dart';
import 'package:aslan_pixel/features/agents/bloc/task_bloc.dart';
import 'package:aslan_pixel/features/agents/data/models/agent_model.dart';
import 'package:aslan_pixel/features/agents/engine/agent_task_model.dart';
import 'package:aslan_pixel/features/agents/engine/idle_task_engine.dart';

// Re-export so UI files can import the limit from here if desired.
export 'package:aslan_pixel/features/agents/engine/idle_task_engine.dart'
    show kMaxTeamSize;

// ── Palette ────────────────────────────────────────────────────────────────
const _kBackground = Color(0xFF0f2040);
const _kSurface = Color(0xFF162040);
const _kSurfaceElevated = Color(0xFF1c2a4e);
const _kBorder = Color(0xFF1e3050);
const _kNeonGreen = Color(0xFF00f5a0);
const _kTextPrimary = Color(0xFFe8f4ff);
const _kTextSecondary = Color(0xFFa8c4e0);
const _kTextDisabled = Color(0xFF3d5a78);
const _kGold = Color(0xFFf5c518);

/// Modal bottom sheet for assigning an idle task to [agent].
///
/// Pass [currentTeamSize] to enforce the [kMaxTeamSize] = 8 cap.
/// When [currentTeamSize] >= [kMaxTeamSize] the assign button is disabled.
///
/// Usage:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   backgroundColor: Colors.transparent,
///   builder: (_) => TaskAssignmentSheet(
///     uid: uid,
///     agent: agent,
///     bloc: taskBloc,
///     currentTeamSize: agents.length,
///   ),
/// );
/// ```
class TaskAssignmentSheet extends StatefulWidget {
  const TaskAssignmentSheet({
    super.key,
    required this.uid,
    required this.agent,
    required this.bloc,
    this.currentTeamSize = 0,
  });

  final String uid;
  final AgentModel agent;
  final TaskBloc bloc;

  /// Number of agents currently on the team.
  /// Assign is disabled when this reaches [kMaxTeamSize].
  final int currentTeamSize;

  @override
  State<TaskAssignmentSheet> createState() => _TaskAssignmentSheetState();
}

class _TaskAssignmentSheetState extends State<TaskAssignmentSheet> {
  late List<TaskType> _availableTypes;
  late TaskType _selectedType;
  late TaskTier _selectedTier;

  @override
  void initState() {
    super.initState();
    _availableTypes = IdleTaskEngine.availableTaskTypes(widget.agent.type);
    _selectedType = _availableTypes.first;
    _selectedTier = TaskTier.basic;
  }

  int get _rewardPreview {
    final base = IdleTaskEngine.tierBaseReward[_selectedTier]!;
    final multiplier = 1.0 + (widget.agent.level * 0.05);
    return (base * multiplier).round();
  }

  int get _xpPreview => (_rewardPreview * 0.5).round();

  bool get _canAssign => widget.currentTeamSize < kMaxTeamSize;

  void _dispatch() {
    if (!_canAssign) return;
    widget.bloc.add(
      TaskCreated(
        uid: widget.uid,
        agentId: widget.agent.agentId,
        agentType: widget.agent.type,
        taskType: _selectedType,
        tier: _selectedTier,
        agentLevel: widget.agent.level,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.bloc,
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => _SheetBody(
          scrollController: scrollController,
          agent: widget.agent,
          availableTypes: _availableTypes,
          selectedType: _selectedType,
          selectedTier: _selectedTier,
          rewardPreview: _rewardPreview,
          xpPreview: _xpPreview,
          onTypeChanged: (type) => setState(() => _selectedType = type),
          onTierChanged: (tier) => setState(() => _selectedTier = tier),
          onAssign: _canAssign ? _dispatch : null,
          teamFull: !_canAssign,
        ),
      ),
    );
  }
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({
    required this.scrollController,
    required this.agent,
    required this.availableTypes,
    required this.selectedType,
    required this.selectedTier,
    required this.rewardPreview,
    required this.xpPreview,
    required this.onTypeChanged,
    required this.onTierChanged,
    required this.onAssign,
    this.teamFull = false,
  });

  final ScrollController scrollController;
  final AgentModel agent;
  final List<TaskType> availableTypes;
  final TaskType selectedType;
  final TaskTier selectedTier;
  final int rewardPreview;
  final int xpPreview;
  final ValueChanged<TaskType> onTypeChanged;
  final ValueChanged<TaskTier> onTierChanged;

  /// Null when team is full — button will be disabled.
  final VoidCallback? onAssign;

  /// True when [kMaxTeamSize] has been reached.
  final bool teamFull;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: _kBorder, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Text(
              'มอบหมายงาน — ${agent.type.displayName}',
              style: const TextStyle(
                color: _kTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Divider(color: _kBorder, height: 1),
          // Scrollable body
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // ── Task type selector ────────────────────────────────────
                const Text(
                  'ประเภทงาน',
                  style: TextStyle(
                    color: _kTextSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...availableTypes.map(
                  (type) => _TaskTypeRadioTile(
                    type: type,
                    isSelected: selectedType == type,
                    onTap: () => onTypeChanged(type),
                  ),
                ),
                const SizedBox(height: 20),
                // ── Tier selector ─────────────────────────────────────────
                const Text(
                  'ระดับความยาก',
                  style: TextStyle(
                    color: _kTextSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                _TierSegmentedButton(
                  selected: selectedTier,
                  onChanged: onTierChanged,
                ),
                const SizedBox(height: 20),
                // ── Reward preview ────────────────────────────────────────
                _RewardPreviewCard(
                  rewardCoins: rewardPreview,
                  rewardXp: xpPreview,
                  duration: IdleTaskEngine.tierDurations[selectedTier]!,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          // ── Assign button ────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (teamFull)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'ทีมเต็มแล้ว (สูงสุด $kMaxTeamSize คน)',
                      style: const TextStyle(
                        color: _kTextDisabled,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: onAssign,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          teamFull ? _kTextDisabled : _kNeonGreen,
                      foregroundColor: const Color(0xFF0a1628),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'มอบหมาย',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _TaskTypeRadioTile extends StatelessWidget {
  const _TaskTypeRadioTile({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  final TaskType type;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _kSurfaceElevated : _kSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _kNeonGreen : _kBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? _kNeonGreen : _kTextDisabled,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              IdleTaskEngine.taskNameTh(type),
              style: TextStyle(
                color: isSelected ? _kTextPrimary : _kTextSecondary,
                fontSize: 14,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TierSegmentedButton extends StatelessWidget {
  const _TierSegmentedButton({
    required this.selected,
    required this.onChanged,
  });

  final TaskTier selected;
  final ValueChanged<TaskTier> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TaskTier>(
      segments: TaskTier.values.map((tier) {
        final label = switch (tier) {
          TaskTier.basic => 'พื้นฐาน',
          TaskTier.standard => 'มาตรฐาน',
          TaskTier.advanced => 'ขั้นสูง',
          TaskTier.elite => 'Elite',
        };
        return ButtonSegment<TaskTier>(
          value: tier,
          label: Text(
            label,
            style: const TextStyle(fontSize: 11),
          ),
        );
      }).toList(),
      selected: {selected},
      onSelectionChanged: (set) {
        if (set.isNotEmpty) onChanged(set.first);
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _kNeonGreen;
          return _kSurface;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF0a1628);
          }
          return _kTextSecondary;
        }),
        side: WidgetStateProperty.all(
          const BorderSide(color: _kBorder),
        ),
      ),
    );
  }
}

class _RewardPreviewCard extends StatelessWidget {
  const _RewardPreviewCard({
    required this.rewardCoins,
    required this.rewardXp,
    required this.duration,
  });

  final int rewardCoins;
  final int rewardXp;
  final Duration duration;

  String _durationLabel() {
    if (duration.inHours >= 1) {
      return '${duration.inHours} ชั่วโมง';
    }
    return '${duration.inMinutes} นาที';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ตัวอย่างรางวัล',
            style: TextStyle(
              color: _kTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _RewardChip(
                icon: Icons.monetization_on_rounded,
                color: _kGold,
                label: '$rewardCoins เหรียญ',
              ),
              const SizedBox(width: 12),
              _RewardChip(
                icon: Icons.flash_on_rounded,
                color: const Color(0xFF4fc3f7),
                label: '$rewardXp XP',
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    color: _kTextDisabled,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _durationLabel(),
                    style: const TextStyle(
                      color: _kTextDisabled,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
