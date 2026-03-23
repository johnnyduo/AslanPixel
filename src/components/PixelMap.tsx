import { useState, useEffect, useRef, useCallback } from "react";
import { AGENTS } from "@/data/agents";

interface Room {
  name: string;
  label: string;
  x: number; y: number; w: number; h: number;
  color: string;
  glowColor: string;
  icon: string;
  desc: string;
  stats: string[];
}

const rooms: Room[] = [
  { name: "hub",      label: "Town Square",    x: 33, y: 30, w: 34, h: 22, color: "hsl(43 90% 55%)",   glowColor: "hsl(43 90% 55% / 0.15)",   icon: "◈", desc: "Central Command",    stats: ["6 Agents Active", "24 Quests Today", "LIVE"] },
  { name: "guild",    label: "Guild Hall",      x:  4, y:  8, w: 26, h: 20, color: "hsl(195 100% 50%)", glowColor: "hsl(195 100% 50% / 0.14)", icon: "⬡", desc: "Agent Coordination", stats: ["Intel Feed", "318 Ops Done", "ONLINE"] },
  { name: "vault",    label: "Vault House",     x: 70, y:  8, w: 26, h: 20, color: "hsl(280 65% 65%)",  glowColor: "hsl(280 65% 65% / 0.14)",  icon: "◆", desc: "Treasury & Assets",   stats: ["12,847 HBAR", "3 Tokens", "SECURED"] },
  { name: "strategy", label: "Strategy Tower",  x:  4, y: 55, w: 26, h: 20, color: "hsl(142 70% 45%)",  glowColor: "hsl(142 70% 45% / 0.14)",  icon: "▲", desc: "Planning Operations", stats: ["Risk: LOW", "241 Plans", "RUNNING"] },
  { name: "market",   label: "Market Gate",     x: 70, y: 55, w: 26, h: 20, color: "hsl(38 92% 50%)",   glowColor: "hsl(38 92% 50% / 0.14)",   icon: "◉", desc: "Execution Hub",       stats: ["412 TX Done", "0 Pending", "READY"] },
  { name: "archive",  label: "Archive Library", x: 33, y: 78, w: 34, h: 18, color: "hsl(0 72% 60%)",    glowColor: "hsl(0 72% 60% / 0.14)",    icon: "▣", desc: "Onchain Records",     stats: ["Receipt #2041", "509 Logs", "IMMUTABLE"] },
];

const corridors = [
  { x1: "30%", y1: "18%", x2: "70%", y2: "18%" },
  { x1: "30%", y1: "78%", x2: "70%", y2: "78%" },
  { x1: "17%", y1: "28%", x2: "17%", y2: "55%" },
  { x1: "83%", y1: "28%", x2: "83%", y2: "55%" },
  { x1: "33%", y1: "41%", x2: "30%", y2: "18%" },
  { x1: "67%", y1: "41%", x2: "70%", y2: "18%" },
  { x1: "33%", y1: "41%", x2: "30%", y2: "55%" },
  { x1: "67%", y1: "41%", x2: "70%", y2: "55%" },
  { x1: "50%", y1: "52%", x2: "50%", y2: "78%" },
];

const desks = [
  { x: "39%", y: "34%", w: "7%", h: "4%" },
  { x: "54%", y: "34%", w: "7%", h: "4%" },
  { x: "39%", y: "43%", w: "7%", h: "4%" },
  { x: "54%", y: "43%", w: "7%", h: "4%" },
  { x: "47%", y: "38%", w: "6%", h: "5%" },
];

// Patrol waypoints for each agent (% of container)
// dir = "s"|"w"|"e"|"n" based on dominant movement direction between waypoints
const PATROL: Record<string, { x: number; y: number }[]> = {
  scout:      [{ x:13,y:16},{x:25,y:22},{x:38,y:32},{x:50,y:41},{x:38,y:52},{x:15,y:58},{x:10,y:45},{x:13,y:16}],
  strategist: [{ x:12,y:62},{x:28,y:50},{x:44,y:38},{x:58,y:32},{x:78,y:16},{x:65,y:34},{x:12,y:62}],
  sentinel:   [{ x:34,y:30},{x:64,y:30},{x:67,y:52},{x:50,y:57},{x:34,y:52},{x:32,y:38},{x:34,y:30}],
  treasurer:  [{ x:80,y:15},{x:72,y:26},{x:60,y:38},{x:60,y:38},{x:72,y:26},{x:80,y:15}],
  executor:   [{ x:80,y:62},{x:68,y:55},{x:56,y:47},{x:50,y:54},{x:50,y:72},{x:56,y:80},{x:68,y:70},{x:80,y:62}],
  archivist:  [{ x:48,y:88},{x:49,y:80},{x:50,y:65},{x:51,y:52},{x:50,y:65},{x:49,y:80},{x:48,y:88}],
};

