/**
 * AslanGuild — Hackathon Slide Deck Generator
 * Google Apps Script → creates a fully themed Google Slides presentation
 * Run: paste into script.google.com → Run → createAslanDeck()
 *
 * Design: dark pixel-art, neon-on-black, matches the web app exactly
 * 10 slides calibrated against hackathon judging criteria
 */

// ─── BRAND PALETTE ────────────────────────────────────────────────────────────
const C = {
  // Backgrounds
  bg:       { r:0.047, g:0.055, b:0.098 },   // hsl(225 35% 7%) — near-black navy
  panel:    { r:0.071, g:0.082, b:0.137 },   // glass panel
  panelBrd: { r:0.118, g:0.141, b:0.220 },   // panel border

  // Neon accents (agent colors)
  cyan:     { r:0.000, g:0.800, b:1.000 },   // Nexus   ◈
  gold:     { r:1.000, g:0.780, b:0.200 },   // Oryn    ▲
  green:    { r:0.200, g:0.820, b:0.400 },   // Drax    ◆
  purple:   { r:0.700, g:0.400, b:0.900 },   // Lyss    ◉
  orange:   { r:1.000, g:0.620, b:0.100 },   // Vex     ▶
  red:      { r:0.920, g:0.280, b:0.280 },   // Kael    ▣

  // Text
  white:    { r:1.000, g:1.000, b:1.000 },
  dim:      { r:0.580, g:0.620, b:0.720 },
  muted:    { r:0.340, g:0.380, b:0.500 },

  // Hedera
  hedera:   { r:0.000, g:0.749, b:0.796 },   // official Hedera teal
};

// ─── SLIDE DIMENSIONS ─────────────────────────────────────────────────────────
const W = 720;   // pts (widescreen 16:9)
const H = 405;

// ─── HELPERS ──────────────────────────────────────────────────────────────────
function rgb(c) { return c; }

function addBg(slide) {
  const bg = slide.insertShape(SlidesApp.ShapeType.RECTANGLE, 0, 0, W, H);
  bg.getFill().setSolidFill(C.bg.r * 255, C.bg.g * 255, C.bg.b * 255);
  bg.getBorder().setTransparent();
  bg.setTitle("bg");
}

function col255(c) {
  return { r: Math.round(c.r * 255), g: Math.round(c.g * 255), b: Math.round(c.b * 255) };
}

function addRect(slide, x, y, w, h, fillC, alpha) {
  const s = slide.insertShape(SlidesApp.ShapeType.RECTANGLE, x, y, w, h);
  const f = col255(fillC);
  s.getFill().setSolidFill(f.r, f.g, f.b);
  if (alpha !== undefined) s.setOpacity(alpha);
  s.getBorder().setTransparent();
  return s;
}

function addText(slide, text, x, y, w, h, opts) {
  const box = slide.insertTextBox(text, x, y, w, h);
  const tf  = box.getText();
  const sty = tf.getTextStyle();
  sty.setFontFamily(opts.font || "Space Mono");
  sty.setFontSize(opts.size || 14);
  const fc = col255(opts.color || C.white);
  sty.setForegroundColor(fc.r, fc.g, fc.b);
  if (opts.bold)   sty.setBold(true);
  if (opts.italic) sty.setItalic(true);
  const ps = tf.getParagraphStyle();
  ps.setParagraphAlignment(opts.align === "center" ? SlidesApp.ParagraphAlignment.CENTER :
                           opts.align === "right"  ? SlidesApp.ParagraphAlignment.END :
                                                     SlidesApp.ParagraphAlignment.START);
  box.getBorder().setTransparent();
  box.getFill().setTransparent();
  return box;
}

function addLine(slide, x1, y1, x2, y2, colorC, weight) {
  const line = slide.insertLine(SlidesApp.LineCategory.STRAIGHT,
    SlidesApp.LineType.STRAIGHT_CONNECTOR_1, x1, y1, x2, y2);
  const fc = col255(colorC);
  line.getLineFill().setSolidFill(fc.r, fc.g, fc.b);
  line.setWeight(weight || 1);
  return line;
}

/** Glowing accent bar on left edge */
function addAccentBar(slide, colorC) {
  const fc = col255(colorC);
  const bar = slide.insertShape(SlidesApp.ShapeType.RECTANGLE, 0, 0, 4, H);
  bar.getFill().setSolidFill(fc.r, fc.g, fc.b);
  bar.getBorder().setTransparent();
}

