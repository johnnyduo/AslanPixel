# Apex Hackathon Submission — AslanGuild

## Project Name
AslanGuild — Agentic Guild on Hedera

## Challenge Theme
Theme 1: AI & Agents

## Project Description (100 words max)
AslanGuild is a multi-agent AI society on Hedera — 6 autonomous agents (Nexus, Oryn, Drax, Lyss, Vex, Kael) that collectively plan, validate, execute, and archive DeFi operations in real-time. Users type a natural-language intent; agents vote on it, then execute sequentially with full transparency. Every action is streamed live via Gemini AI, every quest receipt stored in QuestReceipt.sol, agent reputation updated in AgentRegistry.sol, and activity published to Hedera Consensus Service. The platform self-operates via an auto-quest scheduler — no user required. Humans observe; agents act.

**Tech Stack:** React + TypeScript + Vite + Vercel Edge SSE, Gemini 3.1 Flash Lite, ethers.js, @hashgraph/sdk, Hedera EVM + HCS + HTS + Mirror Node, SaucerSwap testnet, Reown AppKit, Recharts

## Hedera Testnet Account ID
`0.0.5769159`

## Deployed Contract Addresses (Hedera Testnet)
- QuestReceipt: `0x444f5895D29809847E8642Df0e0f4DBdBf541C7D`
- AgentRegistry: `0x8B90AA6D1A12111C8F08C8B9Af4cca9f90336CC4`
- PolicyManager: `0xdBc14F4c53c071cd925fa4a730D06ddc1b4911E4`
- MockUSDC: `0x152Bf42A48677b678c658E452788ea2687525BF7`
- USDCFaucet: `0xCA0558Fa81166C5939335282973Aa2F3A00B3953`

## Hedera Integration Proof
- Every quest generates a real Hedera EVM transaction
- QuestReceipt.sol has been called 5+ times (verify on HashScan)
- All 6 agents registered in AgentRegistry.sol
- HCS topic created and receiving messages on every quest
- USDC Faucet deployed and functional — users can claim test USDC

## Developer Experience Ratings
- Confidence building on Hedera (1-10): **7**
- Ease of getting help when blocked (1-10): **7**
- API/SDK intuitiveness (1-10): **6**
- Ease of debugging (1-10): **6**
- Likely to build again on Hedera (1-10): **9**

## Friction & Blockers
The biggest friction was the dual-runtime split between Vercel Edge (no @hashgraph/sdk, no Node APIs) and Node.js runtime. The EVM JSON-RPC endpoint (testnet.hashio.io/api) works great but the gas/fee model differs from mainnet Ethereum in subtle ways that caused unexpected simulation failures. Mirror Node rate limits on testnet also caused occasional 429s during demo.

## What Worked Well
Hedera's EVM compatibility is excellent — standard ethers.js just works. Mirror Node is genuinely powerful for real-time state. HCS is a unique capability that no other L1 has at this level.

## Suggestions
Better documentation on the runtime split (Edge vs Node) for Vercel deployments. More testnet faucet liquidity. HCS SDK examples in JavaScript/TypeScript would save hours.

## Building on Hedera — Thoughts
Hedera's finality speed is genuinely transformative for agentic applications. Traditional blockchains have 15-60s finality which breaks agent UX (users expect instant feedback). Hedera's 3-5s HCS consensus makes real-time agent coordination possible. The EVM layer + HTS + HCS combination is uniquely powerful — no other chain has all three at this quality level. The main pain point is the tooling maturity gap compared to Ethereum ecosystem, but the underlying protocol is excellent.
