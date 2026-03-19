import 'package:mocktail/mocktail.dart';

import 'package:aslan_pixel/features/auth/data/repositories/auth_repository.dart';
import 'package:aslan_pixel/features/agents/data/repositories/agent_repository.dart';
import 'package:aslan_pixel/features/agents/data/repositories/agent_task_repository.dart';
import 'package:aslan_pixel/features/quests/data/repositories/quest_repository.dart';
import 'package:aslan_pixel/features/feed/data/repositories/feed_repository.dart';
import 'package:aslan_pixel/features/finance/data/repositories/prediction_repository.dart';
import 'package:aslan_pixel/features/finance/data/repositories/ai_insight_repository.dart';
import 'package:aslan_pixel/features/notifications/data/repositories/notification_repository.dart';
import 'package:aslan_pixel/features/profile/data/repositories/profile_repository.dart';
import 'package:aslan_pixel/data/services/ai_service.dart';
import 'package:aslan_pixel/features/home/data/repositories/room_repository.dart';
import 'package:aslan_pixel/features/inventory/data/repositories/economy_repository.dart';
import 'package:aslan_pixel/features/follows/data/repositories/follow_repository.dart';
import 'package:aslan_pixel/features/world/data/repositories/plaza_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockAgentRepository extends Mock implements AgentRepository {}
class MockAgentTaskRepository extends Mock implements AgentTaskRepository {}
class MockQuestRepository extends Mock implements QuestRepository {}
class MockFeedRepository extends Mock implements FeedRepository {}
class MockPredictionRepository extends Mock implements PredictionRepository {}
class MockAiInsightRepository extends Mock implements AiInsightRepository {}
class MockNotificationRepository extends Mock implements NotificationRepository {}
class MockProfileRepository extends Mock implements ProfileRepository {}
class MockAiService extends Mock implements AIService {}
class MockRoomRepository extends Mock implements RoomRepository {}
class MockEconomyRepository extends Mock implements EconomyRepository {}
class MockFollowRepository extends Mock implements FollowRepository {}
class MockPlazaRepository extends Mock implements PlazaRepository {}