/** Top header strip with title + label */
function addHeader(slide, label, titleText, accentC) {
  // thin top bar
  addRect(slide, 0, 0, W, 44, C.panel, 1);
  addLine(slide, 0, 44, W, 44, accentC, 0.5);

  // slide label pill
  const lc = col255(accentC);
  const pill = slide.insertShape(SlidesApp.ShapeType.ROUND_RECTANGLE, 20, 11, 80, 22);
  pill.getFill().setSolidFill(lc.r, lc.g, lc.b);
  pill.setOpacity(0.15);
  pill.getBorder().setTransparent();

  addText(slide, label, 20, 11, 80, 22, { size: 7, color: accentC, bold: true, align: "center", font: "Space Mono" });
  addText(slide, titleText, 112, 10, W - 140, 24, { size: 13, color: C.white, bold: true, font: "Space Mono" });
}

/** Pixel-art NPC sprite (text-art block representing an agent) */
function addAgentCard(slide, x, y, w, agent) {
  const h = 110;
  const ac = col255(agent.color);

  // card bg
  const card = slide.insertShape(SlidesApp.ShapeType.ROUND_RECTANGLE, x, y, w, h);
  card.getFill().setSolidFill(ac.r, ac.g, ac.b);
  card.setOpacity(0.08);
  const brd = card.getBorder();
  brd.getLineFill().setSolidFill(ac.r, ac.g, ac.b);
  brd.setWeight(1);

  // accent top strip
  const strip = slide.insertShape(SlidesApp.ShapeType.RECTANGLE, x, y, w, 3);
  strip.getFill().setSolidFill(ac.r, ac.g, ac.b);
  strip.getBorder().setTransparent();

  // icon + name
  addText(slide, agent.icon, x + 8, y + 8, 30, 28, { size: 18, color: agent.color, bold: true, align: "center" });
  addText(slide, agent.name, x + 8, y + 34, w - 16, 14, { size: 9, color: agent.color, bold: true, font: "Space Mono" });
  addText(slide, agent.role, x + 8, y + 47, w - 16, 14, { size: 7, color: C.dim, font: "Space Mono" });
  addLine(slide, x + 8, y + 63, x + w - 8, y + 63, agent.color, 0.4);
  addText(slide, agent.desc, x + 8, y + 67, w - 16, 38, { size: 7, color: C.dim, font: "Space Mono" });
}

/** Horizontal divider line with center diamond */
function addDivider(slide, y, colorC) {
  addLine(slide, 30, y, W / 2 - 8, y, colorC, 0.3);
  addText(slide, "◆", W / 2 - 6, y - 7, 12, 14, { size: 7, color: colorC, align: "center" });
  addLine(slide, W / 2 + 8, y, W - 30, y, colorC, 0.3);
}

/** Footer strip */
function addFooter(slide, accentC) {
  addRect(slide, 0, H - 28, W, 28, C.panel, 1);
  addLine(slide, 0, H - 28, W, H - 28, accentC, 0.3);
  addText(slide, "ASLAN GUILD  //  Agentic Guild on Hedera  //  aslanpixel.vercel.app",
          20, H - 22, W - 160, 16, { size: 7, color: C.muted, font: "Space Mono" });
  addText(slide, "AI & AGENTS TRACK",
          W - 150, H - 22, 130, 16, { size: 7, color: accentC, bold: true, align: "right", font: "Space Mono" });
}

/** Stat box */
function addStatBox(slide, x, y, w, h, label, value, subtext, colorC) {
  const ac = col255(colorC);
  const box = slide.insertShape(SlidesApp.ShapeType.ROUND_RECTANGLE, x, y, w, h);
  box.getFill().setSolidFill(ac.r, ac.g, ac.b);
  box.setOpacity(0.09);
  box.getBorder().setTransparent();

  const bar = slide.insertShape(SlidesApp.ShapeType.RECTANGLE, x, y, 2, h);
  bar.getFill().setSolidFill(ac.r, ac.g, ac.b);
  bar.getBorder().setTransparent();

  addText(slide, label,   x + 10, y + 6,  w - 14, 14, { size: 7, color: C.muted, font: "Space Mono" });
  addText(slide, value,   x + 10, y + 20, w - 14, 22, { size: 14, color: colorC, bold: true, font: "Space Mono" });
  if (subtext)
    addText(slide, subtext, x + 10, y + 42, w - 14, 14, { size: 7, color: C.dim, font: "Space Mono" });
}

/** Flow arrow box */
function addFlowBox(slide, x, y, w, h, text, colorC) {
  const ac = col255(colorC);
  const box = slide.insertShape(SlidesApp.ShapeType.ROUND_RECTANGLE, x, y, w, h);
  box.getFill().setSolidFill(ac.r, ac.g, ac.b);
  box.setOpacity(0.12);
  const brd = box.getBorder();
  brd.getLineFill().setSolidFill(ac.r, ac.g, ac.b);
  brd.setWeight(1);
  addText(slide, text, x + 6, y + (h / 2) - 10, w - 12, 20, { size: 8, color: colorC, bold: true, align: "center", font: "Space Mono" });
}

