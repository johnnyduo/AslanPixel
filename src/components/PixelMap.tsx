import { useState, useEffect, useRef } from "react";
import { AGENTS } from "@/data/agents";

interface Room {
  name: string;
  label: string;
  x: number; y: number; w: number; h: number;
  color: string;
  glowColor: string;
  icon: string;
  desc: string;
}

const rooms: Room[] = [
  { name: "hub",      label: "Town Square",     x: 33, y: 30, w: 34, h: 22, color: "hsl(43 90% 55%)",   glowColor: "hsl(43 90% 55% / 0.15)",   icon: "◈", desc: "Central plaza" },
  { name: "guild",    label: "Guild Hall",       x:  4, y:  8, w: 26, h: 20, color: "hsl(195 100% 50%)", glowColor: "hsl(195 100% 50% / 0.14)", icon: "⬡", desc: "Agent command" },
  { name: "vault",    label: "Vault House",      x: 70, y:  8, w: 26, h: 20, color: "hsl(280 65% 65%)",  glowColor: "hsl(280 65% 65% / 0.14)",  icon: "◆", desc: "Assets & portfolio" },
  { name: "strategy", label: "Strategy Tower",   x:  4, y: 55, w: 26, h: 20, color: "hsl(142 70% 45%)",  glowColor: "hsl(142 70% 45% / 0.14)",  icon: "▲", desc: "Planning ops" },
  { name: "market",   label: "Market Gate",      x: 70, y: 55, w: 26, h: 20, color: "hsl(38 92% 50%)",   glowColor: "hsl(38 92% 50% / 0.14)",   icon: "◉", desc: "Execution hub" },
  { name: "archive",  label: "Archive Library",  x: 33, y: 78, w: 34, h: 18, color: "hsl(0 72% 60%)",    glowColor: "hsl(0 72% 60% / 0.14)",    icon: "▣", desc: "Onchain records" },
];

// Corridors connecting rooms
const corridors = [
  { x1: "30%", y1: "18%", x2: "70%", y2: "18%" },   // top h
  { x1: "30%", y1: "78%", x2: "70%", y2: "78%" },   // bottom h
  { x1: "17%", y1: "28%", x2: "17%", y2: "55%" },   // left v
  { x1: "83%", y1: "28%", x2: "83%", y2: "55%" },   // right v
  { x1: "33%", y1: "41%", x2: "30%", y2: "18%" },   // hub→guild top
  { x1: "67%", y1: "41%", x2: "70%", y2: "18%" },   // hub→vault top
  { x1: "33%", y1: "41%", x2: "30%", y2: "55%" },   // hub→strategy
  { x1: "67%", y1: "41%", x2: "70%", y2: "55%" },   // hub→market
  { x1: "50%", y1: "52%", x2: "50%", y2: "78%" },   // hub→archive
];

// Desks inside hub
const desks = [
  { x: "39%", y: "34%", w: "7%", h: "4%" },
  { x: "54%", y: "34%", w: "7%", h: "4%" },
  { x: "39%", y: "43%", w: "7%", h: "4%" },
  { x: "54%", y: "43%", w: "7%", h: "4%" },
  { x: "47%", y: "38%", w: "6%", h: "5%" },
];


