// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title PolicyManager
 * @notice Enforces risk rules and limits for agent operations
 * @dev Sentinel agent checks these policies before any execution
 */
contract PolicyManager {
    struct Policy {
        string name;
        uint256 maxPositionBps;     // Max position size in basis points (e.g. 500 = 5%)
        uint256 maxSlippageBps;     // Max slippage in basis points (e.g. 25 = 0.25%)
        uint256 maxSingleTxHbar;    // Max HBAR per single transaction (in tinyhbar)
        uint256 dailyLimitHbar;     // Daily spending limit (in tinyhbar)
        bool requireAudit;          // Require smart contract audit before interaction
        bool active;
    }

    struct DailyUsage {
        uint256 date;               // Unix timestamp day bucket
        uint256 spent;              // tinyhbar spent today
    }

    mapping(string => Policy) public policies;        // policyId => Policy
    mapping(address => DailyUsage) public dailyUsage; // wallet => usage
    string[] public policyIds;
    address public immutable admin;

    event PolicyCreated(string policyId, string name);
    event PolicyUpdated(string policyId);
    event PolicyViolation(string policyId, string reason, address agent);
    event SpendingRecorded(address agent, uint256 amount, uint256 dailyTotal);

    modifier onlyAdmin() {
        require(msg.sender == admin, "PolicyManager: not admin");
        _;
    }

    constructor() {
        admin = msg.sender;
        // Default conservative policy
        _createDefaultPolicy();
    }

    function _createDefaultPolicy() internal {
        policies["default"] = Policy({
            name: "Default Conservative",
            maxPositionBps: 500,         // 5% max position
            maxSlippageBps: 25,          // 0.25% max slippage
            maxSingleTxHbar: 1000 * 1e8, // 1000 HBAR per TX
            dailyLimitHbar: 5000 * 1e8,  // 5000 HBAR per day
            requireAudit: true,
            active: true
        });
        policyIds.push("default");
    }

    function createPolicy(
        string calldata policyId,
        string calldata name,
        uint256 maxPositionBps,
        uint256 maxSlippageBps,
        uint256 maxSingleTxHbar,
        uint256 dailyLimitHbar,
        bool requireAudit
    ) external onlyAdmin {
        require(!policies[policyId].active, "PolicyManager: policy exists");
        policies[policyId] = Policy({
            name: name,
            maxPositionBps: maxPositionBps,
            maxSlippageBps: maxSlippageBps,
            maxSingleTxHbar: maxSingleTxHbar,
            dailyLimitHbar: dailyLimitHbar,
            requireAudit: requireAudit,
            active: true
        });
        policyIds.push(policyId);
        emit PolicyCreated(policyId, name);
    }

    function checkPolicy(
        string calldata policyId,
        uint256 amountHbar,
        uint256 slippageBps,
        address agentWallet
    ) external returns (bool passed, string memory reason) {
        Policy storage p = policies[policyId];
        require(p.active, "PolicyManager: policy not found");

        if (amountHbar > p.maxSingleTxHbar) {
            emit PolicyViolation(policyId, "TX exceeds single limit", agentWallet);
            return (false, "TX exceeds single limit");
        }

        if (slippageBps > p.maxSlippageBps) {
            emit PolicyViolation(policyId, "Slippage too high", agentWallet);
            return (false, "Slippage too high");
        }

        // Check daily limit
        uint256 today = block.timestamp / 86400;
        DailyUsage storage usage = dailyUsage[agentWallet];
        if (usage.date != today) {
            usage.date = today;
            usage.spent = 0;
        }

        if (usage.spent + amountHbar > p.dailyLimitHbar) {
            emit PolicyViolation(policyId, "Daily limit exceeded", agentWallet);
            return (false, "Daily limit exceeded");
        }

        usage.spent += amountHbar;
        emit SpendingRecorded(agentWallet, amountHbar, usage.spent);
        return (true, "PASS");
    }

    function getPolicy(string calldata policyId) external view returns (Policy memory) {
        return policies[policyId];
    }
}
