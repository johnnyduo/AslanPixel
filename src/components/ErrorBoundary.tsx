import { Component, type ReactNode } from "react";

interface Props { children: ReactNode; }
interface State { hasError: boolean; error: string | null; }

export class ErrorBoundary extends Component<Props, State> {
  state: State = { hasError: false, error: null };

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error: error.message ?? "Unknown error" };
  }

  componentDidCatch(error: Error) {
    console.error("[ErrorBoundary]", error);
    // Clear potentially corrupt localStorage entries
    try { localStorage.removeItem("aslan_chat_history"); } catch { /* ignore */ }
  }

  render() {
    if (!this.state.hasError) return this.props.children;
    return (
      <div className="h-screen flex items-center justify-center bg-background">
        <div className="glass-panel p-8 max-w-sm text-center space-y-4"
          style={{ border: "1px solid hsl(0 72% 55% / 0.4)" }}>
          <p className="font-pixel text-[10px] text-destructive tracking-wider">◆ SYSTEM ERROR</p>
          <p className="text-xs font-mono text-muted-foreground">{this.state.error}</p>
          <button
            className="font-pixel text-[9px] px-4 py-2 rounded"
            style={{ background: "hsl(43 90% 45%)", color: "hsl(225 30% 6%)" }}
            onClick={() => { this.setState({ hasError: false, error: null }); window.location.reload(); }}
          >
            RELOAD
          </button>
        </div>
      </div>
    );
  }
}
