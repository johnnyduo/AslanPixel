import TopBar from "@/components/TopBar";
import LeftPanel from "@/components/LeftPanel";
import RightPanel from "@/components/RightPanel";
import BottomPanel from "@/components/BottomPanel";
import PixelMap from "@/components/PixelMap";

const Index = () => {
  return (
    <div className="h-screen flex flex-col overflow-hidden bg-background">
      <TopBar />
      <div className="flex-1 flex overflow-hidden">
        {/* Left Panel - hidden on small screens */}
        <div className="hidden lg:flex">
          <LeftPanel />
        </div>

        {/* Center + Bottom */}
        <div className="flex-1 flex flex-col overflow-hidden p-1 gap-1">
          <PixelMap />
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