// Compute direction string from dx/dy
function getDir(dx: number, dy: number): "s" | "n" | "e" | "w" {
  if (Math.abs(dx) > Math.abs(dy)) return dx > 0 ? "e" : "w";
  return dy > 0 ? "s" : "n";
}

// Compute which direction each agent faces at time t (0..1)
function getAgentDir(id: string, t: number): "s" | "n" | "e" | "w" {
  const pts = PATROL[id];
  if (!pts) return "s";
  const seg = t * (pts.length - 1);
  const i = Math.min(Math.floor(seg), pts.length - 2);
  const a = pts[i], b = pts[i + 1];
  return getDir(b.x - a.x, b.y - a.y);
}

// Scan-line overlay (SVG-based, cheap)
const ScanLines = ({ color }: { color: string }) => (
  <svg className="absolute inset-0 w-full h-full pointer-events-none" style={{ opacity: 0.08 }}>
    <defs>
      <pattern id={`scan-${color.replace(/[^a-z0-9]/gi,'')}`} x="0" y="0" width="1" height="4" patternUnits="userSpaceOnUse">
        <rect x="0" y="0" width="1" height="1" fill={color} />
      </pattern>
    </defs>
    <rect width="100%" height="100%" fill={`url(#scan-${color.replace(/[^a-z0-9]/gi,'')})`} />
  </svg>
);