// ─── THE 10 SLIDES ─────────────────────────────────────────────────────────────

// SLIDE 1 — COVER
function slide01_Cover(pres) {
  const s = pres.appendSlide(SlidesApp.PredefinedLayout.BLANK);
  addBg(s);

  // Scanline texture (thin horizontal lines)
  for (let i = 0; i < H; i += 8) {
    const line = s.insertShape(SlidesApp.ShapeType.RECTANGLE, 0, i, W, 1);
    line.getFill().setSolidFill(255, 255, 255);
    line.setOpacity(0.012);
    line.getBorder().setTransparent();
  }

  // Vertical accent bars
  addAccentBar(s, C.cyan);
  const br = s.insertShape(SlidesApp.ShapeType.RECTANGLE, W - 4, 0, 4, H);
  br.getFill().setSolidFill(Math.round(C.cyan.r*255), Math.round(C.cyan.g*255), Math.round(C.cyan.b*255));
  br.getBorder().setTransparent();

  // Center glow circle
  const glow = s.insertShape(SlidesApp.ShapeType.ELLIPSE, W/2 - 120, H/2 - 100, 240, 200);
  glow.getFill().setSolidFill(0, 180, 255);
  glow.setOpacity(0.04);
  glow.getBorder().setTransparent();

  // Agent icons scattered (pixel art NPC feel)
  const icons = [
    { icon:"◈", x:60,  y:60,  c:C.cyan,   size:28 },
    { icon:"▲", x:620, y:50,  c:C.gold,   size:24 },
    { icon:"◆", x:55,  y:290, c:C.green,  size:22 },
    { icon:"◉", x:630, y:300, c:C.purple, size:24 },
    { icon:"▶", x:340, y:330, c:C.orange, size:20 },
    { icon:"▣", x:80,  y:170, c:C.red,    size:20 },
  ];
  icons.forEach(ic => {
    addText(s, ic.icon, ic.x, ic.y, 40, 40, { size: ic.size, color: ic.c, bold: true, align: "center" });
  });

  // Title
  addText(s, "ASLAN GUILD", W/2 - 200, 100, 400, 60,
    { size: 42, color: C.cyan, bold: true, align: "center", font: "Space Mono" });

  addText(s, "Agentic Guild on Hedera", W/2 - 200, 158, 400, 28,
    { size: 16, color: C.white, align: "center", font: "Space Mono" });

  addText(s, "6 autonomous AI agents that THINK · TRANSACT · COLLABORATE", W/2 - 240, 192, 480, 20,
    { size: 9, color: C.dim, align: "center", font: "Space Mono" });

  // Tagline box
  const tbox = s.insertShape(SlidesApp.ShapeType.ROUND_RECTANGLE, W/2 - 175, 225, 350, 36);
  tbox.getFill().setSolidFill(0, 204, 255);
  tbox.setOpacity(0.10);
  const tbrd = tbox.getBorder();
  tbrd.getLineFill().setSolidFill(0, 204, 255);
  tbrd.setWeight(1);
  addText(s, "AI & Agents Track  ·  Hedera Hackathon  ·  2026",
          W/2 - 170, 233, 340, 20, { size: 9, color: C.cyan, bold: true, align: "center", font: "Space Mono" });

  // Live URL
  addText(s, "⬡  aslanpixel.vercel.app", W/2 - 120, 280, 240, 18,
    { size: 9, color: C.hedera, align: "center", font: "Space Mono" });

  // Bottom footer
  addFooter(s, C.cyan);
}

// SLIDE 2 — THE PROBLEM
function slide02_Problem(pres) {
  const s = pres.appendSlide(SlidesApp.PredefinedLayout.BLANK);
  addBg(s);
  addAccentBar(s, C.red);
  addHeader(s, "01  PROBLEM", "DeFi is a Black Box", C.red);

  // Big quote
  addText(s, '"You send funds.\nYou wait.\nYou hope."',
          50, 65, W - 100, 70,
          { size: 20, color: C.white, bold: true, align: "center", font: "Space Mono", italic: true });

  addDivider(s, 145, C.red);

  // Three pain points
  const pains = [
    { icon: "⚠", title: "Opaque Operations", desc: "No visibility into what's happening with your assets. Strategies execute in the dark — no audit trail, no stream." , c: C.red },
    { icon: "⚡", title: "Complex Coordination", desc: "Multi-step DeFi needs scouts, strategists, risk checks, treasury guards, executors — impossible for one agent.", c: C.orange },
    { icon: "◎", title: "No Accountability", desc: "When a TX fails or slippage spikes — who's responsible? Centralized bots leave no onchain proof.", c: C.gold },
  ];

  pains.forEach((p, i) => {
    const x = 36 + i * 216;
    addStatBox(s, x, 158, 200, 110, p.icon + "  " + p.title, "", p.desc, p.c);
    addText(s, p.icon + " " + p.title, x + 12, 166, 180, 18, { size: 9, color: p.c, bold: true, font: "Space Mono" });
    addText(s, p.desc, x + 12, 186, 178, 60, { size: 8, color: C.dim, font: "Space Mono" });
  });

  addFooter(s, C.red);
}

