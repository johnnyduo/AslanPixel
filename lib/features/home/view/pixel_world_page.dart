import 'package:firebase_auth/firebase_auth.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:aslan_pixel/core/enums/agent_type.dart';
import 'package:aslan_pixel/data/services/cached_ai_service.dart';
import 'package:aslan_pixel/data/services/gemini_ai_service.dart';
import 'package:aslan_pixel/features/agents/bloc/agent_bloc.dart';
import 'package:aslan_pixel/features/agents/bloc/task_bloc.dart';
import 'package:aslan_pixel/features/agents/data/datasources/firestore_agent_datasource.dart';
import 'package:aslan_pixel/features/agents/data/datasources/firestore_agent_task_datasource.dart';
import 'package:aslan_pixel/features/agents/data/models/agent_model.dart'
    hide AgentStatus;
import 'package:aslan_pixel/features/agents/view/agent_dialogue_bubble.dart';
import 'package:aslan_pixel/features/agents/view/task_assignment_sheet.dart';
import 'package:aslan_pixel/features/home/bloc/pixel_world_bloc.dart';
import 'package:aslan_pixel/features/home/bloc/room_bloc.dart';
import 'package:aslan_pixel/features/home/bloc/room_event.dart';
import 'package:aslan_pixel/features/home/bloc/room_state.dart';
import 'package:aslan_pixel/features/home/data/datasources/firestore_room_datasource.dart';
import 'package:aslan_pixel/features/home/game/pixel_room_game.dart';
import 'package:aslan_pixel/features/home/view/room_3d_page.dart';
import 'package:aslan_pixel/features/home/view/room_item_picker.dart';
import 'package:aslan_pixel/features/home/game/npc_quotes.dart';
import 'package:aslan_pixel/shared/widgets/ready_to_collect_badge.dart';
import 'package:aslan_pixel/features/agents/view/agent_shop_page.dart';
import 'package:aslan_pixel/features/home/view/room_theme_shop_page.dart';
import 'package:aslan_pixel/shared/widgets/reward_popup.dart';

// ---------------------------------------------------------------------------
// Color constants
// ---------------------------------------------------------------------------

const _colorNavy = Color(0xFF0A1628);
const _colorNeonGreen = Color(0xFF00F5A0);
const _colorGold = Color(0xFFF5C518);
const _colorCyberPurple = Color(0xFF7B2FFF);
const _colorCyan = Color(0xFF00D9FF);

Color _agentChipColor(AgentType type) {
  switch (type) {
    case AgentType.analyst:
      return _colorNeonGreen;
    case AgentType.scout:
      return _colorGold;
    case AgentType.risk:
      return _colorCyberPurple;
    case AgentType.social:
      return _colorCyan;
  }
}

IconData _statusIcon(AgentStatus status) {
  switch (status) {
    case AgentStatus.idle:
      return Icons.pause_circle_outline;
    case AgentStatus.working:
      return Icons.run_circle_outlined;
    case AgentStatus.returning:
      return Icons.arrow_circle_down_outlined;
    case AgentStatus.celebrating:
      return Icons.celebration;
    case AgentStatus.fail:
      return Icons.error_outline;
  }
}

Color _statusIconColor(AgentStatus status) {
  switch (status) {
    case AgentStatus.idle:
      return Colors.grey;
    case AgentStatus.working:
      return _colorNeonGreen;
    case AgentStatus.returning:
      return _colorGold;
    case AgentStatus.celebrating:
      return _colorGold;
    case AgentStatus.fail:
      return Colors.redAccent;
  }
}

// ---------------------------------------------------------------------------
// PixelWorldPage
// ---------------------------------------------------------------------------

/// The pixel world screen — wraps [PixelWorldBloc] and embeds the Flame game.
class PixelWorldPage extends StatefulWidget {
  const PixelWorldPage({super.key});

  static const String routeName = '/pixel-world';

  @override
  State<PixelWorldPage> createState() => _PixelWorldPageState();
}

