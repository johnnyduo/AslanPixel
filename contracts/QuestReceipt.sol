// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title QuestReceipt
 * @notice Immutable receipt storage for AslanGuild agent operations on Hedera
 * @dev Deployed on Hedera testnet via EVM compatibility layer
 */
contract QuestReceipt {
    struct Receipt {
        bytes32 inputHash;      // SHA-256 of user intent
        bytes32 outputHash;     // SHA-256 of agent reasoning bundle
        bytes32 txHash;         // Hash of executed transaction
        address[] agents;       // Agent wallet addresses that participated
        string[] agentIds;      // Agent IDs (scout, strategist, etc.)
        uint256 timestamp;      // Block timestamp
        uint256 questId;        // Sequential quest ID
        string intent;          // Human-readable intent summary
        bool success;           // Whether quest completed successfully
    }

    mapping(uint256 => Receipt) public receipts;
    uint256 public questCount;
    address public immutable guildMaster;

    event ReceiptStored(
        uint256 indexed questId,
        bytes32 inputHash,
        bytes32 outputHash,
        bool success,
        uint256 timestamp
    );

    modifier onlyGuildMaster() {
        require(msg.sender == guildMaster, "QuestReceipt: not guild master");
        _;
    }

    constructor() {
        guildMaster = msg.sender;
    }

    function storeReceipt(
        bytes32 inputHash,
        bytes32 outputHash,
        bytes32 txHash,
        address[] calldata agents,
        string[] calldata agentIds,
        string calldata intent,
        bool success
    ) external onlyGuildMaster returns (uint256 questId) {
        questId = ++questCount;
        receipts[questId] = Receipt({
            inputHash: inputHash,
            outputHash: outputHash,
            txHash: txHash,
            agents: agents,
            agentIds: agentIds,
            timestamp: block.timestamp,
            questId: questId,
            intent: intent,
            success: success
        });

        emit ReceiptStored(questId, inputHash, outputHash, success, block.timestamp);
    }

    function getReceipt(uint256 questId) external view returns (Receipt memory) {
        require(questId > 0 && questId <= questCount, "QuestReceipt: invalid quest ID");
        return receipts[questId];
    }

    function getLatestReceipt() external view returns (Receipt memory) {
        require(questCount > 0, "QuestReceipt: no receipts yet");
        return receipts[questCount];
    }

    /// @notice Returns up to `limit` latest receipts (newest first)
    function getRecentReceipts(uint256 limit) external view returns (Receipt[] memory) {
        uint256 count = questCount < limit ? questCount : limit;
        Receipt[] memory result = new Receipt[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = receipts[questCount - i];
        }
        return result;
    }
}