// SLIDE 3 — THE SOLUTION
function slide03_Solution(pres) {
  const s = pres.appendSlide(SlidesApp.PredefinedLayout.BLANK);
  addBg(s);
  addAccentBar(s, C.cyan);
  addHeader(s, "02  SOLUTION", "AslanGuild — Transparent Autonomous DeFi", C.cyan);

  addText(s, "A guild of 6 specialized AI agents that coordinate, vote, execute, and archive every DeFi operation — live and onchain.",
          36, 56, W - 72, 32, { size: 10, color: C.dim, font: "Space Mono" });

  // Three pillars
  const pillars = [
    { icon: "◈", word: "THINK", sub: "Gemini AI in-character reasoning per agent. Each agent has a role, philosophy, and memory.", c: C.cyan },
    { icon: "▶", word: "TRANSACT", sub: "Every quest generates a real Hedera EVM TX. Simulate → Sign → Submit → HashScan verified.", c: C.green },
    { icon: "▣", word: "COLLABORATE", sub: "6-agent vote consensus. Drax can VETO. Sequential handoff streamed live to the user.", c: C.gold },
  ];

  pillars.forEach((p, i) => {
    const x = 36 + i * 216;
    const y = 100;
    const bx = s.insertShape(SlidesApp.ShapeType.ROUND_RECTANGLE, x, y, 200, 130);
    const ac = col255(p.c);
    bx.getFill().setSolidFill(ac.r, ac.g, ac.b);
    bx.setOpacity(0.10);
    const brd = bx.getBorder();
    brd.getLineFill().setSolidFill(ac.r, ac.g, ac.b);
    brd.setWeight(1.5);

    addText(s, p.icon, x + 10, y + 10, 36, 36, { size: 22, color: p.c, bold: true });
    addText(s, p.word, x + 10, y + 48, 180, 20, { size: 13, color: p.c, bold: true, font: "Space Mono" });
    addLine(s, x + 10, y + 70, x + 190, y + 70, p.c, 0.3);
    addText(s, p.sub, x + 10, y + 76, 182, 50, { size: 8, color: C.dim, font: "Space Mono" });
  });

  // Hedera checkmarks
  addDivider(s, 248, C.cyan);
  const checks = [
    "✓  HCS — every agent action posted as consensus message",
    "✓  EVM — smart contracts on Hedera Testnet (chain 296)",
    "✓  Mirror Node — live price, balance, receipt lookups",
    "✓  QuestReceipt.sol — immutable audit trail, publicly readable",
  ];
  checks.forEach((c, i) => {
    addText(s, c, 36 + (i < 2 ? 0 : 340), 258 + (i % 2) * 20, 320, 18, { size: 8, color: i < 2 ? C.cyan : C.green, font: "Space Mono" });
  });

  addFooter(s, C.cyan);
}

// SLIDE 4 — THE 6 AGENTS
function slide04_Agents(pres) {
  const s = pres.appendSlide(SlidesApp.PredefinedLayout.BLANK);
  addBg(s);
  addAccentBar(s, C.gold);
  addHeader(s, "03  THE GUILD", "6 Autonomous Agents — Each Owns a Domain", C.gold);

  const agents = [
    { icon:"◈", name:"NEXUS",  role:"HCS Intelligence",  desc:"Subscribes HCS topics\n847 msgs/min ingested\nAnomaly detection", color:C.cyan },
    { icon:"▲", name:"ORYN",   role:"Strategy Engine",   desc:"3-branch EVM models\nConfidence-weighted\nFallback planning",  color:C.gold },
    { icon:"◆", name:"DRAX",   role:"Risk Sentinel",     desc:"PolicyManager.sol\nSlippage cap 0.25%\nVETO authority",        color:C.green },
    { icon:"◉", name:"LYSS",   role:"Treasury Keeper",   desc:"HTS balance tracking\ntinyhbar precision\nGas buffer reserve", color:C.purple },
    { icon:"▶", name:"VEX",    role:"TX Executor",       desc:"Simulate → Sign\nSubmit → Monitor\nNonce management",          color:C.orange },
    { icon:"▣", name:"KAEL",   role:"Ledger Archivist",  desc:"QuestReceipt.sol\nMirror Node archive\nImmutable records",    color:C.red },
  ];

  agents.forEach((ag, i) => {
    const col = i % 3;
    const row = Math.floor(i / 3);
    const x   = 22 + col * 228;
    const y   = 56 + row * 120;
    addAgentCard(s, x, y, 215, ag);
  });

  addFooter(s, C.gold);
}

