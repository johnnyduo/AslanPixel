/**
 * AslanGuild — Hackathon Slide Deck Generator
 * Google Apps Script → creates a fully themed Google Slides presentation
 * Run: paste into script.google.com → Run → createAslanDeck()
 *
 * Design: dark pixel-art, neon-on-black, matches the web app exactly
 * 10 slides calibrated against hackathon judging criteria
 *
 * NOTE: Google Slides default page = 960×540 pt (16:9). We use these exact
 * dimensions — no setPageWidth/Height calls needed.
 */

// ─── BRAND PALETTE ────────────────────────────────────────────────────────────
var C = {
  bg:       { r:12,  g:14,  b:25  },   // hsl(225 35% 7%) — near-black navy
  panel:    { r:18,  g:21,  b:35  },   // glass panel
  cyan:     { r:0,   g:204, b:255 },   // Nexus   ◈
  gold:     { r:255, g:199, b:51  },   // Oryn    ▲
  green:    { r:51,  g:209, b:102 },   // Drax    ◆
  purple:   { r:179, g:102, b:230 },   // Lyss    ◉
  orange:   { r:255, g:158, b:26  },   // Vex     ▶
  red:      { r:235, g:71,  b:71  },   // Kael    ▣
  white:    { r:255, g:255, b:255 },
  dim:      { r:148, g:158, b:184 },
  muted:    { r:87,  g:97,  b:128 },
  hedera:   { r:0,   g:191, b:203 },
};

// ─── SLIDE DIMENSIONS (Google Slides default 16:9) ────────────────────────────
var W = 960;
var H = 540;

// ─── LOW-LEVEL HELPERS ────────────────────────────────────────────────────────

function addBg(slide) {
  var bg = slide.insertShape(SlidesApp.ShapeType.RECTANGLE, 0, 0, W, H);
  bg.getFill().setSolidFill(C.bg.r, C.bg.g, C.bg.b);
  bg.getBorder().setTransparent();
}

function addRect(slide, x, y, w, h, col, opacity) {
  var s = slide.insertShape(SlidesApp.ShapeType.RECTANGLE, x, y, w, h);
  s.getFill().setSolidFill(col.r, col.g, col.b);
  s.getBorder().setTransparent();
  if (opacity !== undefined) s.setOpacity(opacity);
  return s;
}

function addRRect(slide, x, y, w, h, col, opacity, borderCol, borderW) {
  var s = slide.insertShape(SlidesApp.ShapeType.ROUND_RECTANGLE, x, y, w, h);
  s.getFill().setSolidFill(col.r, col.g, col.b);
  s.setOpacity(opacity || 1);
  if (borderCol) {
    var brd = s.getBorder();
    brd.getLineFill().setSolidFill(borderCol.r, borderCol.g, borderCol.b);
    brd.setWeight(borderW || 1);
  } else {
    s.getBorder().setTransparent();
  }
  return s;
}

function addText(slide, text, x, y, w, h, opts) {
  var box = slide.insertTextBox(text, x, y, w, h);
  var tf  = box.getText();
  var sty = tf.getTextStyle();
  sty.setFontFamily(opts.font || "Space Mono");
  sty.setFontSize(opts.size || 14);
  var col = opts.color || C.white;
  sty.setForegroundColor(col.r, col.g, col.b);
  if (opts.bold)   sty.setBold(true);
  if (opts.italic) sty.setItalic(true);
  var ps = tf.getParagraphStyle();
  ps.setParagraphAlignment(
    opts.align === "center" ? SlidesApp.ParagraphAlignment.CENTER :
    opts.align === "right"  ? SlidesApp.ParagraphAlignment.END :
                              SlidesApp.ParagraphAlignment.START
  );
  box.getBorder().setTransparent();
  box.getFill().setTransparent();
  return box;
}

function addLine(slide, x1, y1, x2, y2, col, w) {
  var ln = slide.insertLine(
    SlidesApp.LineCategory.STRAIGHT,
    SlidesApp.LineType.STRAIGHT_CONNECTOR_1,
    x1, y1, x2, y2
  );
  ln.getLineFill().setSolidFill(col.r, col.g, col.b);
  ln.setWeight(w || 1);
  return ln;
}

