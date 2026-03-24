import { useState, useEffect, useRef, useMemo } from "react";
import { JsonRpcProvider, Contract } from "ethers";
import { useAppKitState } from "@reown/appkit/react";
import { AGENTS } from "@/data/agents";
import type { Agent } from "@/data/agents";
import { useLiveTimeline } from "@/hooks/useLiveTimeline";
import { useAgentStats } from "@/hooks/useContracts";
import type { TimelineMessage } from "@/lib/agentConversation";

// ── MAP THEMES ───────────────────────────────────────────────────────────────
interface MapTheme {
  id: string;
  name: string;
  icon: string;
  // overall tint & scanline
  bgBase: string;           // CSS background for the map container
  scanline: string;         // scanline colour
  borderColor: string;      // map border glow
  ambientGlow: string;      // radial glow behind rooms
  // corner glow colours (top-left, top-right, bottom-left, bottom-right)
  cornerGlows: [string,string,string,string];
  // decoration palette overrides (indexed same as `decorations` array order)
  decoColors: string[];
  // room color overrides (keyed by room name — undefined = keep original)
  roomColors: Partial<Record<string,string>>;
  // skybox gradient
  skybox: string;
}

const THEMES: MapTheme[] = [
  {
    id: "cyber",
    name: "Cyber",
    icon: "◈",
    bgBase: "hsl(225 30% 5% / 0.9)",
    scanline: "hsl(225 35% 3% / 0.08)",
    borderColor: "hsl(43 90% 55% / 0.22)",
    ambientGlow: "hsl(43 90% 55% / 0.05)",
    cornerGlows: [
      "hsl(195 100% 50% / 0.06)",
      "hsl(280 65% 65% / 0.06)",
      "hsl(142 70% 45% / 0.06)",
      "hsl(38 92% 50% / 0.06)",
    ],
    decoColors: [
      "#00e5ff","#a78bfa","#34d399","#fb923c", // crystals
      "#00e5ff","#34d399",                      // left hnodes
      "#a78bfa","#fb923c",                      // right hnodes
      "#00e5ff","#a78bfa",                      // top orbs
      "#34d399","#fb923c",                      // mid runes
      "#06b6d4","#f59e0b",                      // arch towers
      "#00bfff","#c084fc","#4ade80","#fb923c","#fbbf24","#f87171", // lanterns
      "#fbbf24",                                // top edge orb
      "#f87171",                                // bottom edge orb
    ],
    roomColors: {},
    skybox: `
      radial-gradient(ellipse 90% 85% at 50% 50%, transparent 45%, hsl(225 35% 3% / 0.6) 100%),
      radial-gradient(ellipse 30% 20% at 15% 15%, hsl(195 100% 50% / 0.06) 0%, transparent 70%),
      radial-gradient(ellipse 30% 20% at 85% 15%, hsl(280 65% 65% / 0.06) 0%, transparent 70%),
      radial-gradient(ellipse 30% 20% at 15% 85%, hsl(142 70% 45% / 0.06) 0%, transparent 70%),
      radial-gradient(ellipse 30% 20% at 85% 85%, hsl(38 92% 50% / 0.06) 0%, transparent 70%),
      radial-gradient(ellipse 20% 15% at 50% 40%, hsl(43 90% 55% / 0.05) 0%, transparent 70%)
    `,
  },
  {
    id: "lava",
    name: "Lava",
    icon: "◆",
    bgBase: "hsl(15 40% 5% / 0.95)",
    scanline: "hsl(10 50% 3% / 0.12)",
    borderColor: "hsl(20 95% 55% / 0.30)",
    ambientGlow: "hsl(20 95% 55% / 0.06)",
    cornerGlows: [
      "hsl(0 90% 55% / 0.08)",
      "hsl(30 100% 55% / 0.07)",
      "hsl(15 85% 45% / 0.07)",
      "hsl(40 100% 50% / 0.08)",
    ],
    decoColors: [
      "#ff4500","#ff6b00","#ff2200","#ffaa00", // crystals
      "#ff4500","#ff6b00",                      // left hnodes
      "#ff2200","#ffaa00",                      // right hnodes
      "#ff4500","#ff6b00",                      // top orbs
      "#ff2200","#ffaa00",                      // mid runes
      "#ff6633","#ff9900",                      // arch towers
      "#ff3300","#ff6b00","#ff4400","#ffaa00","#ff7700","#ff2200", // lanterns
      "#ffcc00",                                // top edge orb
      "#ff4400",                                // bottom edge orb
    ],
    roomColors: {
      consensushub:  "hsl(20 95% 55%)",
      tokenforge:    "hsl(0 90% 60%)",
      mirrorvault:   "hsl(35 100% 55%)",
      smartspire:    "hsl(10 90% 50%)",
      dexgate:       "hsl(40 95% 55%)",
      ledgerarchive: "hsl(5 85% 55%)",
    },
    skybox: `
      radial-gradient(ellipse 90% 85% at 50% 50%, transparent 40%, hsl(10 50% 3% / 0.75) 100%),
      radial-gradient(ellipse 40% 25% at 50% 70%, hsl(20 100% 40% / 0.10) 0%, transparent 70%),
      radial-gradient(ellipse 25% 20% at 20% 80%, hsl(0 90% 40% / 0.08) 0%, transparent 70%),
      radial-gradient(ellipse 25% 20% at 80% 80%, hsl(40 100% 45% / 0.08) 0%, transparent 70%),
      radial-gradient(ellipse 20% 15% at 50% 90%, hsl(15 95% 50% / 0.12) 0%, transparent 70%)
    `,
  },
  {
    id: "void",
    name: "Void",
    icon: "▣",
    bgBase: "hsl(270 30% 4% / 0.97)",
    scanline: "hsl(270 40% 3% / 0.10)",
    borderColor: "hsl(280 80% 65% / 0.25)",
    ambientGlow: "hsl(280 80% 65% / 0.05)",
    cornerGlows: [
      "hsl(260 80% 65% / 0.07)",
      "hsl(300 70% 60% / 0.07)",
      "hsl(240 90% 65% / 0.07)",
      "hsl(280 75% 60% / 0.07)",
    ],
    decoColors: [
      "#c084fc","#e879f9","#818cf8","#a78bfa", // crystals
      "#c084fc","#818cf8",                      // left hnodes
      "#e879f9","#a78bfa",                      // right hnodes
      "#c084fc","#e879f9",                      // top orbs
      "#818cf8","#a78bfa",                      // mid runes
      "#7c3aed","#d946ef",                      // arch towers
      "#a855f7","#c084fc","#818cf8","#e879f9","#9333ea","#7c3aed", // lanterns
      "#d946ef",                                // top edge orb
      "#7c3aed",                                // bottom edge orb
    ],
    roomColors: {
      consensushub:  "hsl(280 80% 65%)",
      tokenforge:    "hsl(260 80% 65%)",
      mirrorvault:   "hsl(300 70% 60%)",
      smartspire:    "hsl(240 90% 65%)",
      dexgate:       "hsl(290 75% 60%)",
      ledgerarchive: "hsl(270 75% 62%)",
    },
    skybox: `
      radial-gradient(ellipse 90% 85% at 50% 50%, transparent 45%, hsl(270 40% 3% / 0.80) 100%),
      radial-gradient(ellipse 50% 40% at 50% 20%, hsl(280 80% 50% / 0.06) 0%, transparent 70%),
      radial-gradient(ellipse 30% 25% at 20% 50%, hsl(260 80% 55% / 0.07) 0%, transparent 70%),
      radial-gradient(ellipse 30% 25% at 80% 50%, hsl(300 70% 55% / 0.07) 0%, transparent 70%),
      radial-gradient(ellipse 20% 15% at 50% 50%, hsl(280 90% 60% / 0.05) 0%, transparent 70%)
    `,
  },
];

