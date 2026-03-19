// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';

import 'package:aslan_pixel/features/quests/engine/micro_quest_engine.dart';

void main() {
  final kNow = DateTime(2026, 3, 18, 14, 10);
  const kUid = 'test_user_123';

  // ── generateMicroQuest — basic behaviour ─────────────────────────────────

  group('MicroQuestEngine.generateMicroQuest', () {
    test('returns valid quest with financial theme', () {
      final quest = MicroQuestEngine.generateMicroQuest(kUid, kNow, 0);

      expect(quest, isNotNull);
      expect(quest!.questId, contains(kUid));
      expect(quest.questId, contains('micro'));
      expect(quest.objective, isNotEmpty);
      expect(quest.objectiveTh, isNotEmpty);
      expect(quest.reward, isNotEmpty);
      expect(quest.reward['coins'], isA<int>());
      expect(quest.reward['xp'], isA<int>());
      expect(quest.actionType, isNotNull);
    });

    test('returns null when completedThisHour >= 5 (max per hour)', () {
      final quest = MicroQuestEngine.generateMicroQuest(kUid, kNow, 5);
      expect(quest, isNull);
    });

    test('returns null when completedThisHour > 5', () {
      final quest = MicroQuestEngine.generateMicroQuest(kUid, kNow, 10);
      expect(quest, isNull);
    });

    test('generated quest has type "micro"', () {
      final quest = MicroQuestEngine.generateMicroQuest(kUid, kNow, 0);
      expect(quest!.type, 'micro');
    });

    test('quest expires within 1-3 minutes', () {
      final quest = MicroQuestEngine.generateMicroQuest(kUid, kNow, 0);
      final expiry = quest!.expiresAt!;
      final diff = expiry.difference(kNow);

      expect(diff.inMinutes, greaterThanOrEqualTo(1));
      expect(diff.inMinutes, lessThanOrEqualTo(3));
    });

    test('quest starts with progress 0 and target 1', () {
      final quest = MicroQuestEngine.generateMicroQuest(kUid, kNow, 0);
      expect(quest!.progress, 0);
      expect(quest.target, 1);
      expect(quest.completed, isFalse);
    });
  });

  // ── Deterministic generation ─────────────────────────────────────────────

  group('MicroQuestEngine — deterministic', () {
    test('same uid + time produces same quest', () {
      final q1 = MicroQuestEngine.generateMicroQuest(kUid, kNow, 0);
      final q2 = MicroQuestEngine.generateMicroQuest(kUid, kNow, 0);

      expect(q1!.objective, equals(q2!.objective));
      expect(q1.objectiveTh, equals(q2.objectiveTh));
      expect(q1.actionType, equals(q2.actionType));
    });

    test('different uid produces potentially different quest', () {
      final q1 = MicroQuestEngine.generateMicroQuest('user_a', kNow, 0);
      final q2 = MicroQuestEngine.generateMicroQuest('user_b', kNow, 0);

      // They CAN be the same by chance, but questId will always differ
      expect(q1!.questId, isNot(equals(q2!.questId)));
    });
  });

  // ── All 10 templates produce valid quests ────────────────────────────────

  group('MicroQuestEngine — all templates valid', () {
    test('all 10 templates produce valid quests across varied times', () {
      final seenObjectives = <String>{};

      // Generate quests at different 5-minute windows to cover all templates
      for (var minute = 0; minute < 60; minute += 5) {
        final time = DateTime(2026, 3, 18, 14, minute);
        // Try multiple uids to increase template coverage
        for (var i = 0; i < 10; i++) {
          final quest = MicroQuestEngine.generateMicroQuest(
            'user_$i',
            time,
            0,
          );
          expect(quest, isNotNull, reason: 'quest at minute $minute uid $i');
          expect(quest!.type, 'micro');
          expect(quest.objective, isNotEmpty);
          expect(quest.objectiveTh, isNotEmpty);
          expect(quest.reward['coins'], isA<int>());
          expect(quest.reward['xp'], isA<int>());
          expect(quest.reward['coins'], greaterThan(0));
          expect(quest.reward['xp'], greaterThan(0));
          expect(quest.actionType, isNotNull);
          seenObjectives.add(quest.objective);
        }
      }

      // We should have seen multiple unique objectives (at least 5 of the 10)
      expect(seenObjectives.length, greaterThanOrEqualTo(5));
    });
  });

  // ── shouldGenerate ───────────────────────────────────────────────────────

  group('MicroQuestEngine.shouldGenerate', () {
    test('returns true when lastMicroQuestAt is null', () {
      expect(MicroQuestEngine.shouldGenerate(null), isTrue);
    });

    test('returns true after 5+ minutes', () {
      final sixMinutesAgo = DateTime.now().subtract(Duration(minutes: 6));
      expect(MicroQuestEngine.shouldGenerate(sixMinutesAgo), isTrue);
    });

    test('returns true at exactly 5 minutes', () {
      final fiveMinutesAgo = DateTime.now().subtract(Duration(minutes: 5));
      expect(MicroQuestEngine.shouldGenerate(fiveMinutesAgo), isTrue);
    });

    test('returns false within 5 minutes', () {
      final twoMinutesAgo = DateTime.now().subtract(Duration(minutes: 2));
      expect(MicroQuestEngine.shouldGenerate(twoMinutesAgo), isFalse);
    });

    test('returns false when just generated', () {
      final justNow = DateTime.now();
      expect(MicroQuestEngine.shouldGenerate(justNow), isFalse);
    });
  });
}
