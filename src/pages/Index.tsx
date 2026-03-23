import { useState } from "react";
import TopBar from "@/components/TopBar";
import LeftPanel from "@/components/LeftPanel";
import RightPanel from "@/components/RightPanel";
import BottomPanel from "@/components/BottomPanel";
import PixelMap from "@/components/PixelMap";
import DashboardPanel from "@/components/DashboardPanel";
import { useAgentInit } from "@/hooks/useAgentInit";

const Index = () => {
  const [dashOpen, setDashOpen] = useState(false);

  // Register agents onchain on first load
  useAgentInit();

  return (
    <div className="h-screen flex flex-col overflow-hidden bg-background">
      <TopBar onDashboardToggle={() => setDashOpen((v) => !v)} />
      <div className="flex-1 flex overflow-hidden relative">
        {/* Dashboard overlay */}
        {dashOpen && (
          <DashboardPanel onClose={() => setDashOpen(false)} />
        )}

        {/* Left Panel - hidden on small screens */}
        <div className="hidden lg:flex">
          <LeftPanel />
        </div>

        {/* Center + Bottom */}
        <div className="flex-1 flex flex-col overflow-hidden p-1 gap-1">
          <PixelMap hideAgents={dashOpen} />
          <BottomPanel />
        </div>

        {/* Right Panel - hidden on small screens */}
        <div className="hidden lg:flex">
          <RightPanel />
        </div>
      </div>
    </div>
  );
};

export default Index;