// SLIDE 5 — HOW IT WORKS (PIPELINE)
function slide05_Pipeline(pres) {
  const s = pres.appendSlide(SlidesApp.PredefinedLayout.BLANK);
  addBg(s);
  addAccentBar(s, C.green);
  addHeader(s, "04  HOW IT WORKS", "Quest Pipeline — Intent to Immutable Receipt", C.green);

  // User intent
  addText(s, "User types:", 30, 56, 90, 16, { size: 7, color: C.muted, font: "Space Mono" });
  const intentBox = s.insertShape(SlidesApp.ShapeType.ROUND_RECTANGLE, 30, 70, 280, 28);
  intentBox.getFill().setSolidFill(0, 204, 100);
  intentBox.setOpacity(0.10);
  const ib = intentBox.getBorder();
  ib.getLineFill().setSolidFill(0, 204, 100);
  ib.setWeight(1);
  addText(s, '"Rebalance treasury with 30% USDC buffer"',
          36, 76, 270, 16, { size: 8, color: C.green, font: "Space Mono", italic: true });

  // Arrow down
  addText(s, "↓", 155, 100, 30, 20, { size: 14, color: C.green, align: "center", bold: true });

  // Pipeline steps (vertical left side)
  const steps = [
    { label:"① VOTE", desc:"All 6 agents vote. Drax can VETO.", c:C.red },
    { label:"② PAYMENT GATE", desc:"x402 — 1 HBAR per quest", c:C.gold },
    { label:"③ NEXUS SCANS", desc:"HCS + SaucerSwap market data", c:C.cyan },
    { label:"④ ORYN MODELS", desc:"3-branch EVM strategy 91% conf", c:C.gold },
    { label:"⑤ DRAX VALIDATES", desc:"PolicyManager.sol compliance", c:C.green },
    { label:"⑥ VEX EXECUTES", desc:"Simulate → Submit → Confirmed", c:C.orange },
    { label:"⑦ KAEL ARCHIVES", desc:"QuestReceipt.sol + HCS topic", c:C.red },
  ];

  steps.forEach((st, i) => {
    const y = 120 + i * 36;
    addFlowBox(s, 30, y, 180, 28, st.label, st.c);
    addText(s, st.desc, 218, y + 7, 210, 16, { size: 8, color: C.dim, font: "Space Mono" });
    if (i < steps.length - 1)
      addText(s, "↓", 104, y + 28, 32, 14, { size: 10, color: st.c, align: "center" });
  });

  // Right panel: result
  const rx = 440;
  addRect(s, rx, 56, 256, 310, C.panel, 1);
  addLine(s, rx, 56, rx, 366, C.green, 0.5);

  addText(s, "⬢ RESULT", rx + 14, 62, 220, 16, { size: 9, color: C.green, bold: true, font: "Space Mono" });
  addLine(s, rx + 14, 80, rx + 240, 80, C.green, 0.3);

  const results = [
    { label:"TX hash on HashScan", c:C.cyan },
    { label:"QuestReceipt #N stored onchain", c:C.green },
    { label:"HCS message published", c:C.gold },
    { label:"Agent reputations updated", c:C.purple },
    { label:"Timeline streamed live (SSE)", c:C.orange },
    { label:"Mirror Node confirms IMMUTABLE", c:C.red },
  ];
  results.forEach((r, i) => {
    addText(s, "✓  " + r.label, rx + 14, 88 + i * 30, 230, 22,
            { size: 8, color: r.c, font: "Space Mono" });
  });

  addFooter(s, C.green);
}