// Left accent bar
function accentBar(slide, col) {
  addRect(slide, 0, 0, 5, H, col);
}

// Right accent bar
function accentBarR(slide, col) {
  addRect(slide, W - 5, 0, 5, H, col);
}

// Header strip (top 58 pt)
function addHeader(slide, pill, title, col) {
  addRect(slide, 0, 0, W, 58, C.panel);
  addLine(slide, 0, 58, W, 58, col, 1);

  // pill badge
  addRRect(slide, 26, 15, 100, 28, col, 0.15);
  addText(slide, pill, 26, 15, 100, 28, { size: 8, color: col, bold: true, align: "center" });

  addText(slide, title, 140, 14, W - 160, 30,
          { size: 17, color: C.white, bold: true });
}

// Footer strip (bottom 36 pt)
function addFooter(slide, col) {
  addRect(slide, 0, H - 36, W, 36, C.panel);
  addLine(slide, 0, H - 36, W, H - 36, col, 0.5);
  addText(slide, "ASLAN GUILD  //  Agentic Guild on Hedera  //  aslanpixel.vercel.app",
          26, H - 28, W - 200, 20, { size: 8, color: C.muted });
  addText(slide, "AI & AGENTS TRACK",
          W - 190, H - 28, 170, 20, { size: 8, color: col, bold: true, align: "right" });
}

// Divider with center diamond
function addDivider(slide, y, col) {
  addLine(slide, 40, y, W / 2 - 12, y, col, 0.4);
  addText(slide, "◆", W / 2 - 8, y - 9, 16, 18, { size: 8, color: col, align: "center" });
  addLine(slide, W / 2 + 12, y, W - 40, y, col, 0.4);
}

// Scanline overlay (pixel-art texture)
function addScanlines(slide) {
  for (var i = 0; i < H; i += 10) {
    var ln = slide.insertShape(SlidesApp.ShapeType.RECTANGLE, 0, i, W, 1);
    ln.getFill().setSolidFill(255, 255, 255);
    ln.setOpacity(0.015);
    ln.getBorder().setTransparent();
  }
}

// Agent card (for slide 4)
function addAgentCard(slide, x, y, w, h, agent) {
  addRRect(slide, x, y, w, h, agent.col, 0.10, agent.col, 1);
  // top color strip
  addRect(slide, x, y, w, 4, agent.col);
  // icon
  addText(slide, agent.icon, x + 10, y + 10, 40, 38,
          { size: 24, color: agent.col, bold: true, align: "center" });
  // name
  addText(slide, agent.name, x + 58, y + 10, w - 70, 22,
          { size: 12, color: agent.col, bold: true });
  // role
  addText(slide, agent.role, x + 58, y + 32, w - 70, 18,
          { size: 9, color: C.dim });
  addLine(slide, x + 10, y + 58, x + w - 10, y + 58, agent.col, 0.4);
  // desc
  addText(slide, agent.desc, x + 10, y + 64, w - 20, h - 68,
          { size: 8.5, color: C.dim });
}

// Flow step box
function addFlowBox(slide, x, y, w, h, label, col) {
  addRRect(slide, x, y, w, h, col, 0.14, col, 1);
  addText(slide, label, x + 8, y + h / 2 - 11, w - 16, 22,
          { size: 9, color: col, bold: true, align: "center" });
}

// Horizontal layer row (for Hedera/Contracts slides)
function addLayerRow(slide, y, h, icon, label, sub, desc, col) {
  addRRect(slide, 40, y, W - 80, h, col, 0.08, col, 0.6);
  addText(slide, icon + "  " + label, 58, y + 10, 150, 26,
          { size: 14, color: col, bold: true });
  addText(slide, sub, 58, y + 38, 170, 18, { size: 8, color: C.dim });
  addLine(slide, 218, y + 10, 218, y + h - 10, col, 0.4);
  addText(slide, desc, 232, y + 14, W - 290, h - 24,
          { size: 10, color: C.white });
}

