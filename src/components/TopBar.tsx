import { Wifi, Bell, Wallet } from "lucide-react";
import { Button } from "@/components/ui/button";

const TopBar = () => {
  return (
    <header className="h-14 glass-panel-strong flex items-center justify-between px-5 rounded-none border-x-0 border-t-0">
      <div className="flex items-center gap-3">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 gradient-gold rounded-lg flex items-center justify-center">
            <span className="font-pixel text-xs text-primary-foreground">AP</span>
          </div>
          <div>
            <h1 className="font-pixel text-sm text-gold leading-none">ASLAN PIXEL</h1>
            <p className="text-[10px] text-muted-foreground font-mono">PROJECT v1.0</p>
          </div>
        </div>
      </div>

      <div className="flex items-center gap-2">
        <div className="flex items-center gap-1.5 px-3 py-1.5 glass-panel text-xs font-mono">
          <div className="w-2 h-2 rounded-full bg-success animate-pulse-glow" />
          <span className="text-success">Mainnet</span>
        </div>

        <div className="flex items-center gap-1.5 px-3 py-1.5 glass-panel text-xs font-mono">
          <span className="text-gold">ℏ</span>
          <span className="text-foreground">12,847.50</span>
          <span className="text-muted-foreground">HBAR</span>
        </div>

        <Button variant="ghost" size="icon" className="relative">
          <Bell className="w-4 h-4 text-muted-foreground" />
          <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-gold rounded-full" />
        </Button>

        <Button variant="gold" size="sm" className="gap-2">
          <Wallet className="w-3.5 h-3.5" />
          <span className="hidden sm:inline">0x4a...8f2c</span>
          <span className="sm:hidden">Wallet</span>
        </Button>
      </div>
    </header>
  );
};

export default TopBar;
