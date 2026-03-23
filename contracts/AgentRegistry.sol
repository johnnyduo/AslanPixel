// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title AgentRegistry
 * @notice Tracks agent reputation and quest results onchain
 */
contract AgentRegistry {
    struct AgentRecord {
        string agentId;
        string name;
        uint256 reputation;      // 0-1000
        uint256 completedQuests;
        uint256 successCount;
        uint256 registeredAt;
        bool active;
    }

    mapping(bytes32 => AgentRecord) private _agents;
    bytes32[] public agentKeys;
    address public immutable registry;

    event AgentRegistered(bytes32 indexed key, string agentId, string name);
    event QuestCompleted(bytes32 indexed key, uint256 questId, bool success);
    event ReputationUpdated(bytes32 indexed key, uint256 newRep);

    modifier onlyRegistry() {
        require(msg.sender == registry, "unauthorized");
        _;
    }

    constructor() {
        registry = msg.sender;
    }

    function registerAgent(
        string calldata agentId,
        string calldata name,
        string calldata, // role (unused, saves gas)
        address          // wallet (unused for now)
    ) external onlyRegistry {
        bytes32 key = keccak256(abi.encodePacked(agentId));
        require(_agents[key].registeredAt == 0, "exists");
        _agents[key] = AgentRecord({
            agentId: agentId,
            name: name,
            reputation: 500,
            completedQuests: 0,
            successCount: 0,
            registeredAt: block.timestamp,
            active: true
        });
        agentKeys.push(key);
        emit AgentRegistered(key, agentId, name);
    }

    function recordQuestResult(
        string calldata agentId,
        uint256 questId,
        bool success
    ) external onlyRegistry {
        bytes32 key = keccak256(abi.encodePacked(agentId));
        AgentRecord storage a = _agents[key];
        require(a.registeredAt > 0, "not found");
        a.completedQuests++;
        if (success) {
            a.successCount++;
            a.reputation = a.reputation >= 990 ? 1000 : a.reputation + 10;
        } else {
            a.reputation = a.reputation <= 20 ? 0 : a.reputation - 20;
        }
        emit QuestCompleted(key, questId, success);
        emit ReputationUpdated(key, a.reputation);
    }

    function getAgent(string calldata agentId) external view returns (AgentRecord memory) {
        return _agents[keccak256(abi.encodePacked(agentId))];
    }

    function getAgentCount() external view returns (uint256) {
        return agentKeys.length;
    }

    function deactivateAgent(string calldata agentId) external onlyRegistry {
        _agents[keccak256(abi.encodePacked(agentId))].active = false;
    }
}
