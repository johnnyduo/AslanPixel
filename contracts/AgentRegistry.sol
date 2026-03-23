// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title AgentRegistry
 * @notice Tracks agent metadata, reputation, and performance onchain
 * @dev Each agent has a unique ID and onchain reputation score
 */
contract AgentRegistry {
    struct AgentRecord {
        string agentId;         // e.g. "scout", "strategist"
        string name;            // Display name e.g. "Nexus"
        string role;            // e.g. "HCS Intelligence"
        address wallet;         // Agent's Hedera EVM address
        uint256 reputation;     // 0-1000 score
        uint256 completedQuests;
        uint256 successCount;
        uint256 registeredAt;
        bool active;
    }

    mapping(string => AgentRecord) public agents;
    string[] public agentIds;
    address public immutable registry;

    event AgentRegistered(string agentId, string name, address wallet);
    event ReputationUpdated(string agentId, uint256 oldRep, uint256 newRep);
    event QuestCompleted(string agentId, uint256 questId, bool success);

    modifier onlyRegistry() {
        require(msg.sender == registry, "AgentRegistry: unauthorized");
        _;
    }

    constructor() {
        registry = msg.sender;
    }

    function registerAgent(
        string calldata agentId,
        string calldata name,
        string calldata role,
        address wallet
    ) external onlyRegistry {
        require(agents[agentId].registeredAt == 0, "AgentRegistry: already registered");
        agents[agentId] = AgentRecord({
            agentId: agentId,
            name: name,
            role: role,
            wallet: wallet,
            reputation: 500, // Start at 50%
            completedQuests: 0,
            successCount: 0,
            registeredAt: block.timestamp,
            active: true
        });
        agentIds.push(agentId);
        emit AgentRegistered(agentId, name, wallet);
    }

    function recordQuestResult(
        string calldata agentId,
        uint256 questId,
        bool success
    ) external onlyRegistry {
        AgentRecord storage agent = agents[agentId];
        require(agent.registeredAt > 0, "AgentRegistry: agent not found");

        uint256 oldRep = agent.reputation;
        agent.completedQuests++;

        if (success) {
            agent.successCount++;
            // Increase reputation, cap at 1000
            agent.reputation = agent.reputation >= 990 ? 1000 : agent.reputation + 10;
        } else {
            // Decrease reputation, floor at 0
            agent.reputation = agent.reputation <= 20 ? 0 : agent.reputation - 20;
        }

        emit QuestCompleted(agentId, questId, success);
        emit ReputationUpdated(agentId, oldRep, agent.reputation);
    }

    function getAgent(string calldata agentId) external view returns (AgentRecord memory) {
        return agents[agentId];
    }

    function getAllAgents() external view returns (AgentRecord[] memory) {
        AgentRecord[] memory all = new AgentRecord[](agentIds.length);
        for (uint256 i = 0; i < agentIds.length; i++) {
            all[i] = agents[agentIds[i]];
        }
        return all;
    }

    function getSuccessRate(string calldata agentId) external view returns (uint256) {
        AgentRecord storage agent = agents[agentId];
        if (agent.completedQuests == 0) return 0;
        return (agent.successCount * 100) / agent.completedQuests;
    }

    function deactivateAgent(string calldata agentId) external onlyRegistry {
        agents[agentId].active = false;
    }

    function getAgentCount() external view returns (uint256) {
        return agentIds.length;
    }
}