const HEDERA_TESTNET_RPC = "https://testnet.hashio.io/api";
const QUEST_RECEIPT_ADDRESS = "0x444f5895D29809847E8642Df0e0f4DBdBf541C7D";
const AGENT_REGISTRY_ADDRESS = "0x8B90AA6D1A12111C8F08C8B9Af4cca9f90336CC4";

interface Room {
  name: string; label: string;
  x: number; y: number; w: number; h: number;
  color: string; icon: string; desc: string; stats: string[];
}

const BASE_ROOMS: Room[] = [
  // Positions sized to match pixel art buildings exactly, leaving corridors clear
  // Corridors: top-H(y=27%), mid-H(y=54%), left-V(x=30%), right-V(x=68%), arch-V(x=50%)
  { name:"consensushub", label:"Consensus Hub",   x:36, y:32, w:28, h:18, color:"hsl(43 90% 55%)",   icon:"⬡", desc:"HCS — Hedera Consensus Service",  stats:["HCS Topic #0.0.1234","847 msgs/min","Last Seq #4,192"] },
  { name:"tokenforge",   label:"Token Forge",     x: 5, y: 6, w:21, h:17, color:"hsl(195 100% 50%)", icon:"◈", desc:"HTS — Hedera Token Service",       stats:["HTS Tokens: 12","3 Pending Mints","Total Supply: 1.2M"] },
  { name:"mirrorvault",  label:"Mirror Vault",    x:74, y: 6, w:21, h:17, color:"hsl(280 65% 65%)",  icon:"◆", desc:"Mirror Node — Real-time State",    stats:["12,847.50 HBAR","Slot: 4,192,441","Sync: LIVE"] },
  { name:"smartspire",   label:"Smart Spire",     x: 5, y:57, w:21, h:17, color:"hsl(142 70% 45%)",  icon:"▲", desc:"EVM — Smart Contracts",            stats:["3 Contracts Deployed","Gas: 2,115 tinyhbar","Audit: PASS"] },
  { name:"dexgate",      label:"DEX Gate",        x:74, y:57, w:21, h:17, color:"hsl(38 92% 50%)",   icon:"▶", desc:"SaucerSwap — DeFi Execution",      stats:["Vol 24h: $48,291","Top: HBAR/USDC","Slippage: 0.12%"] },
  { name:"ledgerarchive",label:"Ledger Archive",  x:36, y:80, w:28, h:16, color:"hsl(0 72% 60%)",    icon:"▣", desc:"QuestReceipt — Immutable Log",     stats:["Receipts: …","Last ID: …","Hash: 0xab12…"] },
];

// ── HEDERA KINGDOM DECORATIONS ──────────────────────────────────────────────
// All trees removed. Pure cyber-fantasy: crystals, nodes, orbs, towers, runes.
const decorations = [
  // ── FOUR CORNER CRYSTAL PILLARS ──
  { x:"2.5%", y:"6%",  type:"crystal", color:"#00e5ff" },
  { x:"97.5%",y:"6%",  type:"crystal", color:"#a78bfa" },
  { x:"2.5%", y:"82%", type:"crystal", color:"#34d399" },
  { x:"97.5%",y:"82%", type:"crystal", color:"#fb923c" },

  // ── LEFT WALL: Hedera Nodes (between Token Forge & Smart Spire) ──
  { x:"2.5%", y:"38%", type:"hnode",   color:"#00e5ff" },
  { x:"2.5%", y:"50%", type:"hnode",   color:"#34d399" },

  // ── RIGHT WALL: Hedera Nodes (between Mirror Vault & DEX Gate) ──
  { x:"97.5%",y:"38%", type:"hnode",   color:"#a78bfa" },
  { x:"97.5%",y:"50%", type:"hnode",   color:"#fb923c" },

  // ── TOP CORRIDOR: Energy Orbs flanking (y≈27% corridor) ──
  { x:"31%",  y:"22%", type:"orb",     color:"#00e5ff" },
  { x:"69%",  y:"22%", type:"orb",     color:"#a78bfa" },

  // ── MID CORRIDOR: Rune Stones flanking (y≈54% corridor) ──
  { x:"31%",  y:"49%", type:"rune",    color:"#34d399" },
  { x:"69%",  y:"49%", type:"rune",    color:"#fb923c" },

  // ── ARCH CORRIDOR: Data Towers (x≈50%, between Hub & Archive) ──
  { x:"46%",  y:"62%", type:"tower",   color:"#06b6d4" },
  { x:"54%",  y:"62%", type:"tower",   color:"#f59e0b" },

  // ── JUNCTION LANTERNS — glowing wayposts at every corridor cross ──
  { x:"30%",  y:"27%", type:"lantern", color:"#00bfff"  },
  { x:"68%",  y:"27%", type:"lantern", color:"#c084fc"  },
  { x:"30%",  y:"54%", type:"lantern", color:"#4ade80"  },
  { x:"68%",  y:"54%", type:"lantern", color:"#fb923c"  },
  { x:"50%",  y:"54%", type:"lantern", color:"#fbbf24"  },
  { x:"50%",  y:"70%", type:"lantern", color:"#f87171"  },

  // ── TOP EDGE: Mini Orbs accent ──
  { x:"50%",  y:"4%",  type:"orb",     color:"#fbbf24" },

  // ── BOTTOM EDGE: Mini Orbs accent ──
  { x:"50%",  y:"95%", type:"orb",     color:"#f87171" },
];

