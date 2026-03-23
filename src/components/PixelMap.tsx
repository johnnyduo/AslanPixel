import { useState, useEffect, useRef } from "react";
import { AGENTS } from "@/data/agents";

interface Room {
  name: string; label: string;
  x: number; y: number; w: number; h: number;
  color: string; icon: string; desc: string; stats: string[];
}

const rooms: Room[] = [
  // Positions sized to match pixel art buildings exactly, leaving corridors clear
  // Corridors: top-H(y=27%), mid-H(y=54%), left-V(x=30%), right-V(x=68%), arch-V(x=50%)
  { name:"consensushub", label:"Consensus Hub",   x:36, y:32, w:28, h:18, color:"hsl(43 90% 55%)",   icon:"⬡", desc:"HCS — Hedera Consensus",  stats:["HCS Topic #0.0.1234","847 msgs/min","LIVE"] },
  { name:"tokenforge",   label:"Token Forge",     x: 5, y: 6, w:21, h:17, color:"hsl(195 100% 50%)", icon:"◈", desc:"HTS Token Operations",    stats:["HTS Tokens: 12","3 Pending Mint","ONLINE"] },
  { name:"mirrorvault",  label:"Mirror Vault",    x:74, y: 6, w:21, h:17, color:"hsl(280 65% 65%)",  icon:"◆", desc:"Mirror Node State",       stats:["12,847.50 HBAR","Slot: 4,192,441","SYNCED"] },
  { name:"smartspire",   label:"Smart Spire",     x: 5, y:57, w:21, h:17, color:"hsl(142 70% 45%)",  icon:"▲", desc:"EVM Smart Contracts",     stats:["3 Contracts","Risk: LOW","DEPLOYED"] },
  { name:"dexgate",      label:"DEX Gate",        x:74, y:57, w:21, h:17, color:"hsl(38 92% 50%)",   icon:"▶", desc:"SaucerSwap Execution",    stats:["412 TX Done","0 Pending","READY"] },
  { name:"ledgerarchive",label:"Ledger Archive",  x:36, y:80, w:28, h:16, color:"hsl(0 72% 60%)",    icon:"▣", desc:"Onchain Receipts",        stats:["Receipt #2041","Mirror: CONFIRMED","IMMUTABLE"] },
];

