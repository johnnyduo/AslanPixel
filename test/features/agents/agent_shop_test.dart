import 'package:flutter_test/flutter_test.dart';

import 'package:aslan_pixel/core/enums/agent_type.dart';
import 'package:aslan_pixel/features/agents/data/agent_shop.dart';

void main() {
  group('kAgentShop catalog', () {
    test('has exactly 4 items', () {
      expect(kAgentShop.length, 4);
    });

    test('Analyst is free (price 0)', () {
      final analyst = kAgentShop.firstWhere(
        (i) => i.type == AgentType.analyst,
      );
      expect(analyst.price, 0);
    });

    test('Scout costs 200', () {
      final scout = kAgentShop.firstWhere(
        (i) => i.type == AgentType.scout,
      );
      expect(scout.price, 200);
    });

    test('Risk Guardian costs 500', () {
      final risk = kAgentShop.firstWhere(
        (i) => i.type == AgentType.risk,
      );
      expect(risk.price, 500);
    });

    test('Social Agent costs 800', () {
      final social = kAgentShop.firstWhere(
        (i) => i.type == AgentType.social,
      );
      expect(social.price, 800);
    });

    test('all items have non-empty nameTh', () {
      for (final item in kAgentShop) {
        expect(item.nameTh.isNotEmpty, isTrue,
            reason: '${item.nameEn} has empty nameTh');
      }
    });

    test('all items have non-empty descriptionTh', () {
      for (final item in kAgentShop) {
        expect(item.descriptionTh.isNotEmpty, isTrue,
            reason: '${item.nameEn} has empty descriptionTh');
      }
    });

    test('unlock levels are ascending', () {
      for (var i = 1; i < kAgentShop.length; i++) {
        expect(
          kAgentShop[i].unlockLevel,
          greaterThanOrEqualTo(kAgentShop[i - 1].unlockLevel),
          reason:
              '${kAgentShop[i].nameEn} unlockLevel should be >= ${kAgentShop[i - 1].nameEn}',
        );
      }
    });

    test('all AgentType values are represented', () {
      final shopTypes = kAgentShop.map((i) => i.type).toSet();
      for (final agentType in AgentType.values) {
        expect(shopTypes.contains(agentType), isTrue,
            reason: '$agentType not found in kAgentShop');
      }
    });

    test('all items have non-empty emoji', () {
      for (final item in kAgentShop) {
        expect(item.emoji.isNotEmpty, isTrue,
            reason: '${item.nameEn} has empty emoji');
      }
    });

    test('all items have non-empty nameEn', () {
      for (final item in kAgentShop) {
        expect(item.nameEn.isNotEmpty, isTrue);
      }
    });
  });
}
