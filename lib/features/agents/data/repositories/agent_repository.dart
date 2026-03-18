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
}
