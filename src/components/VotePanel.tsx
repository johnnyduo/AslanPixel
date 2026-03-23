/**
 * VotePanel — multi-agent consensus vote before executing a quest
 * 6 agents vote sequentially, Drax (sentinel) can veto
 */
import { useEffect, useState } from "react";
import { Shield, CheckCircle, XCircle, Loader2 } from "lucide-react";
import { AGENTS } from "@/data/agents";

interface VoteState {
  agentId: string;
  vote: "pending" | "approve" | "veto";
  reason: string;
}

interface VotePanelProps {
  intent: string;
  onApproved: () => void;
  onVetoed: (reason: string) => void;
}

// Drax vetoes if intent has high-risk keywords AND no explicit "simulate"
function shouldVeto(agentId: string, intent: string): boolean {
  if (agentId !== "sentinel") return false;
  const lower = intent.toLowerCase();
  const risky = ["100%", "all in", "max", "everything", "entire"];
  const safe = ["simulate", "analyze", "scan", "report", "check"];
  const hasSafe = safe.some((w) => lower.includes(w));
  const hasRisky = risky.some((w) => lower.includes(w));
  return hasRisky && !hasSafe;
}

const APPROVE_REASONS: Record<string, string> = {
  scout:      "HCS signal clean — no anomalies in consensus stream. Proceeding.",
  strategist: "3-branch model converged. Confidence 91%. Branch A optimal.",
  sentinel:   "PolicyManager check: slippage ✓, position ✓, audit hash ✓. CLEARED.",
  treasurer:  "Treasury budget sufficient. Gas reserve locked at 500 HBAR.",
  executor:   "EVM simulation: SAFE. Nonce locked. Ready to submit.",
  archivist:  "Receipt template prepared. QuestReceipt.sol standing by.",
};

const VETO_REASONS: Record<string, string> = {
  sentinel: "Policy violation: max allocation exceeded or unchecked slippage. VETOED.",
};