// PATROL mirrors CSS keyframe waypoints exactly (for direction detection)
// Each entry is an ordered list of key positions matching CSS @keyframes npc-move-N
const PATROL: Record<string, { x:number; y:number }[]> = {
  // Scout (npc-move-1): guild → top-H corridor → hub → left-V → strategy → back
  scout: [
    {x:15,y:14},{x:15,y:14},  // guild inside, wait
    {x:26,y:14},{x:26,y:27},  // exit east, go south to top-H
    {x:36,y:27},{x:36,y:41},  // east to hub entrance, south into hub
    {x:50,y:41},{x:36,y:41},  // cross hub east, back west
    {x:36,y:50},{x:30,y:50},  // exit hub south, west to left-V
    {x:30,y:57},{x:15,y:57},  // south on left-V, west into strategy
    {x:15,y:65},{x:15,y:65},  // deeper in strategy, wait
    {x:15,y:57},{x:30,y:57},  // north out of strategy, east to left-V
    {x:30,y:27},{x:26,y:27},  // north on left-V to top-H, west
    {x:26,y:14},{x:15,y:14},  // north to guild level, west into guild
  ],
  // Strategist (npc-move-2): strategy → left-V → hub → right-V → vault → back
  strategist: [
    {x:15,y:65},{x:26,y:65},  // strategy → exit east
    {x:26,y:54},{x:50,y:54},  // north to mid-H, east along mid-H
    {x:50,y:41},{x:63,y:41},  // north into hub, east across hub
    {x:63,y:27},{x:68,y:27},  // north exit hub, east on top-H
    {x:68,y:14},{x:85,y:14},  // north to vault level, east into vault
    {x:85,y:14},{x:68,y:14},  // wait in vault, west exit
    {x:68,y:27},{x:63,y:27},  // south on right-V, west to hub corner
    {x:63,y:41},{x:50,y:41},  // south into hub, west cross hub
    {x:50,y:54},{x:26,y:54},  // south exit hub, west along mid-H
    {x:26,y:65},{x:15,y:65},  // south enter strategy, west deeper
  ],
  // Sentinel (npc-move-3): hub perimeter loop (strictly rectangular)
  sentinel: [
    {x:37,y:32},{x:63,y:32},  // hub top-left → top-right (east)
    {x:63,y:50},{x:37,y:50},  // top-right → bottom-right (south), → bottom-left (west)
    {x:37,y:32},{x:50,y:32},  // bottom-left → top-left (north), → top-middle (east)
    {x:50,y:50},{x:37,y:32},  // → bottom-middle (south), return to start
  ],
  // Treasurer (npc-move-4): vault → right-V south → hub east side → back
  treasurer: [
    {x:85,y:14},{x:85,y:14},  // vault inside, wait
    {x:74,y:14},{x:68,y:14},  // west exit vault, reach right-V junction
    {x:68,y:27},{x:68,y:41},  // south on right-V to top-H, continue south to hub level
    {x:63,y:41},{x:63,y:41},  // west enter hub east side, wait
    {x:68,y:41},{x:68,y:27},  // east exit hub, north on right-V
    {x:68,y:14},{x:74,y:14},  // north to vault level, east enter vault
    {x:85,y:14},              // east deeper in vault
  ],
  // Executor (npc-move-5): market → right-V north → mid-H west → archive-V south → archive → back
  executor: [
    {x:85,y:65},{x:74,y:65},  // market → exit west
    {x:68,y:65},{x:68,y:54},  // reach right-V junction, north to mid-H
    {x:50,y:54},{x:50,y:50},  // west along mid-H, north enter hub bottom
    {x:50,y:50},{x:50,y:54},  // wait at hub, south exit
    {x:50,y:65},{x:50,y:80},  // south on arch-V, reach archive top
    {x:50,y:88},{x:50,y:88},  // enter archive, wait
    {x:50,y:80},{x:50,y:65},  // north exit archive, north on arch-V
    {x:68,y:65},{x:74,y:65},  // east to market junction, east to market door
    {x:85,y:65},              // into market
  ],
  // Archivist (npc-move-6): archive → arch-V north → hub → cross hub → back south
  archivist: [
    {x:50,y:88},{x:50,y:80},  // archive → exit north
    {x:50,y:65},{x:50,y:54},  // north on arch-V, continue to mid-H
    {x:50,y:50},{x:50,y:41},  // north enter hub south, north through hub center
    {x:37,y:41},{x:37,y:41},  // west cross hub, wait at hub west
    {x:50,y:41},{x:63,y:41},  // east back to center, east cross hub
    {x:63,y:41},{x:50,y:41},  // wait at hub east, west back to center
    {x:50,y:50},{x:50,y:65},  // south exit hub, south on arch-V
    {x:50,y:80},{x:50,y:88},  // reach archive, enter archive
  ],
};

function getDir(dx:number, dy:number): "s"|"n"|"e"|"w" {
  if (Math.abs(dx) >= Math.abs(dy)) return dx >= 0 ? "e" : "w";
  return dy > 0 ? "s" : "n";
}

function getAgentDir(id:string, t:number): "s"|"n"|"e"|"w" {
  const pts = PATROL[id];
  if (!pts) return "e";
  const seg = t * (pts.length - 1);
  const i   = Math.min(Math.floor(seg), pts.length - 2);
  return getDir(pts[i+1].x - pts[i].x, pts[i+1].y - pts[i].y);
}

// ── HEDERA KINGDOM DECORATIONS ──────────────────────────────────────────────

// Crystal Pillar — tall glowing obelisk
const CrystalPillarSVG = ({ color = "#00e5ff" }: { color?: string }) => (
  <svg width="18" height="32" viewBox="0 0 18 32" style={{ imageRendering:"pixelated" }}>
    {/* base */}
    <rect x="3" y="28" width="12" height="4" fill="#1a2240"/>
    <rect x="2" y="27" width="14" height="2" fill="#243060"/>
    {/* shaft */}
    <rect x="5" y="8"  width="8"  height="20" fill="#0d1630"/>
    <rect x="6" y="8"  width="6"  height="20" fill={color} opacity="0.18"/>
    {/* facets */}
    <rect x="5" y="10" width="2"  height="16" fill={color} opacity="0.35"/>
    <rect x="11" y="10" width="2" height="16" fill={color} opacity="0.20"/>
    {/* cap */}
    <rect x="6" y="4"  width="6"  height="5"  fill={color} opacity="0.6"/>
    <rect x="7" y="2"  width="4"  height="3"  fill={color} opacity="0.8"/>
    <rect x="8" y="0"  width="2"  height="3"  fill="#fff"  opacity="0.9"/>
    {/* inner glow line */}
    <rect x="8" y="5"  width="2"  height="22" fill="#fff"  opacity="0.12"/>
  </svg>
);

