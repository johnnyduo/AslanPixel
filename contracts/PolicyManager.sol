// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title PolicyManager
 * @notice Enforces risk rules for agent operations
 */
contract PolicyManager {
    struct Policy {
        uint256 maxSingleTxHbar;
        uint256 dailyLimitHbar;
        uint256 maxSlippageBps;
        bool requireAudit;
        bool active;
    }

    mapping(bytes32 => Policy) public policies;
    mapping(address => uint256[2]) public dailyUsage; // [day, spent]
    address public immutable admin;

    event PolicyViolation(bytes32 indexed key, address agent);
    event SpendingRecorded(address agent, uint256 amount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "unauthorized");
        _;
    }

    constructor() {
        admin = msg.sender;
        // Default conservative policy
        policies[keccak256("default")] = Policy({
            maxSingleTxHbar: 1000 * 1e8,
            dailyLimitHbar:  5000 * 1e8,
            maxSlippageBps:  25,
            requireAudit:    true,
            active:          true
        });
    }

    function createPolicy(
        string calldata policyId,
        uint256 maxSingleTxHbar,
        uint256 dailyLimitHbar,
        uint256 maxSlippageBps,
        bool requireAudit
    ) external onlyAdmin {
        bytes32 key = keccak256(abi.encodePacked(policyId));
        require(!policies[key].active, "exists");
        policies[key] = Policy(maxSingleTxHbar, dailyLimitHbar, maxSlippageBps, requireAudit, true);
    }

    function checkPolicy(
        string calldata policyId,
        uint256 amountHbar,
        uint256 slippageBps,
        address agentWallet
    ) public returns (bool passed) {
        bytes32 key = keccak256(abi.encodePacked(policyId));
        Policy storage p = policies[key];
        require(p.active, "not found");

        if (amountHbar > p.maxSingleTxHbar) {
            emit PolicyViolation(key, agentWallet);
            return false;
        }
        if (slippageBps > p.maxSlippageBps) {
            emit PolicyViolation(key, agentWallet);
            return false;
        }

        uint256 today = block.timestamp / 86400;
        uint256[2] storage u = dailyUsage[agentWallet];
        if (u[0] != today) { u[0] = today; u[1] = 0; }
        if (u[1] + amountHbar > p.dailyLimitHbar) {
            emit PolicyViolation(key, agentWallet);
            return false;
        }
        u[1] += amountHbar;
        emit SpendingRecorded(agentWallet, amountHbar);
        return true;
    }

    function getPolicy(string calldata policyId) external view returns (Policy memory) {
        return policies[keccak256(abi.encodePacked(policyId))];
    }

    function deactivatePolicy(string calldata policyId) external onlyAdmin {
        policies[keccak256(abi.encodePacked(policyId))].active = false;
    }
}