// SLIDE 6 — HEDERA INTEGRATION
function slide06_Hedera(pres) {
  const s = pres.appendSlide(SlidesApp.PredefinedLayout.BLANK);
  addBg(s);
  addAccentBar(s, C.hedera);
  addHeader(s, "05  HEDERA", "Native Hedera Integration — Every Layer", C.hedera);

  const layers = [
    { label:"HCS", full:"Hedera Consensus Service", desc:"All 6 agent actions + quest events published as HCS messages. Sequence-numbered, tamper-proof consensus stream.", c:C.cyan, icon:"◈" },
    { label:"HTS", full:"Hedera Token Service", desc:"HBAR + USDC balances tracked via Mirror Node. Lyss manages HTS portfolio in tinyhbar precision.", c:C.purple, icon:"◉" },
    { label:"EVM", full:"Hedera EVM (Chain 296)", desc:"5 smart contracts deployed. Vex simulates then submits TXs. Gas priced in tinyhbar.", c:C.gold, icon:"▶" },
    { label:"MIRROR", full:"Mirror Node API", desc:"Real-time price feed, balance lookups, receipt confirmations. 30s cache via /api/hedera proxy.", c:C.green, icon:"▣" },
  ];

  layers.forEach((l, i) => {
    const y = 58 + i * 76;
    const ac = col255(l.c);
    const bx = s.insertShape(SlidesApp.ShapeType.ROUND_RECTANGLE, 30, y, W - 60, 66);
    bx.getFill().setSolidFill(ac.r, ac.g, ac.b);
    bx.setOpacity(0.07);
    const brd = bx.getBorder();
    brd.getLineFill().setSolidFill(ac.r, ac.g, ac.b);
    brd.setWeight(0.5);

    addText(s, l.icon + " " + l.label, 46, y + 8, 90, 22, { size: 13, color: l.c, bold: true, font: "Space Mono" });
    addText(s, l.full, 46, y + 30, 180, 18, { size: 8, color: C.dim, font: "Space Mono" });
    addLine(s, 155, y + 10, 155, y + 56, l.c, 0.3);
    addText(s, l.desc, 165, y + 12, W - 200, 44, { size: 9, color: C.white, font: "Space Mono" });
  });

  addFooter(s, C.hedera);
}

// SLIDE 7 — SMART CONTRACTS
function slide07_Contracts(pres) {
  const s = pres.appendSlide(SlidesApp.PredefinedLayout.BLANK);
  addBg(s);
  addAccentBar(s, C.purple);
  addHeader(s, "06  CONTRACTS", "5 Smart Contracts — Hedera Testnet EVM", C.purple);

  const contracts = [
    { name:"AgentRegistry.sol",  addr:"0x8B90AA6D1A12111C8F08C8B9Af4cca9f90336CC4", role:"Stores agent identities, reputations (0–1000), quest counts. Dynamic registration onchain.", c:C.cyan },
    { name:"QuestReceipt.sol",   addr:"0x444f5895D29809847E8642Df0e0f4DBdBf541C7D", role:"Immutable quest log — inputHash, txHash, success flag, timestamp. Public read.", c:C.green },
    { name:"PolicyManager.sol",  addr:"0xdBc14F4c53c071cd925fa4a730D06ddc1b4911E4", role:"Drax enforces: max position 5%, slippage ≤0.25%, audit required.", c:C.red },
    { name:"MockUSDC + Faucet",  addr:"0x152B…BF7  ·  0xCA05…B3953",               role:"Testnet USDC with drip faucet — UI button drips 100 USDC to wallet instantly.", c:C.gold },
  ];

  contracts.forEach((c, i) => {
    const y = 58 + i * 76;
    const ac = col255(c.c);
    const bx = s.insertShape(SlidesApp.ShapeType.ROUND_RECTANGLE, 30, y, W - 60, 66);
    bx.getFill().setSolidFill(ac.r, ac.g, ac.b);
    bx.setOpacity(0.07);
    const brd = bx.getBorder();
    brd.getLineFill().setSolidFill(ac.r, ac.g, ac.b);
    brd.setWeight(0.5);

    addText(s, c.name, 46, y + 8, 240, 16, { size: 10, color: c.c, bold: true, font: "Space Mono" });
    addText(s, c.addr, 46, y + 26, 320, 14, { size: 7, color: C.muted, font: "Space Mono" });
    addLine(s, 375, y + 10, 375, y + 56, c.c, 0.3);
    addText(s, c.role, 385, y + 12, W - 420, 44, { size: 9, color: C.white, font: "Space Mono" });
  });

  // HashScan link
  addText(s, "⬡ All contracts verified on HashScan testnet · Chain ID 296",
          30, H - 46, W - 60, 16, { size: 8, color: C.hedera, align: "center", font: "Space Mono" });

  addFooter(s, C.purple);
}

