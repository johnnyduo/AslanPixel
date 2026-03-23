#!/usr/bin/env node
/**
 * Generate a new EVM wallet for Hedera testnet deployment
 * Outputs address + private key to .env.deploy (gitignored)
 */
import { ethers } from "ethers";
import { writeFileSync, existsSync } from "fs";
import { join, dirname } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT = join(__dirname, "..", "..");
const ENV_FILE = join(ROOT, ".env.deploy");

if (existsSync(ENV_FILE)) {
  // Already have a wallet — just show the address
  const content = (await import("fs")).readFileSync(ENV_FILE, "utf8");
  const pkMatch = content.match(/DEPLOY_PRIVATE_KEY=(.+)/);
  if (pkMatch) {
    const wallet = new ethers.Wallet(pkMatch[1].trim());
    console.log("\n✅ Existing deploy wallet found:");
    console.log("   EVM Address :", wallet.address);
    console.log("   (private key already in .env.deploy)\n");
    console.log("📋 Fund this address on Hedera testnet:");
    console.log("   https://portal.hedera.com  → send HBAR to", wallet.address);
    console.log("   Or use HashScan: https://hashscan.io/testnet/account/" + wallet.address);
    process.exit(0);
  }
}

// Generate fresh wallet
const wallet = ethers.Wallet.createRandom();

const envContent = `# AslanGuild deploy wallet — DO NOT COMMIT
# Fund this EVM address on Hedera testnet before deploying
DEPLOY_PRIVATE_KEY=${wallet.privateKey}
DEPLOY_ADDRESS=${wallet.address}

# Fill these after deploying contracts:
QUEST_RECEIPT_CONTRACT=
AGENT_REGISTRY_CONTRACT=
POLICY_MANAGER_CONTRACT=
MOCK_USDC_CONTRACT=
USDC_FAUCET_CONTRACT=
`;

writeFileSync(ENV_FILE, envContent);

console.log("\n🔑 New deploy wallet generated!");
console.log("   EVM Address :", wallet.address);
console.log("   Saved to    : .env.deploy (gitignored)\n");
console.log("⚡ Next: fund this address with HBAR on Hedera testnet:");
console.log("   https://portal.hedera.com  → transfer HBAR to:");
console.log("  ", wallet.address);
console.log("\n   Then run: node scripts/deploy/deploy-all.mjs\n");