// ─── SLIDE 1 — COVER ─────────────────────────────────────────────────────────
function slide01_Cover(pres) {
  var s = pres.appendSlide(SlidesApp.PredefinedLayout.BLANK);
  addBg(s);
  addScanlines(s);
  accentBar(s, C.cyan);
  accentBarR(s, C.cyan);

  // Background glow circle
  var g = s.insertShape(SlidesApp.ShapeType.ELLIPSE, W/2 - 160, H/2 - 130, 320, 260);
  g.getFill().setSolidFill(0, 180, 255);
  g.setOpacity(0.05);
  g.getBorder().setTransparent();

  // Scattered agent icons
  var icons = [
    { i:"◈", x:80,  y:80,  c:C.cyan,   sz:34 },
    { i:"▲", x:830, y:65,  c:C.gold,   sz:28 },
    { i:"◆", x:72,  y:390, c:C.green,  sz:26 },
    { i:"◉", x:842, y:400, c:C.purple, sz:28 },
    { i:"▶", x:455, y:445, c:C.orange, sz:24 },
    { i:"▣", x:100, y:230, c:C.red,    sz:24 },
  ];
  icons.forEach(function(ic) {
    addText(s, ic.i, ic.x, ic.y, 50, 50,
            { size: ic.sz, color: ic.c, bold: true, align: "center" });
  });

  // Main title
  addText(s, "ASLAN GUILD", W/2 - 260, 128, 520, 78,
          { size: 56, color: C.cyan, bold: true, align: "center" });

  addText(s, "Agentic Guild on Hedera", W/2 - 260, 208, 520, 36,
          { size: 20, color: C.white, align: "center" });

  addText(s, "6 autonomous AI agents  ·  THINK  ·  TRANSACT  ·  COLLABORATE",
          W/2 - 300, 248, 600, 24, { size: 11, color: C.dim, align: "center" });

  // Track badge
  addRRect(s, W/2 - 220, 288, 440, 46, C.cyan, 0.10, C.cyan, 1);
  addText(s, "AI & Agents Track  ·  Hedera Hackathon  ·  2026",
          W/2 - 210, 300, 420, 24, { size: 11, color: C.cyan, bold: true, align: "center" });

  // URL
  addText(s, "⬡   aslanpixel.vercel.app",
          W/2 - 160, 352, 320, 22, { size: 11, color: C.hedera, align: "center" });

  addFooter(s, C.cyan);
}

// ─── SLIDE 2 — PROBLEM ───────────────────────────────────────────────────────
function slide02_Problem(pres) {
  var s = pres.appendSlide(SlidesApp.PredefinedLayout.BLANK);
  addBg(s);
  accentBar(s, C.red);
  addHeader(s, "01  PROBLEM", "DeFi is a Black Box", C.red);

  addText(s, '"You send funds.  You wait.  You hope."',
          60, 80, W - 120, 52,
          { size: 24, color: C.white, bold: true, italic: true, align: "center" });

  addDivider(s, 148, C.red);

  var pains = [
    { icon:"⚠", title:"Opaque Operations",
      desc:"No visibility into what's happening\nwith your assets. Strategies execute\nin the dark — no audit trail.", c:C.red },
    { icon:"⚡", title:"Complex Coordination",
      desc:"Multi-step DeFi needs scouts, strategists,\nrisk guards, executors, archivists —\nimpossible for one agent.", c:C.orange },
    { icon:"◎", title:"No Accountability",
      desc:"When a TX fails or slippage spikes —\nwho's responsible? Centralized bots\nleave no onchain proof.", c:C.gold },
  ];

  pains.forEach(function(p, i) {
    var x = 46 + i * 292;
    addRRect(s, x, 162, 270, 200, p.c, 0.09, p.c, 0.6);
    addRect(s, x, 162, 270, 4, p.c);
    addText(s, p.icon, x + 14, 174, 50, 50, { size: 28, color: p.c, bold: true });
    addText(s, p.title, x + 14, 226, 242, 26, { size: 12, color: p.c, bold: true });
    addLine(s, x + 14, 256, x + 256, 256, p.c, 0.35);
    addText(s, p.desc, x + 14, 264, 242, 90, { size: 9.5, color: C.dim });
  });

  addFooter(s, C.red);
}