// Decorations — trees, shrubs, flowers, lanterns, barrels, benches
// Corridors: top-H(y=27%), mid-H(y=54%), left-V(x=30%), right-V(x=68%), arch-V(x=50%)
// Trees/shrubs placed in empty space OUTSIDE buildings (not blocking corridors)
const decorations = [
  // ── TOP-LEFT FOREST (corner above guild, left of top-H corridor) ──
  { x:"1%",  y:"2%",  type:"tree2" }, { x:"3%",  y:"1%",  type:"tree" },
  { x:"5%",  y:"3%",  type:"shrub" }, { x:"2%",  y:"5%",  type:"tree2" },
  { x:"1%",  y:"4%",  type:"shrub" },

  // ── TOP-RIGHT FOREST (corner above vault, right of top-H corridor) ──
  { x:"97%", y:"2%",  type:"tree2" }, { x:"95%", y:"1%",  type:"tree" },
  { x:"98%", y:"4%",  type:"shrub" }, { x:"96%", y:"4%",  type:"tree2" },
  { x:"99%", y:"2%",  type:"shrub" },

  // ── BOTTOM-LEFT CORNER (below strategy, bottom-left) ──
  { x:"1%",  y:"76%", type:"tree2" }, { x:"3%",  y:"77%", type:"tree" },
  { x:"2%",  y:"79%", type:"shrub" }, { x:"1%",  y:"81%", type:"tree" },
  { x:"4%",  y:"80%", type:"shrub" }, { x:"2%",  y:"83%", type:"tree2" },

  // ── BOTTOM-RIGHT CORNER (below market) ──
  { x:"97%", y:"76%", type:"tree2" }, { x:"95%", y:"78%", type:"tree" },
  { x:"98%", y:"80%", type:"shrub" }, { x:"96%", y:"82%", type:"tree" },
  { x:"99%", y:"79%", type:"shrub" }, { x:"97%", y:"84%", type:"tree2" },

  // ── BOTTOM STRIP (below archive, bottom edge) ──
  { x:"20%", y:"97%", type:"shrub" }, { x:"30%", y:"98%", type:"tree" },
  { x:"36%", y:"97%", type:"shrub" }, { x:"65%", y:"97%", type:"shrub" },
  { x:"70%", y:"98%", type:"tree"  }, { x:"78%", y:"97%", type:"shrub" },

  // ── TOP STRIP (above guild and vault, top edge) ──
  { x:"14%", y:"2%",  type:"shrub" }, { x:"18%", y:"1%",  type:"tree" },
  { x:"22%", y:"3%",  type:"shrub" },
  { x:"78%", y:"2%",  type:"shrub" }, { x:"82%", y:"1%",  type:"tree" },
  { x:"86%", y:"3%",  type:"shrub" },

  // ── BETWEEN GUILD AND STRATEGY (left wall strip, x=1-3%) ──
  { x:"2%",  y:"28%", type:"shrub" }, { x:"1%",  y:"32%", type:"tree2" },
  { x:"2%",  y:"36%", type:"shrub" }, { x:"1%",  y:"41%", type:"tree"  },
  { x:"2%",  y:"45%", type:"shrub" }, { x:"1%",  y:"49%", type:"tree2" },
  { x:"2%",  y:"53%", type:"shrub" },

  // ── BETWEEN VAULT AND MARKET (right wall strip, x=97-99%) ──
  { x:"98%", y:"28%", type:"shrub" }, { x:"99%", y:"32%", type:"tree2" },
  { x:"98%", y:"36%", type:"shrub" }, { x:"99%", y:"41%", type:"tree"  },
  { x:"98%", y:"45%", type:"shrub" }, { x:"99%", y:"49%", type:"tree2" },
  { x:"98%", y:"53%", type:"shrub" },

  // ── TOP-H CORRIDOR SIDES (y≈27%, flanking trees) ──
  { x:"29%", y:"24%", type:"tree"  }, { x:"32%", y:"24%", type:"shrub" },
  { x:"35%", y:"24%", type:"shrub" },
  { x:"64%", y:"24%", type:"shrub" }, { x:"67%", y:"24%", type:"tree"  },
  { x:"71%", y:"24%", type:"shrub" },
  { x:"29%", y:"30%", type:"shrub" }, { x:"32%", y:"30%", type:"flower"},
  { x:"67%", y:"30%", type:"flower"}, { x:"71%", y:"30%", type:"shrub" },

  // ── MID-H CORRIDOR SIDES (y≈54%, flanking trees) ──
  { x:"29%", y:"52%", type:"shrub" }, { x:"33%", y:"52%", type:"flower"},
  { x:"65%", y:"52%", type:"flower"}, { x:"69%", y:"52%", type:"shrub" },
  { x:"29%", y:"56%", type:"tree"  }, { x:"33%", y:"56%", type:"shrub" },
  { x:"65%", y:"56%", type:"shrub" }, { x:"69%", y:"56%", type:"tree"  },

  // ── LEFT-V CORRIDOR SIDES (x≈30%, flanking trees) ──
  { x:"27%", y:"30%", type:"shrub" }, { x:"27%", y:"35%", type:"tree"  },
  { x:"27%", y:"42%", type:"shrub" }, { x:"27%", y:"48%", type:"tree2" },
  { x:"33%", y:"30%", type:"flower"}, { x:"33%", y:"38%", type:"shrub" },
  { x:"33%", y:"46%", type:"flower"}, { x:"33%", y:"52%", type:"shrub" },

  // ── RIGHT-V CORRIDOR SIDES (x≈68%, flanking trees) ──
  { x:"65%", y:"30%", type:"shrub" }, { x:"65%", y:"36%", type:"tree"  },
  { x:"65%", y:"43%", type:"shrub" }, { x:"65%", y:"49%", type:"tree2" },
  { x:"71%", y:"30%", type:"flower"}, { x:"71%", y:"38%", type:"shrub" },
  { x:"71%", y:"46%", type:"flower"}, { x:"71%", y:"52%", type:"shrub" },

  // ── ARCH-V CORRIDOR SIDES (x≈50%, between hub and archive) ──
  { x:"46%", y:"54%", type:"shrub" }, { x:"46%", y:"60%", type:"tree2" },
  { x:"46%", y:"67%", type:"shrub" }, { x:"46%", y:"74%", type:"flower"},
  { x:"54%", y:"54%", type:"flower"}, { x:"54%", y:"61%", type:"shrub" },
  { x:"54%", y:"68%", type:"tree2" }, { x:"54%", y:"75%", type:"shrub" },

  // ── LANTERNS (at corridor junctions) ──
  { x:"30%", y:"27%", type:"lantern", color:"hsl(195 100% 50%)" },  // guild-side top-H
  { x:"68%", y:"27%", type:"lantern", color:"hsl(280 65% 65%)" },   // vault-side top-H
  { x:"30%", y:"54%", type:"lantern", color:"hsl(142 70% 45%)" },   // strategy-side mid-H
  { x:"68%", y:"54%", type:"lantern", color:"hsl(38 92% 50%)" },    // market-side mid-H
  { x:"50%", y:"54%", type:"lantern", color:"hsl(43 90% 55%)" },    // archive corridor top
  { x:"50%", y:"68%", type:"lantern", color:"hsl(0 72% 60%)" },     // archive corridor mid

  // ── BARRELS & BENCHES (resting spots along corridors) ──
  { x:"31%", y:"25%", type:"barrel" }, { x:"67%", y:"25%", type:"barrel" },
  { x:"28%", y:"44%", type:"bench"  }, { x:"34%", y:"44%", type:"bench"  },
  { x:"64%", y:"44%", type:"bench"  }, { x:"72%", y:"44%", type:"bench"  },
  { x:"48%", y:"61%", type:"barrel" }, { x:"53%", y:"61%", type:"barrel" },
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

// Tree pixel art SVG (tall pine)
const TreeSVG = () => (
  <svg width="16" height="22" viewBox="0 0 16 22" style={{ imageRendering:"pixelated" }}>
    <rect x="7" y="16" width="2" height="6" fill="#3d2a1a"/>
    <rect x="4" y="12" width="8" height="6" fill="#1a3d1a"/>
    <rect x="3" y="8"  width="10" height="6" fill="#1e4d1e"/>
    <rect x="4" y="5"  width="8"  height="5" fill="#256325"/>
    <rect x="5" y="2"  width="6"  height="5" fill="#2d7a2d"/>
    <rect x="6" y="0"  width="4"  height="3" fill="#38963a"/>
    <rect x="7" y="0"  width="2"  height="1" fill="#4ab04c"/>
  </svg>
);

// Tree2 — wider oak-style
const Tree2SVG = () => (
  <svg width="20" height="18" viewBox="0 0 20 18" style={{ imageRendering:"pixelated" }}>
    <rect x="9"  y="13" width="2"  height="5"  fill="#3d2a1a"/>
    <rect x="8"  y="11" width="4"  height="3"  fill="#4a3320"/>
    <rect x="2"  y="5"  width="16" height="8"  fill="#1a3d1a"/>
    <rect x="0"  y="6"  width="20" height="6"  fill="#1e4d1e"/>
    <rect x="2"  y="4"  width="16" height="4"  fill="#256325"/>
    <rect x="4"  y="2"  width="12" height="5"  fill="#2d7a2d"/>
    <rect x="6"  y="0"  width="8"  height="4"  fill="#38963a"/>
    <rect x="3"  y="7"  width="2"  height="2"  fill="#38963a" opacity="0.6"/>
    <rect x="15" y="7"  width="2"  height="2"  fill="#38963a" opacity="0.6"/>
  </svg>
);

// Shrub — low bush
const ShrubSVG = () => (
  <svg width="14" height="10" viewBox="0 0 14 10" style={{ imageRendering:"pixelated" }}>
    <rect x="5"  y="7"  width="4"  height="3"  fill="#3d2a1a"/>
    <rect x="0"  y="4"  width="14" height="5"  fill="#1e4d1e"/>
    <rect x="1"  y="2"  width="12" height="5"  fill="#256325"/>
    <rect x="2"  y="0"  width="10" height="4"  fill="#2d7a2d"/>
    <rect x="4"  y="1"  width="2"  height="2"  fill="#38963a"/>
    <rect x="8"  y="1"  width="2"  height="2"  fill="#38963a"/>
  </svg>
);

// Flower — small colorful ground cover
const FlowerSVG = () => (
  <svg width="12" height="10" viewBox="0 0 12 10" style={{ imageRendering:"pixelated" }}>
    <rect x="5"  y="5"  width="2"  height="5"  fill="#2d6e2d"/>
    <rect x="3"  y="6"  width="6"  height="2"  fill="#2d6e2d"/>
    <rect x="5"  y="2"  width="2"  height="4"  fill="#e86a4a"/>
    <rect x="4"  y="3"  width="4"  height="2"  fill="#f08060"/>
    <rect x="5"  y="3"  width="2"  height="2"  fill="#ffdd44"/>
    <rect x="2"  y="4"  width="2"  height="2"  fill="#e86a4a" opacity="0.7"/>
    <rect x="8"  y="4"  width="2"  height="2"  fill="#6ab0e8" opacity="0.8"/>
  </svg>
);

// Lantern pixel art SVG
const LanternSVG = ({ color }: { color: string }) => (
  <svg width="10" height="18" viewBox="0 0 10 18" style={{ imageRendering:"pixelated" }}>
    <rect x="4" y="0" width="2" height="3" fill="#888"/>
    <rect x="3" y="3" width="4" height="1" fill="#aaa"/>
    <rect x="2" y="4" width="6" height="8" fill="#222" rx="1"/>
    <rect x="3" y="5" width="4" height="6" fill={color} opacity="0.85"/>
    <rect x="2" y="12" width="6" height="2" fill="#aaa"/>
    <rect x="3" y="14" width="4" height="2" fill="#888"/>
  </svg>
);

// Barrel SVG
const BarrelSVG = () => (
  <svg width="12" height="12" viewBox="0 0 12 12" style={{ imageRendering:"pixelated" }}>
    <rect x="2" y="1" width="8" height="10" fill="#5a3a1a" rx="2"/>
    <rect x="1" y="3" width="10" height="1" fill="#8a5a2a"/>
    <rect x="1" y="7" width="10" height="1" fill="#8a5a2a"/>
    <rect x="0" y="4" width="12" height="3" fill="#6b4422" opacity="0.3"/>
  </svg>
);

// Bench SVG
const BenchSVG = () => (
  <svg width="18" height="10" viewBox="0 0 18 10" style={{ imageRendering:"pixelated" }}>
    <rect x="0" y="3" width="18" height="3" fill="#6b4422"/>
    <rect x="2" y="6" width="2" height="4" fill="#5a3a1a"/>
    <rect x="14" y="6" width="2" height="4" fill="#5a3a1a"/>
    <rect x="0" y="2" width="18" height="1" fill="#8a5a2a"/>
  </svg>
);

const DECO_COMPONENTS: Record<string, (color?:string) => JSX.Element> = {
  tree:    () => <TreeSVG />,
  tree2:   () => <Tree2SVG />,
  shrub:   () => <ShrubSVG />,
  flower:  () => <FlowerSVG />,
  lantern: (c) => <LanternSVG color={c||"#fff"} />,
  barrel:  () => <BarrelSVG />,
  bench:   () => <BenchSVG />,
};

const PixelMap = () => {
  const [hoveredRoom,  setHoveredRoom]  = useState<string|null>(null);
  const [hoveredAgent, setHoveredAgent] = useState<string|null>(null);
  const [activeQuote,  setActiveQuote]  = useState<{id:string;quote:string}|null>(null);
  const [agentDirs,    setAgentDirs]    = useState<Record<string,"s"|"n"|"e"|"w">>({});
  const timerRef = useRef<ReturnType<typeof setTimeout>|null>(null);
  const startRef = useRef(Date.now());

  // Quote cycling
  useEffect(() => {
    const cycle = () => {
      const a = AGENTS[Math.floor(Math.random() * AGENTS.length)];
      setActiveQuote({ id: a.id, quote: a.quote });
      timerRef.current = setTimeout(() => setActiveQuote(null), 3500);
    };
    const iv = setInterval(cycle, 6000);
    const init = setTimeout(cycle, 800);
    return () => { clearInterval(iv); clearTimeout(init); if (timerRef.current) clearTimeout(timerRef.current); };
  }, []);

  // Direction tracking — durations must match CSS @keyframes npc-move-N exactly
  // animIndex: scout=1(35s), strategist=2(40s), sentinel=3(45s), treasurer=4(50s), executor=5(55s), archivist=6(60s)
  const NPC_DURATIONS: Record<number, number> = { 1:35000, 2:40000, 3:45000, 4:50000, 5:55000, 6:60000 };
  useEffect(() => {
    const update = () => {
      const now = Date.now();
      const dirs: Record<string,"s"|"n"|"e"|"w"> = {};
      for (const a of AGENTS) {
        const dur = NPC_DURATIONS[a.animIndex] ?? 35000;
        dirs[a.id] = getAgentDir(a.id, ((now - startRef.current) % dur) / dur);
      }
      setAgentDirs(dirs);
    };
    update();
    const iv = setInterval(update, 300);
    return () => clearInterval(iv);
  }, []);

  return (
    <div className="flex-1 glass-panel relative overflow-hidden select-none" style={{ minHeight: 0 }}>

      {/* ── PIXEL ART MAP BACKGROUND ── */}
      <div className="absolute inset-0" style={{
        backgroundImage: "url(/assets/map-bg.png)",
        backgroundSize: "cover",
        backgroundPosition: "center",
        imageRendering: "pixelated",
      }} />
      {/* Subtle dark vignette only at edges */}
      <div className="absolute inset-0 pointer-events-none" style={{
        background: "radial-gradient(ellipse 85% 80% at 50% 50%, transparent 50%, hsl(225 30% 4% / 0.5) 100%)",
      }} />

      {/* ── CORRIDOR DECORATIONS ── */}
      {decorations.map((d, i) => {
        const Component = DECO_COMPONENTS[d.type];
        if (!Component) return null;
        const isLantern = d.type === "lantern";
        return (
          <div key={i} className="absolute pointer-events-none z-10"
            style={{ left: d.x, top: d.y, transform: "translate(-50%,-100%)" }}>
            {Component((d as any).color)}
            {/* Lantern glow */}
            {isLantern && (
              <div className="absolute" style={{
                width: 28, height: 28,
                left: "50%", top: "60%",
                transform: "translate(-50%,-50%)",
                background: `radial-gradient(circle, ${(d as any).color} 0%, transparent 70%)`,
                opacity: 0.35,
                animation: `pulse-glow ${2.5 + i * 0.3}s ease-in-out infinite`,
                borderRadius: "50%",
              }} />
            )}
          </div>
        );
      })}

      {/* ── ROOMS — pure glow border, NO background fill ── */}
      {rooms.map((r) => {
        const hov = hoveredRoom === r.name;
        return (
          <div key={r.name} className="absolute cursor-pointer z-20"
            style={{ left:`${r.x}%`, top:`${r.y}%`, width:`${r.w}%`, height:`${r.h}%` }}
            onMouseEnter={() => setHoveredRoom(r.name)}
            onMouseLeave={() => setHoveredRoom(null)}
          >
            {/* Outer glow bloom — scales with room size via vw units */}
            <div className="absolute pointer-events-none transition-all duration-500"
              style={{
                // Extend glow slightly beyond room bounds
                inset: hov ? `${-r.h * 0.08}%` : "0%",
                borderRadius: "10px",
                boxShadow: hov
                  ? `0 0 ${r.w * 0.4}px ${r.color}55, 0 0 ${r.w * 0.8}px ${r.color}25, inset 0 0 ${r.w * 0.3}px ${r.color}10`
                  : `0 0 0px transparent`,
                border: hov ? `2px solid ${r.color}cc` : `1px solid ${r.color}15`,
                transition: "all 0.35s ease",
                // Pixel-art scanline overlay on hover
                backgroundImage: hov
                  ? `repeating-linear-gradient(0deg, transparent, transparent 3px, ${r.color}04 3px, ${r.color}04 4px)`
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

            {/* Icon + label — only text, no background */}
            <div className="absolute bottom-1 left-0 right-0 flex flex-col items-center gap-0 pointer-events-none">
              <span className="font-pixel text-[10px] transition-all duration-300"
                style={{
                  color: hov ? r.color : r.color + "80",
                  textShadow: hov ? `0 0 12px ${r.color}, 0 0 24px ${r.color}80` : `0 0 4px ${r.color}40`,
                }}>
                {r.icon} {r.label}
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

      {/* ── NPCs ── */}
      {AGENTS.map((agent) => {
        const isHov = hoveredAgent === agent.id;
        const isQ   = activeQuote?.id === agent.id;
        const dir   = agentDirs[agent.id] || "e";
        return (
          <div key={agent.id} className="absolute z-30"
            style={{ animation:`npc-move-${agent.animIndex} ${[35,40,45,50,55,60][agent.animIndex-1]??35}s linear infinite` }}
            onMouseEnter={() => setHoveredAgent(agent.id)}
            onMouseLeave={() => setHoveredAgent(null)}
          >
            {/* Speech bubble */}
            {(isHov || isQ) && (
              <div className="absolute z-40 pointer-events-none"
                style={{
                  bottom:"calc(100% + 6px)", left:"32px", transform:"translateX(-50%)",
                  width:148, padding:"5px 8px", borderRadius:6,
                  background:"hsl(225 28% 9% / 0.98)",
                  border:`1px solid ${agent.color}55`,
                  boxShadow:`0 0 20px ${agent.color}25`,
                  animation:"timeline-enter 0.15s ease-out",
                }}>
                {isHov && (
                  <div className="font-pixel text-[7px] mb-1" style={{ color: agent.color }}>
                    {agent.name} · {agent.role}
                  </div>
                )}
                <p className="text-[8px] font-mono leading-snug" style={{ color: agent.color+"dd" }}>
                  "{agent.quote}"
                </p>
                <div className="absolute top-full left-1/2 -translate-x-1/2"
                  style={{ width:0, height:0, borderLeft:"4px solid transparent", borderRight:"4px solid transparent", borderTop:`4px solid ${agent.color}55` }}/>
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
              <div style={{
                width:64, height:64,
                backgroundImage:`url(/assets/npcs/npc-${agent.id}-${dir}.png)`,
                backgroundRepeat:"no-repeat",
                backgroundSize:`${9*64}px 64px`,
                imageRendering:"pixelated",
                animation:`npc-sprite-${agent.animIndex} 0.6s steps(1) infinite`,
              }}/>
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
      {rooms.map((r,i) => (
        <div key={`amb-${i}`} className="absolute pointer-events-none z-10"
          style={{
            left:`${r.x+r.w/2}%`, top:`${r.y+r.h/2}%`,
            width:120, height:120, transform:"translate(-50%,-50%)",
            background:`radial-gradient(circle, ${r.color}0a 0%, transparent 70%)`,
            animation:`pulse-glow ${3.5+i*0.6}s ease-in-out infinite`,
          }}/>
      ))}

      {/* ── MINIMAP ── */}
      <div className="absolute top-2 right-2 w-[72px] h-[62px] glass-panel p-1 opacity-50 hover:opacity-100 transition-opacity z-40">
        <div className="w-full h-full relative rounded-sm overflow-hidden" style={{ background:"hsl(225 32% 6%)" }}>
          {rooms.map(r=>(
            <div key={r.name} className="absolute rounded-[1px] transition-all duration-200"
              style={{
                left:`${r.x}%`, top:`${r.y}%`, width:`${r.w}%`, height:`${r.h}%`,
                background: hoveredRoom===r.name ? r.color+"a0" : r.color+"35",
                boxShadow: hoveredRoom===r.name ? `0 0 4px ${r.color}` : "none",
              }}/>
          ))}
          {AGENTS.map(a=>(
            <div key={`mm-${a.id}`} className="absolute w-[5px] h-[5px] rounded-full"
              style={{
                background:a.color, boxShadow:`0 0 4px ${a.color}`,
                animation:`npc-move-${a.animIndex} ${[35,40,45,50,55,60][a.animIndex-1]??35}s linear infinite`,
              }}/>
          ))}
        </div>
        <p className="text-[5px] text-muted-foreground font-pixel text-center mt-0.5 tracking-widest">MAP</p>
      </div>

      {/* ── AGENT LEGEND ── */}
      <div className="absolute bottom-2 left-2 flex flex-col gap-0.5 z-40">
        {AGENTS.map(a=>(
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
