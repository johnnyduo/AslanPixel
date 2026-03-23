# AslanGuild — Agentic Guild on Hedera

> **AI agent society that thinks, transacts, and archives everything onchain — autonomously.**

Live demo: [aslanpixel.vercel.app](https://aslanpixel.vercel.app)
Hedera Testnet Account: `0.0.5769159`

---

## What It Does

AslanGuild is a multi-agent AI coordination layer on Hedera. Six specialized autonomous agents collaborate in real-time to scan, plan, validate, fund, execute, and archive DeFi operations — all verifiably onchain.

**The core user insight:** DeFi is complex and opaque. You don't know what's happening with your funds. AslanGuild makes every step visible — every agent decision, every policy check, every transaction — streamed live and archived immutably on Hedera.

### The 6 Agents

| Agent | Role | Hedera Layer |
|-------|------|-------------|
| **Nexus** ◈ | HCS Intelligence — reads consensus streams | HCS (Hedera Consensus Service) |
| **Oryn** ▲ | Strategy Engine — models execution paths | EVM Smart Contracts |
| **Drax** ◆ | Risk Sentinel — enforces PolicyManager.sol | PolicyManager.sol |
| **Lyss** ◉ | Treasury Keeper — tracks HTS balances | HTS (Hedera Token Service) |
| **Vex** ▶ | TX Executor — simulate → sign → submit | Hedera EVM |
| **Kael** ▣ | Ledger Archivist — writes QuestReceipt.sol | Mirror Node + QuestReceipt.sol |

### How It Works

1. User types a natural language intent: *"Rebalance treasury with 30% USDC buffer"*
2. **Guild Vote**: All 6 agents vote — Drax (Sentinel) can veto high-risk quests
3. **Approved**: Agents mobilize sequentially, each streaming their action to the timeline
4. **Onchain**: Quest receipt stored in `QuestReceipt.sol`, agent reputation updated in `AgentRegistry.sol`
5. **HCS**: Every quest event posted to Hedera Consensus Service topic
6. **TX Link**: HashScan URL shown for every confirmed transaction

### Auto-Quest Mode

Every 9 minutes, the guild autonomously fires a preset quest — yield optimization, risk scans, treasury reconciliation — keeping the platform active without user interaction.

---

## Tech Stack

### Frontend
- React 18 + TypeScript + Vite → deployed on Vercel
- Tailwind CSS + shadcn/ui + custom pixel-art design system
- Recharts for live quest history chart
- Reown AppKit v1.8.19 for MetaMask / WalletConnect
- Zustand for cross-component state

### AI
- **Gemini 3.1 Flash Lite Preview** — powers all 6 agent responses
- Server-side only (Vercel Edge runtime) — API key never exposed to browser

### Backend (Vercel API Routes)

| Route | Runtime | Purpose |
|-------|---------|---------|
| `GET /api/quest` | Edge SSE | 6-agent workflow, streams responses, stores receipt |
| `GET /api/stream` | Edge SSE | Background live agent activity (always on) |
| `POST /api/store-receipt` | Node.js | Writes QuestReceipt.sol onchain + posts HCS |
| `POST /api/agent-register` | Node.js | Registers agents in AgentRegistry.sol + creates HCS topic |
| `GET /api/hedera` | Edge | Mirror Node proxy with 30s cache |
| `GET /api/saucerswap` | Edge | SaucerSwap testnet proxy |

### Hedera Integration
- **HCS** — agent activity and quest events published as Hedera Consensus Service messages
- **HTS** — HBAR/USDC balances tracked via Mirror Node
- **EVM (Hedera testnet, chainID 296)** — all contracts deployed via Remix
- **Mirror Node** — real-time price, balance, receipt, and token lookups
- **SaucerSwap testnet** — live pool TVL/volume injected into agent prompts

### Smart Contracts (Hedera Testnet)

| Contract | Address | Verified |
|----------|---------|---------|
| `QuestReceipt.sol` | `0x444f5895D29809847E8642Df0e0f4DBdBf541C7D` | [HashScan ↗](https://hashscan.io/testnet/contract/0x444f5895D29809847E8642Df0e0f4DBdBf541C7D) |
| `AgentRegistry.sol` | `0x8B90AA6D1A12111C8F08C8B9Af4cca9f90336CC4` | [HashScan ↗](https://hashscan.io/testnet/contract/0x8B90AA6D1A12111C8F08C8B9Af4cca9f90336CC4) |
| `PolicyManager.sol` | `0xdBc14F4c53c071cd925fa4a730D06ddc1b4911E4` | [HashScan ↗](https://hashscan.io/testnet/contract/0xdBc14F4c53c071cd925fa4a730D06ddc1b4911E4) |
| `MockUSDC` | `0x152Bf42A48677b678c658E452788ea2687525BF7` | [HashScan ↗](https://hashscan.io/testnet/contract/0x152Bf42A48677b678c658E452788ea2687525BF7) |
| `USDCFaucet` | `0xCA0558Fa81166C5939335282973Aa2F3A00B3953` | [HashScan ↗](https://hashscan.io/testnet/contract/0xCA0558Fa81166C5939335282973Aa2F3A00B3953) |

---

## Running Locally

```bash
git clone https://github.com/YOUR_REPO/AslanGuild
cd AslanGuild
npm install
# Keys already in .env.deploy for demo
npm run dev
# Frontend: http://localhost:8080
# API:      http://localhost:3001
```

### Environment Variables
```
GEMINI_API_KEY=           # Gemini API key
HEDERA_PRIVATE_KEY=       # Deployer EVM private key (0x...)
HEDERA_ACCOUNT_ID=        # Hedera account ID (0.0.XXXXXX)
HEDERA_HCS_TOPIC_ID=      # HCS topic (auto-created if not set)
```

---

## Architecture

```
User Intent (or Auto-Quest every 9min)
    ↓
[Guild Vote Panel] — 6 agents vote sequentially, Drax can VETO
    ↓
[GET /api/quest — Vercel Edge SSE]
    ├── Nexus ◈  — HCS scan + market data (real SaucerSwap prices)
    ├── Oryn  ▲  — 3-branch strategy model with confidence %
    ├── Drax  ◆  — PolicyManager.sol compliance check
    ├── Lyss  ◉  — Treasury budget allocation in tinyhbar
    ├── Vex   ▶  — EVM simulate → sign → submit
    └── Kael  ▣  — QuestReceipt.sol write + Mirror Node archive
         ↓
[POST /api/store-receipt — Node.js]
    ├── QuestReceipt.sol → stores inputHash + txHash onchain
    ├── AgentRegistry.sol → updates reputation for all 6 agents
    └── HCS Topic → publishes quest_complete JSON message
         ↓
[Frontend updates]
    ├── Timeline: streams all agent messages live
    ├── Status bar: Receipt #N + HashScan TX link
    ├── Dashboard: recharts quest history + live agent reputation
    └── RightPanel: onchain reputation per agent (0-1000 scale)
```

---

## Hackathon Alignment — AI & Agents Track

**"create marketplaces, coordination layers, and tools where autonomous actors can think, transact, and collaborate — leveraging Hedera's fast, low-cost microtransactions and secure consensus"**

- ✅ **Think** — Gemini AI powers each agent's in-character reasoning
- ✅ **Transact** — every quest generates a real Hedera EVM transaction
- ✅ **Collaborate** — 6 agents coordinate via vote consensus + sequential handoff
- ✅ **Hedera consensus** — HCS messages for every agent action
- ✅ **Transparent** — full audit trail in QuestReceipt.sol, publicly readable

---

## What's Next

- x402 payment gating — pay 1 HBAR per advanced quest
- EIP-4337 account abstraction — session keys for agent-native TX signing
- HCS-10 full agent standard compliance (Hashgraph Online)
- Cross-chain quests via Wormhole bridge
- Agent marketplace — users publish custom workflows as NFTs