// Hedera Node — floating hex beacon
const HederaNodeSVG = ({ color = "#8b5cf6" }: { color?: string }) => (
  <svg width="24" height="28" viewBox="0 0 24 28" style={{ imageRendering:"pixelated" }}>
    {/* pole */}
    <rect x="11" y="16" width="2" height="12" fill="#1a2240"/>
    <rect x="10" y="26" width="4" height="2"  fill="#243060"/>
    {/* hex body */}
    <polygon points="12,2 20,7 20,17 12,22 4,17 4,7" fill="#0d1630"/>
    <polygon points="12,4 18,8 18,16 12,20 6,16 6,8"  fill={color} opacity="0.25"/>
    {/* H rune */}
    <rect x="9"  y="8"  width="2" height="8"  fill={color} opacity="0.9"/>
    <rect x="13" y="8"  width="2" height="8"  fill={color} opacity="0.9"/>
    <rect x="9"  y="11" width="6" height="2"  fill={color} opacity="0.9"/>
    {/* rim glow */}
    <polygon points="12,2 20,7 20,17 12,22 4,17 4,7" fill="none"
      stroke={color} strokeWidth="1" opacity="0.7"/>
  </svg>
);

// Energy Orb — pulsing sphere on pedestal
const EnergyOrbSVG = ({ color = "#f59e0b" }: { color?: string }) => (
  <svg width="20" height="26" viewBox="0 0 20 26" style={{ imageRendering:"pixelated" }}>
    {/* pedestal */}
    <rect x="7"  y="22" width="6"  height="4"  fill="#1a2240"/>
    <rect x="6"  y="20" width="8"  height="3"  fill="#243060"/>
    <rect x="8"  y="18" width="4"  height="3"  fill="#2d3a70"/>
    {/* orb outer */}
    <rect x="4"  y="4"  width="12" height="12" fill={color} opacity="0.15" rx="6"/>
    <rect x="5"  y="5"  width="10" height="10" fill={color} opacity="0.30" rx="5"/>
    <rect x="6"  y="6"  width="8"  height="8"  fill={color} opacity="0.55" rx="4"/>
    {/* orb core */}
    <rect x="8"  y="8"  width="4"  height="4"  fill="#fff"  opacity="0.8"/>
    <rect x="9"  y="9"  width="2"  height="2"  fill="#fff"  opacity="1.0"/>
    {/* sparkles */}
    <rect x="3"  y="7"  width="2"  height="2"  fill={color} opacity="0.6"/>
    <rect x="15" y="9"  width="2"  height="2"  fill={color} opacity="0.5"/>
    <rect x="9"  y="1"  width="2"  height="2"  fill={color} opacity="0.7"/>
  </svg>
);

// Rune Stone — ancient monolith with glowing sigils
const RuneStoneSVG = ({ color = "#10b981" }: { color?: string }) => (
  <svg width="20" height="28" viewBox="0 0 20 28" style={{ imageRendering:"pixelated" }}>
    {/* base slab */}
    <rect x="2"  y="24" width="16" height="4"  fill="#111827"/>
    {/* stone body */}
    <rect x="4"  y="4"  width="12" height="22" fill="#1e293b"/>
    <rect x="3"  y="5"  width="14" height="20" fill="#243050"/>
    {/* top arch */}
    <rect x="5"  y="2"  width="10" height="4"  fill="#2d3a6a"/>
    <rect x="7"  y="0"  width="6"  height="4"  fill="#3a4880"/>
    {/* rune glyphs */}
    <rect x="8"  y="7"  width="4"  height="1"  fill={color} opacity="0.9"/>
    <rect x="9"  y="8"  width="2"  height="4"  fill={color} opacity="0.9"/>
    <rect x="8"  y="12" width="4"  height="1"  fill={color} opacity="0.9"/>
    <rect x="7"  y="15" width="6"  height="1"  fill={color} opacity="0.7"/>
    <rect x="8"  y="16" width="4"  height="3"  fill={color} opacity="0.5"/>
    <rect x="9"  y="19" width="2"  height="2"  fill={color} opacity="0.8"/>
    {/* edge glow */}
    <rect x="3"  y="5"  width="1"  height="20" fill={color} opacity="0.15"/>
    <rect x="16" y="5"  width="1"  height="20" fill={color} opacity="0.10"/>
  </svg>
);

// Data Tower — antenna mast broadcasting consensus
const DataTowerSVG = ({ color = "#06b6d4" }: { color?: string }) => (
  <svg width="22" height="34" viewBox="0 0 22 34" style={{ imageRendering:"pixelated" }}>
    {/* base */}
    <rect x="4"  y="30" width="14" height="4"  fill="#111827"/>
    <rect x="6"  y="28" width="10" height="3"  fill="#1a2240"/>
    {/* legs */}
    <rect x="6"  y="18" width="2"  height="12" fill="#243060"/>
    <rect x="14" y="18" width="2"  height="12" fill="#243060"/>
    <rect x="8"  y="22" width="6"  height="2"  fill="#2d3a70"/>
    {/* mast */}
    <rect x="10" y="4"  width="2"  height="16" fill="#334080"/>
    {/* dishes */}
    <rect x="5"  y="10" width="6"  height="2"  fill={color} opacity="0.8"/>
    <rect x="5"  y="9"  width="2"  height="1"  fill={color} opacity="0.6"/>
    <rect x="11" y="14" width="6"  height="2"  fill={color} opacity="0.8"/>
    <rect x="15" y="13" width="2"  height="1"  fill={color} opacity="0.6"/>
    {/* signal rings */}
    <rect x="8"  y="1"  width="6"  height="1"  fill={color} opacity="0.4"/>
    <rect x="7"  y="0"  width="8"  height="1"  fill={color} opacity="0.25"/>
    {/* tip beacon */}
    <rect x="10" y="2"  width="2"  height="3"  fill="#fff"  opacity="0.9"/>
  </svg>
);

// Lantern — kept for junction markers
const LanternSVG = ({ color }: { color: string }) => (
  <svg width="12" height="22" viewBox="0 0 12 22" style={{ imageRendering:"pixelated" }}>
    <rect x="5" y="0"  width="2"  height="4"  fill="#556"/>
    <rect x="3" y="4"  width="6"  height="1"  fill="#778"/>
    <rect x="2" y="5"  width="8"  height="10" fill="#111827"/>
    <rect x="3" y="6"  width="6"  height="8"  fill={color} opacity="0.75"/>
    <rect x="4" y="7"  width="4"  height="6"  fill={color} opacity="0.4"/>
    <rect x="5" y="8"  width="2"  height="4"  fill="#fff"  opacity="0.35"/>
    <rect x="2" y="15" width="8"  height="2"  fill="#778"/>
    <rect x="4" y="17" width="4"  height="3"  fill="#556"/>
    <rect x="5" y="20" width="2"  height="2"  fill="#334"/>
  </svg>
);

