import { useState } from "react";

interface Building {
  name: string;
  label: string;
  x: number;
  y: number;
  w: number;
  h: number;
  color: string;
  glowColor: string;
  icon: string;
}

const buildings: Building[] = [
  { name: "guild", label: "Guild Hall", x: 15, y: 12, w: 18, h: 14, color: "hsl(43 90% 55%)", glowColor: "hsl(43 90% 55% / 0.15)", icon: "⚔" },
  { name: "vault", label: "Vault House", x: 65, y: 10, w: 16, h: 12, color: "hsl(195 100% 50%)", glowColor: "hsl(195 100% 50% / 0.15)", icon: "🏛" },
  { name: "strategy", label: "Strategy Tower", x: 40, y: 5, w: 14, h: 18, color: "hsl(280 60% 55%)", glowColor: "hsl(280 60% 55% / 0.1)", icon: "🗼" },
  { name: "market", label: "Market Gate", x: 10, y: 55, w: 20, h: 12, color: "hsl(142 70% 45%)", glowColor: "hsl(142 70% 45% / 0.12)", icon: "🏪" },
  { name: "archive", label: "Archive Library", x: 60, y: 55, w: 18, h: 14, color: "hsl(38 85% 45%)", glowColor: "hsl(38 85% 45% / 0.12)", icon: "📚" },
  { name: "quest", label: "Quest Board", x: 38, y: 60, w: 16, h: 10, color: "hsl(0 72% 51%)", glowColor: "hsl(0 72% 51% / 0.1)", icon: "📜" },
];

interface NPC {
  id: string;
  name: string;
  color: string;
  animClass: string;
}

const npcs: NPC[] = [
  { id: "kael", name: "Kael", color: "hsl(195 100% 50%)", animClass: "npc-1" },
  { id: "sentinel", name: "Sentinel", color: "hsl(43 90% 55%)", animClass: "npc-2" },
  { id: "oracle", name: "Oracle", color: "hsl(280 60% 55%)", animClass: "npc-3" },
  { id: "merchant", name: "Merchant", color: "hsl(142 70% 45%)", animClass: "npc-4" },
];

const PixelMap = () => {
  const [hoveredBuilding, setHoveredBuilding] = useState<string | null>(null);

  return (
    <div className="flex-1 glass-panel relative overflow-hidden pixel-grid">
      {/* Ground layer */}
      <div className="absolute inset-0" style={{ background: 'radial-gradient(ellipse at center, hsl(225 25% 10%) 0%, hsl(225 30% 6%) 100%)' }} />

      {/* Paths between buildings */}
      <svg className="absolute inset-0 w-full h-full" style={{ opacity: 0.15 }}>
        <line x1="24%" y1="26%" x2="47%" y2="14%" stroke="hsl(43 60% 35%)" strokeWidth="2" strokeDasharray="4 4" />
        <line x1="54%" y1="14%" x2="73%" y2="16%" stroke="hsl(43 60% 35%)" strokeWidth="2" strokeDasharray="4 4" />
        <line x1="24%" y1="26%" x2="20%" y2="55%" stroke="hsl(43 60% 35%)" strokeWidth="2" strokeDasharray="4 4" />
        <line x1="73%" y1="22%" x2="69%" y2="55%" stroke="hsl(43 60% 35%)" strokeWidth="2" strokeDasharray="4 4" />
        <line x1="30%" y1="61%" x2="38%" y2="65%" stroke="hsl(43 60% 35%)" strokeWidth="2" strokeDasharray="4 4" />
        <line x1="54%" y1="65%" x2="60%" y2="62%" stroke="hsl(43 60% 35%)" strokeWidth="2" strokeDasharray="4 4" />
        <line x1="47%" y1="23%" x2="46%" y2="60%" stroke="hsl(43 60% 35%)" strokeWidth="2" strokeDasharray="4 4" />
      </svg>

      {/* Buildings */}
      {buildings.map((b) => (
        <div
          key={b.name}
          className="absolute cursor-pointer transition-all duration-300 group"
          style={{
            left: `${b.x}%`,
            top: `${b.y}%`,
            width: `${b.w}%`,
            height: `${b.h}%`,
          }}
          onMouseEnter={() => setHoveredBuilding(b.name)}
          onMouseLeave={() => setHoveredBuilding(null)}
        >
          {/* Glow effect */}
          <div
            className="absolute inset-0 rounded-lg transition-opacity duration-300"
            style={{
              background: b.glowColor,
              opacity: hoveredBuilding === b.name ? 1 : 0.4,
              filter: 'blur(12px)',
              transform: 'scale(1.3)',
            }}
          />
          {/* Building body */}
          <div
            className="absolute inset-0 rounded-lg border transition-all duration-300"
            style={{
              borderColor: hoveredBuilding === b.name ? b.color : `${b.color}40`,
              background: `linear-gradient(135deg, ${b.glowColor}, hsl(225 25% 10% / 0.8))`,
              backdropFilter: 'blur(8px)',
              boxShadow: hoveredBuilding === b.name ? `0 0 24px ${b.glowColor}` : 'none',
            }}
          >
            <div className="flex flex-col items-center justify-center h-full gap-1">
              <span className="text-lg sm:text-2xl" style={{ imageRendering: 'pixelated' }}>{b.icon}</span>
              <span
                className="font-pixel text-[8px] sm:text-[10px] text-center px-1 leading-tight transition-colors duration-300"
                style={{ color: hoveredBuilding === b.name ? b.color : 'hsl(210 20% 70%)' }}
              >
                {b.label}
              </span>
            </div>
          </div>
        </div>
      ))}

      {/* Animated NPCs */}
      {npcs.map((npc) => (
        <div
          key={npc.id}
          className={`absolute animate-npc-walk`}
          style={{
            animation: `npc-move-${npcs.indexOf(npc) + 1} 20s ease-in-out infinite, npc-walk 0.4s steps(2) infinite`,
          }}
        >
          <div className="relative group cursor-pointer">
            <div
              className="w-4 h-4 sm:w-5 sm:h-5 rounded-sm"
              style={{
                background: npc.color,
                boxShadow: `0 0 8px ${npc.color}80`,
                imageRendering: 'pixelated',
              }}
            />
            <div
              className="absolute -top-5 left-1/2 -translate-x-1/2 px-1.5 py-0.5 rounded text-[8px] font-pixel opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap"
              style={{ background: 'hsl(225 25% 10% / 0.9)', color: npc.color, border: `1px solid ${npc.color}40` }}
            >
              {npc.name}
            </div>
          </div>
        </div>
      ))}

      {/* Minimap hint */}
      <div className="absolute top-3 right-3 w-20 h-16 glass-panel p-1.5 opacity-60 hover:opacity-100 transition-opacity">
        <div className="w-full h-full relative rounded-sm overflow-hidden" style={{ background: 'hsl(225 30% 8%)' }}>
          {buildings.map((b) => (
            <div
              key={b.name}
              className="absolute rounded-[1px]"
              style={{
                left: `${b.x}%`,
                top: `${b.y}%`,
                width: `${b.w}%`,
                height: `${b.h}%`,
                background: `${b.color}60`,
              }}
            />
          ))}
        </div>
        <p className="text-[7px] text-muted-foreground font-pixel text-center mt-0.5">MINIMAP</p>
      </div>
    </div>
  );
};

export default PixelMap;
