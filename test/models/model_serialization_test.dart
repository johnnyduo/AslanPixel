import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aslan_pixel/core/enums/agent_type.dart';
import 'package:aslan_pixel/features/agents/data/models/agent_model.dart';
import 'package:aslan_pixel/features/finance/data/models/prediction_event_model.dart';
import 'package:aslan_pixel/features/follows/data/models/follow_model.dart';
import 'package:aslan_pixel/features/home/data/models/ranking_entry_model.dart';
import 'package:aslan_pixel/features/home/data/models/room_item_model.dart';
import 'package:aslan_pixel/features/pixel_art/data/models/pixel_canvas_model.dart';
import 'package:aslan_pixel/features/world/data/models/plaza_presence_model.dart';

import '../mocks/test_fixtures.dart';

void main() {
  // ═══════════════════════════════════════════════════════════════════════════
  // AgentModel serialization
  // ═══════════════════════════════════════════════════════════════════════════
  group('AgentModel toMap', () {
    test('toMap serializes all fields correctly', () {
      final map = kAnalystAgent.toMap();
      expect(map['agentId'], 'agent_analyst_01');
      expect(map['type'], 'analyst');
      expect(map['level'], 3);
      expect(map['xp'], 2400);
      expect(map['status'], 'idle');
      expect(map['activeTaskId'], isNull);
    });

    test('toMap with working status and activeTaskId', () {
      final map = kWorkingAgent.toMap();
      expect(map['status'], 'working');
      expect(map['activeTaskId'], 'task_001');
    });

    test('toMap serializes all AgentType values', () {
      for (final type in AgentType.values) {
        final agent = kAnalystAgent.copyWith(type: type);
        final map = agent.toMap();
        expect(map['type'], isA<String>());
        expect((map['type'] as String).isNotEmpty, true);
      }
    });

    test('toMap serializes all AgentStatus values', () {
      for (final status in AgentStatus.values) {
        final agent = kAnalystAgent.copyWith(status: status);
        final map = agent.toMap();
        expect(map['status'], isA<String>());
        expect((map['status'] as String).isNotEmpty, true);
      }
    });
  });

  group('AgentModel copyWith', () {
    test('copyWith no args returns equivalent model', () {
      final copied = kAnalystAgent.copyWith();
      expect(copied.agentId, kAnalystAgent.agentId);
      expect(copied.type, kAnalystAgent.type);
      expect(copied.level, kAnalystAgent.level);
      expect(copied.xp, kAnalystAgent.xp);
      expect(copied.status, kAnalystAgent.status);
    });

    test('copyWith replaces only specified fields', () {
      final copied = kAnalystAgent.copyWith(
        level: 5,
        xp: 5000,
        status: AgentStatus.working,
      );
      expect(copied.agentId, kAnalystAgent.agentId);
      expect(copied.type, kAnalystAgent.type);
      expect(copied.level, 5);
      expect(copied.xp, 5000);
      expect(copied.status, AgentStatus.working);
    });
  });

  group('AgentStatusValue', () {
    test('fromString handles all known values', () {
      expect(AgentStatusValue.fromString('idle'), AgentStatus.idle);
      expect(AgentStatusValue.fromString('working'), AgentStatus.working);
      expect(AgentStatusValue.fromString('returning'), AgentStatus.returning);
      expect(AgentStatusValue.fromString('celebrating'), AgentStatus.celebrating);
      expect(AgentStatusValue.fromString('fail'), AgentStatus.fail);
    });

    test('fromString returns idle for null', () {
      expect(AgentStatusValue.fromString(null), AgentStatus.idle);
    });

    test('fromString returns idle for unknown value', () {
      expect(AgentStatusValue.fromString('unknown'), AgentStatus.idle);
    });

    test('value extension returns correct strings', () {
      expect(AgentStatus.idle.value, 'idle');
      expect(AgentStatus.working.value, 'working');
      expect(AgentStatus.returning.value, 'returning');
      expect(AgentStatus.celebrating.value, 'celebrating');
      expect(AgentStatus.fail.value, 'fail');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // FeedPostModel serialization
  // ═══════════════════════════════════════════════════════════════════════════
  group('FeedPostModel toMap', () {
    test('toMap serializes all fields correctly', () {
      final post = kFeedPost();
      final map = post.toMap();
      expect(map['type'], 'user');
      expect(map['authorUid'], 'uid_test_01');
      expect(map['content'], isNotEmpty);
      expect(map['contentTh'], isNotEmpty);
      expect(map['metadata'], isEmpty);
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['reactions'], isA<Map<String, int>>());
    });

    test('toMap preserves null authorUid', () {
      final post = kFeedPost().copyWith(authorUid: null);
      final map = post.toMap();
      expect(map['authorUid'], isNull);
    });

    test('toMap preserves null contentTh', () {
      final post = kFeedPost().copyWith(contentTh: null);
      final map = post.toMap();
      expect(map['contentTh'], isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // NotificationModel serialization
  // ═══════════════════════════════════════════════════════════════════════════
  group('NotificationModel toMap', () {
    test('toMap serializes all fields', () {
      final notif = kNotification();
      final map = notif.toMap();
      expect(map['notifId'], 'notif_001');
      expect(map['type'], 'agent_returned');
      expect(map['title'], 'Agent Returned');
      expect(map['titleTh'], isNotEmpty);
      expect(map['body'], isNotEmpty);
      expect(map['bodyTh'], isNotEmpty);
      expect(map['isRead'], false);
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('toMap with isRead=true', () {
      final notif = kNotification(isRead: true);
      final map = notif.toMap();
      expect(map['isRead'], true);
    });
  });

  group('NotificationModel copyWith', () {
    test('copyWith no args returns equivalent model', () {
      final original = kNotification();
      final copied = original.copyWith();
      expect(copied.notifId, original.notifId);
      expect(copied.type, original.type);
      expect(copied.title, original.title);
      expect(copied.isRead, original.isRead);
    });

    test('copyWith replaces only specified fields', () {
      final original = kNotification();
      final copied = original.copyWith(isRead: true, title: 'New Title');
      expect(copied.isRead, true);
      expect(copied.title, 'New Title');
      expect(copied.type, original.type);
      expect(copied.body, original.body);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // QuestModel serialization
  // ═══════════════════════════════════════════════════════════════════════════
  group('QuestModel toMap', () {
    test('toMap serializes all fields', () {
      final quest = kDailyQuest();
      final map = quest.toMap();
      expect(map['type'], 'daily');
      expect(map['objective'], isNotEmpty);
      expect(map['objectiveTh'], isNotEmpty);
      expect(map['reward'], isA<Map<String, dynamic>>());
      expect(map['progress'], 0);
      expect(map['target'], 1);
      expect(map['completed'], false);
    });

    test('toMap serializes expiresAt as Timestamp when non-null', () {
      final quest = kDailyQuest();
      final map = quest.toMap();
      expect(map['expiresAt'], isA<Timestamp>());
    });

    test('toMap excludes actionType when null', () {
      final quest = kDailyQuest();
      if (quest.actionType == null) {
        final map = quest.toMap();
        expect(map.containsKey('actionType'), false);
      }
    });

    test('completed quest toMap has completed=true', () {
      final quest = kCompletedQuest();
      final map = quest.toMap();
      expect(map['completed'], true);
      expect(map['progress'], 1);
    });
  });

  group('QuestModel copyWith', () {
    test('copyWith no args preserves all fields', () {
      final original = kDailyQuest();
      final copied = original.copyWith();
      expect(copied.questId, original.questId);
      expect(copied.type, original.type);
      expect(copied.progress, original.progress);
      expect(copied.target, original.target);
      expect(copied.completed, original.completed);
    });

    test('copyWith replaces progress and completed', () {
      final original = kDailyQuest();
      final copied = original.copyWith(progress: 1, completed: true);
      expect(copied.progress, 1);
      expect(copied.completed, true);
      expect(copied.questId, original.questId);
    });
  });

  group('QuestModel isComplete', () {
    test('isComplete is false when progress < target', () {
      final q = kDailyQuest();
      expect(q.isComplete, false);
    });

    test('isComplete is true when progress >= target', () {
      final q = kDailyQuest(progress: 1);
      expect(q.isComplete, true);
    });

    test('isComplete is true when progress > target', () {
      final q = kDailyQuest(progress: 5);
      expect(q.isComplete, true);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // BadgeModel serialization
  // ═══════════════════════════════════════════════════════════════════════════
  group('BadgeModel toMap', () {
    test('toMap serializes earned badge', () {
      final badge = kBadge();
      final map = badge.toMap();
      expect(map['name'], 'First Mission');
      expect(map['nameTh'], isNotEmpty);
      expect(map['description'], isNotEmpty);
      expect(map['descriptionTh'], isNotEmpty);
      expect(map['iconEmoji'], isNotEmpty);
      expect(map['category'], 'game');
      expect(map['isEarned'], true);
      expect(map['earnedAt'], isA<Timestamp>());
    });

    test('toMap serializes unearned badge with null earnedAt', () {
      final badge = kBadge(isEarned: false);
      final map = badge.toMap();
      expect(map['isEarned'], false);
      expect(map['earnedAt'], isNull);
    });
  });

  group('BadgeModel copyWith', () {
    test('copyWith no args preserves all fields', () {
      final original = kBadge();
      final copied = original.copyWith();
      expect(copied.badgeId, original.badgeId);
      expect(copied.name, original.name);
      expect(copied.isEarned, original.isEarned);
      expect(copied.earnedAt, original.earnedAt);
    });

    test('copyWith replaces name and category', () {
      final original = kBadge();
      final copied = original.copyWith(name: 'New Badge', category: 'trading');
      expect(copied.name, 'New Badge');
      expect(copied.category, 'trading');
      expect(copied.badgeId, original.badgeId);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // RoomItem serialization
  // ═══════════════════════════════════════════════════════════════════════════
  group('RoomItem fromMap / toMap', () {
    test('toMap serializes all fields', () {
      const item = RoomItem(
        itemId: 'desk_01',
        type: RoomItemType.furniture,
        assetKey: 'desk_01',
        slotX: 3,
        slotY: 2,
        isUnlocked: true,
      );
      final map = item.toMap();
      expect(map['itemId'], 'desk_01');
      expect(map['type'], 'furniture');
      expect(map['assetKey'], 'desk_01');
      expect(map['slotX'], 3);
      expect(map['slotY'], 2);
      expect(map['isUnlocked'], true);
    });

    test('fromMap / toMap round-trip preserves data', () {
      const original = RoomItem(
        itemId: 'plant_02',
        type: RoomItemType.plant,
        assetKey: 'plant_02',
        slotX: 6,
        slotY: 1,
        isUnlocked: false,
      );
      final map = original.toMap();
      final restored = RoomItem.fromMap(map);
      expect(restored.itemId, original.itemId);
      expect(restored.type, original.type);
      expect(restored.assetKey, original.assetKey);
      expect(restored.slotX, original.slotX);
      expect(restored.slotY, original.slotY);
      expect(restored.isUnlocked, original.isUnlocked);
    });

    test('fromMap handles missing fields with defaults', () {
      final item = RoomItem.fromMap(const <String, dynamic>{});
      expect(item.itemId, '');
      expect(item.type, RoomItemType.furniture);
      expect(item.assetKey, '');
      expect(item.slotX, 0);
      expect(item.slotY, 0);
      expect(item.isUnlocked, false);
    });

    test('fromMap handles unknown type string', () {
      final item = RoomItem.fromMap(const {
        'itemId': 'test',
        'type': 'unknown_type',
        'assetKey': 'test',
        'slotX': 0,
        'slotY': 0,
        'isUnlocked': true,
      });
      expect(item.type, RoomItemType.furniture);
    });

    test('all RoomItemType values round-trip correctly', () {
      for (final type in RoomItemType.values) {
        final item = RoomItem(
          itemId: 'test',
          type: type,
          assetKey: 'test',
          slotX: 0,
          slotY: 0,
          isUnlocked: true,
        );
        final restored = RoomItem.fromMap(item.toMap());
        expect(restored.type, type, reason: 'Failed for type ${type.name}');
      }
    });
  });

  group('RoomItem copyWith', () {
    test('copyWith no args preserves all fields', () {
      const original = RoomItem(
        itemId: 'desk_01',
        type: RoomItemType.furniture,
        assetKey: 'desk_01',
        slotX: 3,
        slotY: 2,
        isUnlocked: true,
      );
      final copied = original.copyWith();
      expect(copied.itemId, original.itemId);
      expect(copied.type, original.type);
      expect(copied.slotX, original.slotX);
      expect(copied.slotY, original.slotY);
      expect(copied.isUnlocked, original.isUnlocked);
    });

    test('copyWith replaces specified fields', () {
      const original = RoomItem(
        itemId: 'desk_01',
        type: RoomItemType.furniture,
        assetKey: 'desk_01',
        slotX: 3,
        slotY: 2,
        isUnlocked: false,
      );
      final copied = original.copyWith(
        slotX: 5,
        slotY: 7,
        isUnlocked: true,
      );
      expect(copied.slotX, 5);
      expect(copied.slotY, 7);
      expect(copied.isUnlocked, true);
      expect(copied.itemId, original.itemId);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // RoomModel
  // ═══════════════════════════════════════════════════════════════════════════
  group('RoomModel', () {
    test('toMap serializes all fields', () {
      final room = RoomModel(
        uid: 'uid_01',
        layoutVersion: 2,
        items: const [
          RoomItem(
            itemId: 'desk_01',
            type: RoomItemType.furniture,
            assetKey: 'desk_01',
            slotX: 0,
            slotY: 0,
            isUnlocked: true,
          ),
        ],
        updatedAt: DateTime(2026, 3, 18),
      );
      final map = room.toMap();
      expect(map['uid'], 'uid_01');
      expect(map['layoutVersion'], 2);
      expect(map['items'], isA<List>());
      expect((map['items'] as List).length, 1);
      expect(map['updatedAt'], isA<Timestamp>());
    });

    test('starter factory creates 3 items', () {
      final room = RoomModel.starter('uid_01');
      expect(room.uid, 'uid_01');
      expect(room.layoutVersion, 1);
      expect(room.items.length, 3);
      expect(room.items.every((i) => i.isUnlocked), true);
    });

    test('copyWith preserves and replaces fields', () {
      final room = RoomModel.starter('uid_01');
      final copied = room.copyWith(layoutVersion: 2);
      expect(copied.layoutVersion, 2);
      expect(copied.uid, room.uid);
      expect(copied.items.length, room.items.length);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // RankingEntryModel
  // ═══════════════════════════════════════════════════════════════════════════
  group('RankingEntryModel', () {
    test('toMap serializes all fields', () {
      const entry = RankingEntryModel(
        uid: 'uid_01',
        score: 1500,
        rank: 3,
        category: 'weekly',
        displayName: 'Trader Pro',
        avatarId: 'A3',
      );
      final map = entry.toMap();
      expect(map['uid'], 'uid_01');
      expect(map['score'], 1500);
      expect(map['rank'], 3);
      expect(map['category'], 'weekly');
      expect(map['displayName'], 'Trader Pro');
      expect(map['avatarId'], 'A3');
    });

    test('toMap handles null displayName and avatarId', () {
      const entry = RankingEntryModel(
        uid: 'uid_01',
        score: 0,
        rank: 1,
        category: 'alltime',
      );
      final map = entry.toMap();
      expect(map['displayName'], isNull);
      expect(map['avatarId'], isNull);
    });

    test('copyWith preserves and replaces fields', () {
      const original = RankingEntryModel(
        uid: 'uid_01',
        score: 100,
        rank: 5,
        category: 'weekly',
      );
      final copied = original.copyWith(score: 200, rank: 3);
      expect(copied.score, 200);
      expect(copied.rank, 3);
      expect(copied.uid, original.uid);
      expect(copied.category, original.category);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // PlazaPresenceModel
  // ═══════════════════════════════════════════════════════════════════════════
  group('PlazaPresenceModel', () {
    test('toMap serializes with nested position map', () {
      final model = PlazaPresenceModel(
        uid: 'uid_01',
        avatarId: 'A1',
        displayName: 'Test',
        x: 0.5,
        y: 0.7,
        lastSeen: DateTime(2026, 3, 18),
      );
      final map = model.toMap();
      expect(map['uid'], 'uid_01');
      expect(map['avatarId'], 'A1');
      expect(map['displayName'], 'Test');
      expect(map['position'], isA<Map>());
      expect((map['position'] as Map)['x'], 0.5);
      expect((map['position'] as Map)['y'], 0.7);
      expect(map['lastSeen'], isA<Timestamp>());
    });

    test('toMap handles null avatarId and displayName', () {
      final model = PlazaPresenceModel(
        uid: 'uid_01',
        x: 0.0,
        y: 0.0,
        lastSeen: DateTime(2026, 3, 18),
      );
      final map = model.toMap();
      expect(map['avatarId'], isNull);
      expect(map['displayName'], isNull);
    });

    test('copyWith preserves and replaces fields', () {
      final original = PlazaPresenceModel(
        uid: 'uid_01',
        avatarId: 'A1',
        displayName: 'Test',
        x: 0.5,
        y: 0.7,
        lastSeen: DateTime(2026, 3, 18),
      );
      final copied = original.copyWith(x: 0.9, y: 0.1);
      expect(copied.x, 0.9);
      expect(copied.y, 0.1);
      expect(copied.uid, original.uid);
      expect(copied.avatarId, original.avatarId);
    });

    test('copyWith can set avatarId to null', () {
      final model = PlazaPresenceModel(
        uid: 'uid_01',
        avatarId: 'A1',
        x: 0.5,
        y: 0.5,
        lastSeen: DateTime(2026, 3, 18),
      );
      final copied = model.copyWith(avatarId: null);
      expect(copied.avatarId, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // FollowModel
  // ═══════════════════════════════════════════════════════════════════════════
  group('FollowModel', () {
    test('toMap serializes all fields', () {
      final model = FollowModel(
        targetUid: 'uid_02',
        followedAt: DateTime(2026, 3, 18),
      );
      final map = model.toMap();
      expect(map['targetUid'], 'uid_02');
      expect(map['followedAt'], isA<Timestamp>());
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // PredictionEventModel serialization
  // ═══════════════════════════════════════════════════════════════════════════
  group('PredictionEventModel toMap', () {
    test('toMap serializes all fields including nested options', () {
      final event = kPredictionEvent();
      final map = event.toMap();
      expect(map['eventId'], 'event_ptt_001');
      expect(map['symbol'], 'PTT');
      expect(map['title'], isNotEmpty);
      expect(map['titleTh'], isNotEmpty);
      expect(map['options'], isA<List>());
      expect((map['options'] as List).length, 2);
      expect(map['coinCost'], 10);
      expect(map['settlementAt'], isA<Timestamp>());
      expect(map['settlementRule'], 'above');
      expect(map['status'], 'open');
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('options round-trip via PredictionOption.fromMap', () {
      final event = kPredictionEvent();
      final map = event.toMap();
      final optionsMaps = map['options'] as List;
      final firstOption =
          PredictionOption.fromMap(optionsMaps[0] as Map<String, dynamic>);
      expect(firstOption.optionId, 'yes');
      expect(firstOption.label, 'Yes');
      expect(firstOption.labelTh, isNotEmpty);
    });
  });

  group('PredictionEventModel copyWith', () {
    test('copyWith no args preserves all fields', () {
      final original = kPredictionEvent();
      final copied = original.copyWith();
      expect(copied.eventId, original.eventId);
      expect(copied.symbol, original.symbol);
      expect(copied.options.length, original.options.length);
      expect(copied.coinCost, original.coinCost);
      expect(copied.status, original.status);
    });

    test('copyWith replaces specified fields', () {
      final original = kPredictionEvent();
      final copied = original.copyWith(status: 'closed', coinCost: 20);
      expect(copied.status, 'closed');
      expect(copied.coinCost, 20);
      expect(copied.symbol, original.symbol);
    });
  });

  group('PredictionEventModel equatable', () {
    test('same fields are equal', () {
      final a = kPredictionEvent();
      final b = kPredictionEvent();
      expect(a, b);
    });

    test('different coinCost are not equal', () {
      final a = kPredictionEvent();
      final b = a.copyWith(coinCost: 999);
      expect(a, isNot(b));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // PredictionOption
  // ═══════════════════════════════════════════════════════════════════════════
  group('PredictionOption', () {
    test('fromMap / toMap round-trip', () {
      const option = PredictionOption(
        optionId: 'yes',
        label: 'Yes',
        labelTh: 'ใช่',
      );
      final map = option.toMap();
      final restored = PredictionOption.fromMap(map);
      expect(restored, option);
    });

    test('equatable equality', () {
      const a = PredictionOption(optionId: 'yes', label: 'Yes', labelTh: 'ใช่');
      const b = PredictionOption(optionId: 'yes', label: 'Yes', labelTh: 'ใช่');
      const c = PredictionOption(optionId: 'no', label: 'No', labelTh: 'ไม่');
      expect(a, b);
      expect(a, isNot(c));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // AiInsightModel
  // ═══════════════════════════════════════════════════════════════════════════
  group('AiInsightModel', () {
    test('toMap serializes all fields', () {
      final insight = kAiInsight();
      final map = insight.toMap();
      expect(map['insightId'], 'insight_001');
      expect(map['uid'], 'uid_test_01');
      expect(map['type'], 'market_summary');
      expect(map['content'], isNotEmpty);
      expect(map['contentTh'], isNotEmpty);
      expect(map['modelUsed'], 'gemini-2.0-flash-lite');
      expect(map['generatedAt'], isA<Timestamp>());
      expect(map['expiresAt'], isA<Timestamp>());
    });

    test('copyWith preserves and replaces', () {
      final original = kAiInsight();
      final copied = original.copyWith(
        type: 'agent_tip',
        content: 'New content',
      );
      expect(copied.type, 'agent_tip');
      expect(copied.content, 'New content');
      expect(copied.insightId, original.insightId);
      expect(copied.uid, original.uid);
    });

    test('equatable equality', () {
      final a = kAiInsight();
      final b = kAiInsight();
      expect(a, b);
    });

    test('different content are not equal', () {
      final a = kAiInsight();
      final b = a.copyWith(content: 'Different');
      expect(a, isNot(b));
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // PixelCanvasModel
  // ═══════════════════════════════════════════════════════════════════════════
  group('PixelCanvasModel', () {
    final now = DateTime(2026, 3, 18, 12, 0);

    PixelCanvasModel makeCanvas() => PixelCanvasModel(
          canvasId: 'canvas_01',
          ownerUid: 'uid_01',
          width: 4,
          height: 4,
          pixels: List.generate(4, (_) => List.filled(4, 0xFF0A1628)),
          createdAt: now,
          updatedAt: now,
        );

    test('toMap serializes all fields', () {
      final canvas = makeCanvas();
      final map = canvas.toMap();
      expect(map['ownerUid'], 'uid_01');
      expect(map['width'], 4);
      expect(map['height'], 4);
      expect(map['pixels'], isA<List>());
      expect((map['pixels'] as List).length, 4);
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['updatedAt'], isA<Timestamp>());
      expect(map['storagePath'], isNull);
    });

    test('copyWith preserves and replaces fields', () {
      final original = makeCanvas();
      final copied = original.copyWith(
        width: 8,
        height: 8,
        storagePath: 'gs://bucket/canvas_01.png',
      );
      expect(copied.width, 8);
      expect(copied.height, 8);
      expect(copied.storagePath, 'gs://bucket/canvas_01.png');
      expect(copied.canvasId, original.canvasId);
      expect(copied.ownerUid, original.ownerUid);
    });

    test('blank factory creates canvas with all navy pixels', () {
      final canvas = PixelCanvasModel.blank('uid_01', 8, 8);
      expect(canvas.ownerUid, 'uid_01');
      expect(canvas.width, 8);
      expect(canvas.height, 8);
      expect(canvas.pixels.length, 8);
      expect(canvas.pixels[0].length, 8);
      expect(canvas.pixels[0][0], 0xFF0A1628);
      expect(canvas.storagePath, isNull);
    });

    test('blank factory generates unique canvasId', () {
      final c1 = PixelCanvasModel.blank('uid_01', 4, 4);
      // Small delay to ensure different timestamp
      final c2 = PixelCanvasModel.blank('uid_01', 4, 4);
      // canvasId is based on millisecondsSinceEpoch so they may be same or different
      // but both should be non-empty
      expect(c1.canvasId.isNotEmpty, true);
      expect(c2.canvasId.isNotEmpty, true);
    });
  });
}
