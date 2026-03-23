// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title MockUSDC
 * @notice ERC-20 mock USDC for AslanGuild testnet testing
 * @dev Mintable by owner, 6 decimals (same as real USDC)
 */
contract MockUSDC {
    string public constant name     = "USD Coin (Testnet)";
    string public constant symbol   = "USDC";
    uint8  public constant decimals = 6;

    uint256 public totalSupply;
    address public owner;
    mapping(address => bool) public minters;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner_, address indexed spender, uint256 value);
    event Minted(address indexed to, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "MockUSDC: not owner");
        _;
    }

    modifier onlyMinter() {
        require(msg.sender == owner || minters[msg.sender], "MockUSDC: not minter");
        _;
    }

    constructor(uint256 initialSupply) {
        owner = msg.sender;
        _mint(msg.sender, initialSupply);
    }

    function addMinter(address minter) external onlyOwner {
        minters[minter] = true;
    }

    function mint(address to, uint256 amount) external onlyMinter {
        _mint(to, amount);
        emit Minted(to, amount);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(allowance[from][msg.sender] >= amount, "MockUSDC: insufficient allowance");
        allowance[from][msg.sender] -= amount;
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(balanceOf[from] >= amount, "MockUSDC: insufficient balance");
        balanceOf[from] -= amount;
        balanceOf[to]   += amount;
        emit Transfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal {
        totalSupply     += amount;
        balanceOf[to]   += amount;
        emit Transfer(address(0), to, amount);
    }
}