// SLIDE 8 — LIVE DEMO FEATURES
function slide08_Features(pres) {
  const s = pres.appendSlide(SlidesApp.PredefinedLayout.BLANK);
  addBg(s);
  addAccentBar(s, C.orange);
  addHeader(s, "07  DEMO", "Live Features — Working Right Now", C.orange);

  const features = [
    { icon:"◈", title:"Pixel Map",        desc:"6 NPC agents patrol a pixel-art world. Each building = Hedera module.", c:C.cyan },
    { icon:"▲", title:"Quest Runner",     desc:"Type intent → vote → payment gate → 6-agent SSE stream live.", c:C.gold },
    { icon:"◆", title:"Vote Panel",       desc:"Real-time guild vote. Drax vetoes risk. Animated agent decisions.", c:C.green },
    { icon:"◉", title:"Pay Gate (x402)",  desc:"1 HBAR per quest. MetaMask transaction before execution.", c:C.purple },
    { icon:"▶", title:"Live Timeline",    desc:"SSE stream: all TX hashes are clickable HashScan links.", c:C.orange },
    { icon:"▣", title:"Dashboard",        desc:"Recharts quest history. Agent reputations from contract.", c:C.red },
    { icon:"★", title:"Agent Register",   desc:"Register any agent onchain. Appears in the pixel map as an NPC.", c:C.cyan },
    { icon:"⬡", title:"USDC Faucet",      desc:"Drip 100 testnet USDC to your wallet in one click.", c:C.gold },
    { icon:"⚡", title:"Auto-Quest",       desc:"Every 9 min the guild auto-fires a quest — platform stays alive.", c:C.green },
  ];

  features.forEach((f, i) => {
    const col = i % 3;
    const row = Math.floor(i / 3);
    const x = 22 + col * 232;
    const y = 56 + row * 82;
    const ac = col255(f.c);
    const bx = s.insertShape(SlidesApp.ShapeType.ROUND_RECTANGLE, x, y, 218, 72);
    bx.getFill().setSolidFill(ac.r, ac.g, ac.b);
    bx.setOpacity(0.07);
    const brd = bx.getBorder();
    brd.getLineFill().setSolidFill(ac.r, ac.g, ac.b);
    brd.setWeight(0.5);

    addText(s, f.icon + "  " + f.title, x + 10, y + 8, 198, 18, { size: 9, color: f.c, bold: true, font: "Space Mono" });
    addLine(s, x + 10, y + 28, x + 208, y + 28, f.c, 0.25);
    addText(s, f.desc, x + 10, y + 32, 198, 36, { size: 8, color: C.dim, font: "Space Mono" });
  });

  addFooter(s, C.orange);
}

// SLIDE 9 — JUDGING CRITERIA ALIGNMENT
function slide09_Criteria(pres) {
  const s = pres.appendSlide(SlidesApp.PredefinedLayout.BLANK);
  addBg(s);
  addAccentBar(s, C.green);
  addHeader(s, "08  JUDGING", "Aligned with Every Criterion", C.green);

  addText(s, '"create coordination layers where autonomous actors can think, transact, and collaborate\n— leveraging Hedera\'s fast, low-cost microtransactions and secure consensus"',
          36, 52, W - 72, 40,
          { size: 9, color: C.muted, italic: true, align: "center", font: "Space Mono" });

  addDivider(s, 98, C.green);

  const criteria = [
    { criterion:"Think",             check:"Gemini AI in-character per agent. Confidence %, multi-path reasoning, philosophy.", score:"✓✓✓", c:C.cyan },
    { criterion:"Transact",          check:"Real EVM TXs on Hedera. Simulate → Sign → Submit. HashScan link every time.", score:"✓✓✓", c:C.green },
    { criterion:"Collaborate",       check:"6-agent vote consensus. Sequential handoff. Drax VETO kills bad quests.", score:"✓✓✓", c:C.gold },
    { criterion:"Hedera Consensus",  check:"HCS messages for every action. QuestReceipt.sol immutable onchain audit.", score:"✓✓✓", c:C.hedera },
    { criterion:"Microtransactions", check:"x402 payment gate. Wage meter per session op (0.001–0.05 USDC each).", score:"✓✓✓", c:C.orange },
    { criterion:"Transparency",      check:"Everything streamed live + archived. Mirror Node + HashScan publicly readable.", score:"✓✓✓", c:C.purple },
  ];

  criteria.forEach((c, i) => {
    const y = 106 + i * 44;
    const ac = col255(c.c);
    const bx = s.insertShape(SlidesApp.ShapeType.RECTANGLE, 36, y, W - 72, 36);
    bx.getFill().setSolidFill(ac.r, ac.g, ac.b);
    bx.setOpacity(i % 2 === 0 ? 0.07 : 0.04);
    bx.getBorder().setTransparent();

    addText(s, c.criterion, 46, y + 10, 160, 18, { size: 9, color: c.c, bold: true, font: "Space Mono" });
    addLine(s, 210, y + 4, 210, y + 32, c.c, 0.25);
    addText(s, c.check, 220, y + 6, W - 300, 28, { size: 8, color: C.white, font: "Space Mono" });
    addText(s, c.score, W - 76, y + 10, 60, 18, { size: 10, color: c.c, bold: true, align: "right", font: "Space Mono" });
  });

  addFooter(s, C.green);
}

