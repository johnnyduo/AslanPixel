import '../../../../core/enums/agent_type.dart';
import '../models/agent_model.dart';

abstract class AgentRepository {
  Stream<List<AgentModel>> watchAgents(String uid);

  Future<AgentModel?> getAgent(String uid, AgentType type);

  Future<void> updateAgentStatus(
    String uid,
    String agentId,
    AgentStatus status,
  );

  Future<void> levelUpAgent(String uid, String agentId);

  Future<void> clearActiveTask(String uid, String agentId);

  /// Purchases an agent: deducts [price] coins and creates the agent document.
  /// Throws if coins are insufficient or agent already owned.
  Future<void> purchaseAgent({
    required String uid,
    required AgentType type,
    required int price,
  });
}
