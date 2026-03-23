// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./MockUSDC.sol";

/**
 * @title USDCFaucet
 * @notice Testnet faucet — drip 1000 USDC per address per day
 */
contract USDCFaucet {
    MockUSDC public usdc;
    uint256 public constant DRIP_AMOUNT  = 1_000 * 1e6; // 1000 USDC (6 decimals)
    uint256 public constant COOLDOWN     = 24 hours;

    mapping(address => uint256) public lastClaim;
    address public owner;

    event Dripped(address indexed to, uint256 amount, uint256 nextClaimAt);

    modifier onlyOwner() {
        require(msg.sender == owner, "Faucet: not owner");
        _;
    }

    constructor(address usdcAddress) {
        usdc  = MockUSDC(usdcAddress);
        owner = msg.sender;
    }

    function drip() external {
        require(
            block.timestamp >= lastClaim[msg.sender] + COOLDOWN,
            "Faucet: cooldown active"
        );
        lastClaim[msg.sender] = block.timestamp;
        usdc.mint(msg.sender, DRIP_AMOUNT);
        emit Dripped(msg.sender, DRIP_AMOUNT, block.timestamp + COOLDOWN);
    }

    function dripTo(address to) external onlyOwner {
        usdc.mint(to, DRIP_AMOUNT);
        emit Dripped(to, DRIP_AMOUNT, 0);
    }

    function nextClaimTime(address user) external view returns (uint256) {
        uint256 next = lastClaim[user] + COOLDOWN;
        return next > block.timestamp ? next : 0;
    }

    /// @notice Transfer USDC ownership to faucet so it can mint
    function acceptUsdcOwnership() external onlyOwner {
        // Call after deploying: usdc.transferOwnership(faucetAddress)
        // This just documents the intended ownership chain
    }
}
