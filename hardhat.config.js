import "@nomicfoundation/hardhat-ethers";
import dotenv from "dotenv";
import { readFileSync } from "fs";

// Load .env.deploy if it exists
let HEDERA_PK = "";
try {
  const raw = readFileSync(".env.deploy", "utf8");
  const match = raw.match(/DEPLOY_PRIVATE_KEY=(.+)/);
  if (match) HEDERA_PK = match[1].trim();
} catch {}

/** @type {import('hardhat/types').HardhatUserConfig} */
const config = {
  solidity: {
    version: "0.8.19",
    settings: { optimizer: { enabled: true, runs: 200 } },
  },
  networks: {
    hederaTestnet: {
      type: "http",
      url: "https://testnet.hashio.io/api",
      chainId: 296,
      accounts: HEDERA_PK ? [HEDERA_PK] : [],
      gasPrice: 2_000_000_000_000,
    },
  },
  paths: {
    sources: "./contracts",
    artifacts: "./artifacts",
    cache: "./cache-hh",
  },
};

export default config;