const PixelMap = () => {
  const [hoveredRoom, setHoveredRoom] = useState<string | null>(null);
  const [hoveredAgent, setHoveredAgent] = useState<string | null>(null);
  const [activeQuote, setActiveQuote] = useState<{ id: string; quote: string } | null>(null);
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    const cycle = () => {
      const idx = Math.floor(Math.random() * AGENTS.length);
      const a = AGENTS[idx];
      setActiveQuote({ id: a.id, quote: a.quote });
      timerRef.current = setTimeout(() => setActiveQuote(null), 3500);
    };
    const interval = setInterval(cycle, 6000);
    const init = setTimeout(cycle, 800);
    return () => {
      clearInterval(interval);
      clearTimeout(init);
      if (timerRef.current) clearTimeout(timerRef.current);
    };
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
          opacity: 0.35,
        }}
      />
      {/* Dark floor overlay */}
      <div
        className="absolute inset-0"
        style={{ background: "radial-gradient(ellipse 90% 70% at 50% 42%, hsl(225 25% 11% / 0.7) 0%, hsl(225 30% 6% / 0.85) 100%)" }}
      />

      {/* Fine grid */}
      <div className="absolute inset-0 pointer-events-none" style={{
        backgroundImage: "linear-gradient(hsl(225 15% 18% / 0.2) 1px, transparent 1px), linear-gradient(90deg, hsl(225 15% 18% / 0.2) 1px, transparent 1px)",
        backgroundSize: "20px 20px",
      }} />
      {/* Coarse grid */}
      <div className="absolute inset-0 pointer-events-none" style={{
        backgroundImage: "linear-gradient(hsl(225 15% 22% / 0.12) 1px, transparent 1px), linear-gradient(90deg, hsl(225 15% 22% / 0.12) 1px, transparent 1px)",
        backgroundSize: "100px 100px",
      }} />

      {/* Corridors */}
      <svg className="absolute inset-0 w-full h-full pointer-events-none" style={{ opacity: 0.2 }}>
        {corridors.map((c, i) => (
          <g key={i}>
            <line x1={c.x1} y1={c.y1} x2={c.x2} y2={c.y2} stroke="hsl(43 50% 30%)" strokeWidth="10" opacity="0.06" />
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
            border: "1px solid hsl(225 15% 24%)",
            boxShadow: "inset 0 1px 0 hsl(225 20% 26% / 0.5)",
          }} />
      ))}

      {/* Rooms */}
      {rooms.map((r) => {
        const hov = hoveredRoom === r.name;
        return (
          <div
            key={r.name}
            className="absolute cursor-pointer transition-all duration-300"
            style={{ left: `${r.x}%`, top: `${r.y}%`, width: `${r.w}%`, height: `${r.h}%` }}
            onMouseEnter={() => setHoveredRoom(r.name)}
            onMouseLeave={() => setHoveredRoom(null)}
          >
            {/* Glow bloom */}
            <div className="absolute inset-0 rounded-lg pointer-events-none transition-opacity duration-300"
              style={{
                background: r.glowColor,
                opacity: hov ? 1 : 0.3,
                filter: "blur(16px)",
                transform: "scale(1.3)",
              }} />
            {/* Wall */}
            <div className="absolute inset-0 rounded-lg transition-all duration-300"
              style={{
                border: `2px solid ${hov ? r.color : r.color + "28"}`,
                background: "linear-gradient(145deg, hsl(225 22% 12% / 0.93), hsl(225 28% 8% / 0.88))",
                backdropFilter: "blur(6px)",
                boxShadow: hov ? `0 0 24px ${r.glowColor}, inset 0 1px 0 ${r.color}18` : "inset 0 1px 0 hsl(225 20% 20% / 0.35)",
              }}>
              {/* Inner border */}
              <div className="absolute inset-[3px] rounded-md pointer-events-none"
                style={{ border: `1px solid ${r.color}12` }} />
              {/* Label */}
              <div className="flex flex-col items-center justify-center h-full gap-0.5 px-1">
                <span className="font-pixel text-base sm:text-xl transition-colors duration-200"
                  style={{ color: hov ? r.color : r.color + "80" }}>{r.icon}</span>
                <span className="font-pixel text-[7px] sm:text-[9px] text-center leading-tight transition-colors duration-200"
                  style={{ color: hov ? r.color : "hsl(210 15% 50%)" }}>{r.label}</span>
                {hov && (
                  <span className="text-[7px] text-center leading-tight mt-0.5" style={{ color: "hsl(210 15% 55%)" }}>
                    {r.desc}
                  </span>
                )}
              </div>
              {/* Corner pixels */}
              {["top-0 left-0", "top-0 right-0", "bottom-0 left-0", "bottom-0 right-0"].map((pos, i) => (
                <div key={i} className={`absolute ${pos} w-2 h-2 rounded-[1px]`}
                  style={{ background: r.color + (hov ? "55" : "20") }} />
              ))}
            </div>
          </div>
        );
      })}

      {/* 6 NPCs */}
      {AGENTS.map((agent) => {
        const isHov = hoveredAgent === agent.id;
        const isQ = activeQuote?.id === agent.id;
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
                  bottom: "calc(100% + 2px)",
                  left: "32px",
                  transform: "translateX(-50%)",
                  width: "140px",
                  padding: "5px 7px",
                  borderRadius: "6px",
                  background: "hsl(225 25% 10% / 0.97)",
                  border: `1px solid ${agent.color}55`,
                  boxShadow: `0 0 14px ${agent.color}25`,
                  animation: "timeline-enter 0.2s ease-out forwards",
                }}
              >
                {isHov && (
                  <div className="font-pixel text-[7px] mb-1 opacity-70" style={{ color: agent.color }}>
                    {agent.name} · {agent.role}
                  </div>
                )}
                <p className="text-[8px] font-mono leading-snug" style={{ color: agent.color + "dd" }}>
                  "{agent.quote}"
                </p>
                {/* Tail */}
                <div className="absolute top-full left-1/2 -translate-x-1/2"
                  style={{ width: 0, height: 0, borderLeft: "4px solid transparent", borderRight: "4px solid transparent", borderTop: `4px solid ${agent.color}55` }} />
              </div>
            )}

            {/* Real LPC sprite — walk animation */}
            <div
              className="relative cursor-pointer select-none"
              style={{ filter: isHov ? `drop-shadow(0 0 4px ${agent.color}) brightness(1.1)` : undefined }}
            >
              <div
                style={{
                  width: 64,
                  height: 64,
                  backgroundImage: `url(/assets/npcs/npc-${agent.id}.png)`,
                  backgroundRepeat: "no-repeat",
                  backgroundSize: `${9 * 64}px 64px`,
                  imageRendering: "pixelated",
                  animation: `npc-sprite-${agent.animIndex} 0.65s steps(1) infinite`,
                }}
              />
              {/* Color glow overlay */}
              <div
                className="absolute inset-0 pointer-events-none rounded"
                style={{
                  boxShadow: `inset 0 0 12px ${agent.color}00`,
                  mixBlendMode: "screen",
                  opacity: isHov ? 0.3 : 0,
                  background: agent.color + "20",
                  transition: "opacity 0.2s",
                }}
              />
              {/* Icon badge */}
              <div
                className="absolute -top-2 -right-1 text-[9px] font-pixel"
                style={{ color: agent.color, textShadow: `0 0 6px ${agent.color}` }}
              >
                {agent.icon}
              </div>
              {/* Name label */}
              <div
                className="absolute top-full left-1/2 -translate-x-1/2 text-[7px] font-pixel whitespace-nowrap mt-0.5"
                style={{ color: agent.color + "cc" }}
              >
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
            width: "80px", height: "80px",
            transform: "translate(-50%, -50%)",
            background: `radial-gradient(circle, ${r.color}07 0%, transparent 70%)`,
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
              }} />
          ))}
          {AGENTS.map((a) => (
            <div key={`mm-${a.id}`} className="absolute w-[5px] h-[5px] rounded-full"
              style={{
                background: a.color,
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
            }}
            onMouseEnter={() => setHoveredAgent(a.id)}
            onMouseLeave={() => setHoveredAgent(null)}
          >
            <div className="w-[7px] h-[7px] rounded-[1px] shrink-0" style={{ background: a.color }} />
            <span className="text-[7px] font-pixel" style={{ color: a.color + "cc" }}>{a.name}</span>
            <span className="text-[6px] text-muted-foreground ml-0.5">{a.role.split(" ")[0]}</span>
          </div>
        ))}
      </div>
    </div>
  );
};

export default PixelMap;