// ─── SLIDE 3 — SOLUTION ──────────────────────────────────────────────────────
function slide03_Solution(pres) {
  var s = pres.appendSlide(SlidesApp.PredefinedLayout.BLANK);
  addBg(s);
  accentBar(s, C.cyan);
  addHeader(s, "02  SOLUTION", "AslanGuild — Transparent Autonomous DeFi", C.cyan);

  addText(s,
    "A guild of 6 specialized AI agents that coordinate, vote, execute, and archive every DeFi operation — live and onchain.",
    46, 72, W - 92, 30, { size: 10.5, color: C.dim });

  var pillars = [
    { icon:"◈", word:"THINK",
      sub:"Gemini AI powers in-character reasoning per agent.\nEach agent has a role, philosophy, confidence %,\nand unique decision logic.", c:C.cyan },
    { icon:"▶", word:"TRANSACT",
      sub:"Every quest generates a real Hedera EVM TX.\nSimulate → Sign → Submit → HashScan verified.\nGas in tinyhbar, nonce locked.", c:C.green },
    { icon:"▣", word:"COLLABORATE",
      sub:"6-agent vote consensus before any execution.\nDrax can VETO high-risk quests.\nSequential handoff streamed live via SSE.", c:C.gold },
  ];

  pillars.forEach(function(p, i) {
    var x = 46 + i * 292;
    var y = 112;
    addRRect(s, x, y, 270, 170, p.c, 0.10, p.c, 1.5);
    addText(s, p.icon, x + 14, y + 12, 44, 44, { size: 28, color: p.c, bold: true });
    addText(s, p.word, x + 14, y + 62, 242, 28, { size: 16, color: p.c, bold: true });
    addLine(s, x + 14, y + 94, x + 256, y + 94, p.c, 0.4);
    addText(s, p.sub, x + 14, y + 102, 242, 62, { size: 9, color: C.dim });
  });

  addDivider(s, 302, C.cyan);

  var checks = [
    { t:"✓  HCS — every agent action posted as consensus message", c:C.cyan },
    { t:"✓  EVM — 5 smart contracts on Hedera Testnet (chain 296)", c:C.green },
    { t:"✓  Mirror Node — live price, balance, receipt lookups", c:C.gold },
    { t:"✓  QuestReceipt.sol — immutable audit trail, publicly readable", c:C.purple },
  ];
  checks.forEach(function(ck, i) {
    var x = 46 + (i % 2) * 460;
    var y = 314 + Math.floor(i / 2) * 28;
    addText(s, ck.t, x, y, 440, 24, { size: 9.5, color: ck.c });
  });

  addFooter(s, C.cyan);
}

// ─── SLIDE 4 — THE 6 AGENTS ──────────────────────────────────────────────────
function slide04_Agents(pres) {
  var s = pres.appendSlide(SlidesApp.PredefinedLayout.BLANK);
  addBg(s);
  accentBar(s, C.gold);
  addHeader(s, "03  THE GUILD", "6 Autonomous Agents — Each Owns a Domain", C.gold);

  var agents = [
    { icon:"◈", name:"NEXUS",  role:"HCS Intelligence",
      desc:"Subscribes HCS topics · 847 msgs/min\nAnomaly detection · sequence gap alerts\nCross-references 3 mirror nodes",
      col:C.cyan },
    { icon:"▲", name:"ORYN",   role:"Strategy Engine",
      desc:"3-branch EVM models · confidence-weighted\nFallback planning on every path\nSaucerSwap TVL/pool data injected",
      col:C.gold },
    { icon:"◆", name:"DRAX",   role:"Risk Sentinel",
      desc:"PolicyManager.sol enforcer · VETO authority\nSlippage cap 0.25% · max position 5%\nAudit hash verified per TX",
      col:C.green },
    { icon:"◉", name:"LYSS",   role:"Treasury Keeper",
      desc:"HTS portfolio tracked in tinyhbar\n500 HBAR gas buffer reserved always\nBlocks over-allocation at cap",
      col:C.purple },
    { icon:"▶", name:"VEX",    role:"TX Executor",
      desc:"Simulate → Sign → Submit → Monitor\nNonce management · gas pricing\nMirror node confirmation loop",
      col:C.orange },
    { icon:"▣", name:"KAEL",   role:"Ledger Archivist",
      desc:"QuestReceipt.sol writer · Mirror archive\ninputHash + txHash stored immutably\n100% success rate · ledger never lies",
      col:C.red },
  ];

  agents.forEach(function(ag, i) {
    var col = i % 3;
    var row = Math.floor(i / 3);
    var x = 26 + col * 304;
    var y = 72 + row * 196;
    addAgentCard(s, x, y, 290, 182, ag);
  });

  addFooter(s, C.gold);
}

