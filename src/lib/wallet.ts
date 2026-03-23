import { defineChain } from "@reown/appkit/networks";

// Hedera Testnet EVM chain definition — re-exported for use in hooks/components
// AppKit is initialized in main.tsx before React renders
export const hederaTestnet = defineChain({
  id: 296,
  caipNetworkId: "eip155:296",
  chainNamespace: "eip155",
  name: "Hedera Testnet",
  nativeCurrency: { name: "HBAR", symbol: "HBAR", decimals: 8 },
  rpcUrls: {
    default: { http: ["https://testnet.hashio.io/api"] },
  },
  blockExplorers: {
    default: { name: "HashScan", url: "https://hashscan.io/testnet" },
  },
});
