# AslanPixel — Agentic Guild on Hedera

> **Think. Transact. Collaborate. On Hedera.**
> AI agents that debate, vote, and execute real DeFi transactions — every step streamed live and archived immutably onchain.

Live demo: [aslanpixel.vercel.app](https://aslanpixel.vercel.app)
GitHub: [github.com/johnnyduo/AslanPixel](https://github.com/johnnyduo/AslanPixel)
Hedera Testnet Account: `0.0.8342565`

<img width="1690" height="902" alt="Screenshot 2569-03-24 at 08 56 48" src="https://github.com/user-attachments/assets/f2dee283-d172-4ddb-a241-8de6fb980fc7" />

---

## What It Does

AslanPixel is a multi-agent AI guild on Hedera. Six specialized autonomous agents — each powered by Gemini AI, each with their own role and personality — collaborate in real-time to scan, plan, validate, fund, execute, and archive DeFi operations. Every decision is a vote. Every action is a real EVM transaction. Every step is onchain.

**The core insight:** DeFi is a black box. You send funds, you wait, you hope. AslanPixel makes every step visible — every agent decision, every policy check, every transaction — streamed live and archived immutably on Hedera. Not a chatbot. Not a single agent. Not off-chain.

<img width="1713" height="920" alt="Screenshot 2569-03-24 at 08 57 13" src="https://github.com/user-attachments/assets/a505d8a8-d495-451a-8548-cb9b7ac8bd8c" />

### The 6 Agents

| Agent | Role | Hedera Layer |
|-------|------|-------------|
| **Nexus** ◈ | HCS Intelligence — reads consensus streams | HCS (Hedera Consensus Service) |
| **Oryn** ▲ | Strategy Engine — models 3 execution paths | EVM Smart Contracts |
| **Drax** ◆ | Risk Sentinel — enforces PolicyManager.sol, holds VETO | PolicyManager.sol |
| **Lyss** ◉ | Treasury Keeper — holds 500 HBAR gas reserve, tracks USDC | HTS (Hedera Token Service) |
| **Vex** ▶ | TX Executor — simulate → sign → submit, links HashScan | Hedera EVM |
| **Kael** ▣ | Ledger Archivist — writes QuestReceipt.sol, updates reputation | Mirror Node + QuestReceipt.sol |

### How It Works

1. User types a natural language intent: *"Rebalance treasury with 30% USDC buffer"*
2. **Guild Vote**: All 6 agents vote sequentially — Drax (Sentinel) can veto high-risk quests
3. **Approved**: Agents mobilize sequentially, each streaming their action live to the timeline
4. **Onchain**: Quest receipt stored in `QuestReceipt.sol`, agent reputation updated in `AgentRegistry.sol`
5. **HCS**: Every quest event posted to Hedera Consensus Service topic `0.0.5178025`
6. **TX Link**: HashScan URL shown for every confirmed transaction

### Live Features

| Feature | Description |
|---------|-------------|
| **Pixel World Map** | NPCs patrol a pixel-art world — each building represents a Hedera module |
| **Quest Runner** | Type an intent → 7-step agent stream fires instantly, live in browser |
| **Guild Vote Panel** | Watch each agent debate in real-time — Drax can VETO any quest |
| **Live TX Timeline** | Every step streams via SSE — TX hash links directly to HashScan |
| **Agent Dashboard** | Recharts quest history + reputation scores pulled live from chain |
| **Register an Agent** | Your agent ID goes onchain — NPC spawns in the pixel map |
| **USDC Faucet** | One click → 100 testnet USDC, cooldown enforced onchain |
| **Auto-Quest Mode** | Guild fires automatically every 9 minutes — platform is always alive |

---

## Tech Stack

### Frontend
- React 18 + TypeScript + Vite → deployed on Vercel
- Tailwind CSS + shadcn/ui + custom pixel-art design system
- Recharts for live quest history chart
- Reown AppKit v1.8.19 for MetaMask / WalletConnect
- Zustand for cross-component state

### AI
- **Gemini 3.1 Flash Lite Preview** (`gemini-3.1-flash-lite-preview`) — powers all 6 agent responses
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
- **HCS** — agent activity and quest events published as Hedera Consensus Service messages (topic `0.0.5178025`)
- **HTS** — HBAR/USDC balances tracked via Mirror Node in tinyhbar
- **EVM (Hedera testnet, chainID 296)** — all contracts deployed via Remix IDE
- **Mirror Node** — real-time price, balance, receipt, and token lookups (30s Vercel Edge cache)
- **SaucerSwap testnet** — live pool TVL/volume injected into agent prompts

### Smart Contracts (Hedera Testnet)

| Contract | Address | Verified |
|----------|---------|---------|
| `QuestReceipt.sol` | `0x444f5895D29809847E8642Df0e0f4DBdBf541C7D` | [HashScan ↗](https://hashscan.io/testnet/contract/0x444f5895D29809847E8642Df0e0f4DBdBf541C7D) |
| `AgentRegistry.sol` | `0x8B90AA6D1A12111C8F08C8B9Af4cca9f90336CC4` | [HashScan ↗](https://hashscan.io/testnet/contract/0x8B90AA6D1A12111C8F08C8B9Af4cca9f90336CC4) |
| `PolicyManager.sol` | `0xdBc14F4c53c071cd925fa4a730D06ddc1b4911E4` | [HashScan ↗](https://hashscan.io/testnet/contract/0xdBc14F4c53c071cd925fa4a730D06ddc1b4911E4) |
| `MockUSDC` | `0x152Bf42A48677b678c658E452788ea2687525BF7` | [HashScan ↗](https://hashscan.io/testnet/contract/0x152Bf42A48677b678c658E452788ea2687525BF7) |
| `USDCFaucet` | `0xCA0558Fa81166C5939335282973Aa2F3A00B3953` | [HashScan ↗](https://hashscan.io/testnet/contract/0xCA0558Fa81166C5939335282973Aa2F3A00B3953) |

### ERC-8004 Trustless Agents (Hedera Testnet, chainId 296)

Agents are registered as **ERC-8004 Trustless Agents** via the canonical [ERC-8004](https://eips.ethereum.org/EIPS/eip-8004) IdentityRegistry — co-authored by MetaMask, Ethereum Foundation, Google, and Coinbase (live on Ethereum mainnet Jan 2026). ERC-8004 extends ERC-721, so each `agentId = tokenId` is an NFT — tradeable on any marketplace. Reputation is tracked on-chain via the ReputationRegistry and persists through ownership transfers. 43+ agents registered on Hedera testnet.

| Contract | Address | HashScan |
|----------|---------|---------|
| `ERC-8004 IdentityRegistry` | `0x8004A818BFB912233c491871b3d84c89A494BD9e` | [View ↗](https://hashscan.io/testnet/contract/0x8004A818BFB912233c491871b3d84c89A494BD9e) |
| `ERC-8004 ReputationRegistry` | `0x8004B663056A597Dffe9eCcC1965A193B7388713` | [View ↗](https://hashscan.io/testnet/contract/0x8004B663056A597Dffe9eCcC1965A193B7388713) |

**Agent Card (A2A Discovery):** [`/.well-known/agent-card.json`](https://aslanpixel.vercel.app/.well-known/agent-card.json) — live endpoint returning full guild metadata: all 6 agents, HCS topic, contract addresses, quest/stream API endpoints. Compatible with HOL Registry Broker and any A2A-standard client.

---

## Running Locally

```bash
git clone https://github.com/johnnyduo/AslanPixel
cd AslanPixel
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
HEDERA_ACCOUNT_ID=        # Hedera account ID (0.0.8342565)
HEDERA_HCS_TOPIC_ID=      # HCS topic ID (0.0.5178025)
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
    ├── Drax  ◆  — PolicyManager.sol compliance check (VETO if fails)
    ├── Lyss  ◉  — Treasury budget allocation in tinyhbar
    ├── Vex   ▶  — EVM simulate → sign → submit
    └── Kael  ▣  — QuestReceipt.sol write + Mirror Node archive
         ↓
[POST /api/store-receipt — Node.js]
    ├── QuestReceipt.sol → stores inputHash + txHash onchain
    ├── AgentRegistry.sol → updates reputation for all 6 agents
    └── HCS Topic 0.0.5178025 → publishes quest_complete JSON message
         ↓
[Frontend updates]
    ├── Timeline: streams all agent messages live via SSE
    ├── Status bar: Receipt #N + HashScan TX link
    ├── Dashboard: recharts quest history + live agent reputation
    └── RightPanel: onchain reputation per agent (0–1000 scale)
```

---

## Hackathon Alignment — AI & Agents Track

**"create marketplaces, coordination layers, and tools where autonomous actors can think, transact, and collaborate — leveraging Hedera's fast, low-cost microtransactions and secure consensus"**

- ✅ **Think** — Gemini 3.1 Flash Lite powers each agent's in-character reasoning, confidence scoring, and multi-branch strategy
- ✅ **Transact** — every quest generates a real Hedera EVM transaction (simulate → sign → submit, Chain 296)
- ✅ **Collaborate** — 6 agents coordinate via sequential vote + handoff, Drax VETO blocks non-compliant quests
- ✅ **Hedera consensus** — HCS messages for every agent action, topic `0.0.5178025`
- ✅ **Microtransactions** — agent session wages per op; auto-quest fires every 9 min
- ✅ **Transparent** — full audit trail in QuestReceipt.sol, publicly readable on HashScan forever

---

## Future Roadmap

| Phase | Feature | Description |
|-------|---------|-------------|
| **v1.1** | **x402 API Enforcement** | Full HTTP 402 payment gating — advanced quests require HBAR micropayment before execution |
| **v1.1** | **EIP-4337 Account Abstraction** | Session keys for agent-native TX signing — no wallet popups per action |
| **v1.2** | **ERC-6551 Token Bound Accounts** | Each agent NFT gets its own EVM wallet — agents hold funds, sign independently |
| **v1.2** | **Agent Marketplace** | Users publish, discover, and trade custom agent NFTs on any ERC-721 marketplace |
| **v2.0** | **Cross-Chain Quests** | Hedera + EVM chains via Wormhole bridge — agents execute across networks in one quest |
| **v2.0** | **Agent-to-Agent Economy** | Agents hire sub-agents, pay wages in HBAR, and compose multi-guild workflows autonomously |