// ─── SLIDE 5 — PIPELINE ──────────────────────────────────────────────────────
function slide05_Pipeline(pres) {
  var s = pres.appendSlide(SlidesApp.PredefinedLayout.BLANK);
  addBg(s);
  accentBar(s, C.green);
  addHeader(s, "04  HOW IT WORKS", "Quest Pipeline — Intent to Immutable Receipt", C.green);

  // Intent input
  addText(s, "User types:", 40, 72, 110, 18, { size: 8, color: C.muted });
  addRRect(s, 40, 90, 380, 36, C.green, 0.10, C.green, 1);
  addText(s, '"Rebalance treasury with 30% USDC buffer"',
          50, 99, 360, 20, { size: 9.5, color: C.green, italic: true });

  addText(s, "↓", 218, 130, 36, 22, { size: 16, color: C.green, bold: true, align: "center" });

  // Pipeline steps
  var steps = [
    { label:"① GUILD VOTE",      desc:"All 6 agents vote · Drax can VETO",       c:C.red },
    { label:"② PAYMENT GATE",    desc:"x402 · 1 HBAR per quest execution",       c:C.gold },
    { label:"③ NEXUS SCANS",     desc:"HCS stream + SaucerSwap market data",     c:C.cyan },
    { label:"④ ORYN MODELS",     desc:"3-branch strategy · 91% confidence",      c:C.gold },
    { label:"⑤ DRAX VALIDATES",  desc:"PolicyManager.sol compliance check",      c:C.green },
    { label:"⑥ VEX EXECUTES",    desc:"Simulate → Sign → Submit → Confirmed",   c:C.orange },
    { label:"⑦ KAEL ARCHIVES",   desc:"QuestReceipt.sol + HCS topic publish",    c:C.red },
  ];

  steps.forEach(function(st, i) {
    var y = 156 + i * 48;
    addFlowBox(s, 40, y, 240, 36, st.label, st.c);
    addText(s, st.desc, 290, y + 9, 270, 20, { size: 9, color: C.dim });
    if (i < steps.length - 1)
      addText(s, "↓", 148, y + 36, 36, 16, { size: 11, color: st.c, align: "center" });
  });

  // Result panel (right)
  var rx = 582;
  addRRect(s, rx, 72, 344, 396, C.panel, 1, C.green, 0.5);
  addText(s, "⬢  QUEST RESULT", rx + 18, 82, 300, 22,
          { size: 11, color: C.green, bold: true });
  addLine(s, rx + 18, 108, rx + 322, 108, C.green, 0.4);

  var results = [
    { t:"TX hash on HashScan · clickable link", c:C.cyan },
    { t:"QuestReceipt #N stored onchain",       c:C.green },
    { t:"HCS message published to topic",       c:C.gold },
    { t:"Agent reputations updated (0–1000)",   c:C.purple },
    { t:"SSE timeline streamed live to UI",     c:C.orange },
    { t:"Mirror Node: state IMMUTABLE",         c:C.red },
  ];
  results.forEach(function(r, i) {
    addText(s, "✓  " + r.t, rx + 18, 118 + i * 52, 306, 44,
            { size: 9.5, color: r.c });
    if (i < results.length - 1)
      addLine(s, rx + 18, 158 + i * 52, rx + 322, 158 + i * 52, C.muted, 0.3);
  });

  addFooter(s, C.green);
}