const DECO_COMPONENTS: Record<string, (color?:string) => JSX.Element> = {
  crystal:   (c) => <CrystalPillarSVG color={c||"#00e5ff"} />,
  hnode:     (c) => <HederaNodeSVG    color={c||"#8b5cf6"} />,
  orb:       (c) => <EnergyOrbSVG     color={c||"#f59e0b"} />,
  rune:      (c) => <RuneStoneSVG     color={c||"#10b981"} />,
  tower:     (c) => <DataTowerSVG     color={c||"#06b6d4"} />,
  lantern:   (c) => <LanternSVG       color={c||"#fff"}    />,
};

// Strip "AgentName: " prefix from message content for cleaner bubble display
function stripPrefix(content: string): string {
  return content.replace(/^[A-Za-z]+:\s*/, "");
}

// Durations per animIndex (1-10)
const NPC_ANIM_DURATIONS: Record<number, number> = {
  1:35000, 2:40000, 3:45000, 4:50000, 5:55000, 6:60000,
  7:38000, 8:42000, 9:47000, 10:52000,
};

// Custom agent colors palette for agents 7+
const CUSTOM_AGENT_COLORS = [
  "hsl(310 70% 60%)", "hsl(170 80% 50%)", "hsl(55 90% 55%)", "hsl(230 80% 65%)",
];

