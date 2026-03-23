import { useState, useEffect, useRef } from "react";
import { useNavigate } from "react-router-dom";

const AGENTS = [
  { id: "nexus",  symbol: "◈", name: "Nexus",  role: "HCS Intelligence",      color: "#00d4ff", delay: 0 },
  { id: "oryn",   symbol: "▲", name: "Oryn",   role: "Strategy Engine",        color: "#a855f7", delay: 120 },
  { id: "drax",   symbol: "◆", name: "Drax",   role: "Risk Sentinel",          color: "#ef4444", delay: 240 },
  { id: "lyss",   symbol: "◉", name: "Lyss",   role: "Treasury Keeper",        color: "#22c55e", delay: 360 },
  { id: "vex",    symbol: "▶", name: "Vex",    role: "TX Executor",            color: "#f59e0b", delay: 480 },
  { id: "kael",   symbol: "▣", name: "Kael",   role: "Ledger Archivist",       color: "#e2e8f0", delay: 600 },
];

const LIVE_EVENTS = [
  { agent: "Nexus ◈",  color: "#00d4ff", msg: "HCS topic scan complete — 847 messages indexed" },
  { agent: "Oryn ▲",   color: "#a855f7", msg: "3-branch strategy modeled — confidence 94.2%" },
  { agent: "Drax ◆",   color: "#ef4444", msg: "PolicyManager.sol check PASSED — 0 violations" },
  { agent: "Lyss ◉",   color: "#22c55e", msg: "Treasury: 142.3 HBAR / 8,420 USDC — budget OK" },
  { agent: "Vex ▶",    color: "#f59e0b", msg: "EVM simulate → sign → submit — TX confirmed" },
  { agent: "Kael ▣",   color: "#e2e8f0", msg: "QuestReceipt #238 stored onchain — immutable" },
  { agent: "Nexus ◈",  color: "#00d4ff", msg: "SaucerSwap HBAR/USDC pool TVL: $2.4M" },
  { agent: "Drax ◆",   color: "#ef4444", msg: "VETO — quest risk score 87/100 — standing down" },
  { agent: "Oryn ▲",   color: "#a855f7", msg: "Yield optimization path found — +12.4% APR" },
  { agent: "Lyss ◉",   color: "#22c55e", msg: "30% USDC buffer locked — treasury rebalanced" },
];

const STATS = [
  { value: "6", label: "AI Agents" },
  { value: "238+", label: "Quests Onchain" },
  { value: "1,428", label: "HCS Messages" },
  { value: "3", label: "Smart Contracts" },
];

const HEDERA_BADGES = [
  "HCS Consensus",
  "HTS Token Service",
  "Hedera EVM",
  "Mirror Node",
  "SaucerSwap DEX",
  "HashScan Verified",
];

// Animated pixel grid background
function PixelGrid() {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    const W = canvas.width = canvas.offsetWidth;
    const H = canvas.height = canvas.offsetHeight;
    const SIZE = 32;
    const COLS = Math.ceil(W / SIZE);
    const ROWS = Math.ceil(H / SIZE);

    type Cell = { x: number; y: number; alpha: number; speed: number; hue: number };
    const cells: Cell[] = [];
    for (let r = 0; r < ROWS; r++) {
      for (let c = 0; c < COLS; c++) {
        if (Math.random() > 0.85) {
          cells.push({
            x: c * SIZE,
            y: r * SIZE,
            alpha: Math.random(),
            speed: 0.003 + Math.random() * 0.008,
            hue: Math.random() > 0.5 ? 43 : 195,
          });
        }
      }
    }

    let frame: number;
    const draw = () => {
      ctx.clearRect(0, 0, W, H);
      for (const cell of cells) {
        cell.alpha += cell.speed;
        if (cell.alpha > 1) { cell.alpha = 0; cell.speed = 0.003 + Math.random() * 0.008; }
        const a = Math.sin(cell.alpha * Math.PI) * 0.15;
        ctx.fillStyle = `hsla(${cell.hue}, 80%, 60%, ${a})`;
        ctx.fillRect(cell.x + 1, cell.y + 1, SIZE - 2, SIZE - 2);
      }
      frame = requestAnimationFrame(draw);
    };
    draw();
    return () => cancelAnimationFrame(frame);
  }, []);

  return (
    <canvas
      ref={canvasRef}
      className="absolute inset-0 w-full h-full pointer-events-none"
      style={{ imageRendering: "pixelated" }}
    />
  );
}

