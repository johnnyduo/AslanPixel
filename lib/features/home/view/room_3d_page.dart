import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import 'package:aslan_pixel/core/enums/agent_type.dart';
import 'package:aslan_pixel/features/home/view/model_showcase_page.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const _kBgColor = Color(0xFF0D1117);
const _kSurfaceColor = Color(0xFF161B22);
const _kNeonGreen = Color(0xFF00F5A0);
const _kGold = Color(0xFFF5C518);
const _kCyberPurple = Color(0xFF7B2FFF);

/// Maps each [AgentType] to a KayKit character GLB file.
const _kAgentCharacterMap = <AgentType, String>{
  AgentType.analyst: 'assets/3d/characters/Knight.glb',
  AgentType.scout: 'assets/3d/characters/Ranger.glb',
  AgentType.risk: 'assets/3d/characters/Barbarian.glb',
  AgentType.social: 'assets/3d/characters/Mage.glb',
};

const _kAgentCharacterLabels = <AgentType, String>{
  AgentType.analyst: 'Knight (Analyst)',
  AgentType.scout: 'Ranger (Scout)',
  AgentType.risk: 'Barbarian (Risk)',
  AgentType.social: 'Mage (Social)',
};

// ---------------------------------------------------------------------------
// Room3DPage
// ---------------------------------------------------------------------------

/// A 3D room viewer that displays the user's trading room character using
/// model_viewer_plus. Shows a KayKit character model that the user can rotate
/// and interact with.
class Room3DPage extends StatefulWidget {
  const Room3DPage({super.key, this.agentType});

  static const String routeName = '/room-3d';

  /// The active agent type — determines which 3D character is displayed.
  /// Defaults to [AgentType.analyst] if null.
  final AgentType? agentType;

  @override
  State<Room3DPage> createState() => _Room3DPageState();
}

class _Room3DPageState extends State<Room3DPage> {
  late AgentType _selectedAgent;

  @override
  void initState() {
    super.initState();
    _selectedAgent = widget.agentType ?? AgentType.analyst;
  }

  String get _modelSrc =>
      _kAgentCharacterMap[_selectedAgent] ??
      'assets/3d/characters/Knight.glb';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgColor,
      appBar: AppBar(
        backgroundColor: _kSurfaceColor,
        foregroundColor: Colors.white,
        title: const Text(
          '3D Trading Room',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view_rounded),
            tooltip: 'Model Showcase',
            onPressed: () {
              Navigator.of(context).pushNamed(ModelShowcasePage.routeName);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ---- Room background ----
          Expanded(
            child: Stack(
              children: [
                // Pixel art room background
                Positioned.fill(
                  child: Image.asset(
                    'assets/sprites/room_backgrounds/room_penthouse.png',
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.none,
                  ),
                ),
                // Subtle dark overlay
                Positioned.fill(
                  child: Container(
                    color: _kBgColor.withValues(alpha: 0.15),
                  ),
                ),
                // 3D Character — small, centered bottom
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 280,
                  child: ModelViewer(
                    key: ValueKey(_selectedAgent),
                    src: _modelSrc,
                    alt: _kAgentCharacterLabels[_selectedAgent] ?? 'Character',
                    ar: false,
                    autoRotate: true,
                    autoRotateDelay: 0,
                    cameraControls: true,
                    cameraOrbit: '0deg 80deg 2.5m',
                    backgroundColor: const Color(0x00000000),
                    exposure: 1.5,
                  ),
                ),
                // Agent name + type label
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _kBgColor.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _chipColor(_selectedAgent).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _chipColor(_selectedAgent),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _kAgentCharacterLabels[_selectedAgent] ?? '',
                          style: TextStyle(
                            color: _chipColor(_selectedAgent),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Lv 1 • ว่าง',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ---- Character selector chips ----
          Container(
            color: _kSurfaceColor,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Character',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: AgentType.values.map((type) {
                    final isSelected = type == _selectedAgent;
                    final chipColor = _chipColor(type);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedAgent = type),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? chipColor.withValues(alpha: 40 / 255)
                                  : Colors.white.withValues(alpha: 8 / 255),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? chipColor
                                    : Colors.white.withValues(alpha: 20 / 255),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _agentIcon(type),
                                  color: isSelected ? chipColor : Colors.white38,
                                  size: 20,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  type.displayName,
                                  style: TextStyle(
                                    color: isSelected
                                        ? chipColor
                                        : Colors.white54,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _chipColor(AgentType type) {
    switch (type) {
      case AgentType.analyst:
        return _kNeonGreen;
      case AgentType.scout:
        return _kGold;
      case AgentType.risk:
        return _kCyberPurple;
      case AgentType.social:
        return const Color(0xFF00D9FF);
    }
  }

  IconData _agentIcon(AgentType type) {
    switch (type) {
      case AgentType.analyst:
        return Icons.shield_outlined;
      case AgentType.scout:
        return Icons.explore_outlined;
      case AgentType.risk:
        return Icons.local_fire_department_outlined;
      case AgentType.social:
        return Icons.auto_awesome;
    }
  }
}
