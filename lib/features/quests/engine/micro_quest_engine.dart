import 'dart:math';
import 'package:aslan_pixel/features/quests/data/models/quest_model.dart';

/// Generates micro-quests (1-5 minute challenges) for constant engagement.
///
/// Financial trading themed — every micro-quest relates to market activity.
class MicroQuestEngine {
  const MicroQuestEngine._();

  /// Generates a single micro-quest based on current time.
  /// Returns null if user has completed max micro-quests this hour (5 max).
  static QuestModel? generateMicroQuest(
      String uid, DateTime now, int completedThisHour) {
    if (completedThisHour >= 5) return null; // Max 5 per hour

    final seed = '${uid}_micro_${now.hour}_${now.minute ~/ 5}'.hashCode;
    final rng = Random(seed);
    final template = _templates[rng.nextInt(_templates.length)];

    return QuestModel(
      questId: '${uid}_micro_${now.millisecondsSinceEpoch}',
      type: 'micro',
      objective: template.objective,
      objectiveTh: template.objectiveTh,
      reward: Map<String, dynamic>.from(template.reward),
      expiresAt: now.add(template.duration),
      progress: 0,
      target: 1,
      completed: false,
      actionType: template.actionType,
    );
  }

  /// Returns true when a new micro-quest should appear (every 5 minutes).
  static bool shouldGenerate(DateTime? lastMicroQuestAt) {
    if (lastMicroQuestAt == null) return true;
    return DateTime.now().difference(lastMicroQuestAt).inMinutes >= 5;
  }

  static const _templates = [
    _MicroTemplate(
      objectiveTh: 'เช็คราคา BTC สักครู่',
      objective: 'Quick check BTC price',
      reward: {'coins': 5, 'xp': 3},
      duration: Duration(minutes: 2),
      actionType: 'price_check',
    ),
    _MicroTemplate(
      objectiveTh: 'ส่ง Agent วิจัยด่วน 1 ครั้ง',
      objective: 'Send agent on quick research',
      reward: {'coins': 8, 'xp': 5},
      duration: Duration(minutes: 3),
      actionType: 'quick_research',
    ),
    _MicroTemplate(
      objectiveTh: 'ดูพอร์ตโฟลิโอ 1 ครั้ง',
      objective: 'Review portfolio once',
      reward: {'coins': 5, 'xp': 3},
      duration: Duration(minutes: 2),
      actionType: 'portfolio_check',
    ),
    _MicroTemplate(
      objectiveTh: 'อ่าน AI Insight 1 รายการ',
      objective: 'Read 1 AI market insight',
      reward: {'coins': 10, 'xp': 5},
      duration: Duration(minutes: 3),
      actionType: 'read_insight',
    ),
    _MicroTemplate(
      objectiveTh: 'โหวต Bull/Bear 1 ครั้ง',
      objective: 'Cast 1 Bull/Bear vote',
      reward: {'coins': 8, 'xp': 5},
      duration: Duration(minutes: 2),
      actionType: 'bull_bear_vote',
    ),
    _MicroTemplate(
      objectiveTh: 'เยี่ยมชม Plaza ดูตลาด',
      objective: 'Visit plaza to check market',
      reward: {'coins': 5, 'xp': 3},
      duration: Duration(minutes: 2),
      actionType: 'plaza_market',
    ),
    _MicroTemplate(
      objectiveTh: 'วิเคราะห์กราฟ 30 วินาที',
      objective: 'Analyze chart for 30 seconds',
      reward: {'coins': 6, 'xp': 4},
      duration: Duration(minutes: 1),
      actionType: 'chart_analysis',
    ),
    _MicroTemplate(
      objectiveTh: 'เปิดดู Leaderboard ใครอันดับ 1',
      objective: 'Check leaderboard rankings',
      reward: {'coins': 5, 'xp': 3},
      duration: Duration(minutes: 2),
      actionType: 'leaderboard_check',
    ),
    _MicroTemplate(
      objectiveTh: 'ตรวจสอบ Streak ของวันนี้',
      objective: 'Check your daily streak',
      reward: {'coins': 3, 'xp': 2},
      duration: Duration(minutes: 1),
      actionType: 'streak_check',
    ),
    _MicroTemplate(
      objectiveTh: 'สำรวจหุ้น SET ตัวใหม่',
      objective: 'Explore a new SET stock',
      reward: {'coins': 7, 'xp': 4},
      duration: Duration(minutes: 3),
      actionType: 'stock_explore',
    ),
  ];
}

class _MicroTemplate {
  const _MicroTemplate({
    required this.objectiveTh,
    required this.objective,
    required this.reward,
    required this.duration,
    required this.actionType,
  });
  final String objectiveTh;
  final String objective;
  final Map<String, dynamic> reward;
  final Duration duration;
  final String actionType;
}