// SLIDE 10 — CLOSING / VISION
function slide10_Closing(pres) {
  const s = pres.appendSlide(SlidesApp.PredefinedLayout.BLANK);
  addBg(s);

  // Scanlines
  for (let i = 0; i < H; i += 8) {
    const line = s.insertShape(SlidesApp.ShapeType.RECTANGLE, 0, i, W, 1);
    line.getFill().setSolidFill(255, 255, 255);
    line.setOpacity(0.012);
    line.getBorder().setTransparent();
  }

  addAccentBar(s, C.cyan);
  const br = s.insertShape(SlidesApp.ShapeType.RECTANGLE, W - 4, 0, 4, H);
  br.getFill().setSolidFill(0, 204, 255);
  br.setOpacity(1);
  br.getBorder().setTransparent();

  // Glow
  const glow = s.insertShape(SlidesApp.ShapeType.ELLIPSE, W/2 - 100, H/2 - 80, 200, 160);
  glow.getFill().setSolidFill(0, 180, 255);
  glow.setOpacity(0.05);
  glow.getBorder().setTransparent();

  addText(s, "The Guild is Live.", W/2 - 200, 68, 400, 48,
    { size: 32, color: C.white, bold: true, align: "center", font: "Space Mono" });

  addText(s, "6 agents. 5 contracts. Every decision onchain.", W/2 - 220, 120, 440, 22,
    { size: 12, color: C.dim, align: "center", font: "Space Mono" });

  addDivider(s, 152, C.cyan);

  // Roadmap
  const next = [
    { icon:"▶", label:"HCS-10 Agent Standard", sub:"Hashgraph Online compliance", c:C.cyan },
    { icon:"⬡", label:"EIP-4337 Account Abstraction", sub:"Session keys for agent-native signing", c:C.gold },
    { icon:"◈", label:"Agent Marketplace", sub:"Users mint custom agent workflows as NFTs", c:C.purple },
    { icon:"★", label:"Cross-Chain via Wormhole", sub:"Quests spanning Hedera + Ethereum", c:C.green },
  ];

  next.forEach((n, i) => {
    const x = 36 + (i % 2) * 330;
    const y = 162 + Math.floor(i / 2) * 56;
    const ac = col255(n.c);
    const bx = s.insertShape(SlidesApp.ShapeType.ROUND_RECTANGLE, x, y, 310, 46);
    bx.getFill().setSolidFill(ac.r, ac.g, ac.b);
    bx.setOpacity(0.08);
    const brd = bx.getBorder();
    brd.getLineFill().setSolidFill(ac.r, ac.g, ac.b);
    brd.setWeight(0.8);
    addText(s, n.icon + "  " + n.label, x + 12, y + 6, 290, 18, { size: 9, color: n.c, bold: true, font: "Space Mono" });
    addText(s, n.sub, x + 12, y + 24, 290, 16, { size: 8, color: C.dim, font: "Space Mono" });
  });

  // CTA
  const ctaY = 284;
  const ctaBox = s.insertShape(SlidesApp.ShapeType.ROUND_RECTANGLE, W/2 - 180, ctaY, 360, 44);
  ctaBox.getFill().setSolidFill(0, 204, 255);
  ctaBox.setOpacity(0.12);
  const cb = ctaBox.getBorder();
  cb.getLineFill().setSolidFill(0, 204, 255);
  cb.setWeight(1.5);
  addText(s, "aslanpixel.vercel.app", W/2 - 170, ctaY + 6, 340, 20,
    { size: 14, color: C.cyan, bold: true, align: "center", font: "Space Mono" });
  addText(s, "Live demo · Hedera Testnet · Code on GitHub", W/2 - 170, ctaY + 24, 340, 16,
    { size: 8, color: C.dim, align: "center", font: "Space Mono" });

  addFooter(s, C.cyan);
}

// ─── MAIN ENTRY POINT ─────────────────────────────────────────────────────────
function createAslanDeck() {
  const pres = SlidesApp.create("AslanGuild — Hackathon Deck 2026");
  pres.setPageWidth(W);
  pres.setPageHeight(H);

  // Remove the default blank slide
  const slides = pres.getSlides();
  if (slides.length > 0) slides[0].remove();

  slide01_Cover(pres);
  slide02_Problem(pres);
  slide03_Solution(pres);
  slide04_Agents(pres);
  slide05_Pipeline(pres);
  slide06_Hedera(pres);
  slide07_Contracts(pres);
  slide08_Features(pres);
  slide09_Criteria(pres);
  slide10_Closing(pres);

  const url = pres.getUrl();
  Logger.log("✓ Deck created: " + url);

  // Show URL in dialog
  const html = HtmlService.createHtmlOutput(
    '<p style="font-family:monospace;font-size:14px">✓ Deck created!<br><a href="' + url + '" target="_blank">' + url + '</a></p>'
  ).setWidth(500).setHeight(80);
  SlidesApp.getUi().showModalDialog(html, "AslanGuild Deck Ready");
}
