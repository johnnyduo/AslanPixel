// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title AgentNFT
 * @notice ERC-721 NFT-based agent registry for AslanPixel.
 *         The 6 canonical guild agents are batch-minted at deployment.
 *         Anyone can mint a new agent NFT (custom agents), making agents
 *         tradeable onchain.
 *
 *         Token IDs:
 *           1 = Nexus   (scout)
 *           2 = Oryn    (strategist)
 *           3 = Drax    (sentinel)
 *           4 = Lyss    (treasurer)
 *           5 = Vex     (executor)
 *           6 = Kael    (archivist)
 *           7+ = user-minted custom agents
 *
 * @dev Minimal ERC-721 (no external dependency) + reputation tracking.
 *      Reputation is tied to tokenId, not address, so it persists through transfers.
 */
contract AgentNFT {

    // -----------------------------------------------------------------------
    // ERC-721 storage
    // -----------------------------------------------------------------------
    string public name     = "AslanPixel Agent";
    string public symbol   = "ASLAN";

    uint256 public totalSupply;
    uint256 private _nextTokenId = 1;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // -----------------------------------------------------------------------
    // Agent metadata + reputation
    // -----------------------------------------------------------------------
    struct AgentRecord {
        string  agentId;        // canonical ID (e.g. "scout")
        string  name;           // display name (e.g. "Nexus")
        string  role;           // role description
        uint256 reputation;     // 0-1000, starts at 500
        uint256 completedQuests;
        uint256 successCount;
        uint256 registeredAt;
        bool    active;
    }

    // tokenId => AgentRecord
    mapping(uint256 => AgentRecord) public agents;

    // agentId string => tokenId (for reverse lookup)
    mapping(bytes32 => uint256) private _agentIdToToken;

    // -----------------------------------------------------------------------
    // Access control
    // -----------------------------------------------------------------------
    address public immutable deployer;

    // questRecorder can call recordQuestResult (set to QuestReceipt contract or deployer)
    address public questRecorder;

    // -----------------------------------------------------------------------
    // Events
    // -----------------------------------------------------------------------
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event AgentMinted(uint256 indexed tokenId, string agentId, string agentName, address owner);
    event QuestCompleted(uint256 indexed tokenId, uint256 questId, bool success);
    event ReputationUpdated(uint256 indexed tokenId, uint256 newRep);

    // -----------------------------------------------------------------------
    // Constructor — batch mint 6 canonical agents to deployer
    // -----------------------------------------------------------------------
    constructor() {
        deployer       = msg.sender;
        questRecorder  = msg.sender;

        // Mint canonical guild agents (tokenId 1–6)
        _mintAgent(msg.sender, "scout",      "Nexus", "HCS Intelligence");
        _mintAgent(msg.sender, "strategist", "Oryn",  "Strategy Engine");
        _mintAgent(msg.sender, "sentinel",   "Drax",  "Risk Sentinel");
        _mintAgent(msg.sender, "treasurer",  "Lyss",  "Treasury Keeper");
        _mintAgent(msg.sender, "executor",   "Vex",   "TX Executor");
        _mintAgent(msg.sender, "archivist",  "Kael",  "Ledger Archivist");
    }

    // -----------------------------------------------------------------------
    // Public mint — register a new agent as an NFT
    // -----------------------------------------------------------------------
    /**
     * @notice Mint a new agent NFT. The caller becomes the agent owner.
     * @param agentId  Unique string identifier (e.g. "my-agent-42")
     * @param agentName Display name shown in the UI
     * @param role      Role / personality description
     * @return tokenId  The minted NFT token ID
     */
    function mintAgent(
        string calldata agentId,
        string calldata agentName,
        string calldata role
    ) external returns (uint256 tokenId) {
        bytes32 key = keccak256(abi.encodePacked(agentId));
        require(_agentIdToToken[key] == 0, "AgentNFT: agentId already registered");
        require(bytes(agentId).length > 0,   "AgentNFT: empty agentId");
        require(bytes(agentName).length > 0, "AgentNFT: empty name");

        tokenId = _mintAgent(msg.sender, agentId, agentName, role);
    }

    // -----------------------------------------------------------------------
    // Reputation tracking (called by questRecorder)
    // -----------------------------------------------------------------------
    function recordQuestResult(
        string calldata agentId,
        uint256 questId,
        bool success
    ) external {
        require(
            msg.sender == questRecorder || msg.sender == deployer,
            "AgentNFT: unauthorized"
        );
        bytes32 key = keccak256(abi.encodePacked(agentId));
        uint256 tokenId = _agentIdToToken[key];
        require(tokenId != 0, "AgentNFT: agent not found");

        AgentRecord storage a = agents[tokenId];
        a.completedQuests++;
        if (success) {
            a.successCount++;
            a.reputation = a.reputation >= 990 ? 1000 : a.reputation + 10;
        } else {
            a.reputation = a.reputation <= 20 ? 0 : a.reputation - 20;
        }
        emit QuestCompleted(tokenId, questId, success);
        emit ReputationUpdated(tokenId, a.reputation);
    }

    // -----------------------------------------------------------------------
    // View helpers
    // -----------------------------------------------------------------------
    function getAgent(string calldata agentId) external view returns (AgentRecord memory) {
        bytes32 key = keccak256(abi.encodePacked(agentId));
        uint256 tokenId = _agentIdToToken[key];
        require(tokenId != 0, "AgentNFT: not found");
        return agents[tokenId];
    }

    function getAgentByTokenId(uint256 tokenId) external view returns (AgentRecord memory) {
        require(_owners[tokenId] != address(0), "AgentNFT: token does not exist");
        return agents[tokenId];
    }

    function getAgentCount() external view returns (uint256) {
        return totalSupply;
    }

    function tokenIdOf(string calldata agentId) external view returns (uint256) {
        bytes32 key = keccak256(abi.encodePacked(agentId));
        return _agentIdToToken[key];
    }

    // -----------------------------------------------------------------------
    // Admin
    // -----------------------------------------------------------------------
    function setQuestRecorder(address recorder) external {
        require(msg.sender == deployer, "AgentNFT: only deployer");
        questRecorder = recorder;
    }

    function deactivateAgent(string calldata agentId) external {
        bytes32 key = keccak256(abi.encodePacked(agentId));
        uint256 tokenId = _agentIdToToken[key];
        require(tokenId != 0, "AgentNFT: not found");
        require(
            msg.sender == deployer || msg.sender == _owners[tokenId],
            "AgentNFT: unauthorized"
        );
        agents[tokenId].active = false;
    }

    // -----------------------------------------------------------------------
    // ERC-721 standard
    // -----------------------------------------------------------------------
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: token does not exist");
        return owner;
    }

    function approve(address to, uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approve to current owner");
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: not owner nor approved for all"
        );
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_owners[tokenId] != address(0), "ERC721: nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) external {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: not approved");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata) external {
        transferFrom(from, to, tokenId);
    }

    // ERC-165 supportsInterface
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            interfaceId == 0x80ac58cd || // ERC721
            interfaceId == 0x01ffc9a7;   // ERC165
    }

    // -----------------------------------------------------------------------
    // Internal
    // -----------------------------------------------------------------------
    function _mintAgent(
        address to,
        string memory agentId,
        string memory agentName,
        string memory role
    ) internal returns (uint256 tokenId) {
        tokenId = _nextTokenId++;
        _owners[tokenId] = to;
        _balances[to]++;
        totalSupply++;

        bytes32 key = keccak256(abi.encodePacked(agentId));
        _agentIdToToken[key] = tokenId;

        agents[tokenId] = AgentRecord({
            agentId:        agentId,
            name:           agentName,
            role:           role,
            reputation:     500,
            completedQuests: 0,
            successCount:   0,
            registeredAt:   block.timestamp,
            active:         true
        });

        emit Transfer(address(0), to, tokenId);
        emit AgentMinted(tokenId, agentId, agentName, to);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (
            spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender)
        );
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer from wrong owner");
        require(to != address(0), "ERC721: transfer to zero address");

        delete _tokenApprovals[tokenId];
        _balances[from]--;
        _balances[to]++;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }
}
