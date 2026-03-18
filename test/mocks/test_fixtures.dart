import 'package:aslan_pixel/core/enums/agent_type.dart';
import 'package:aslan_pixel/features/agents/data/models/agent_model.dart';
import 'package:aslan_pixel/features/agents/engine/agent_task_model.dart';
import 'package:aslan_pixel/features/auth/data/models/user_model.dart';
import 'package:aslan_pixel/features/feed/data/models/feed_post_model.dart';
import 'package:aslan_pixel/features/finance/data/models/ai_insight_model.dart';
import 'package:aslan_pixel/features/finance/data/models/prediction_entry_model.dart';
import 'package:aslan_pixel/features/finance/data/models/prediction_event_model.dart';
import 'package:aslan_pixel/features/inventory/data/models/economy_model.dart';
import 'package:aslan_pixel/features/notifications/data/models/notification_model.dart';
import 'package:aslan_pixel/features/profile/data/models/badge_model.dart';
import 'package:aslan_pixel/features/quests/data/models/quest_model.dart';

// ── Dates ──────────────────────────────────────────────────────────────────────
final kNow = DateTime(2026, 3, 18, 12, 0);
final kFuture = kNow.add(const Duration(hours: 2));
final kPast = kNow.subtract(const Duration(hours: 2));

// ── UserModel ─────────────────────────────────────────────────────────────────
const kUser = UserModel(
  uid: 'uid_test_01',
  displayName: 'Test User',
  email: 'test@aslanpixel.com',
  photoUrl: null,
  avatarId: 'A1',
  onboardingComplete: true,
);

const kUserOnboarding = UserModel(
  uid: 'uid_test_02',
  displayName: 'New User',
  email: 'new@aslanpixel.com',
  onboardingComplete: false,
);

// ── AgentModel ────────────────────────────────────────────────────────────────
const kAnalystAgent = AgentModel(
  agentId: 'agent_analyst_01',
  type: AgentType.analyst,
  level: 3,
  xp: 2400,
  status: AgentStatus.idle,
);

const kScoutAgent = AgentModel(
  agentId: 'agent_scout_01',
  type: AgentType.scout,
  level: 1,
  xp: 0,
  status: AgentStatus.idle,
);

const kWorkingAgent = AgentModel(
  agentId: 'agent_analyst_02',
  type: AgentType.analyst,
  level: 2,
  xp: 1500,
  status: AgentStatus.working,
  activeTaskId: 'task_001',
);

// ── AgentTask ─────────────────────────────────────────────────────────────────
AgentTask kPendingTask({DateTime? completesAt}) => AgentTask(
      taskId: 'task_basic_001',
      agentId: 'agent_analyst_01',
      agentType: AgentType.analyst,
      taskType: TaskType.research,
      tier: TaskTier.basic,
      startedAt: kPast,
      completesAt: completesAt ?? kFuture,
      baseReward: 10,
      xpReward: 5,
      isSettled: false,
      actualReward: null,
    );

AgentTask kCompletedTask() => kPendingTask(completesAt: kPast);

AgentTask kSettledTask() => AgentTask(
      taskId: 'task_basic_settled',
      agentId: 'agent_analyst_01',
      agentType: AgentType.analyst,
      taskType: TaskType.research,
      tier: TaskTier.basic,
      startedAt: kPast.subtract(const Duration(hours: 1)),
      completesAt: kPast,
      baseReward: 10,
      xpReward: 5,
      isSettled: true,
      actualReward: 11,
    );

// ── EconomyModel ──────────────────────────────────────────────────────────────
EconomyModel kEconomy({int coins = 500, int xp = 2000}) => EconomyModel(
      coins: coins,
      xp: xp,
      unlockPoints: 10,
      lastUpdated: kNow,
    );

// ── QuestModel ────────────────────────────────────────────────────────────────
QuestModel kDailyQuest({int progress = 0, bool completed = false}) => QuestModel(
      questId: 'daily_send_agent_2026-03-18',
      type: 'daily',
      objective: 'Send an agent on a mission',
      objectiveTh: 'ส่งตัวแทนไปทำภารกิจ',
      reward: const {'coins': 20, 'xp': 10},
      progress: progress,
      target: 1,
      completed: completed,
      expiresAt: kFuture,
    );

QuestModel kCompletedQuest() => kDailyQuest(progress: 1, completed: true);

// ── FeedPostModel ─────────────────────────────────────────────────────────────
FeedPostModel kFeedPost({String postId = 'post_001'}) => FeedPostModel(
      postId: postId,
      type: 'user',
      authorUid: 'uid_test_01',
      content: 'Market looks bullish today!',
      contentTh: 'ตลาดดูกระทิงวันนี้!',
      metadata: const {},
      createdAt: kNow,
      reactions: const {'🔥': 5, '❤️': 2},
    );

// ── PredictionEventModel ──────────────────────────────────────────────────────
PredictionEventModel kPredictionEvent() => PredictionEventModel(
      eventId: 'event_ptt_001',
      symbol: 'PTT',
      title: 'PTT above 35 by end of day',
      titleTh: 'PTT จะปิดเกิน 35 บาทวันนี้',
      options: const [
        PredictionOption(optionId: 'yes', label: 'Yes', labelTh: 'ใช่'),
        PredictionOption(optionId: 'no', label: 'No', labelTh: 'ไม่'),
      ],
      coinCost: 10,
      settlementAt: kFuture,
      settlementRule: 'above',
      status: 'open',
      createdAt: kPast,
    );

PredictionEntryModel kPredictionEntry() => PredictionEntryModel(
      entryId: 'entry_001',
      eventId: 'event_ptt_001',
      uid: 'uid_test_01',
      selectedOptionId: 'yes',
      coinStaked: 10,
      enteredAt: kNow,
      result: null,
      rewardGranted: 0,
    );

// ── AiInsightModel ────────────────────────────────────────────────────────────
AiInsightModel kAiInsight({bool expired = false}) => AiInsightModel(
      insightId: 'insight_001',
      uid: 'uid_test_01',
      type: 'market_summary',
      content: 'Market is trending upward with strong volume.',
      contentTh: 'ตลาดมีแนวโน้มขาขึ้นพร้อมปริมาณซื้อขายสูง',
      modelUsed: 'gemini-2.0-flash-lite',
      generatedAt: kNow,
      expiresAt: expired ? kPast : kFuture,
    );

// ── NotificationModel ─────────────────────────────────────────────────────────
NotificationModel kNotification({bool isRead = false}) => NotificationModel(
      notifId: 'notif_001',
      type: 'agent_returned',
      title: 'Agent Returned',
      titleTh: 'ตัวแทนกลับมาแล้ว',
      body: 'Your analyst has completed the mission.',
      bodyTh: 'นักวิเคราะห์ของคุณทำภารกิจเสร็จแล้ว',
      isRead: isRead,
      createdAt: kNow,
    );

// ── BadgeModel ────────────────────────────────────────────────────────────────
BadgeModel kBadge({bool isEarned = true}) => BadgeModel(
      badgeId: 'first_mission',
      name: 'First Mission',
      nameTh: 'ภารกิจแรก',
      description: 'Complete your first agent task',
      descriptionTh: 'ทำภารกิจตัวแทนครั้งแรก',
      iconEmoji: '🎯',
      category: 'game',
      isEarned: isEarned,
      earnedAt: isEarned ? kNow : null,
    );