export default function VotePanel({ intent, onApproved, onVetoed }: VotePanelProps) {
  const [votes, setVotes] = useState<VoteState[]>(
    AGENTS.map((a) => ({ agentId: a.id, vote: "pending", reason: "" }))
  );
  const [currentIdx, setCurrentIdx] = useState(-1);
  const [done, setDone] = useState(false);

  useEffect(() => {
    // Start the vote sequence
    let idx = 0;

    const next = () => {
      if (idx >= AGENTS.length) {
        setDone(true);
        return;
      }
      setCurrentIdx(idx);
      const agent = AGENTS[idx];
      const isVeto = shouldVeto(agent.id, intent);
      const vote = isVeto ? "veto" : "approve";
      const reason = isVeto
        ? (VETO_REASONS[agent.id] ?? "Vetoed.")
        : (APPROVE_REASONS[agent.id] ?? "Approved.");

      setTimeout(() => {
        setVotes((prev) =>
          prev.map((v) =>
            v.agentId === agent.id ? { ...v, vote, reason } : v
          )
        );
        idx++;
        if (isVeto) {
          setDone(true);
          setTimeout(() => onVetoed(reason), 1200);
        } else {
          setTimeout(next, 480);
        }
      }, 520);
    };

    const startDelay = setTimeout(next, 300);
    return () => clearTimeout(startDelay);
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  // Auto-proceed if all voted and no veto
  useEffect(() => {
    if (!done) return;
    const allApproved = votes.every((v) => v.vote === "approve");
    if (allApproved) {
      const approved = votes.filter((v) => v.vote === "approve").length;
      if (approved === AGENTS.length) {
        setTimeout(() => onApproved(), 800);
      }
    }
  }, [done, votes, onApproved]);

  const approveCount = votes.filter((v) => v.vote === "approve").length;
  const vetoAgent = votes.find((v) => v.vote === "veto");
  const isVetoed = !!vetoAgent;

  return (
    <div
      className="absolute inset-0 z-20 flex items-end justify-center pb-2 px-2"
      style={{ background: "hsl(225 30% 6% / 0.92)" }}
    >
      <div
        className="w-full max-w-2xl glass-panel p-3 space-y-2 animate-timeline-enter"
        style={{ border: "1px solid hsl(43 90% 55% / 0.4)" }}
      >
        {/* Header */}
        <div className="flex items-center gap-2">
          <Shield className="w-3.5 h-3.5 text-gold" />
          <span className="font-pixel text-[10px] text-gold tracking-wider">GUILD VOTE</span>
          <span className="text-[9px] font-mono text-muted-foreground ml-1 truncate flex-1">
            "{intent.replace(/^\[AUTO\] /, "")}"
          </span>
          <div
            className="shrink-0 px-1.5 py-0.5 rounded text-[8px] font-pixel"
            style={{
              background: isVetoed
                ? "hsl(0 72% 55% / 0.15)"
                : done
                ? "hsl(142 70% 50% / 0.15)"
                : "hsl(43 90% 55% / 0.1)",
              border: `1px solid ${isVetoed ? "hsl(0 72% 55% / 0.4)" : done ? "hsl(142 70% 50% / 0.4)" : "hsl(43 90% 55% / 0.3)"}`,
              color: isVetoed
                ? "hsl(0 72% 65%)"
                : done
                ? "hsl(142 70% 60%)"
                : "hsl(43 90% 65%)",
            }}
          >
            {isVetoed ? "VETOED" : done ? `${approveCount}/6 APPROVED` : `${approveCount}/6 VOTING`}
          </div>
        </div>

        {/* Agent vote rows */}
        <div className="grid grid-cols-2 gap-1 sm:grid-cols-3">
          {votes.map((v, i) => {
            const agent = AGENTS.find((a) => a.id === v.agentId)!;
            const isActive = i === currentIdx && v.vote === "pending";
            return (
              <div
                key={v.agentId}
                className="flex items-center gap-1.5 px-2 py-1.5 rounded-md transition-all duration-300"
                style={{
                  background:
                    v.vote === "approve"
                      ? "hsl(142 70% 50% / 0.07)"
                      : v.vote === "veto"
                      ? "hsl(0 72% 55% / 0.1)"
                      : isActive
                      ? `${agent.color}0a`
                      : "hsl(225 20% 10%)",
                  border: `1px solid ${
                    v.vote === "approve"
                      ? "hsl(142 70% 50% / 0.3)"
                      : v.vote === "veto"
                      ? "hsl(0 72% 55% / 0.4)"
                      : isActive
                      ? `${agent.color}50`
                      : "hsl(225 15% 18%)"
                  }`,
                }}
              >
                <span className="font-pixel text-xs" style={{ color: agent.color }}>
                  {agent.icon}
                </span>
                <span className="text-[9px] font-pixel flex-1" style={{ color: agent.color + "cc" }}>
                  {agent.name}
                </span>
                {v.vote === "pending" && isActive && (
                  <Loader2 className="w-3 h-3 animate-spin text-muted-foreground" />
                )}
                {v.vote === "pending" && !isActive && (
                  <div className="w-3 h-3 rounded-full bg-secondary" />
                )}
                {v.vote === "approve" && (
                  <CheckCircle className="w-3 h-3 text-success shrink-0" />
                )}
                {v.vote === "veto" && (
                  <XCircle className="w-3 h-3 text-destructive shrink-0" />
                )}
              </div>
            );
          })}
        </div>

        {/* Veto reason */}
        {isVetoed && vetoAgent && (
          <p className="text-[9px] font-mono text-destructive text-center border border-destructive/30 rounded px-2 py-1.5">
            ◆ Drax: {vetoAgent.reason}
          </p>
        )}

        {/* Approved message */}
        {done && !isVetoed && (
          <p className="text-[9px] font-pixel text-success text-center animate-pulse">
            ◈ ALL AGENTS CLEARED — EXECUTING QUEST...
          </p>
        )}
      </div>
    </div>
  );
}