// ─── SLIDE 6 — HEDERA INTEGRATION ────────────────────────────────────────────
function slide06_Hedera(pres) {
  var s = pres.appendSlide(SlidesApp.PredefinedLayout.BLANK);
  addBg(s);
  accentBar(s, C.hedera);
  addHeader(s, "05  HEDERA", "Native Hedera Integration — Every Layer Used", C.hedera);

  var layers = [
    { icon:"◈", label:"HCS", sub:"Hedera Consensus Service",
      desc:"All 6 agent actions + quest events published as tamper-proof HCS messages.\nSequence-numbered consensus stream. Agents subscribe in real-time at 847 msgs/min.",
      c:C.cyan },
    { icon:"◉", label:"HTS", sub:"Hedera Token Service",
      desc:"HBAR + USDC balances tracked via Mirror Node in tinyhbar precision.\nLyss manages HTS portfolio, blocks over-allocation, reserves 500 HBAR gas buffer.",
      c:C.purple },
    { icon:"▶", label:"EVM", sub:"Hedera EVM  ·  Chain ID 296",
      desc:"5 smart contracts deployed on Hedera Testnet via Remix. Vex simulates then\nsubmits TXs priced in tinyhbar. Nonce-locked sequential execution.",
      c:C.gold },
    { icon:"▣", label:"MIRROR", sub:"Mirror Node API",
      desc:"Real-time price feed, balance lookups, receipt confirmations. 30s cache via\n/api/hedera proxy on Vercel Edge. SaucerSwap TVL injected into agent prompts.",
      c:C.green },
  ];

  layers.forEach(function(l, i) {
    addLayerRow(s, 72 + i * 112, 100, l.icon, l.label, l.sub, l.desc, l.c);
  });

  addFooter(s, C.hedera);
}

// ─── SLIDE 7 — SMART CONTRACTS ───────────────────────────────────────────────
function slide07_Contracts(pres) {
  var s = pres.appendSlide(SlidesApp.PredefinedLayout.BLANK);
  addBg(s);
  accentBar(s, C.purple);
  addHeader(s, "06  CONTRACTS", "5 Smart Contracts — Hedera Testnet EVM", C.purple);

  var contracts = [
    { name:"AgentRegistry.sol",
      addr:"0x8B90AA6D1A12111C8F08C8B9Af4cca9f90336CC4",
      role:"Stores agent identities, reputations (0–1000 scale), quest counts.\nDynamic onchain registration — new agents appear in the pixel map as NPCs.", c:C.cyan },
    { name:"QuestReceipt.sol",
      addr:"0x444f5895D29809847E8642Df0e0f4DBdBf541C7D",
      role:"Immutable quest log — inputHash, txHash, success flag, consensus timestamp.\nPublic read — anyone can audit every quest ever executed.", c:C.green },
    { name:"PolicyManager.sol",
      addr:"0xdBc14F4c53c071cd925fa4a730D06ddc1b4911E4",
      role:"Drax enforces: max position 5%, slippage ≤ 0.25%, audit hash required.\nIf any check fails — quest is blocked before any TX is sent.", c:C.red },
    { name:"MockUSDC  +  USDCFaucet",
      addr:"0x152B…BF7   ·   0xCA05…B3953",
      role:"Testnet USDC token with on-demand drip faucet. One click from the UI\ndrips 100 USDC to your wallet — no external faucet needed.", c:C.gold },
  ];

  contracts.forEach(function(c, i) {
    var y = 74 + i * 110;
    addRRect(s, 40, y, W - 80, 98, c.c, 0.08, c.c, 0.5);
    addText(s, c.name, 58, y + 12, 420, 24, { size: 13, color: c.c, bold: true });
    addText(s, c.addr, 58, y + 38, 440, 18, { size: 8, color: C.muted });
    addLine(s, 506, y + 10, 506, y + 86, c.c, 0.4);
    addText(s, c.role, 520, y + 12, W - 568, 74, { size: 9.5, color: C.white });
  });

  addText(s, "⬡  All contracts verified on HashScan testnet  ·  hashscan.io/testnet",
          40, H - 58, W - 80, 20, { size: 9, color: C.hedera, align: "center" });

  addFooter(s, C.purple);
}