class _PixelWorldPageState extends State<PixelWorldPage>
    with WidgetsBindingObserver {
  late final TaskBloc _taskBloc;
  late final AgentBloc _agentBloc;
  late final RoomBloc _roomBloc;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _taskBloc = TaskBloc(repository: FirestoreAgentTaskDatasource());
    _agentBloc = AgentBloc(
      repository: FirestoreAgentDatasource(),
    );
    _roomBloc = RoomBloc(repository: FirestoreRoomDatasource());

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isNotEmpty) {
      _taskBloc.add(TaskWatchStarted(uid));
      _agentBloc.add(AgentWatchStarted(uid));
      _roomBloc.add(RoomLoadRequested(uid));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isNotEmpty) {
        _taskBloc.add(TasksSettleRequested(uid: uid));
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _taskBloc.close();
    _agentBloc.close();
    _roomBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PixelWorldBloc>(
          create: (_) => PixelWorldBloc(
            aiService: CachedAiService(GeminiAiService()),
          )..add(const PixelWorldStarted()),
        ),
        BlocProvider<TaskBloc>.value(value: _taskBloc),
        BlocProvider<AgentBloc>.value(value: _agentBloc),
        BlocProvider<RoomBloc>.value(value: _roomBloc),
      ],
      child: const _PixelWorldView(),
    );
  }
}

// ---------------------------------------------------------------------------
// _PixelWorldView
// ---------------------------------------------------------------------------

class _PixelWorldView extends StatefulWidget {
  const _PixelWorldView();

  @override
  State<_PixelWorldView> createState() => _PixelWorldViewState();
}

class _PixelWorldViewState extends State<_PixelWorldView> {
  PixelRoomGame? _game;

