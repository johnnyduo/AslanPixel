import 'package:flutter_test/flutter_test.dart';

import 'package:aslan_pixel/features/quests/engine/quest_generator.dart';

void main() {
  // ── Fixed reference date for deterministic tests ──────────────────────────
  final kDate = DateTime(2026, 3, 18);
  const kUid = 'uid_test_01';
  const kOtherUid = 'uid_test_99';

  // ── generateDailyQuests ──────────────────────────────────────────────────

  group('QuestGenerator.generateDailyQuests', () {
    test('generates exactly 3 quests', () {
      final quests = QuestGenerator.generateDailyQuests(kUid, kDate);
      expect(quests.length, 3);
    });

    test('same uid + date always produces the same 3 quests (deterministic)', () {
      final first = QuestGenerator.generateDailyQuests(kUid, kDate);
      final second = QuestGenerator.generateDailyQuests(kUid, kDate);
      expect(
        first.map((q) => q.questId).toList(),
        second.map((q) => q.questId).toList(),
      );
    });

    test('all quests have non-null actionType', () {
      final quests = QuestGenerator.generateDailyQuests(kUid, kDate);
      for (final q in quests) {
        expect(q.actionType, isNotNull,
            reason: 'quest ${q.questId} has null actionType');
      }
    });

    test('all quests expire exactly 24 hours after the generation date', () {
      final quests = QuestGenerator.generateDailyQuests(kUid, kDate);
      final expectedExpiry = DateTime(kDate.year, kDate.month, kDate.day)
          .add(const Duration(days: 1));
      for (final q in quests) {
        expect(q.expiresAt, isNotNull);
        expect(q.expiresAt, expectedExpiry,
            reason: 'quest ${q.questId} has wrong expiresAt');
      }
    });

    test('different uids generate different quest id sets', () {
      final forUid1 = QuestGenerator.generateDailyQuests(kUid, kDate);
      final forUid2 = QuestGenerator.generateDailyQuests(kOtherUid, kDate);
      final ids1 = forUid1.map((q) => q.questId).toSet();
      final ids2 = forUid2.map((q) => q.questId).toSet();
      // At least one quest id must differ (different seed → different shuffle)
      expect(ids1, isNot(equals(ids2)));
    });

    test('all quests have type "daily"', () {
      final quests = QuestGenerator.generateDailyQuests(kUid, kDate);
      for (final q in quests) {
        expect(q.type, 'daily');
      }
    });

    test('all quests start with progress 0 and completed false', () {
      final quests = QuestGenerator.generateDailyQuests(kUid, kDate);
      for (final q in quests) {
        expect(q.progress, 0);
        expect(q.completed, isFalse);
      }
    });

    test('all quests have target >= 1', () {
      final quests = QuestGenerator.generateDailyQuests(kUid, kDate);
      for (final q in quests) {
        expect(q.target, greaterThanOrEqualTo(1));
      }
    });

    test('all quests have non-empty objectiveTh', () {
      final quests = QuestGenerator.generateDailyQuests(kUid, kDate);
      for (final q in quests) {
        expect(q.objectiveTh, isNotEmpty);
      }
    });

    test('no duplicate quests in a single generation (unique actionTypes)', () {
      final quests = QuestGenerator.generateDailyQuests(kUid, kDate);
      final actionTypes = quests.map((q) => q.actionType).toSet();
      // 3 quests picked from 5 templates — all 3 should be distinct
      expect(actionTypes.length, 3);
    });

    test('actionType values are within the known valid set', () {
      const validActionTypes = {
        'agent_work',
        'market_news',
        'feed_post',
        'prediction',
        'plaza_visit',
      };
      final quests = QuestGenerator.generateDailyQuests(kUid, kDate);
      for (final q in quests) {
        expect(validActionTypes, contains(q.actionType));
      }
    });

    test('different dates for same uid generate different quests', () {
      final today = QuestGenerator.generateDailyQuests(kUid, kDate);
      final tomorrow =
          QuestGenerator.generateDailyQuests(kUid, kDate.add(const Duration(days: 1)));
      final todayIds = today.map((q) => q.questId).toSet();
      final tomorrowIds = tomorrow.map((q) => q.questId).toSet();
      expect(todayIds, isNot(equals(tomorrowIds)));
    });
  });

  // ── needsRefresh ─────────────────────────────────────────────────────────

  group('QuestGenerator.needsRefresh', () {
    test('returns true when lastGeneratedAt is null (never generated)', () {
      expect(QuestGenerator.needsRefresh(null), isTrue);
    });

    test('returns false for a timestamp from today', () {
      // Use DateTime.now() so it falls on today.
      final todayTimestamp = DateTime.now();
      expect(QuestGenerator.needsRefresh(todayTimestamp), isFalse);
    });

    test('returns true for a timestamp from yesterday', () {
      final yesterday =
          DateTime.now().subtract(const Duration(days: 1));
      expect(QuestGenerator.needsRefresh(yesterday), isTrue);
    });

    test('returns true for a timestamp from two days ago', () {
      final twoDaysAgo =
          DateTime.now().subtract(const Duration(days: 2));
      expect(QuestGenerator.needsRefresh(twoDaysAgo), isTrue);
    });

    test('returns true for a timestamp from a previous year', () {
      final lastYear = DateTime(2025, 3, 18);
      expect(QuestGenerator.needsRefresh(lastYear), isTrue);
    });

    test('returns false for a timestamp later the same day', () {
      // Use a fixed noon time on today's date to avoid midnight edge cases.
      final now = DateTime.now();
      final laterToday = DateTime(now.year, now.month, now.day, 23, 59);
      expect(QuestGenerator.needsRefresh(laterToday), isFalse);
    });

    test('returns false for a timestamp earlier the same day', () {
      final earlierToday =
          DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 0, 1);
      expect(QuestGenerator.needsRefresh(earlierToday), isFalse);
    });
  });
}
