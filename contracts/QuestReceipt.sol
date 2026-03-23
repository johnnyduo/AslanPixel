// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title QuestReceipt
 * @notice Immutable receipt storage for AslanGuild agent operations on Hedera
 */
contract QuestReceipt {
    struct Receipt {
        bytes32 inputHash;
        bytes32 outputHash;
        bytes32 txHash;
        uint256 timestamp;
        uint256 questId;
        bool success;
        string intent;
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
        require(msg.sender == guildMaster, "not master");
        _;
    }

    constructor() {
        guildMaster = msg.sender;
    }

    function storeReceipt(
        bytes32 inputHash,
        bytes32 outputHash,
        bytes32 txHash,
        string calldata intent,
        bool success
    ) external onlyGuildMaster returns (uint256 questId) {
        questId = ++questCount;
        receipts[questId] = Receipt({
            inputHash: inputHash,
            outputHash: outputHash,
            txHash: txHash,
            timestamp: block.timestamp,
            questId: questId,
            success: success,
            intent: intent
        });
        emit ReceiptStored(questId, inputHash, outputHash, success, block.timestamp);
    }

    function getReceipt(uint256 questId) external view returns (Receipt memory) {
        require(questId > 0 && questId <= questCount, "invalid id");
        return receipts[questId];
    }

    function getLatestReceipt() external view returns (Receipt memory) {
        require(questCount > 0, "none yet");
        return receipts[questCount];
    }

    function getRecentReceipts(uint256 limit) external view returns (Receipt[] memory) {
        uint256 count = questCount < limit ? questCount : limit;
        Receipt[] memory result = new Receipt[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = receipts[questCount - i];
        }
        return result;
    }
}