// Pixel lion head — pure CSS pixel art
function PixelLion() {
  // 16x16 grid, each cell is 0 (transparent), 1 (mane/gold), 2 (face/tan), 3 (dark/shadow), 4 (eye/white), 5 (nose/pink)
  const G = [
    [0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0],
    [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0],
    [0,1,1,1,2,2,2,2,2,2,2,2,1,1,1,0],
    [1,1,1,2,2,2,2,2,2,2,2,2,2,1,1,1],
    [1,1,2,2,2,2,2,2,2,2,2,2,2,2,1,1],
    [1,1,2,2,4,3,2,2,2,2,3,4,2,2,1,1],
    [1,1,2,2,4,3,2,2,2,2,3,4,2,2,1,1],
    [1,1,2,2,2,2,2,2,2,2,2,2,2,2,1,1],
    [1,1,2,2,2,5,5,2,2,5,5,2,2,2,1,1],
    [1,1,2,2,2,2,3,3,3,3,2,2,2,2,1,1],
    [1,1,1,2,2,2,2,2,2,2,2,2,2,1,1,1],
    [0,1,1,1,2,2,2,2,2,2,2,2,1,1,1,0],
    [0,1,1,1,1,2,2,2,2,2,2,1,1,1,1,0],
    [0,0,1,1,1,1,1,1,1,1,1,1,1,1,0,0],
    [0,0,0,1,1,1,0,0,0,0,1,1,1,0,0,0],
    [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
  ];
  const COLORS = ["transparent","#f59e0b","#fcd28d","#92400e","#fffbf0","#f97316"];
  const SIZE = 14; // px per cell

  return (
    <div className="relative z-10 mb-6 flex justify-center" style={{ filter: "drop-shadow(0 0 24px rgba(245,158,11,0.5))" }}>
      <div style={{ display: "grid", gridTemplateColumns: `repeat(16, ${SIZE}px)`, imageRendering: "pixelated" }}>
        {G.flat().map((v, i) => (
          <div
            key={i}
            style={{
              width: SIZE,
              height: SIZE,
              background: COLORS[v],
              animation: v === 4 ? "pulse 2s ease-in-out infinite" : undefined,
            }}
          />
        ))}
      </div>
    </div>
  );
}

// Scrolling live feed
function LiveFeed() {
  const [lines, setLines] = useState<typeof LIVE_EVENTS>([]);
  const [idx, setIdx] = useState(0);

  useEffect(() => {
    const t = setInterval(() => {
      setLines(prev => {
        const next = [...prev, LIVE_EVENTS[idx % LIVE_EVENTS.length]];
        return next.slice(-6);
      });
      setIdx(i => i + 1);
    }, 1400);
    return () => clearInterval(t);
  }, [idx]);

  return (
    <div className="font-mono text-[11px] space-y-1 h-[108px] overflow-hidden">
      {lines.map((line, i) => (
        <div
          key={i}
          className="flex gap-2 items-start animate-in fade-in slide-in-from-bottom-1 duration-300"
        >
          <span className="shrink-0 opacity-40 text-slate-400">
            {new Date().toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit", second: "2-digit" })}
          </span>
          <span style={{ color: line.color }} className="shrink-0 font-bold w-16">{line.agent.split(" ")[0]}</span>
          <span className="text-slate-300 opacity-80">{line.msg}</span>
        </div>
      ))}
    </div>
  );
}

export default function Landing() {
  const navigate = useNavigate();
  const [entered, setEntered] = useState(false);
  const [voteStep, setVoteStep] = useState(-1);

  // Run vote animation loop
  useEffect(() => {
    const run = () => {
      setVoteStep(-1);
      let s = 0;
      const t = setInterval(() => {
        s++;
        setVoteStep(s);
        if (s >= AGENTS.length) { clearInterval(t); setTimeout(run, 3000); }
      }, 500);
    };
    const init = setTimeout(run, 1200);
    return () => clearTimeout(init);
  }, []);

  const handleEnter = () => {
    setEntered(true);
    setTimeout(() => navigate("/app"), 600);
  };

  return (
    <div
      className={`min-h-screen bg-[#0a0a0f] text-white overflow-x-hidden transition-opacity duration-500 ${entered ? "opacity-0" : "opacity-100"}`}
      style={{ fontFamily: "'Courier New', monospace" }}
    >
      {/* ─── HERO ─────────────────────────────────────────────── */}
      <section className="relative min-h-screen flex flex-col items-center justify-center px-4 overflow-hidden">
        <PixelGrid />

        {/* Glow orb */}
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] rounded-full pointer-events-none"
          style={{ background: "radial-gradient(circle, rgba(43,131,255,0.06) 0%, transparent 70%)" }} />

        {/* Pixel lion mascot */}
        <PixelLion />

        {/* Hedera AgentKit badge */}
        <div className="relative z-10 mb-4 flex flex-wrap justify-center items-center gap-2">
          <div className="flex items-center gap-2 border border-amber-500/30 rounded px-3 py-1 bg-amber-500/5">
            <span className="w-2 h-2 rounded-full bg-amber-400 animate-pulse" />
            <span className="text-amber-400 text-xs tracking-widest uppercase">Built on Hedera Testnet</span>
          </div>
          <div className="flex items-center gap-2 border border-purple-500/40 rounded px-3 py-1 bg-purple-500/5">
            <span className="text-purple-300 text-xs">⚡</span>
            <span className="text-purple-300 text-xs tracking-widest uppercase font-bold">Powered by Hedera AgentKit</span>
          </div>
        </div>

        {/* Title */}
        <div className="relative z-10 text-center mb-4">
          <h1 className="text-5xl md:text-7xl font-bold tracking-tight mb-2"
            style={{ textShadow: "0 0 40px rgba(43,131,255,0.4)" }}>
            <span className="text-amber-400">Aslan</span>
            <span className="text-white"> Pixel</span>
          </h1>
          <p className="text-lg md:text-xl text-slate-400 tracking-widest uppercase">
            Agentic AI Society on Hedera
          </p>
        </div>

        {/* Subtitle */}
        <p className="relative z-10 text-center text-slate-300 max-w-xl mb-10 leading-relaxed text-sm md:text-base">
          Six autonomous AI agents that <span className="text-amber-400">think</span>,{" "}
          <span className="text-cyan-400">transact</span>, and{" "}
          <span className="text-purple-400">archive</span> everything onchain —
          every decision, every transaction, every receipt — verified and immutable on Hedera.
        </p>

        {/* CTA */}
        <button
          onClick={handleEnter}
          className="relative z-10 group px-10 py-4 text-base font-bold tracking-widest uppercase border-2 border-amber-500 text-amber-400 hover:bg-amber-500 hover:text-black transition-all duration-200 cursor-pointer"
          style={{ imageRendering: "pixelated" }}
        >
          <span className="group-hover:opacity-0 transition-opacity">▶ Enter the Pixel</span>
          <span className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
            Entering Pixel...
          </span>
        </button>

        <p className="relative z-10 mt-4 text-slate-600 text-xs">Live demo — Hedera Testnet — No signup needed · Powered by Hedera AgentKit</p>

        {/* Stats */}
        <div className="relative z-10 mt-14 grid grid-cols-2 md:grid-cols-4 gap-px border border-slate-800 bg-slate-800">
          {STATS.map(s => (
            <div key={s.label} className="bg-[#0a0a0f] px-8 py-5 text-center">
              <div className="text-2xl md:text-3xl font-bold text-amber-400">{s.value}</div>
              <div className="text-xs text-slate-500 uppercase tracking-widest mt-1">{s.label}</div>
            </div>
          ))}
        </div>
      </section>

      {/* ─── HOW IT WORKS ─────────────────────────────────────── */}
      <section className="py-24 px-4 max-w-5xl mx-auto">
        <h2 className="text-center text-2xl font-bold mb-2 text-amber-400 tracking-widest uppercase">How It Works</h2>
        <p className="text-center text-slate-500 text-sm mb-12">One intent triggers a 6-agent autonomous pipeline</p>

        <div className="relative">
          {/* Line */}
          <div className="absolute left-6 top-0 bottom-0 w-px bg-gradient-to-b from-amber-500/40 via-cyan-500/20 to-transparent hidden md:block" />

          <div className="space-y-8">
            {[
              { n: "01", title: "You type an intent", desc: "Natural language like \"Rebalance treasury with 30% USDC buffer\" — or let Auto-Quest fire every 9 minutes autonomously.", color: "#f59e0b" },
              { n: "02", title: "Guild Vote: 6 agents decide", desc: "All 6 agents vote sequentially. Drax (Risk Sentinel) can VETO if it detects policy violations — the quest stops.", color: "#ef4444" },
              { n: "03", title: "Agents mobilize onchain", desc: "Nexus reads HCS, Oryn models strategy, Lyss allocates budget, Vex executes the EVM transaction — each streamed live.", color: "#00d4ff" },
              { n: "04", title: "Receipt archived forever", desc: "Kael writes an immutable QuestReceipt.sol entry. Agent reputation updated in AgentRegistry.sol. HCS message posted.", color: "#a855f7" },
            ].map(step => (
              <div key={step.n} className="flex gap-6 items-start md:ml-16">
                <div className="shrink-0 w-10 h-10 border flex items-center justify-center text-xs font-bold"
                  style={{ borderColor: step.color, color: step.color }}>
                  {step.n}
                </div>
                <div>
                  <h3 className="font-bold text-white mb-1" style={{ color: step.color }}>{step.title}</h3>
                  <p className="text-slate-400 text-sm leading-relaxed">{step.desc}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ─── AGENTS ───────────────────────────────────────────── */}
      <section className="py-20 px-4 bg-[#080810] border-y border-slate-900">
        <div className="max-w-5xl mx-auto">
          <h2 className="text-center text-2xl font-bold mb-2 text-amber-400 tracking-widest uppercase">The 6 Agents</h2>
          <p className="text-center text-slate-500 text-sm mb-12">Autonomous, specialized, always watching</p>

          {/* Vote demo */}
          <div className="mb-10 border border-slate-800 bg-[#0a0a0f] p-4">
            <div className="flex items-center gap-2 mb-3">
              <span className="w-2 h-2 rounded-full bg-green-400 animate-pulse" />
              <span className="text-xs text-slate-500 uppercase tracking-widest">Live Guild Vote Simulation</span>
            </div>
            <div className="grid grid-cols-3 md:grid-cols-6 gap-2">
              {AGENTS.map((agent, i) => {
                const voted = voteStep >= i;
                const isVeto = agent.id === "drax" && false; // never veto in demo
                return (
                  <div
                    key={agent.id}
                    className="border p-2 text-center transition-all duration-300"
                    style={{
                      borderColor: voted ? agent.color + "60" : "#1e293b",
                      background: voted ? agent.color + "08" : "transparent",
                    }}
                  >
                    <div className="text-lg font-bold" style={{ color: voted ? agent.color : "#334155" }}>
                      {agent.symbol}
                    </div>
                    <div className="text-[10px] font-bold mt-1" style={{ color: voted ? agent.color : "#475569" }}>
                      {agent.name}
                    </div>
                    <div className="text-[8px] text-slate-600 mt-0.5">{agent.role}</div>
                    <div className="mt-1 text-[10px]">
                      {voted ? (
                        <span style={{ color: agent.color }}>✓ YES</span>
                      ) : (
                        <span className="text-slate-700">— wait</span>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
            {voteStep >= AGENTS.length - 1 && (
              <div className="mt-3 text-center text-xs text-green-400 font-bold animate-in fade-in duration-500">
                ✓ 6/6 APPROVED — Quest executing...
              </div>
            )}
          </div>
        </div>
      </section>

      {/* ─── LIVE FEED ────────────────────────────────────────── */}
      <section className="py-20 px-4 max-w-5xl mx-auto">
        <div className="grid md:grid-cols-2 gap-8 items-start">
          <div>
            <h2 className="text-2xl font-bold mb-2 text-amber-400 tracking-widest uppercase">Live Agent Activity</h2>
            <p className="text-slate-400 text-sm mb-6 leading-relaxed">
              Agents never sleep. Every 9 minutes, the guild fires an autonomous quest — yield optimization, risk scans, treasury reconciliation — streamed live with no human trigger.
            </p>
            <div className="space-y-3">
              {["Every action posted to HCS consensus", "Every quest receipt stored onchain", "Agent reputation updated per mission", "Full audit trail — no black boxes"].map(f => (
                <div key={f} className="flex items-center gap-2 text-sm text-slate-300">
                  <span className="text-amber-400">◆</span> {f}
                </div>
              ))}
            </div>
          </div>

          <div className="border border-slate-800 bg-[#080810] p-4">
            <div className="flex items-center gap-2 mb-3 border-b border-slate-800 pb-2">
              <span className="w-2 h-2 rounded-full bg-cyan-400 animate-pulse" />
              <span className="text-xs text-slate-500 uppercase tracking-widest">Agent Feed — Live</span>
            </div>
            <LiveFeed />
          </div>
        </div>
      </section>

      {/* ─── HEDERA INTEGRATIONS ──────────────────────────────── */}
      <section className="py-20 px-4 bg-[#080810] border-y border-slate-900">
        <div className="max-w-5xl mx-auto text-center">
          <h2 className="text-2xl font-bold mb-2 text-amber-400 tracking-widest uppercase">Full Hedera Stack</h2>
          <p className="text-slate-500 text-sm mb-10">Not a demo — real transactions, real consensus, real receipts</p>
          <div className="flex flex-wrap justify-center gap-2 mb-12">
            {HEDERA_BADGES.map(b => (
              <span key={b} className="border border-amber-500/30 text-amber-400/80 text-xs px-3 py-1 tracking-widest">
                {b}
              </span>
            ))}
          </div>

          {/* Contracts */}
          <div className="grid md:grid-cols-3 gap-px bg-slate-800 border border-slate-800">
            {[
              { name: "QuestReceipt.sol", addr: "0x444f...541C7D", desc: "Immutable quest receipts" },
              { name: "AgentRegistry.sol", addr: "0x8B90...336CC4", desc: "Agent reputation (0-1000)" },
              { name: "PolicyManager.sol", addr: "0xdBc1...4911E4", desc: "Risk enforcement rules" },
            ].map(c => (
              <div key={c.name} className="bg-[#080810] p-5 text-left">
                <div className="text-amber-400 font-bold text-sm mb-1">{c.name}</div>
                <div className="text-cyan-400/60 font-mono text-xs mb-2">{c.addr}</div>
                <div className="text-slate-500 text-xs">{c.desc}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ─── FINAL CTA ────────────────────────────────────────── */}
      <section className="py-24 px-4 text-center relative overflow-hidden">
        <div className="absolute inset-0 pointer-events-none"
          style={{ background: "radial-gradient(ellipse at center, rgba(43,131,255,0.04) 0%, transparent 70%)" }} />
        <p className="text-slate-500 text-xs uppercase tracking-widest mb-4">Apex Hackathon 2025 — AI & Agents Track</p>
        <h2 className="text-3xl md:text-5xl font-bold mb-4">
          <span className="text-amber-400">Watch agents</span>{" "}
          <span className="text-white">think, vote, and act.</span>
        </h2>
        <p className="text-slate-400 max-w-md mx-auto mb-10 text-sm leading-relaxed">
          No signup. No seed phrase needed to observe. Connect a wallet to claim testnet USDC and send your own quest.
        </p>
        <button
          onClick={handleEnter}
          className="group px-12 py-5 text-base font-bold tracking-widest uppercase border-2 border-amber-500 text-amber-400 hover:bg-amber-500 hover:text-black transition-all duration-200 cursor-pointer"
        >
          ▶ Enter the Pixel
        </button>
      </section>

      {/* Footer */}
      <footer className="border-t border-slate-900 py-8 px-4 text-center text-slate-700 text-xs">
        <p>Aslan Pixel — Hedera Testnet — Account 0.0.5769159</p>
        <p className="mt-1">QuestReceipt.sol · AgentRegistry.sol · PolicyManager.sol · MockUSDC · USDCFaucet</p>
        <p className="mt-2 text-purple-800">⚡ Powered by Hedera AgentKit</p>
      </footer>
    </div>
  );
}
