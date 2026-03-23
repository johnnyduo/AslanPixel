/**
 * DashboardPanel — live guild stats: treasury, agent reputation, quest history chart
 */
import { AreaChart, Area, XAxis, YAxis, Tooltip, ResponsiveContainer } from "recharts";
import { BarChart2, TrendingUp, X, Shield, Zap, ExternalLink } from "lucide-react";
import { useQuestReceipts, useAgentStats } from "@/hooks/useContracts";
import { useHbarPrice } from "@/hooks/useHbarPrice";
import { useSaucerSwap } from "@/hooks/useSaucerSwap";
import { AGENTS } from "@/data/agents";

interface DashboardPanelProps {
  onClose: () => void;
}

export default function DashboardPanel({ onClose }: DashboardPanelProps) {
  const { receipts, count, loading: receiptsLoading } = useQuestReceipts();
  const { agents: onchainAgents, loading: agentsLoading } = useAgentStats();
  const { price: hbarPrice } = useHbarPrice();
  const { pools } = useSaucerSwap();

  // Build chart data from receipts (most recent 15, oldest first for chart)
  const chartData = [...receipts]
    .reverse()
    .slice(0, 15)
    .map((r) => ({
      name: r.timestamp > 0
        ? new Date(r.timestamp * 1000).toLocaleTimeString("en-GB", { hour: "2-digit", minute: "2-digit" })
        : `Q${r.questId}`,
      id: r.questId,
      success: r.success ? 1 : 0,
    }));

  const successRate = receipts.length > 0
    ? Math.round((receipts.filter((r) => r.success).length / receipts.length) * 100)
    : 100;

  const topPool = pools[0];
  const totalTvl = pools.reduce((s, p) => s + p.tvlUsd, 0);

  return (
    <div
      className="absolute inset-0 z-30 overflow-y-auto"
      style={{ background: "hsl(225 30% 5% / 0.97)" }}
    >
      <div className="max-w-4xl mx-auto p-4 space-y-4">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <BarChart2 className="w-4 h-4 text-gold" />
            <h2 className="font-pixel text-sm text-gold tracking-wider">GUILD DASHBOARD</h2>
            <div className="flex items-center gap-1 px-1.5 py-0.5 rounded" style={{ background: "hsl(142 70% 50% / 0.1)", border: "1px solid hsl(142 70% 50% / 0.3)" }}>
              <div className="w-1.5 h-1.5 rounded-full bg-success animate-pulse" />
              <span className="text-[7px] font-pixel text-success">LIVE</span>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded hover:bg-secondary/40 transition-colors"
          >
            <X className="w-4 h-4 text-muted-foreground" />
          </button>
        </div>

        {/* Stats Row */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
          <StatCard label="HBAR Price" value={`$${hbarPrice.toFixed(4)}`} color="hsl(43 90% 55%)" icon="⬡" />
          <StatCard label="Total Quests" value={receiptsLoading ? "…" : String(count)} color="hsl(195 100% 55%)" icon="◈" />
          <StatCard label="Success Rate" value={`${successRate}%`} color="hsl(142 70% 50%)" icon="◆" />
          <StatCard label="SaucerSwap TVL" value={`$${(totalTvl / 1000).toFixed(1)}k`} color="hsl(38 92% 55%)" icon="▶" />
        </div>

        {/* Quest History Chart */}
        <div className="glass-panel p-4 space-y-3">
          <div className="flex items-center gap-2">
            <TrendingUp className="w-3.5 h-3.5 text-gold" />
            <span className="font-pixel text-[10px] text-gold">QUEST HISTORY</span>
            <span className="text-[9px] text-muted-foreground font-mono ml-auto">
              {count} total onchain
            </span>
          </div>
          {chartData.length > 0 ? (
            <ResponsiveContainer width="100%" height={120}>
              <AreaChart data={chartData} margin={{ top: 4, right: 4, bottom: 0, left: -20 }}>
                <defs>
                  <linearGradient id="questGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="hsl(43 90% 55%)" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="hsl(43 90% 55%)" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <XAxis dataKey="time" tick={{ fontSize: 8, fill: "hsl(215 12% 45%)", fontFamily: "JetBrains Mono" }} />
                <YAxis hide />
                <Tooltip
                  contentStyle={{
                    background: "hsl(225 25% 10%)",
                    border: "1px solid hsl(43 90% 55% / 0.3)",
                    borderRadius: "6px",
                    fontSize: "10px",
                    fontFamily: "JetBrains Mono",
                    color: "hsl(43 90% 65%)",
                  }}
                  formatter={(val, name) => [val === 1 ? "✓ SUCCESS" : "✗ FAILED", `Quest #${name}`]}
                />
                <Area
                  type="monotone"
                  dataKey="id"
                  stroke="hsl(43 90% 55%)"
                  strokeWidth={1.5}
                  fill="url(#questGrad)"
                  dot={{ r: 2, fill: "hsl(43 90% 55%)", strokeWidth: 0 }}
                />
              </AreaChart>
            </ResponsiveContainer>
          ) : (
            <div className="h-[120px] flex items-center justify-center">
              <span className="text-[10px] text-muted-foreground font-mono">
                {receiptsLoading ? "Loading onchain data…" : "No quests yet — run your first quest"}
              </span>
            </div>
          )}
        </div>

        {/* Agent Reputation */}
        <div className="glass-panel p-4 space-y-3">
          <div className="flex items-center gap-2">
            <Shield className="w-3.5 h-3.5 text-cyan" />
            <span className="font-pixel text-[10px] text-cyan">AGENT REGISTRY</span>
            {!agentsLoading && onchainAgents.some((a) => a.registeredAt > 0) && (
              <span className="text-[7px] font-pixel px-1 py-0.5 rounded ml-auto" style={{ background: "hsl(195 100% 55% / 0.1)", color: "hsl(195 100% 55%)", border: "1px solid hsl(195 100% 55% / 0.3)" }}>ONCHAIN</span>
            )}
          </div>
          <div className="space-y-2">
            {AGENTS.map((agent) => {
              const onchain = onchainAgents.find((a) => a.agentId === agent.id);
              const rep = onchain?.registeredAt ? onchain.reputation : 500; // 0-1000
              const quests = onchain?.registeredAt ? onchain.completedQuests : agent.completedQuests;
              const isActive = onchain?.active ?? true;
              return (
                <div key={agent.id} className="flex items-center gap-3">
                  <span className="font-pixel text-sm shrink-0" style={{ color: agent.color }}>{agent.icon}</span>
                  <span className="text-[10px] font-pixel w-12 shrink-0" style={{ color: agent.color }}>{agent.name}</span>
                  <div className="flex-1 h-1.5 bg-secondary rounded-full overflow-hidden">
                    <div
                      className="h-full rounded-full transition-all duration-700"
                      style={{
                        width: `${rep / 10}%`,
                        background: `linear-gradient(90deg, ${agent.color}80, ${agent.color})`,
                        boxShadow: `0 0 6px ${agent.color}60`,
                      }}
                    />
                  </div>
                  <span className="text-[9px] font-mono w-10 text-right shrink-0" style={{ color: agent.color }}>{rep}</span>
                  <span className="text-[9px] font-mono text-muted-foreground w-12 text-right shrink-0">{quests}q</span>
                  {isActive && (
                    <div className="w-1.5 h-1.5 rounded-full bg-success shrink-0" />
                  )}
                </div>
              );
            })}
          </div>
        </div>

        {/* Live SaucerSwap Pools */}
        <div className="glass-panel p-4 space-y-3">
          <div className="flex items-center gap-2">
            <Zap className="w-3.5 h-3.5 text-gold" />
            <span className="font-pixel text-[10px] text-gold">SAUCERSWAP POOLS</span>
            <a
              href="https://testnet.saucerswap.finance"
              target="_blank"
              rel="noopener noreferrer"
              className="ml-auto flex items-center gap-1 text-[8px] font-mono text-cyan hover:text-gold transition-colors"
            >
              testnet <ExternalLink className="w-2.5 h-2.5" />
            </a>
          </div>
          <div className="space-y-1.5">
            {pools.map((pool) => (
              <div
                key={pool.id}
                className="flex items-center gap-3 px-2.5 py-1.5 rounded-md"
                style={{ background: "hsl(225 20% 10%)", border: "1px solid hsl(225 15% 18%)" }}
              >
                <span className="text-[10px] font-mono font-semibold text-foreground w-24 shrink-0">
                  {pool.tokenA.symbol}/{pool.tokenB.symbol}
                </span>
                <div className="flex-1 text-[9px] font-mono text-muted-foreground">
                  TVL ${pool.tvlUsd > 0 ? (pool.tvlUsd / 1000).toFixed(1) + "k" : "—"}
                </div>
                <div className="text-[9px] font-mono text-muted-foreground">
                  24h ${pool.volume24h > 0 ? (pool.volume24h / 1000).toFixed(1) + "k" : "—"}
                </div>
                <div className="text-[9px] font-mono" style={{ color: "hsl(43 90% 55%)" }}>
                  {pool.fee}%
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Recent Receipts */}
        {receipts.length > 0 && (
          <div className="glass-panel p-4 space-y-3">
            <div className="flex items-center gap-2">
              <span className="font-pixel text-[10px]" style={{ color: "hsl(0 72% 62%)" }}>▣ RECENT RECEIPTS</span>
            </div>
            <div className="space-y-1.5">
              {receipts.slice(0, 5).map((r) => (
                <div
                  key={r.questId}
                  className="flex items-center gap-2 px-2.5 py-1.5 rounded-md text-[9px] font-mono"
                  style={{ background: "hsl(225 20% 10%)", border: "1px solid hsl(225 15% 18%)" }}
                >
                  <span className="text-muted-foreground w-6 shrink-0">#{r.questId}</span>
                  <div
                    className="w-1.5 h-1.5 rounded-full shrink-0"
                    style={{ background: r.success ? "hsl(142 70% 50%)" : "hsl(0 72% 55%)" }}
                  />
                  <span className="flex-1 text-foreground truncate">{r.intent || "—"}</span>
                  {r.txHash && r.txHash !== "0x" + "00".repeat(32) && (
                    <a
                      href={`https://hashscan.io/testnet/tx/${r.txHash}`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-cyan hover:text-gold transition-colors flex items-center gap-0.5 shrink-0"
                    >
                      TX <ExternalLink className="w-2.5 h-2.5" />
                    </a>
                  )}
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

function StatCard({ label, value, color, icon }: { label: string; value: string; color: string; icon: string }) {
  return (
    <div
      className="glass-panel p-3 space-y-1 text-center"
      style={{ border: `1px solid ${color}25` }}
    >
      <div className="font-pixel text-base" style={{ color }}>{icon}</div>
      <div className="font-mono text-sm font-semibold" style={{ color }}>{value}</div>
      <div className="text-[8px] text-muted-foreground uppercase tracking-wider font-mono">{label}</div>
    </div>
  );
}
