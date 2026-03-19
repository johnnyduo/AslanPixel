import 'package:flutter_test/flutter_test.dart';

import 'package:aslan_pixel/core/enums/agent_type.dart';
import 'package:aslan_pixel/features/agents/data/models/agent_model.dart';

void main() {
  group('AgentModel — XP threshold getters', () {
    test('xpForNextLevel returns level * 1000', () {
      const agent = AgentModel(
        agentId: 'a1',
        type: AgentType.analyst,
        level: 3,
        xp: 1500,
        status: AgentStatus.idle,
      );
      expect(agent.xpForNextLevel, 3000);
    });

    test('xpForNextLevel at level 1 returns 1000', () {
      const agent = AgentModel(
        agentId: 'a1',
        type: AgentType.scout,
        level: 1,
        xp: 0,
        status: AgentStatus.idle,
      );
      expect(agent.xpForNextLevel, 1000);
    });

    test('xpForNextLevel at level 10 returns 10000', () {
      const agent = AgentModel(
        agentId: 'a1',
        type: AgentType.risk,
        level: 10,
        xp: 5000,
        status: AgentStatus.idle,
      );
      expect(agent.xpForNextLevel, 10000);
    });
  });

  group('AgentModel — levelProgress', () {
    test('levelProgress is 0.0 when xp is 0', () {
      const agent = AgentModel(
        agentId: 'a1',
        type: AgentType.analyst,
        level: 2,
        xp: 0,
        status: AgentStatus.idle,
      );
      expect(agent.levelProgress, 0.0);
    });

    test('levelProgress is 0.5 when xp is half of xpForNextLevel', () {
      const agent = AgentModel(
        agentId: 'a1',
        type: AgentType.analyst,
        level: 2,
        xp: 1000,
        status: AgentStatus.idle,
      );
      expect(agent.levelProgress, 0.5);
    });

    test('levelProgress handles xp exactly at threshold', () {
      const agent = AgentModel(
        agentId: 'a1',
        type: AgentType.analyst,
        level: 1,
        xp: 1000,
        status: AgentStatus.idle,
      );
      // 1000 % 1000 = 0, so progress wraps to 0.0 (ready for level up)
      expect(agent.levelProgress, 0.0);
    });

    test('levelProgress for level 5 with 3500 xp', () {
      const agent = AgentModel(
        agentId: 'a1',
        type: AgentType.social,
        level: 5,
        xp: 3500,
        status: AgentStatus.idle,
      );
      // 3500 % 5000 = 3500 / 5000 = 0.7
      expect(agent.levelProgress, 0.7);
    });
  });

  group('AgentModel — canLevelUp', () {
    test('canLevelUp is false when xp < xpForNextLevel', () {
      const agent = AgentModel(
        agentId: 'a1',
        type: AgentType.analyst,
        level: 3,
        xp: 2999,
        status: AgentStatus.idle,
      );
      expect(agent.canLevelUp, false);
    });

    test('canLevelUp is true when xp == xpForNextLevel', () {
      const agent = AgentModel(
        agentId: 'a1',
        type: AgentType.analyst,
        level: 3,
        xp: 3000,
        status: AgentStatus.idle,
      );
      expect(agent.canLevelUp, true);
    });

    test('canLevelUp is true when xp > xpForNextLevel', () {
      const agent = AgentModel(
        agentId: 'a1',
        type: AgentType.analyst,
        level: 2,
        xp: 5000,
        status: AgentStatus.idle,
      );
      expect(agent.canLevelUp, true);
    });

    test('canLevelUp is false for fresh level 1 agent', () {
      const agent = AgentModel(
        agentId: 'a1',
        type: AgentType.scout,
        level: 1,
        xp: 0,
        status: AgentStatus.idle,
      );
      expect(agent.canLevelUp, false);
    });

    test('canLevelUp is false at level 1 with 999 xp', () {
      const agent = AgentModel(
        agentId: 'a1',
        type: AgentType.scout,
        level: 1,
        xp: 999,
        status: AgentStatus.idle,
      );
      expect(agent.canLevelUp, false);
    });

    test('canLevelUp is true at level 1 with 1000 xp', () {
      const agent = AgentModel(
        agentId: 'a1',
        type: AgentType.scout,
        level: 1,
        xp: 1000,
        status: AgentStatus.idle,
      );
      expect(agent.canLevelUp, true);
    });
  });
}