const PixelMap = ({ hideAgents = false }: { hideAgents?: boolean }) => {
  const [rooms, setRooms] = useState<Room[]>(BASE_ROOMS);
  const [hoveredRoom,  setHoveredRoom]  = useState<string|null>(null);
  const [hoveredAgent, setHoveredAgent] = useState<string|null>(null);
  const [themeIdx, setThemeIdx] = useState(0);
  const { open: walletModalOpen } = useAppKitState();
  const { agents: onchainAgents } = useAgentStats();
  const theme = THEMES[themeIdx];

  // Merge static AGENTS with any newly registered custom agents from onchain
  const allAgents = useMemo<Agent[]>(() => {
    const staticIds = new Set(AGENTS.map(a => a.id));
    const customOnchain = onchainAgents.filter(
      oc => !staticIds.has(oc.agentId) && oc.registeredAt > 0 && oc.active
    );
    const extras: Agent[] = customOnchain.map((oc, i) => ({
      id: oc.agentId,
      name: oc.name || oc.agentId,
      fullName: oc.name || oc.agentId,
      role: "Custom Agent",
      trait: "Registered · Onchain",
      color: CUSTOM_AGENT_COLORS[i % CUSTOM_AGENT_COLORS.length],
      glowColor: CUSTOM_AGENT_COLORS[i % CUSTOM_AGENT_COLORS.length].replace(")", " / 0.2)").replace("hsl(", "hsl("),
      icon: "★",
      initials: (oc.name || oc.agentId).slice(0, 2).toUpperCase(),
      gradientClass: "from-pink-500 to-purple-600",
      quote: "Registered and operational on Hedera testnet.",
      philosophy: "Custom agent registered via AgentRegistry.sol on Hedera EVM testnet.",
      confidence: 80,
      reputation: Math.round(oc.reputation / 200),
      completedQuests: oc.completedQuests,
      successRate: oc.completedQuests > 0 ? Math.round((oc.successCount / oc.completedQuests) * 100) : 80,
      specialization: "Custom",
      status: "active" as const,
      animIndex: Math.min(7 + i, 10),
      homeRoom: "consensushub",
      recentActions: [],
    }));
    return [...AGENTS, ...extras];
  }, [onchainAgents]);

  // Apply theme colors to rooms
  const themedRooms = rooms.map(r => ({
    ...r,
    color: theme.roomColors[r.name] ?? r.color,
  }));

  // Fetch live contract stats for Ledger Archive (QuestReceipt) and Smart Spire (AgentRegistry)
  useEffect(() => {
    const fetchContractStats = async () => {
      try {
        const provider = new JsonRpcProvider(HEDERA_TESTNET_RPC);
        const questContract = new Contract(
          QUEST_RECEIPT_ADDRESS,
          ["function questCount() view returns (uint256)"],
          provider
        );
        const agentContract = new Contract(
          AGENT_REGISTRY_ADDRESS,
          ["function getAgentCount() view returns (uint256)"],
          provider
        );

        const [questCount, agentCount] = await Promise.all([
          questContract.questCount().catch(() => null) as Promise<bigint | null>,
          agentContract.getAgentCount().catch(() => null) as Promise<bigint | null>,
        ]);

        setRooms((prev) =>
          prev.map((r) => {
            if (r.name === "ledgerarchive" && questCount != null) {
              const count = Number(questCount);
              const countStr = count.toLocaleString("en-US");
              return {
                ...r,
                stats: [
                  `Receipts: ${countStr}`,
                  `Last ID: #${count}`,
                  "Hash: 0xab12…",
                ],
              };
            }
            if (r.name === "smartspire" && agentCount != null) {
              return {
                ...r,
                stats: [
                  `${Number(agentCount)} Contracts Deployed`,
                  "Gas: 2,115 tinyhbar",
                  "Audit: PASS",
                ],
              };
            }
            return r;
          })
        );
      } catch {
        // keep static fallback stats on error
      }
    };

    fetchContractStats();
    const interval = setInterval(fetchContractStats, 60000);
    return () => clearInterval(interval);
  }, []);
  // activeBubble: one agent speaks, then a reply agent responds
  const [activeBubble, setActiveBubble] = useState<{
    speakerId: string;
    msg: TimelineMessage;
    replyId?: string;
    replyMsg?: TimelineMessage;
  } | null>(null);
  const [agentDirs,    setAgentDirs]    = useState<Record<string,"s"|"n"|"e"|"w">>({});
  const bubbleTimerRef = useRef<ReturnType<typeof setTimeout>|null>(null);
  const startRef = useRef(Date.now());

  // Pull live messages from the shared timeline hook
  const { messages: liveMessages } = useLiveTimeline();

  // Build per-agent latest message map
  const latestByAgent = useRef<Record<string, TimelineMessage>>({});
  useEffect(() => {
    const map: Record<string, TimelineMessage> = {};
    // liveMessages is newest-first; iterate to get latest per agent
    for (const m of [...liveMessages].reverse()) {
      map[m.agentId] = m;
    }
    latestByAgent.current = map;
  }, [liveMessages]);

  // Conversation cycling — pick a speaker from latest messages, then find a "reply" agent
  useEffect(() => {
    const showNext = () => {
      const msgs = liveMessages;
      if (msgs.length === 0) return;

      // Pick a random recent message as the "speaker"
      const pool = msgs.slice(0, Math.min(msgs.length, 12));
      const speakerMsg = pool[Math.floor(Math.random() * pool.length)];
      const speakerId = speakerMsg.agentId;

      // Find a different agent's message as "reply"
      const replyPool = pool.filter(m => m.agentId !== speakerId);
      const replyMsg = replyPool.length > 0
        ? replyPool[Math.floor(Math.random() * replyPool.length)]
        : undefined;

      setActiveBubble({
        speakerId,
        msg: speakerMsg,
        replyId: replyMsg?.agentId,
        replyMsg,
      });

      // Show for 4.5s then clear
      if (bubbleTimerRef.current) clearTimeout(bubbleTimerRef.current);
      bubbleTimerRef.current = setTimeout(() => setActiveBubble(null), 4500);
    };

    // Start quickly, then repeat every 6s
    const init = setTimeout(showNext, 1200);
    const iv = setInterval(showNext, 6000);
    return () => {
      clearTimeout(init);
      clearInterval(iv);
      if (bubbleTimerRef.current) clearTimeout(bubbleTimerRef.current);
    };
  }, [liveMessages]);

  // Direction tracking — durations must match CSS @keyframes npc-move-N exactly
  useEffect(() => {
    const update = () => {
      const now = Date.now();
      const dirs: Record<string,"s"|"n"|"e"|"w"> = {};
      for (const a of allAgents) {
        const dur = NPC_ANIM_DURATIONS[a.animIndex] ?? 35000;
        dirs[a.id] = getAgentDir(a.id, ((now - startRef.current) % dur) / dur);
      }
      setAgentDirs(dirs);
    };
    update();
    const iv = setInterval(update, 300);
    return () => clearInterval(iv);
  }, [allAgents]);

  return (
    <div className="flex-1 relative overflow-hidden select-none" style={{
      minHeight: 0,
      background: theme.bgBase,
      border: `1px solid ${theme.borderColor}`,
      borderRadius: "12px",
      animation: "kingdom-border 4s ease-in-out infinite",
      transition: "background 0.6s ease, border-color 0.6s ease",
      boxShadow: `
        inset 0 0 80px hsl(225 35% 3% / 0.6),
        0 0 0 1px ${theme.borderColor},
        0 8px 40px -8px hsl(225 35% 3% / 0.9),
        0 0 60px -20px ${theme.ambientGlow}
      `,
    }}>

      {/* ── PIXEL ART MAP BACKGROUND ── */}
      <div className="absolute inset-0" style={{
        backgroundImage: "url(/assets/map-bg.png)",
        backgroundSize: "cover",
        backgroundPosition: "center",
        imageRendering: "pixelated",
      }} />

      {/* Ambient color wash — theme-driven */}
      <div className="absolute inset-0 pointer-events-none" style={{
        background: theme.skybox,
        transition: "background 0.6s ease",
      }} />

      {/* Scanline overlay */}
      <div className="absolute inset-0 pointer-events-none" style={{
        backgroundImage: `repeating-linear-gradient(0deg, transparent, transparent 3px, ${theme.scanline} 3px, ${theme.scanline} 4px)`,
        mixBlendMode: "multiply",
      }} />

      {/* ── KINGDOM DECORATIONS ── */}
      {decorations.map((d, i) => {
        const Component = DECO_COMPONENTS[d.type];
        if (!Component) return null;
        const col = theme.decoColors[i] ?? (d as any).color ?? "#00e5ff";
        const glowSizes: Record<string,number> = { crystal:48, hnode:56, orb:44, rune:36, tower:52, lantern:32 };
        const glowSize = glowSizes[d.type] || 40;
        const glowOpacity = d.type === "lantern" ? 0.45 : 0.55;
        const animDur = 1.8 + (i % 7) * 0.4;
        return (
          <div key={i} className="absolute pointer-events-none z-10"
            style={{ left: d.x, top: d.y, transform: "translate(-50%,-100%)" }}>
            {/* Radial glow bloom behind decoration */}
            <div className="absolute" style={{
              width: glowSize, height: glowSize,
              left: "50%", bottom: 0,
              transform: "translate(-50%, 40%)",
              background: `radial-gradient(circle, ${col}bb 0%, ${col}44 40%, transparent 70%)`,
              opacity: glowOpacity,
              animation: `pulse-glow ${animDur}s ease-in-out infinite`,
              borderRadius: "50%",
              filter: "blur(2px)",
            }} />
            {Component(col)}
            {/* Extra sparkle for nodes and crystals */}
            {(d.type === "hnode" || d.type === "crystal") && (
              <div className="absolute" style={{
                width: glowSize * 1.6, height: glowSize * 1.6,
                left: "50%", bottom: "20%",
                transform: "translate(-50%, 50%)",
                background: `radial-gradient(circle, ${col}30 0%, transparent 65%)`,
                animation: `pulse-glow ${animDur + 0.7}s ease-in-out infinite reverse`,
                borderRadius: "50%",
              }} />
            )}
          </div>
        );
      })}

      {/* ── ROOMS — pure glow border, NO background fill ── */}
      {themedRooms.map((r) => {
        const hov = hoveredRoom === r.name;
        return (
          <div key={r.name} className="absolute cursor-pointer z-20"
            style={{ left:`${r.x}%`, top:`${r.y}%`, width:`${r.w}%`, height:`${r.h}%` }}
            onMouseEnter={() => setHoveredRoom(r.name)}
            onMouseLeave={() => setHoveredRoom(null)}
          >
            {/* Outer glow bloom — idle glow + bright on hover */}
            <div className="absolute pointer-events-none"
              style={{
                inset: hov ? `${-r.h * 0.06}%` : "-2px",
                borderRadius: "8px",
                border: hov ? `2px solid ${r.color}ee` : `1px solid ${r.color}50`,
                boxShadow: hov
                  ? `0 0 ${r.w*0.5}px ${r.color}66, 0 0 ${r.w}px ${r.color}22, inset 0 0 ${r.w*0.3}px ${r.color}15`
                  : `0 0 ${r.w*0.15}px ${r.color}30, 0 0 ${r.w*0.3}px ${r.color}10`,
                transition: "all 0.4s ease",
                backgroundImage: hov
                  ? `repeating-linear-gradient(0deg, transparent, transparent 3px, ${r.color}06 3px, ${r.color}06 4px)`
                  : "none",
              }} />

            {/* Corner pixel markers — always subtle, bright on hover */}
            {[
              "top-0 left-0", "top-0 right-0",
              "bottom-0 left-0", "bottom-0 right-0",
            ].map((pos, i) => (
              <div key={i} className={`absolute ${pos} pointer-events-none`}
                style={{
                  width: hov ? 12 : 6, height: hov ? 12 : 6,
                  margin: 3,
                  background: hov ? r.color : r.color + "50",
                  boxShadow: hov ? `0 0 8px ${r.color}` : "none",
                  transition: "all 0.3s",
                  clipPath: i===0?"polygon(0 0,100% 0,0 100%)"
                           :i===1?"polygon(0 0,100% 0,100% 100%)"
                           :i===2?"polygon(0 0,0 100%,100% 100%)"
                           :"polygon(100% 0,0 100%,100% 100%)",
                }} />
            ))}

            {/* Icon + label — top-center, pill background, nowrap */}
            <div className="absolute top-1 left-0 right-0 flex flex-col items-center gap-0.5 pointer-events-none">
              <span
                className="font-pixel text-[9px] whitespace-nowrap px-1.5 py-0.5 rounded transition-all duration-300"
                style={{
                  color: hov ? "#fff" : r.color + "ee",
                  background: hov ? r.color + "cc" : "hsl(225 30% 6% / 0.82)",
                  border: `1px solid ${r.color}${hov ? "aa" : "44"}`,
                  textShadow: hov ? `0 0 8px ${r.color}` : "none",
                  boxShadow: hov ? `0 0 10px ${r.color}60` : "none",
                }}>
                {r.icon} {r.label}
              </span>
              {/* Hedera service sub-tag */}
              <span
                className="font-pixel text-[6px] whitespace-nowrap px-1 rounded-sm"
                style={{
                  color: r.color + "99",
                  background: "hsl(225 30% 5% / 0.7)",
                }}>
                {r.desc.split("—")[0].trim()}
              </span>
            </div>

            {/* Hover: data panel — floating above room, no background on room itself */}
            {hov && (
              <div className="absolute z-40 pointer-events-none"
                style={{
                  top: "50%", left: "50%",
                  transform: "translate(-50%, -50%)",
                  padding: "8px 12px",
                  borderRadius: 8,
                  background: "hsl(225 28% 8% / 0.95)",
                  border: `1px solid ${r.color}66`,
                  boxShadow: `0 0 24px ${r.color}30, 0 8px 32px hsl(225 30% 3%/0.9)`,
                  backdropFilter: "blur(8px)",
                  animation: "timeline-enter 0.15s ease-out",
                  minWidth: 120, textAlign: "center",
                }}>
                <div className="font-pixel text-[8px] mb-1" style={{ color: r.color }}>{r.icon} {r.label}</div>
                <div className="text-[6px] font-pixel opacity-60 mb-1" style={{ color: r.color }}>{r.desc}</div>
                <div className="w-full h-px mb-1" style={{ background:`linear-gradient(90deg,transparent,${r.color}50,transparent)` }}/>
                {r.stats.map((s,i)=>(
                  <div key={i} className="flex items-center gap-1 justify-center">
                    <div className="w-1 h-1 rounded-[1px]" style={{ background: r.color + "90" }}/>
                    <span className="text-[6px] font-mono" style={{ color: r.color + "bb" }}>{s}</span>
                  </div>
                ))}
                {/* Scanning bar */}
                <div className="w-full mt-1 h-[2px] rounded overflow-hidden" style={{ background: r.color + "15" }}>
                  <div style={{
                    height:"100%",
                    background:`linear-gradient(90deg,transparent,${r.color},transparent)`,
                    animation:"room-scan 1.8s linear infinite",
                  }}/>
                </div>
              </div>
            )}
          </div>
        );
      })}

      {/* ── NPCs — kept alive to preserve animation position; hidden instantly via visibility ── */}
      {allAgents.map((agent) => {
        const shouldHide = walletModalOpen || hideAgents;
        const isHov     = hoveredAgent === agent.id;
        const isSpeaker = activeBubble?.speakerId === agent.id;
        const isReplier = activeBubble?.replyId    === agent.id;
        const dir       = agentDirs[agent.id] || "e";

        // Determine what to show in bubble
        const showBubble = isHov || isSpeaker || isReplier;
        const bubbleMsg  = isHov
          ? (latestByAgent.current[agent.id]?.content ?? agent.quote)
          : isSpeaker
          ? activeBubble!.msg.content
          : isReplier
          ? activeBubble!.replyMsg!.content
          : "";
        const msgType = isHov
          ? (latestByAgent.current[agent.id]?.type ?? "conversation")
          : isSpeaker
          ? activeBubble!.msg.type
          : activeBubble?.replyMsg?.type ?? "conversation";

        const TYPE_COLORS: Record<string,string> = {
          conversation:"#60a5fa", tool_call:"#fbbf24", decision:"#60a5fa",
          transaction:"#4ade80", alert:"#fb923c", policy:"#4ade80",
          receipt:"#f87171", quest:"#fbbf24",
        };
        const typeColor = TYPE_COLORS[msgType] ?? agent.color;

        return (
          <div key={agent.id} className="absolute z-30"
            style={{
              animation:`npc-move-${agent.animIndex} ${NPC_ANIM_DURATIONS[agent.animIndex]??35000}ms linear infinite`,
              visibility: shouldHide ? "hidden" : "visible",
              pointerEvents: shouldHide ? "none" : "auto",
            }}
            onMouseEnter={() => setHoveredAgent(agent.id)}
            onMouseLeave={() => setHoveredAgent(null)}
          >
            {/* Speech bubble — live message content */}
            {showBubble && bubbleMsg && (
              <div className="absolute z-40 pointer-events-none"
                style={{
                  bottom:"calc(100% + 8px)",
                  left: "50%", transform:"translateX(-50%)",
                  width: 180, maxWidth: 180, padding:"6px 10px", borderRadius: 8,
                  background:"hsl(225 32% 8% / 0.97)",
                  border:`1px solid ${agent.color}66`,
                  boxShadow:`0 0 24px ${agent.color}30, 0 4px 16px hsl(225 35% 3%/0.8)`,
                  backdropFilter:"blur(8px)",
                  animation:"timeline-enter 0.18s ease-out",
                }}>
                {/* Agent name + type badge */}
                <div className="flex items-center justify-between mb-1 gap-1">
                  <span className="font-pixel text-[7px]" style={{ color: agent.color }}>
                    {agent.name}
                  </span>
                  <span className="font-pixel text-[6px] px-1 rounded-sm"
                    style={{ color: typeColor, background: typeColor + "18", border:`1px solid ${typeColor}30` }}>
                    {msgType.replace("_"," ").toUpperCase()}
                  </span>
                </div>
                {/* Message content — strip agent name prefix */}
                <p className="text-[8px] font-mono leading-relaxed"
                  style={{ color: agent.color + "ee", wordBreak:"break-word", overflowWrap:"anywhere", overflow:"hidden", display:"-webkit-box", WebkitLineClamp:4, WebkitBoxOrient:"vertical" }}>
                  {stripPrefix(bubbleMsg)}
                </p>
                {/* Reply indicator */}
                {isReplier && (
                  <div className="flex items-center gap-1 mt-1 pt-1 border-t"
                    style={{ borderColor: agent.color + "25" }}>
                    <span className="text-[6px] font-pixel" style={{ color: agent.color + "70" }}>
                      ↩ replying
                    </span>
                  </div>
                )}
                {/* Tail */}
                <div className="absolute top-full left-1/2 -translate-x-1/2"
                  style={{ width:0, height:0,
                    borderLeft:"5px solid transparent", borderRight:"5px solid transparent",
                    borderTop:`5px solid ${agent.color}55` }}/>
              </div>
            )}
            {/* Sprite */}
            <div className="relative cursor-pointer"
              style={{
                filter: isHov
                  ? `drop-shadow(0 0 8px ${agent.color}) drop-shadow(0 0 3px ${agent.color}) brightness(1.2)`
                  : `drop-shadow(0 2px 4px hsl(225 30% 4%/0.8))`,
                transition:"filter 0.2s",
              }}>
              {agent.animIndex <= 6 ? (
                <div style={{
                  width:64, height:64,
                  backgroundImage:`url(/assets/npcs/npc-${agent.id}-${dir}.png)`,
                  backgroundRepeat:"no-repeat",
                  backgroundSize:`${9*64}px 64px`,
                  imageRendering:"pixelated",
                  animation:`npc-sprite-${agent.animIndex} 0.6s steps(1) infinite`,
                }}/>
              ) : (
                // Custom agents: pixel block with icon (no sprite sheet)
                <div style={{
                  width:48, height:48,
                  display:"flex", alignItems:"center", justifyContent:"center",
                  background: agent.color + "20",
                  border: `2px solid ${agent.color}60`,
                  borderRadius: 6,
                  imageRendering:"pixelated",
                }}>
                  <span className="font-pixel text-xl" style={{ color: agent.color }}>{agent.icon}</span>
                </div>
              )}
              <div className="absolute -top-2 -right-1 text-[9px] font-pixel pointer-events-none"
                style={{ color:agent.color, textShadow:`0 0 8px ${agent.color}` }}>
                {agent.icon}
              </div>
              <div className="absolute top-full left-1/2 -translate-x-1/2 text-[6px] font-pixel whitespace-nowrap mt-0.5 pointer-events-none"
                style={{ color:agent.color+"cc", textShadow:`0 0 6px ${agent.color}40` }}>
                {agent.name}
              </div>
            </div>
          </div>
        );
      })}

      {/* ── AMBIENT ROOM GLOWS ── */}
      {themedRooms.map((r,i) => (
        <div key={`amb-${i}`} className="absolute pointer-events-none z-10"
          style={{
            left:`${r.x+r.w/2}%`, top:`${r.y+r.h/2}%`,
            width:120, height:120, transform:"translate(-50%,-50%)",
            background:`radial-gradient(circle, ${r.color}0a 0%, transparent 70%)`,
            animation:`pulse-glow ${3.5+i*0.6}s ease-in-out infinite`,
          }}/>
      ))}

      {/* ── THEME SWITCHER ── */}
      <div className="absolute top-2 left-1/2 -translate-x-1/2 z-50 flex items-center gap-1">
        {THEMES.map((t, i) => (
          <button key={t.id} onClick={() => setThemeIdx(i)}
            className="font-pixel text-[8px] px-2 py-1 rounded transition-all duration-200"
            style={{
              background: themeIdx === i ? t.borderColor.replace("0.22","0.25").replace("0.30","0.30").replace("0.25","0.25") + "33" : "hsl(225 30% 6% / 0.7)",
              border: `1px solid ${themeIdx === i ? t.borderColor : "hsl(225 30% 20% / 0.4)"}`,
              color: themeIdx === i ? "#fff" : "hsl(225 10% 55%)",
              boxShadow: themeIdx === i ? `0 0 8px ${t.borderColor}` : "none",
            }}>
            {t.icon} {t.name}
          </button>
        ))}
      </div>

      {/* ── MINIMAP ── */}
      <div className="absolute top-2 right-2 w-[72px] h-[62px] glass-panel p-1 opacity-50 hover:opacity-100 transition-opacity z-40">
        <div className="w-full h-full relative rounded-sm overflow-hidden" style={{ background:"hsl(225 32% 6%)" }}>
          {themedRooms.map(r=>(
            <div key={r.name} className="absolute rounded-[1px] transition-all duration-200"
              style={{
                left:`${r.x}%`, top:`${r.y}%`, width:`${r.w}%`, height:`${r.h}%`,
                background: hoveredRoom===r.name ? r.color+"a0" : r.color+"35",
                boxShadow: hoveredRoom===r.name ? `0 0 4px ${r.color}` : "none",
              }}/>
          ))}
          {!hideAgents && !walletModalOpen && allAgents.map(a=>(
            <div key={`mm-${a.id}`} className="absolute w-[5px] h-[5px] rounded-full"
              style={{
                background:a.color, boxShadow:`0 0 4px ${a.color}`,
                animation:`npc-move-${a.animIndex} ${NPC_ANIM_DURATIONS[a.animIndex]??35000}ms linear infinite`,
              }}/>
          ))}
        </div>
        <p className="text-[5px] text-muted-foreground font-pixel text-center mt-0.5 tracking-widest">MAP</p>
      </div>

      {/* ── AGENT LEGEND ── */}
      <div className="absolute bottom-2 left-2 flex flex-col gap-0.5 z-40">
        {allAgents.map(a=>(
          <div key={`leg-${a.id}`}
            className="flex items-center gap-1 px-1.5 py-0.5 rounded cursor-pointer transition-all duration-150"
            style={{
              background: hoveredAgent===a.id ? a.color+"15" : "transparent",
              border:`1px solid ${hoveredAgent===a.id ? a.color+"40" : "transparent"}`,
            }}
            onMouseEnter={()=>setHoveredAgent(a.id)}
            onMouseLeave={()=>setHoveredAgent(null)}
          >
            <div className="w-[7px] h-[7px] rounded-[1px] shrink-0"
              style={{ background:a.color, boxShadow:`0 0 4px ${a.color}80` }}/>
            <span className="text-[7px] font-pixel" style={{ color:a.color+"cc" }}>{a.name}</span>
            <span className="text-[6px] text-muted-foreground ml-0.5">{a.role.split(" ")[0]}</span>
          </div>
        ))}
      </div>
    </div>
  );
};

export default PixelMap;
