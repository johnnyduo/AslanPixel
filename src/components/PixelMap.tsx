import { useState, useEffect, useRef } from "react";
import { AGENTS } from "@/data/agents";

interface Room {
  name: string; label: string;
  x: number; y: number; w: number; h: number;
  color: string; icon: string; desc: string; stats: string[];
}

const rooms: Room[] = [
  { name:"hub",      label:"Town Square",    x:33, y:30, w:34, h:22, color:"hsl(43 90% 55%)",   icon:"◈", desc:"Central Command",    stats:["6 Agents Active","24 Quests","LIVE"] },
  { name:"guild",    label:"Guild Hall",      x: 4, y: 8, w:26, h:20, color:"hsl(195 100% 50%)", icon:"⬡", desc:"Agent Coordination", stats:["Intel Feed","318 Ops","ONLINE"] },
  { name:"vault",    label:"Vault House",     x:70, y: 8, w:26, h:20, color:"hsl(280 65% 65%)",  icon:"◆", desc:"Treasury & Assets",   stats:["12,847 HBAR","3 Tokens","SECURED"] },
  { name:"strategy", label:"Strategy Tower",  x: 4, y:55, w:26, h:20, color:"hsl(142 70% 45%)",  icon:"▲", desc:"Planning Operations", stats:["Risk: LOW","241 Plans","RUNNING"] },
  { name:"market",   label:"Market Gate",     x:70, y:55, w:26, h:20, color:"hsl(38 92% 50%)",   icon:"◉", desc:"Execution Hub",       stats:["412 TX Done","0 Pending","READY"] },
  { name:"archive",  label:"Archive Library", x:33, y:78, w:34, h:18, color:"hsl(0 72% 60%)",    icon:"▣", desc:"Onchain Records",     stats:["Receipt #2041","509 Logs","IMMUTABLE"] },
];

// Decorations along corridors: trees, lanterns, signs, barrels
const decorations = [
  // Trees (🌲 pixel art via CSS)
  { x:"27%", y:"14%", type:"tree" }, { x:"72%", y:"14%", type:"tree" },
  { x:"27%", y:"21%", type:"tree" }, { x:"72%", y:"21%", type:"tree" },
  { x:"14%", y:"32%", type:"tree" }, { x:"14%", y:"48%", type:"tree" },
  { x:"85%", y:"32%", type:"tree" }, { x:"85%", y:"48%", type:"tree" },
  { x:"29%", y:"68%", type:"tree" }, { x:"70%", y:"68%", type:"tree" },
  { x:"29%", y:"74%", type:"tree" }, { x:"70%", y:"74%", type:"tree" },
  // Lanterns
  { x:"31%", y:"17%", type:"lantern", color:"hsl(43 90% 55%)" },
  { x:"68%", y:"17%", type:"lantern", color:"hsl(280 65% 65%)" },
  { x:"15%", y:"40%", type:"lantern", color:"hsl(195 100% 50%)" },
  { x:"84%", y:"40%", type:"lantern", color:"hsl(38 92% 50%)" },
  { x:"31%", y:"71%", type:"lantern", color:"hsl(142 70% 45%)" },
  { x:"68%", y:"71%", type:"lantern", color:"hsl(0 72% 60%)" },
  { x:"48%", y:"62%", type:"lantern", color:"hsl(43 90% 55%)" },
  { x:"51%", y:"70%", type:"lantern", color:"hsl(43 90% 55%)" },
  // Benches / barrels
  { x:"48%", y:"17%", type:"barrel" }, { x:"52%", y:"17%", type:"barrel" },
  { x:"16%", y:"44%", type:"bench"  }, { x:"83%", y:"44%", type:"bench"  },
  { x:"48%", y:"65%", type:"barrel" },
];

// NPC patrol waypoints — step positions matching real room locations
const PATROL: Record<string, { x:number; y:number }[]> = {
  scout:      [{x:10,y:14},{x:17,y:18},{x:25,y:22},{x:34,y:32},{x:44,y:38},{x:50,y:41},{x:44,y:48},{x:34,y:52},{x:17,y:62},{x:10,y:52},{x:10,y:40},{x:10,y:14}],
  strategist: [{x:10,y:62},{x:17,y:68},{x:25,y:62},{x:34,y:52},{x:44,y:44},{x:50,y:38},{x:58,y:32},{x:72,y:22},{x:82,y:14},{x:72,y:18},{x:65,y:28},{x:50,y:38},{x:34,y:52},{x:10,y:62}],
  sentinel:   [{x:34,y:32},{x:50,y:32},{x:65,y:32},{x:67,y:44},{x:65,y:52},{x:50,y:56},{x:34,y:52},{x:34,y:44},{x:34,y:32}],
  treasurer:  [{x:82,y:12},{x:75,y:18},{x:65,y:28},{x:58,y:36},{x:65,y:28},{x:75,y:18},{x:82,y:12}],
  executor:   [{x:82,y:62},{x:75,y:62},{x:65,y:56},{x:56,y:48},{x:50,y:56},{x:50,y:68},{x:50,y:78},{x:58,y:82},{x:50,y:78},{x:50,y:68},{x:65,y:56},{x:82,y:62}],
  archivist:  [{x:50,y:88},{x:50,y:82},{x:50,y:74},{x:50,y:65},{x:50,y:56},{x:52,y:65},{x:50,y:74},{x:50,y:82},{x:50,y:88}],
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

// Tree pixel art SVG
const TreeSVG = () => (
  <svg width="16" height="20" viewBox="0 0 16 20" style={{ imageRendering:"pixelated" }}>
    <rect x="7" y="14" width="2" height="6" fill="#3d2a1a"/>
    <rect x="4" y="10" width="8" height="6" fill="#1a3d1a"/>
    <rect x="3" y="7"  width="10" height="5" fill="#1e4d1e"/>
    <rect x="5" y="4"  width="6" height="5"  fill="#256325"/>
    <rect x="6" y="1"  width="4" height="4"  fill="#2d7a2d"/>
    <rect x="7" y="0"  width="2" height="2"  fill="#38963a"/>
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

  // Direction tracking
  useEffect(() => {
    const update = () => {
      const now = Date.now();
      const dirs: Record<string,"s"|"n"|"e"|"w"> = {};
      for (const a of AGENTS) {
        const dur = (22 + a.animIndex * 4) * 1000;
        dirs[a.id] = getAgentDir(a.id, ((now - startRef.current) % dur) / dur);
      }
      setAgentDirs(dirs);
    };
    update();
    const iv = setInterval(update, 350);
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
            {/* Outer glow bloom — only visible on hover */}
            <div className="absolute inset-0 rounded-lg pointer-events-none transition-all duration-500"
              style={{
                boxShadow: hov
                  ? `0 0 40px ${r.color}60, 0 0 80px ${r.color}30, inset 0 0 40px ${r.color}15`
                  : `0 0 0px transparent`,
                border: hov ? `2px solid ${r.color}ee` : `1px solid ${r.color}18`,
                borderRadius: "8px",
                transition: "all 0.35s ease",
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
            style={{ animation:`npc-move-${agent.animIndex} ${22+agent.animIndex*4}s steps(1, end) infinite` }}
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
                animation:`npc-move-${a.animIndex} ${22+a.animIndex*4}s cubic-bezier(0.45,0,0.55,1) infinite`,
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