const PixelMap = () => {
  const [hoveredRoom, setHoveredRoom] = useState<string | null>(null);
  const [hoveredAgent, setHoveredAgent] = useState<string | null>(null);
  const [activeQuote, setActiveQuote] = useState<{ id: string; quote: string } | null>(null);
  const [agentDirs, setAgentDirs] = useState<Record<string, "s"|"n"|"e"|"w">>({});
  const [tick, setTick] = useState(0);
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const startRef = useRef(Date.now());

  // Quote cycling
  useEffect(() => {
    const cycle = () => {
      const idx = Math.floor(Math.random() * AGENTS.length);
      const a = AGENTS[idx];
      setActiveQuote({ id: a.id, quote: a.quote });
      timerRef.current = setTimeout(() => setActiveQuote(null), 3500);
    };
    const interval = setInterval(cycle, 6000);
    const init = setTimeout(cycle, 800);
    return () => { clearInterval(interval); clearTimeout(init); if (timerRef.current) clearTimeout(timerRef.current); };
  }, []);

  // Direction tracking — update every 400ms
  useEffect(() => {
    const update = () => {
      const now = Date.now();
      const dirs: Record<string, "s"|"n"|"e"|"w"> = {};
      for (const a of AGENTS) {
        const duration = (22 + a.animIndex * 4) * 1000; // match CSS animation
        const t = ((now - startRef.current) % duration) / duration;
        dirs[a.id] = getAgentDir(a.id, t);
      }
      setAgentDirs(dirs);
      setTick(t => t + 1);
    };
    update();
    const iv = setInterval(update, 400);
    return () => clearInterval(iv);
  }, []);

  return (
    <div className="flex-1 glass-panel relative overflow-hidden" style={{ minHeight: 0 }}>
      {/* AI-generated pixel art map background */}
      <div
        className="absolute inset-0"
        style={{
          backgroundImage: "url(/assets/map-bg.png)",
          backgroundSize: "cover",
          backgroundPosition: "center",
          opacity: 0.55,
          mixBlendMode: "luminosity",
        }}
      />
      {/* Dark floor overlay */}
      <div
        className="absolute inset-0"
        style={{ background: "radial-gradient(ellipse 90% 70% at 50% 42%, hsl(225 25% 11% / 0.55) 0%, hsl(225 30% 6% / 0.75) 100%)" }}
      />

      {/* Fine grid */}
      <div className="absolute inset-0 pointer-events-none" style={{
        backgroundImage: "linear-gradient(hsl(225 15% 18% / 0.15) 1px, transparent 1px), linear-gradient(90deg, hsl(225 15% 18% / 0.15) 1px, transparent 1px)",
        backgroundSize: "20px 20px",
      }} />

      {/* Corridors */}
      <svg className="absolute inset-0 w-full h-full pointer-events-none" style={{ opacity: 0.35 }}>
        {corridors.map((c, i) => (
          <g key={i}>
            <line x1={c.x1} y1={c.y1} x2={c.x2} y2={c.y2} stroke="hsl(43 50% 30%)" strokeWidth="12" opacity="0.08" />
            <line x1={c.x1} y1={c.y1} x2={c.x2} y2={c.y2} stroke="hsl(43 60% 40%)" strokeWidth="2" strokeDasharray="6 5" />
          </g>
        ))}
      </svg>

      {/* Office desks */}
      {desks.map((d, i) => (
        <div key={i} className="absolute rounded-sm pointer-events-none"
          style={{
            left: d.x, top: d.y, width: d.w, height: d.h,
            background: "hsl(225 20% 16%)",
            border: "1px solid hsl(225 15% 26%)",
            boxShadow: "inset 0 1px 0 hsl(225 20% 28% / 0.6), 0 0 8px hsl(43 60% 30% / 0.08)",
          }} />
      ))}

      {/* Rooms */}
      {rooms.map((r) => {
        const hov = hoveredRoom === r.name;
        return (
          <div
            key={r.name}
            className="absolute cursor-pointer"
            style={{ left: `${r.x}%`, top: `${r.y}%`, width: `${r.w}%`, height: `${r.h}%` }}
            onMouseEnter={() => setHoveredRoom(r.name)}
            onMouseLeave={() => setHoveredRoom(null)}
          >
            {/* Glow bloom */}
            <div className="absolute inset-0 rounded-lg pointer-events-none transition-all duration-500"
              style={{
                background: r.glowColor,
                opacity: hov ? 1 : 0.25,
                filter: hov ? "blur(20px)" : "blur(12px)",
                transform: hov ? "scale(1.4)" : "scale(1.2)",
              }} />

            {/* Wall panel */}
            <div className="absolute inset-0 rounded-lg overflow-hidden transition-all duration-300"
              style={{
                border: `${hov ? 2 : 1}px solid ${hov ? r.color : r.color + "22"}`,
                background: hov
                  ? `linear-gradient(145deg, hsl(225 22% 14% / 0.97), hsl(225 28% 9% / 0.93))`
                  : `linear-gradient(145deg, hsl(225 22% 10% / 0.88), hsl(225 28% 7% / 0.82))`,
                backdropFilter: "blur(8px)",
                boxShadow: hov
                  ? `0 0 32px ${r.glowColor}, 0 0 8px ${r.color}30, inset 0 1px 0 ${r.color}22`
                  : `inset 0 1px 0 hsl(225 20% 20% / 0.3)`,
                transition: "all 0.3s ease",
              }}>

              {/* Scan lines on hover */}
              {hov && <ScanLines color={r.color} />}

              {/* Inner border accent */}
              <div className="absolute inset-[3px] rounded-md pointer-events-none transition-all duration-300"
                style={{ border: `1px solid ${hov ? r.color + "28" : r.color + "08"}` }} />

              {/* Corner pixel decorations */}
              {(["top-0 left-0", "top-0 right-0", "bottom-0 left-0", "bottom-0 right-0"] as const).map((pos, i) => (
                <div key={i} className={`absolute ${pos} pointer-events-none transition-all duration-300`}
                  style={{
                    width: hov ? 10 : 6, height: hov ? 10 : 6,
                    margin: 2,
                    background: hov ? r.color : r.color + "30",
                    clipPath: i === 0 ? "polygon(0 0,100% 0,0 100%)"
                            : i === 1 ? "polygon(0 0,100% 0,100% 100%)"
                            : i === 2 ? "polygon(0 0,0 100%,100% 100%)"
                            :           "polygon(100% 0,0 100%,100% 100%)",
                  }} />
              ))}

              {/* Label + data readout */}
              <div className="flex flex-col items-center justify-center h-full gap-0.5 px-1 relative z-10">
                <span className="font-pixel text-base sm:text-xl transition-all duration-300"
                  style={{
                    color: hov ? r.color : r.color + "70",
                    textShadow: hov ? `0 0 12px ${r.color}` : "none",
                  }}>{r.icon}</span>
                <span className="font-pixel text-[7px] sm:text-[9px] text-center leading-tight transition-colors duration-300"
                  style={{ color: hov ? r.color : "hsl(210 15% 45%)" }}>{r.label}</span>

                {hov && (
                  <div className="flex flex-col items-center gap-[2px] mt-1 w-full px-2"
                    style={{ animation: "timeline-enter 0.15s ease-out forwards" }}>
                    <div className="text-[6px] font-pixel opacity-60" style={{ color: r.color }}>{r.desc}</div>
                    {r.stats.map((s, i) => (
                      <div key={i} className="flex items-center gap-1 w-full justify-center">
                        <div className="w-[4px] h-[4px] rounded-[1px]" style={{ background: r.color + "80" }} />
                        <span className="text-[6px] font-mono" style={{ color: r.color + "aa" }}>{s}</span>
                      </div>
                    ))}
                    {/* Status bar */}
                    <div className="w-full mt-0.5 h-[2px] rounded-full overflow-hidden" style={{ background: r.color + "20" }}>
                      <div className="h-full rounded-full" style={{
                        width: "100%",
                        background: r.color,
                        animation: "room-status-bar 1.5s ease-in-out infinite",
                      }} />
                    </div>
                  </div>
                )}
              </div>

              {/* Animated border glow on hover */}
              {hov && (
                <div className="absolute inset-0 rounded-lg pointer-events-none"
                  style={{
                    boxShadow: `inset 0 0 20px ${r.color}15`,
                    animation: "pulse-glow 2s ease-in-out infinite",
                  }} />
              )}
            </div>
          </div>
        );
      })}

      {/* 6 NPCs — direction-aware sprites */}
      {AGENTS.map((agent) => {
        const isHov = hoveredAgent === agent.id;
        const isQ = activeQuote?.id === agent.id;
        const dir = agentDirs[agent.id] || "e";
        return (
          <div
            key={agent.id}
            className="absolute z-10"
            style={{ animation: `npc-move-${agent.animIndex} ${22 + agent.animIndex * 4}s cubic-bezier(0.45,0,0.55,1) infinite` }}
            onMouseEnter={() => setHoveredAgent(agent.id)}
            onMouseLeave={() => setHoveredAgent(null)}
          >
            {/* Speech bubble */}
            {(isHov || isQ) && (
              <div
                className="absolute z-20 pointer-events-none"
                style={{
                  bottom: "calc(100% + 4px)",
                  left: "32px",
                  transform: "translateX(-50%)",
                  width: "140px",
                  padding: "5px 7px",
                  borderRadius: "6px",
                  background: "hsl(225 25% 10% / 0.97)",
                  border: `1px solid ${agent.color}55`,
                  boxShadow: `0 0 18px ${agent.color}30, 0 4px 12px hsl(225 30% 4% / 0.8)`,
                  animation: "timeline-enter 0.15s ease-out forwards",
                }}
              >
                {isHov && (
                  <div className="font-pixel text-[7px] mb-1 opacity-80" style={{ color: agent.color }}>
                    {agent.name} · {agent.role}
                  </div>
                )}
                <p className="text-[8px] font-mono leading-snug" style={{ color: agent.color + "dd" }}>
                  "{agent.quote}"
                </p>
                <div className="absolute top-full left-1/2 -translate-x-1/2"
                  style={{ width: 0, height: 0, borderLeft: "4px solid transparent", borderRight: "4px solid transparent", borderTop: `4px solid ${agent.color}55` }} />
              </div>
            )}

            {/* Direction-aware LPC sprite */}
            <div
              className="relative cursor-pointer select-none"
              style={{
                filter: isHov
                  ? `drop-shadow(0 0 6px ${agent.color}) drop-shadow(0 0 2px ${agent.color}) brightness(1.15)`
                  : undefined,
                transition: "filter 0.2s",
              }}
            >
              <div
                style={{
                  width: 64,
                  height: 64,
                  backgroundImage: `url(/assets/npcs/npc-${agent.id}-${dir}.png)`,
                  backgroundRepeat: "no-repeat",
                  backgroundSize: `${9 * 64}px 64px`,
                  imageRendering: "pixelated",
                  animation: `npc-sprite-${agent.animIndex} 0.6s steps(1) infinite`,
                }}
              />
              {/* Hover glow overlay */}
              {isHov && (
                <div className="absolute inset-0 pointer-events-none rounded"
                  style={{
                    background: agent.color + "15",
                    mixBlendMode: "screen",
                    animation: "pulse-glow 1s ease-in-out infinite",
                  }} />
              )}
              {/* Icon badge */}
              <div className="absolute -top-2 -right-1 text-[9px] font-pixel"
                style={{ color: agent.color, textShadow: `0 0 8px ${agent.color}` }}>
                {agent.icon}
              </div>
              {/* Name label */}
              <div className="absolute top-full left-1/2 -translate-x-1/2 text-[7px] font-pixel whitespace-nowrap mt-0.5"
                style={{ color: agent.color + "cc" }}>
                {agent.name}
              </div>
            </div>
          </div>
        );
      })}

      {/* Ambient room glows */}
      {rooms.map((r, i) => (
        <div key={`amb-${i}`} className="absolute pointer-events-none"
          style={{
            left: `${r.x + r.w / 2}%`, top: `${r.y + r.h / 2}%`,
            width: "100px", height: "100px",
            transform: "translate(-50%, -50%)",
            background: `radial-gradient(circle, ${r.color}08 0%, transparent 70%)`,
            animation: `pulse-glow ${3.5 + i * 0.6}s ease-in-out infinite`,
          }} />
      ))}

      {/* Minimap */}
      <div className="absolute top-2 right-2 w-[68px] h-[58px] glass-panel p-1 opacity-50 hover:opacity-100 transition-opacity z-10">
        <div className="w-full h-full relative rounded-sm overflow-hidden" style={{ background: "hsl(225 30% 7%)" }}>
          {rooms.map((r) => (
            <div key={r.name} className="absolute rounded-[1px] transition-all duration-200"
              style={{
                left: `${r.x}%`, top: `${r.y}%`, width: `${r.w}%`, height: `${r.h}%`,
                background: hoveredRoom === r.name ? r.color + "90" : r.color + "30",
                boxShadow: hoveredRoom === r.name ? `0 0 4px ${r.color}` : "none",
              }} />
          ))}
          {AGENTS.map((a) => (
            <div key={`mm-${a.id}`} className="absolute w-[5px] h-[5px] rounded-full"
              style={{
                background: a.color,
                boxShadow: `0 0 3px ${a.color}`,
                animation: `npc-move-${a.animIndex} ${22 + a.animIndex * 4}s cubic-bezier(0.45,0,0.55,1) infinite`,
              }} />
          ))}
        </div>
        <p className="text-[6px] text-muted-foreground font-pixel text-center mt-0.5">MAP</p>
      </div>

      {/* Agent legend */}
      <div className="absolute bottom-2 left-2 flex flex-col gap-0.5 z-10">
        {AGENTS.map((a) => (
          <div
            key={`leg-${a.id}`}
            className="flex items-center gap-1 px-1.5 py-0.5 rounded cursor-pointer transition-all duration-150"
            style={{
              background: hoveredAgent === a.id ? a.color + "18" : "transparent",
              border: `1px solid ${hoveredAgent === a.id ? a.color + "45" : "transparent"}`,
              boxShadow: hoveredAgent === a.id ? `0 0 8px ${a.color}20` : "none",
            }}
            onMouseEnter={() => setHoveredAgent(a.id)}
            onMouseLeave={() => setHoveredAgent(null)}
          >
            <div className="w-[7px] h-[7px] rounded-[1px] shrink-0" style={{ background: a.color, boxShadow: `0 0 4px ${a.color}` }} />
            <span className="text-[7px] font-pixel" style={{ color: a.color + "cc" }}>{a.name}</span>
            <span className="text-[6px] text-muted-foreground ml-0.5">{a.role.split(" ")[0]}</span>
          </div>
        ))}
      </div>
    </div>
  );
};

export default PixelMap;