// ─── SLIDE 8 — LIVE FEATURES ─────────────────────────────────────────────────
function slide08_Features(pres) {
  var s = pres.appendSlide(SlidesApp.PredefinedLayout.BLANK);
  addBg(s);
  accentBar(s, C.orange);
  addHeader(s, "07  DEMO", "Live Features — Working Right Now", C.orange);

  var features = [
    { icon:"◈", title:"Pixel Map",
      desc:"6 NPC agents patrol a pixel-art world.\nEach building = a Hedera module.", c:C.cyan },
    { icon:"▲", title:"Quest Runner",
      desc:"Type intent → vote → pay → 6-agent\nSSE stream, all live.", c:C.gold },
    { icon:"◆", title:"Vote Panel",
      desc:"Real-time guild vote. Drax vetoes.\nAnimated per-agent decisions.", c:C.green },
    { icon:"◉", title:"x402 Payment Gate",
      desc:"1 HBAR per quest. MetaMask TX\nbefore any execution begins.", c:C.purple },
    { icon:"▶", title:"Live Timeline",
      desc:"SSE stream. TX hashes are clickable\nHashScan links inline.", c:C.orange },
    { icon:"▣", title:"Dashboard",
      desc:"Recharts quest history chart.\nAgent reputations from contract.", c:C.red },
    { icon:"★", title:"Agent Register",
      desc:"Register onchain → appears in the\npixel map as a live NPC.", c:C.cyan },
    { icon:"⬡", title:"USDC Faucet",
      desc:"Drip 100 testnet USDC to your\nwallet in one button click.", c:C.gold },
    { icon:"⚡", title:"Auto-Quest Mode",
      desc:"Every 9 min the guild auto-fires\na quest. Platform stays alive.", c:C.green },
  ];

  features.forEach(function(f, i) {
    var col = i % 3;
    var row = Math.floor(i / 3);
    var x = 26 + col * 308;
    var y = 72 + row * 142;
    addRRect(s, x, y, 292, 130, f.c, 0.08, f.c, 0.5);
    addRect(s, x, y, 292, 4, f.c);
    addText(s, f.icon + "  " + f.title, x + 14, y + 12, 264, 26,
            { size: 12, color: f.c, bold: true });
    addLine(s, x + 14, y + 42, x + 278, y + 42, f.c, 0.3);
    addText(s, f.desc, x + 14, y + 50, 264, 72, { size: 9.5, color: C.dim });
  });

  addFooter(s, C.orange);
}

// ─── SLIDE 9 — JUDGING CRITERIA ──────────────────────────────────────────────
function slide09_Criteria(pres) {
  var s = pres.appendSlide(SlidesApp.PredefinedLayout.BLANK);
  addBg(s);
  accentBar(s, C.green);
  addHeader(s, "08  JUDGING", "Aligned with Every Criterion — Checked", C.green);

  addText(s,
    '"create marketplaces, coordination layers, and tools where autonomous actors can think, transact, and\ncollaborate — leveraging Hedera\'s fast, low-cost microtransactions and secure consensus"',
    46, 68, W - 92, 46, { size: 9, color: C.muted, italic: true, align: "center" });

  addDivider(s, 122, C.green);

  var criteria = [
    { crit:"Think",              ev:"Gemini AI in-character per agent. Confidence %, multi-path reasoning, agent philosophy.", score:"✓✓✓", c:C.cyan },
    { crit:"Transact",           ev:"Real EVM TXs on Hedera. Simulate → Sign → Submit. HashScan link on every confirmed TX.", score:"✓✓✓", c:C.green },
    { crit:"Collaborate",        ev:"6-agent vote consensus. Sequential handoff. Drax VETO blocks any non-compliant quest.", score:"✓✓✓", c:C.gold },
    { crit:"Hedera Consensus",   ev:"HCS messages for every agent action. QuestReceipt.sol immutable onchain audit trail.", score:"✓✓✓", c:C.hedera },
    { crit:"Microtransactions",  ev:"x402 payment gate: 1 HBAR per quest. Session wage meter: 0.001–0.05 USDC per op.", score:"✓✓✓", c:C.orange },
    { crit:"Transparency",       ev:"Every step streamed live + archived. Mirror Node + HashScan publicly queryable.", score:"✓✓✓", c:C.purple },
  ];

  criteria.forEach(function(c, i) {
    var y = 132 + i * 62;
    addRRect(s, 40, y, W - 80, 54, c.c, i % 2 === 0 ? 0.08 : 0.05);
    addText(s, c.crit, 58, y + 16, 180, 24, { size: 11, color: c.c, bold: true });
    addLine(s, 248, y + 8, 248, y + 46, c.c, 0.35);
    addText(s, c.ev, 262, y + 10, W - 390, 36, { size: 9.5, color: C.white });
    addText(s, c.score, W - 120, y + 16, 100, 24,
            { size: 14, color: c.c, bold: true, align: "right" });
  });

  addFooter(s, C.green);
}