  // Dialogue state
  String? _dialogueText;
  AgentType? _dialogueAgentType;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isEnglish = Localizations.localeOf(context).languageCode == 'en';
    NpcQuotes.useEnglish = isEnglish;
  }

  void _handleAgentTap(BuildContext context, AgentType agentType) {
    context.read<PixelWorldBloc>().add(PixelWorldAgentTapped(agentType));
    _showAgentSheet(context, agentType);
  }

  void _showAgentSheet(BuildContext context, AgentType agentType) {
    final bloc = context.read<PixelWorldBloc>();
    final state = bloc.state;
    final status = state is PixelWorldLoaded
        ? state.agentStatuses[agentType] ?? AgentStatus.idle
        : AgentStatus.idle;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF12213A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AgentDetailSheet(
        agentType: agentType,
        agentStatus: status,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // ---- PixelWorldBloc listener ----
        BlocListener<PixelWorldBloc, PixelWorldState>(
          listener: (context, state) {
            if (state is PixelWorldLoaded && _game == null) {
              setState(() {
                _game = PixelRoomGame(
                  agentStatuses: state.agentStatuses,
                  onAgentTapped: (type) => _handleAgentTap(context, type),
                );
              });
            } else if (state is PixelWorldLoaded && _game != null) {
              _game!.updateAgentStatuses(state.agentStatuses);
            } else if (state is PixelWorldDialogueLoaded) {
              setState(() {
                _dialogueText = state.text;
                _dialogueAgentType = state.agentType;
              });
            }
          },
        ),
        // ---- TaskBloc listener — settle → AgentTaskCompleted + RewardPopup ----
        BlocListener<TaskBloc, TaskState>(
          listener: (context, state) {
            if (state is TaskSettledSuccess) {
              final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
              if (uid.isEmpty) return;

              for (final task in state.settledTasks) {
                context.read<AgentBloc>().add(
                      AgentTaskCompleted(
                        uid: uid,
                        agentId: task.agentId,
                        coinsEarned: task.actualReward ?? 0,
                      ),
                    );
              }

              if (state.settledTasks.isNotEmpty) {
                final summary = state.summary;
                final totalCoins = summary?.totalCoins ??
                    state.settledTasks.fold<int>(
                      0,
                      (sum, t) => sum + (t.actualReward ?? 0),
                    );
                final totalXp = summary?.totalXp ??
                    state.settledTasks.fold<int>(
                      0,
                      (sum, t) => sum + t.xpReward,
                    );
                // streakDays is not stored on the state — use 0 as default;
                // the calling site (TasksSettleRequested) may carry it.
                const streakDays = 0;

                showDialog<void>(
                  context: context,
                  barrierDismissible: false,
                  barrierColor: Colors.black54,
                  builder: (_) => RewardPopup(
                    coins: totalCoins,
                    xp: totalXp,
                    streakDays: streakDays,
                  ),
                );
              }
            }
          },
        ),
        // ---- RoomBloc listener — sync items into Flame game ----
        BlocListener<RoomBloc, RoomState>(
          listener: (context, state) {
            if (state is RoomLoaded && _game != null) {
              _game!.updateRoomItems(state.room.items);
            }
          },
        ),
      ],
      child: Container(
        color: _colorNavy,
        child: BlocBuilder<PixelWorldBloc, PixelWorldState>(
          builder: (context, state) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // ---- Game area (full screen, edge to edge) ----
                if (_game != null)
                  Positioned.fill(
                    child: GameWidget<PixelRoomGame>(game: _game!),
                  )
                else
                  const SizedBox.expand(),

                // ---- Loading overlay ----
                if (state is PixelWorldLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: _colorNeonGreen,
                      strokeWidth: 3,
                    ),
                  ),

                // ---- Error overlay ----
                if (state is PixelWorldError)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        state.message,
                        style: const TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                // ---- Agent status chips ----
                if (state is PixelWorldLoaded)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: MediaQuery.of(context).padding.bottom + 12,
                    child: _AgentStatusBar(
                      agentStatuses: state.agentStatuses,
                      onChipTap: (type) => _handleAgentTap(context, type),
                    ),
                  ),

                // ---- AI Dialogue bubble ----
                if (_dialogueText != null && _dialogueAgentType != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 100,
                    child: AgentDialogueBubble(
                      key: ValueKey('$_dialogueAgentType:$_dialogueText'),
                      text: _dialogueText!,
                      agentType: _dialogueAgentType!,
                    ),
                  ),

                // ---- Ready to collect badge ----
                // Shows when TaskLoaded has ≥1 complete task.
                BlocBuilder<TaskBloc, TaskState>(
                  builder: (context, taskState) {
                    final readyCount = taskState is TaskLoaded
                        ? taskState.tasks
                            .where((t) => t.isComplete)
                            .length
                        : 0;
                    if (readyCount == 0) return const SizedBox.shrink();
                    return Positioned(
                      top: MediaQuery.of(context).padding.top + 12,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: ReadyToCollectBadge(
                          count: readyCount,
                          onTap: () {
                            final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                            if (uid.isNotEmpty) {
                              context.read<TaskBloc>().add(
                                    TasksSettleRequested(uid: uid),
                                  );
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),

                // ---- Agent Shop FAB ----
                Positioned(
                  right: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 130,
                  child: FloatingActionButton.small(
                    heroTag: 'agent_shop_fab',
                    backgroundColor: _colorGold,
                    foregroundColor: _colorNavy,
                    tooltip: 'Agent Shop',
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        AgentShopPage.routeName,
                      );
                    },
                    child: const Icon(Icons.store_outlined, size: 20),
                  ),
                ),

                // ---- Room Theme Shop FAB ----
                Positioned(
                  right: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 180,
                  child: FloatingActionButton.small(
                    heroTag: 'room_theme_shop_fab',
                    backgroundColor: const Color(0xFF00D9FF),
                    foregroundColor: _colorNavy,
                    tooltip: 'Room Themes',
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        RoomThemeShopPage.routeName,
                      );
                    },
                    child: const Icon(Icons.wallpaper_outlined, size: 20),
                  ),
                ),

                // ---- 3D Room FAB ----
                Positioned(
                  right: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 230,
                  child: FloatingActionButton.small(
                    heroTag: 'room_3d_fab',
                    backgroundColor: const Color(0xFF00F5A0),
                    foregroundColor: _colorNavy,
                    tooltip: '3D Room',
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        Room3DPage.routeName,
                      );
                    },
                    child: const Icon(Icons.view_in_ar, size: 20),
                  ),
                ),

                // ---- Customize Room FAB ----
                Positioned(
                  right: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 80,
                  child: _CustomizeRoomFab(game: _game),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _AgentStatusBar
// ---------------------------------------------------------------------------

class _AgentStatusBar extends StatelessWidget {
  const _AgentStatusBar({
    required this.agentStatuses,
    required this.onChipTap,
  });

  final Map<AgentType, AgentStatus> agentStatuses;
  final void Function(AgentType) onChipTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: AgentType.values
            .map(
              (type) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _AgentChip(
                    agentType: type,
                    agentStatus:
                        agentStatuses[type] ?? AgentStatus.idle,
                    onTap: () => onChipTap(type),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _AgentChip
// ---------------------------------------------------------------------------

class _AgentChip extends StatelessWidget {
  const _AgentChip({
    required this.agentType,
    required this.agentStatus,
    required this.onTap,
  });

  final AgentType agentType;
  final AgentStatus agentStatus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final chipColor = _agentChipColor(agentType);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: chipColor.withValues(alpha: 30 / 255),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: chipColor.withValues(alpha: 120 / 255), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _statusIcon(agentStatus),
              size: 18,
              color: _statusIconColor(agentStatus),
            ),
            const SizedBox(height: 2),
            Text(
              agentType.displayName,
              style: TextStyle(
                color: chipColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              agentStatus.label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 9,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _AgentDetailSheet
// ---------------------------------------------------------------------------

class _AgentDetailSheet extends StatelessWidget {
  const _AgentDetailSheet({
    required this.agentType,
    required this.agentStatus,
  });

  final AgentType agentType;
  final AgentStatus agentStatus;

  @override
  Widget build(BuildContext context) {
    final chipColor = _agentChipColor(agentType);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Agent name
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: chipColor.withValues(alpha: 60 / 255),
                  child: Icon(
                    _statusIcon(agentStatus),
                    color: chipColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agentType.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      agentStatus.label,
                      style: TextStyle(
                        color: _statusIconColor(agentStatus),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Send on Mission button — Phase 3 stub
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: chipColor,
                  foregroundColor: _colorNavy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  final uid =
                      FirebaseAuth.instance.currentUser?.uid ?? '';
                  // Convert home AgentStatus → agent_model AgentStatus
                  // using the enum name as a stable string bridge.
                  final agentModelStatus =
                      AgentStatusValue.fromString(agentStatus.name);
                  final agent = AgentModel(
                    agentId: agentType.value,
                    type: agentType,
                    level: 1,
                    xp: 0,
                    status: agentModelStatus,
                  );
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => TaskAssignmentSheet(
                      uid: uid,
                      agent: agent,
                      bloc: TaskBloc(
                        repository: FirestoreAgentTaskDatasource(),
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Send on Mission',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _CustomizeRoomFab
// ---------------------------------------------------------------------------

/// Small floating action button that opens the [RoomItemPicker] bottom sheet.
///
/// Visible only when the Flame game has been created.
class _CustomizeRoomFab extends StatelessWidget {
  const _CustomizeRoomFab({required this.game});

  final PixelRoomGame? game;

  @override
  Widget build(BuildContext context) {
    if (game == null) return const SizedBox.shrink();

    return FloatingActionButton.small(
      heroTag: 'customize_room_fab',
      backgroundColor: _colorCyberPurple,
      foregroundColor: Colors.white,
      tooltip: 'ตกแต่งห้อง',
      onPressed: () {
        final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
        final roomBloc = context.read<RoomBloc>();
        showModalBottomSheet<void>(
          context: context,
          backgroundColor: const Color(0xFF0A1628),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => RoomItemPicker(
            uid: uid,
            bloc: roomBloc,
          ),
        );
      },
      child: const Icon(Icons.dashboard_customize_outlined, size: 20),
    );
  }
}
