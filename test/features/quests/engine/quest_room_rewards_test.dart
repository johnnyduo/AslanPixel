import 'package:aslan_pixel/features/quests/engine/quest_room_rewards.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('kQuestRoomRewards', () {
    test('contains exactly 5 entries', () {
      expect(kQuestRoomRewards.length, 5);
    });

    test('contains all expected action types', () {
      expect(kQuestRoomRewards.containsKey('agent_work'), isTrue);
      expect(kQuestRoomRewards.containsKey('market_news'), isTrue);
      expect(kQuestRoomRewards.containsKey('feed_post'), isTrue);
      expect(kQuestRoomRewards.containsKey('prediction'), isTrue);
      expect(kQuestRoomRewards.containsKey('plaza_visit'), isTrue);
    });

    test('agent_work maps to desk_upgrade_01', () {
      expect(kQuestRoomRewards['agent_work'], 'desk_upgrade_01');
    });

    test('market_news maps to monitor_01', () {
      expect(kQuestRoomRewards['market_news'], 'monitor_01');
    });

    test('feed_post maps to bulletin_board_01', () {
      expect(kQuestRoomRewards['feed_post'], 'bulletin_board_01');
    });

    test('prediction maps to crystal_ball_01', () {
      expect(kQuestRoomRewards['prediction'], 'crystal_ball_01');
    });

    test('plaza_visit maps to door_mat_01', () {
      expect(kQuestRoomRewards['plaza_visit'], 'door_mat_01');
    });

    test('unknown key returns null', () {
      expect(kQuestRoomRewards['nonexistent_action'], isNull);
      expect(kQuestRoomRewards[''], isNull);
      expect(kQuestRoomRewards['AGENT_WORK'], isNull);
    });
  });
}
