import { createAppKit } from "@reown/appkit/react";
import { EthersAdapter } from "@reown/appkit-adapter-ethers";
import { defineChain } from "@reown/appkit/networks";
import { createRoot } from "react-dom/client";
import App from "./App.tsx";
import "./index.css";

const hederaTestnet = defineChain({
  id: 296,
  caipNetworkId: "eip155:296",
  chainNamespace: "eip155",
  name: "Hedera Testnet",
  nativeCurrency: { name: "HBAR", symbol: "HBAR", decimals: 8 },
  rpcUrls: { default: { http: ["https://testnet.hashio.io/api"] } },
  blockExplorers: { default: { name: "HashScan", url: "https://hashscan.io/testnet" } },
});

createAppKit({
  adapters: [new EthersAdapter()],
  networks: [hederaTestnet],
  metadata: {
    name: "Aslan Pixel — Agentic Pixel",
    description: "Hedera-powered agentic pixel society with on-chain quest receipts",
    url: typeof window !== "undefined" ? window.location.origin : "https://aslanpixel.vercel.app",
    icons: ["/favicon.ico"],
  },
  projectId: "f67077cf2d46b0a7df545bf6f1f56223",
  features: { analytics: false, email: false, socials: [] },
  themeMode: "dark",
  themeVariables: {
    "--w3m-accent": "hsl(43 90% 55%)",
    "--w3m-border-radius-master": "4px",
  },
});

createRoot(document.getElementById("root")!).render(<App />);