// ─── SLIDE 10 — CLOSING ──────────────────────────────────────────────────────
function slide10_Closing(pres) {
  var s = pres.appendSlide(SlidesApp.PredefinedLayout.BLANK);
  addBg(s);
  addScanlines(s);
  accentBar(s, C.cyan);
  accentBarR(s, C.cyan);

  var g = s.insertShape(SlidesApp.ShapeType.ELLIPSE, W/2 - 130, H/2 - 110, 260, 220);
  g.getFill().setSolidFill(0, 180, 255);
  g.setOpacity(0.06);
  g.getBorder().setTransparent();

  addText(s, "The Guild is Live.", W/2 - 310, 88, 620, 70,
          { size: 44, color: C.white, bold: true, align: "center" });

  addText(s, "6 agents  ·  5 contracts  ·  Every decision onchain",
          W/2 - 310, 162, 620, 30, { size: 13, color: C.dim, align: "center" });

  addDivider(s, 206, C.cyan);

  var next = [
    { icon:"▶", label:"HCS-10 Agent Standard",          sub:"Full Hashgraph Online compliance", c:C.cyan },
    { icon:"⬡", label:"EIP-4337 Account Abstraction",   sub:"Session keys for agent-native signing", c:C.gold },
    { icon:"◈", label:"Agent Marketplace",               sub:"Custom workflows minted as NFTs", c:C.purple },
    { icon:"★", label:"Cross-Chain via Wormhole",        sub:"Quests spanning Hedera + Ethereum", c:C.green },
  ];

  next.forEach(function(n, i) {
    var x = 40 + (i % 2) * 444;
    var y = 218 + Math.floor(i / 2) * 74;
    addRRect(s, x, y, 414, 62, n.c, 0.09, n.c, 0.8);
    addText(s, n.icon + "  " + n.label, x + 16, y + 8, 382, 26, { size: 12, color: n.c, bold: true });
    addText(s, n.sub, x + 16, y + 34, 382, 22, { size: 9.5, color: C.dim });
  });

  // CTA box
  var ctaY = 380;
  addRRect(s, W/2 - 240, ctaY, 480, 56, C.cyan, 0.13, C.cyan, 1.5);
  addText(s, "aslanpixel.vercel.app",
          W/2 - 230, ctaY + 8, 460, 26,
          { size: 17, color: C.cyan, bold: true, align: "center" });
  addText(s, "Live demo  ·  Hedera Testnet  ·  Open source on GitHub",
          W/2 - 230, ctaY + 32, 460, 20,
          { size: 9, color: C.dim, align: "center" });

  addFooter(s, C.cyan);
}

// ─── MAIN ─────────────────────────────────────────────────────────────────────
function createAslanDeck() {
  var pres = SlidesApp.create("AslanGuild — Hackathon Deck 2026");

  // Remove default blank slide
  var existing = pres.getSlides();
  if (existing.length > 0) existing[0].remove();

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

  var url = pres.getUrl();
  Logger.log("✓ Deck created: " + url);

  var html = HtmlService.createHtmlOutput(
    '<div style="font-family:monospace;padding:12px">' +
    '<p style="color:#00ccff;font-size:15px">✓ AslanGuild deck created!</p>' +
    '<a href="' + url + '" target="_blank" style="font-size:13px">' + url + '</a>' +
    '</div>'
  ).setWidth(560).setHeight(90);
  SlidesApp.getUi().showModalDialog(html, "AslanGuild Deck Ready");
}
