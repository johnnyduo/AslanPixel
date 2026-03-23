#!/usr/bin/env node
/**
 * Deploy all AslanGuild contracts to Hedera testnet EVM
 * Run: node scripts/deploy/deploy-all.mjs
 */
import { ethers } from "ethers";
import { readFileSync, writeFileSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";
import { createRequire } from "module";

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, "..", "..");

// Load .env.deploy
const envRaw = readFileSync(join(ROOT, ".env.deploy"), "utf8");
const env = Object.fromEntries(
  envRaw.split("\n")
    .filter(l => l && !l.startsWith("#"))
    .map(l => l.split("=").map(s => s.trim()))
    .filter(([k]) => k)
);

const PK = env.DEPLOY_PRIVATE_KEY;
if (!PK) { console.error("❌ No DEPLOY_PRIVATE_KEY in .env.deploy — run gen-wallet.mjs first"); process.exit(1); }

const HEDERA_RPC = "https://testnet.hashio.io/api";
const provider = new ethers.JsonRpcProvider(HEDERA_RPC, { chainId: 296, name: "hederaTestnet" });
const deployer = new ethers.Wallet(PK, provider);

function loadArtifact(name) {
  // Try hardhat artifact paths
  const paths = [
    join(ROOT, "artifacts", "contracts", `${name}.sol`, `${name}.json`),
  ];
  for (const p of paths) {
    try { return JSON.parse(readFileSync(p, "utf8")); } catch {}
  }
  throw new Error(`Artifact not found for ${name} — run: npx hardhat compile`);
}

async function deploy(name, constructorArgs = []) {
  const artifact = loadArtifact(name);
  const factory = new ethers.ContractFactory(artifact.abi, artifact.bytecode, deployer);
  console.log(`\n📦 Deploying ${name}...`);
  const contract = await factory.deploy(...constructorArgs, {
    gasLimit: 800_000,
    // gasPrice auto-estimated by provider (Hedera testnet ~990 Gwei)
  });
  await contract.waitForDeployment();
  const address = await contract.getAddress();
  console.log(`   ✅ ${name}: ${address}`);
  return { address, contract, abi: artifact.abi };
}

async function main() {
  console.log("\n🚀 AslanGuild Contract Deploy — Hedera Testnet EVM");
  console.log("   Deployer:", deployer.address);

  const balance = await provider.getBalance(deployer.address);
  console.log("   Balance :", ethers.formatEther(balance), "HBAR");

  if (balance < ethers.parseEther("1")) {
    console.error("\n❌ Insufficient HBAR — need at least 1 HBAR to deploy");
    console.error("   Fund:", deployer.address);
    process.exit(1);
  }

  // 1. QuestReceipt
  const { address: questReceiptAddr } = await deploy("QuestReceipt");

  // 2. AgentRegistry
  const { address: agentRegistryAddr } = await deploy("AgentRegistry");

  // 3. PolicyManager
  const { address: policyManagerAddr } = await deploy("PolicyManager");

  // 4. MockUSDC (10M initial supply = 10_000_000 * 1e6)
  const { address: mockUsdcAddr, contract: usdcContract } = await deploy(
    "MockUSDC",
    [10_000_000n * 1_000_000n]
  );

  // 5. USDCFaucet
  const { address: faucetAddr } = await deploy("USDCFaucet", [mockUsdcAddr]);

  // 6. Add faucet as USDC minter so it can mint on demand
  console.log("\n🔑 Adding faucet as USDC minter...");
  const addMinterTx = await usdcContract.addMinter(faucetAddr, {
    gasLimit: 100_000,
  });
  await addMinterTx.wait();
  console.log("   ✅ Faucet can now mint USDC on demand");

  // 7. Register all 6 agents in AgentRegistry
  const require = createRequire(import.meta.url);
  const registryArtifact = loadArtifact("AgentRegistry");
  const registry = new ethers.Contract(agentRegistryAddr, registryArtifact.abi, deployer);

  const AGENTS = [
    { id: "scout",      name: "Nexus", role: "HCS Intelligence"  },
    { id: "strategist", name: "Oryn",  role: "Strategy Engine"   },
    { id: "sentinel",   name: "Drax",  role: "Risk Sentinel"     },
    { id: "treasurer",  name: "Lyss",  role: "Treasury Keeper"   },
    { id: "executor",   name: "Vex",   role: "TX Executor"       },
    { id: "archivist",  name: "Kael",  role: "Ledger Archivist"  },
  ];

  console.log("\n👾 Registering 6 agents onchain...");
  for (const a of AGENTS) {
    // Use deployer address as placeholder wallet (single key for testnet)
    const tx = await registry.registerAgent(a.id, a.name, a.role, deployer.address, {
      gasLimit: 300_000,
    });
    await tx.wait();
    console.log(`   ✅ ${a.name} (${a.id}) registered`);
  }

  // 8. Update .env.deploy with addresses
  const updatedEnv = envRaw
    .replace(/QUEST_RECEIPT_CONTRACT=.*/, `QUEST_RECEIPT_CONTRACT=${questReceiptAddr}`)
    .replace(/AGENT_REGISTRY_CONTRACT=.*/, `AGENT_REGISTRY_CONTRACT=${agentRegistryAddr}`)
    .replace(/POLICY_MANAGER_CONTRACT=.*/, `POLICY_MANAGER_CONTRACT=${policyManagerAddr}`)
    .replace(/MOCK_USDC_CONTRACT=.*/, `MOCK_USDC_CONTRACT=${mockUsdcAddr}`)
    .replace(/USDC_FAUCET_CONTRACT=.*/, `USDC_FAUCET_CONTRACT=${faucetAddr}`);
  writeFileSync(join(ROOT, ".env.deploy"), updatedEnv);

  console.log("\n" + "=".repeat(60));
  console.log("✨ ALL CONTRACTS DEPLOYED");
  console.log("=".repeat(60));
  console.log(`QuestReceipt    : ${questReceiptAddr}`);
  console.log(`AgentRegistry   : ${agentRegistryAddr}`);
  console.log(`PolicyManager   : ${policyManagerAddr}`);
  console.log(`MockUSDC        : ${mockUsdcAddr}`);
  console.log(`USDCFaucet      : ${faucetAddr}`);
  console.log("=".repeat(60));
  console.log("\n📋 Add these to Vercel env vars:");
  console.log(`QUEST_RECEIPT_CONTRACT=${questReceiptAddr}`);
  console.log(`AGENT_REGISTRY_CONTRACT=${agentRegistryAddr}`);
  console.log(`POLICY_MANAGER_CONTRACT=${policyManagerAddr}`);
  console.log(`MOCK_USDC_CONTRACT=${mockUsdcAddr}`);
  console.log(`USDC_FAUCET_CONTRACT=${faucetAddr}`);
  console.log("\n🔍 View on HashScan:");
  console.log(`https://hashscan.io/testnet/contract/${questReceiptAddr}`);
}

main().catch(e => { console.error(e); process.exit(1); });
