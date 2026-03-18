import 'dart:math';

import 'package:aslan_pixel/features/quests/data/models/quest_model.dart';

/// Pure-Dart engine that generates deterministic daily quests.
///
/// No Firebase dependency — safe to use in unit tests.
class QuestGenerator {
  const QuestGenerator._();

  /// Generates exactly 3 daily quests for [uid] on [date].
  ///
  /// The selection is deterministic: the same uid + date always produces the
  /// same 3 quests, so quests can be re-generated client-side without a
  /// round-trip to Firestore.
  static List<QuestModel> generateDailyQuests(String uid, DateTime date) {
    final seed = '${uid}_${date.year}${date.month}${date.day}'.hashCode;
    final random = Random(seed);

    const templates = [
      _QuestTemplate(
        type: 'daily',
        objectiveTh: 'ส่ง Agent ทำงาน 1 ครั้ง',
        reward: {'coins': 20, 'xp': 10},
        target: 1,
      ),
      _QuestTemplate(
        type: 'daily',
        objectiveTh: 'อ่านข่าวตลาด 1 ครั้ง',
        reward: {'coins': 15, 'xp': 8},
        target: 1,
      ),
      _QuestTemplate(
        type: 'daily',
        objectiveTh: 'โพสต์ในฟีด 1 ครั้ง',
        reward: {'coins': 25, 'xp': 15},
        target: 1,
      ),
      _QuestTemplate(
        type: 'daily',
        objectiveTh: 'เข้าร่วม Prediction 1 ครั้ง',
        reward: {'coins': 30, 'xp': 20},
        target: 1,
      ),
      _QuestTemplate(
        type: 'daily',
        objectiveTh: 'ดู Plaza 1 ครั้ง',
        reward: {'coins': 10, 'xp': 5},
        target: 1,
      ),
    ];

    // Deterministic shuffle — pick 3.
    final picked = List<_QuestTemplate>.of(templates)..shuffle(random);

    final today = DateTime(date.year, date.month, date.day);
    final expiry = today.add(const Duration(days: 1));

    return picked.take(3).map((t) {
      return QuestModel(
        questId:
            '${uid}_daily_${t.objectiveTh.hashCode}_${today.millisecondsSinceEpoch}',
        type: t.type,
        objective: t.objectiveTh,
        objectiveTh: t.objectiveTh,
        reward: Map<String, dynamic>.from(t.reward),
        expiresAt: expiry,
        progress: 0,
        target: t.target,
        completed: false,
      );
    }).toList();
  }

  /// Returns true when daily quests should be regenerated.
  ///
  /// Refresh is needed when [lastGeneratedAt] is null (never generated) or
  /// falls on a calendar day different from today.
  static bool needsRefresh(DateTime? lastGeneratedAt) {
    if (lastGeneratedAt == null) return true;
    final now = DateTime.now();
    return lastGeneratedAt.day != now.day ||
        lastGeneratedAt.month != now.month ||
        lastGeneratedAt.year != now.year;
  }
}

// ── Internal template ─────────────────────────────────────────────────────────

class _QuestTemplate {
  const _QuestTemplate({
    required this.type,
    required this.objectiveTh,
    required this.reward,
    required this.target,
  });

  final String type;
  final String objectiveTh;
  final Map<String, dynamic> reward;
  final int target;
}
