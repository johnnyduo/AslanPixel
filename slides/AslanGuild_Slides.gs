/**
 * AslanPixel — Hackathon Slide Deck  v9  (hype edition)
 * Canvas: 720 × 405 pt  (Google Slides 16:9 widescreen)
 *
 * Layout constants:
 *   P  = 28   left/right padding
 *   FT = 22   footer height (H-22..H)
 *   TH = 56   y where content starts (below title block)
 *   CB = H-FT = 383   bottom of content area
 *   CONTENT_H = CB - TH = 327
 *
 * GAS hard limits:
 *   NO setOpacity() on shapes or lines
 *   insertLine(lineCategory, x1,y1,x2,y2)
 *   setSolidFill(r,g,b) integers 0-255
 *   no getUi() in standalone scripts
 */

// ── COLORS ───────────────────────────────────────────────────────────────────
var BG     = [10,  12,  24];
var CARD   = [20,  24,  44];
var BORDER = [40,  48,  80];
var CYAN   = [0,   204, 255];
var GOLD   = [255, 199, 51];
var GREEN  = [51,  209, 102];
var PURPLE = [160, 90,  220];
var ORANGE = [255, 158, 26];
var RED    = [220, 60,  60];
var WHITE  = [240, 244, 255];
var DIM    = [120, 132, 168];
var MUTED  = [60,  70,  100];
var HEDERA = [0,   180, 190];

// ── CANVAS ───────────────────────────────────────────────────────────────────
var W  = 720;
var H  = 405;
var P  = 28;
var FT = 22;
var TH = 56;
var CB = H - FT; // 383

// ── PRIMITIVES ───────────────────────────────────────────────────────────────

function _bg(s, col) {
  s.getBackground().setSolidFill(col[0], col[1], col[2]);
}

function _rect(s, x, y, w, h, col) {
  var sh = s.insertShape(SlidesApp.ShapeType.RECTANGLE, x, y, w, h);
  sh.getFill().setSolidFill(col[0], col[1], col[2]);
  sh.getBorder().setTransparent();
  return sh;
}

function _card(s, x, y, w, h, col) {
  if (w < 2) w = 2; if (h < 2) h = 2;
  var sh = s.insertShape(SlidesApp.ShapeType.ROUND_RECTANGLE, x, y, w, h);
  sh.getFill().setSolidFill(CARD[0], CARD[1], CARD[2]);
  sh.getBorder().getLineFill().setSolidFill(col[0], col[1], col[2]);
  sh.getBorder().setWeight(1.2);
  return sh;
}

function _line(s, x1, y1, x2, y2, col) {
  var ln = s.insertLine(SlidesApp.LineCategory.STRAIGHT, x1, y1, x2, y2);
  ln.getLineFill().setSolidFill(col[0], col[1], col[2]);
  ln.setWeight(0.8);
  return ln;
}

function _txt(s, text, x, y, w, h, sz, col, bold, align, italic) {
  if (w < 4) w = 4; if (h < 4) h = 4;
  if (x + w > W) w = W - x;
  if (y + h > H) h = H - y;
  var box = s.insertTextBox(text, x, y, w, h);
  var tf  = box.getText();
  var sty = tf.getTextStyle();
  sty.setFontFamily("Space Mono");
  sty.setFontSize(sz || 8);
  sty.setForegroundColor(col[0], col[1], col[2]);
  if (bold)   sty.setBold(true);
  if (italic) sty.setItalic(true);
  tf.getParagraphStyle().setParagraphAlignment(
    align === "C" ? SlidesApp.ParagraphAlignment.CENTER :
    align === "R" ? SlidesApp.ParagraphAlignment.END :
                    SlidesApp.ParagraphAlignment.START
  );
  box.getFill().setTransparent();
  box.getBorder().setTransparent();
  return box;
}

function _sprite(s, agent, x, y, sz) {
  var url = "https://aslanpixel.vercel.app/assets/npcs/npc-" + agent + "-s.png";
  try {
    var img = s.insertImage(url);
    img.setLeft(x).setTop(y).setWidth(sz).setHeight(sz);
    return img;
  } catch(e) { return null; }
}

// ── CHROME & TITLE ───────────────────────────────────────────────────────────
function _chrome(s, col) {
  _bg(s, BG);
  _rect(s, 0, 0, W, 2, col);
  _rect(s, 0, CB, W, FT, CARD);
  _line(s, 0, CB, W, CB, col);
  _txt(s, "ASLAN PIXEL  //  aslanpixel.vercel.app  //  Hedera Hello Future Apex Hackathon 2026",
       P, CB + 5, W - P*2, FT - 7, 6, MUTED, false, "C");
}

function _title(s, label, title, col) {
  _txt(s, label, P, 8, 300, 12, 6.5, col, true);
  _txt(s, title, P, 20, W - P*2, 26, 14, WHITE, true);
  _line(s, P, 50, W - P, 50, BORDER);
}

// ── SLIDE 01: COVER ──────────────────────────────────────────────────────────
function s01(pres) {
  var s = pres.appendSlide(SlidesApp.PredefinedLayout.BLANK);
  _bg(s, BG);
  _rect(s, 0, 0, 3, H, CYAN);
  _rect(s, W-3, 0, 3, H, CYAN);

  _txt(s, "ASLAN PIXEL", W/2-190, 60, 380, 58, 42, CYAN, true, "C");
  _txt(s, "The World's First Agentic DeFi Guild on Hedera",
       W/2-190, 124, 380, 20, 11, WHITE, false, "C");
  _txt(s, "AI AGENTS  ·  REAL TRANSACTIONS  ·  FULLY ONCHAIN",
       W/2-190, 148, 380, 14, 7.5, DIM, false, "C");

  // Stat badges
  var badges = [
    {t:"6+ AGENTS",        c:CYAN},
    {t:"5 CONTRACTS",      c:GREEN},
    {t:"LIVE ON TESTNET",  c:GOLD},
  ];
  var bw = 160; var bx0 = W/2 - (bw*3 + 16)/2;
  badges.forEach(function(b, i) {
    var bx = bx0 + i*(bw+8);
    _card(s, bx, 170, bw, 24, b.c);
    _txt(s, b.t, bx+8, 177, bw-16, 12, 7, b.c, true, "C");
  });

  _txt(s, "aslanpixel.vercel.app", W/2-110, 202, 220, 14, 8.5, HEDERA, false, "C");

  // 6 sprites: corners
  var sp = [
    {id:"scout",      x:6,   y:20 },
    {id:"strategist", x:670, y:20 },
    {id:"executor",   x:6,   y:168},
    {id:"archivist",  x:670, y:168},
    {id:"sentinel",   x:6,   y:316},
    {id:"treasurer",  x:670, y:316},
  ];
  sp.forEach(function(p) { _sprite(s, p.id, p.x, p.y, 44); });

  // Tagline at bottom
  _txt(s, "Think.  Transact.  Collaborate.  On Hedera.",
       W/2-190, 226, 380, 14, 8, CYAN, true, "C");

  _rect(s, 0, CB, W, FT, CARD);
  _line(s, 0, CB, W, CB, CYAN);
  _txt(s, "ASLAN PIXEL  //  Hedera Hello Future Apex Hackathon 2026",
       P, CB+5, W-P*2, FT-7, 6, MUTED, false, "C");
}

// ── SLIDE 02: PROBLEM ────────────────────────────────────────────────────────
// 3 cards each with icon + title + 4 bullet points — fills full height
function s02(pres) {
  var s = pres.appendSlide(SlidesApp.PredefinedLayout.BLANK);
  _chrome(s, RED);
  _title(s, "01  THE PROBLEM", "DeFi Agents Are Broken", RED);

  // Quote bar
  _txt(s, '"You send funds.  You wait.  You have no idea what happens next."',
       P, TH, W-P*2, 18, 9, WHITE, true, "C", true);

  var cy  = TH + 22;          // cards y=78
  var ch  = CB - cy;           // = 305
  var cw  = Math.floor((W - P*2 - 16) / 3); // = 216
  var cards = [
    {icon:"⚠", t:"No Transparency",
     pts:["• TX submits — you see nothing",
          "• No audit trail, no stream",
          "• Can't verify what executed",
          "• DeFi is a black box"],
     sub:"$2.8B lost to opaque protocol failures (2023)", c:RED},
    {icon:"⚡", t:"Can't Coordinate",
     pts:["• Single agent = single point of failure",
          "• Multi-step DeFi needs specialization",
          "• No vote, no veto, no consensus",
          "• One bot can't do it all"],
     sub:"90% of DeFi bots fail at complex multi-step ops", c:ORANGE},
    {icon:"◎", t:"Zero Accountability",
     pts:["• TX fails — who's responsible?",
          "• No proof of decision-making",
          "• No onchain agent identity",
          "• No reputation, no history"],
     sub:"Centralized bots = no audit, no trust, no proof", c:GOLD},
  ];
  cards.forEach(function(col, i) {
    var x = P + i * (cw + 8);
    _card(s, x, cy, cw, ch, col.c);
    _rect(s, x, cy, cw, 3, col.c);
    _txt(s, col.icon, x+10, cy+8,  26, 24, 18, col.c, true);
    _txt(s, col.t,    x+10, cy+38, cw-16, 16, 10, col.c, true);
    _line(s, x+8, cy+58, x+cw-8, cy+58, BORDER);
    var lineH = 22;
    col.pts.forEach(function(pt, j) {
      _txt(s, pt, x+10, cy+64 + j*lineH, cw-16, lineH, 7.5, DIM);
    });
    _line(s, x+8, cy+158, x+cw-8, cy+158, BORDER);
    _txt(s, col.sub, x+10, cy+164, cw-16, ch-170, 6.5, MUTED, false, "L", true);
  });
}

// ── SLIDE 03: SOLUTION ───────────────────────────────────────────────────────
// Left: big "what it is" block. Right: 4 key differentiators stacked
function s03(pres) {
  var s = pres.appendSlide(SlidesApp.PredefinedLayout.BLANK);
  _chrome(s, CYAN);
  _title(s, "02  THE SOLUTION", "An Autonomous Guild That Lives Onchain", CYAN);

  var lw = 290; var rx = P + lw + 12; var rw = W - rx - P;

  // Left: big concept card
  _card(s, P, TH, lw, CB - TH, CYAN);
  _rect(s, P, TH, lw, 3, CYAN);
  _txt(s, "◈  ASLAN PIXEL", P+12, TH+10, lw-20, 20, 12, CYAN, true);
  _line(s, P+8, TH+34, P+lw-8, TH+34, BORDER);
  var bigDesc = "A guild of AI agents that\nthink, debate, and execute\nreal DeFi transactions —\ntogether — on Hedera.\n\nEvery decision is a vote.\nEvery action is a TX.\nEvery step is onchain.";
  _txt(s, bigDesc, P+12, TH+40, lw-20, 120, 8.5, WHITE);

  _line(s, P+8, TH+168, P+lw-8, TH+168, BORDER);
  _txt(s, "NOT a chatbot.\nNOT a single agent.\nNOT off-chain.", P+12, TH+174, lw-20, 56, 8, DIM, false, "L", true);

  // sprite row at bottom of left card
  var sprAgents = ["scout","executor","archivist"];
  var sprSz = 34; var sprW = Math.floor((lw - 20) / 3);
  sprAgents.forEach(function(ag, i) {
    var sx = P + 10 + i * sprW + Math.floor((sprW - sprSz) / 2);
    _sprite(s, ag, sx, TH + 234, sprSz);
  });

  // Right: 4 diff cards stacked
  var dh = Math.floor((CB - TH - 9) / 4); // = 79
  var diffs = [
    {icon:"◈", t:"AI-POWERED AGENTS",
     d:"Any LLM per agent — GPT, Gemini, Claude.\nIn-character reasoning, confidence scoring.", c:CYAN},
    {icon:"▶", t:"REAL EVM TRANSACTIONS",
     d:"Simulate → Sign → Submit on Hedera Chain 296.\nClickable HashScan link for every TX.", c:GREEN},
    {icon:"◉", t:"x402 PAYMENT GATE",
     d:"1 HBAR per quest. HTTP 402 protocol.\nPay-per-use, no subscription, no custodian.", c:GOLD},
    {icon:"▣", t:"IMMUTABLE AUDIT TRAIL",
     d:"QuestReceipt.sol stores every decision onchain.\nHCS messages — tamper-proof, public forever.", c:PURPLE},
  ];
  diffs.forEach(function(d, i) {
    var y = TH + i * (dh + 3);
    _card(s, rx, y, rw, dh, d.c);
    _rect(s, rx, y, 3, dh, d.c);
    _txt(s, d.icon + "  " + d.t, rx+10, y+8,  rw-16, 16, 9, d.c, true);
    _line(s, rx+10, y+28, rx+rw-10, y+28, BORDER);
    _txt(s, d.d, rx+10, y+34, rw-16, dh-40, 7.5, DIM);
  });
}

// ── SLIDE 04: AGENTS ─────────────────────────────────────────────────────────
// 3×2 grid with sprites — expandable guild
function s04(pres) {
  var s = pres.appendSlide(SlidesApp.PredefinedLayout.BLANK);
  _chrome(s, GOLD);
  _title(s, "03  THE GUILD", "6 Specialized Agents — Infinitely Expandable", GOLD);

  var cw  = Math.floor((W - P*2 - 20) / 3);  // 214
  var ch  = Math.floor((CB - TH - 8)  / 2);   // 159
  var gx2 = Math.floor((W - P*2 - cw*3) / 2); // gap between cols

  var agents = [
    {id:"scout",      icon:"◈", name:"NEXUS",    role:"Intel & Recon",
     desc:"Scans HCS stream. Detects anomalies.\nSets quest context. First to speak.",
     proto:"HCS-10  ·  Mirror Node", c:CYAN},
    {id:"strategist", icon:"▲", name:"ORYN",     role:"Strategy Engine",
     desc:"Models 3 execution paths. Live TVL.\nPicks optimal route. Cast the deciding vote.",
     proto:"Hedera AgentKit  ·  SaucerSwap", c:GOLD},
    {id:"sentinel",   icon:"◆", name:"DRAX",     role:"Risk Sentinel",
     desc:"Enforces max 5% position. Slippage ≤ 0.25%.\nHas VETO power — no TX passes without sign-off.",
     proto:"PolicyManager.sol  ·  EIP-4337", c:GREEN},
    {id:"treasurer",  icon:"◉", name:"LYSS",     role:"Treasury Keeper",
     desc:"Holds 500 HBAR gas reserve. Tracks USDC.\nPays agents their session wage per op.",
     proto:"HTS  ·  USDCFaucet.sol", c:PURPLE},
    {id:"executor",   icon:"▶", name:"VEX",      role:"TX Executor",
     desc:"Simulates gas. Signs. Submits to Hedera EVM.\nLinks every TX to HashScan.",
     proto:"EVM Chain 296  ·  Remix", c:ORANGE},
    {id:"archivist",  icon:"▣", name:"KAEL",     role:"Ledger Archivist",
     desc:"Writes QuestReceipt.sol onchain. Permanent.\nReputation scores updated after every quest.",
     proto:"QuestReceipt.sol  ·  HCS", c:RED},
  ];

  agents.forEach(function(ag, i) {
    var col = i % 3; var row = Math.floor(i / 3);
    var x = P + col * (cw + gx2);
    var y = TH + row * (ch + 8);
    _card(s, x, y, cw, ch, ag.c);
    _rect(s, x, y, cw, 2, ag.c);
    _sprite(s, ag.id, x+6, y+6, 36);
    _txt(s, ag.icon + " " + ag.name, x+48, y+6,  cw-54, 16, 10, ag.c, true);
    _txt(s, ag.role,                 x+48, y+24, cw-54, 12, 6.5, DIM);
    _line(s, x+6, y+46, x+cw-6, y+46, BORDER);
    _txt(s, ag.desc,  x+8, y+52, cw-14, 52, 7.5, WHITE);
    _line(s, x+6, y+108, x+cw-6, y+108, BORDER);
    _txt(s, ag.proto, x+8, y+112, cw-14, ch-118, 6, MUTED);
  });

  // "+" card hint
  _txt(s, "+ Register your own agent  →  appears live in the pixel map",
       P, CB-14, W-P*2, 12, 6.5, MUTED, false, "C");
}

// ── SLIDE 05: HOW IT WORKS ───────────────────────────────────────────────────
// 7 steps left + right panel with protocol tags
function s05(pres) {
  var s = pres.appendSlide(SlidesApp.PredefinedLayout.BLANK);
  _chrome(s, GREEN);
  _title(s, "04  HOW IT WORKS", "One Quest. Seven Steps. Fully Onchain.", GREEN);

  var lw  = 218; var rx = P + lw + 8; var rw = W - rx - P;
  var sh  = Math.floor((CB - TH) / 7); // 46

  var steps = [
    {n:"① GUILD VOTE",     sub:"HCS-10  ·  EIP-4337",   c:CYAN},
    {n:"② x402 PAY GATE",  sub:"1 HBAR  ·  MetaMask",   c:GOLD},
    {n:"③ NEXUS SCANS",    sub:"Mirror Node  ·  HCS",    c:CYAN},
    {n:"④ ORYN MODELS",    sub:"AgentKit  ·  SaucerSwap",c:GOLD},
    {n:"⑤ DRAX VALIDATES", sub:"PolicyManager.sol",      c:GREEN},
    {n:"⑥ VEX EXECUTES",   sub:"Hedera EVM Chain 296",   c:ORANGE},
    {n:"⑦ KAEL ARCHIVES",  sub:"QuestReceipt.sol  ·  HCS",c:RED},
  ];
  steps.forEach(function(st, i) {
    var y = TH + i * sh;
    _card(s, P, y, lw, sh - 1, st.c);
    _txt(s, st.n,   P+8, y+5,  lw-14, 16, 8, st.c, true);
    _txt(s, st.sub, P+8, y+22, lw-14, 14, 6, MUTED);
  });

  // Right: outcome panel
  _card(s, rx, TH, rw, CB - TH, GREEN);
  _txt(s, "WHAT YOU GET", rx+12, TH+8, rw-20, 16, 9, GREEN, true);
  _line(s, rx+8, TH+28, rx+rw-8, TH+28, BORDER);

  var outcomes = [
    {t:"x402 gate:  1 HBAR fee enforced before execution",     c:GOLD},
    {t:"EVM TX with full simulation — no surprises",           c:CYAN},
    {t:"HashScan link:  your TX, click to verify",             c:GREEN},
    {t:"QuestReceipt.sol:  immutable hash of every decision",  c:PURPLE},
    {t:"HCS message:  all agents notified, subscribed",        c:HEDERA},
    {t:"Agent reputation updated onchain (0–1000 score)",      c:ORANGE},
    {t:"SSE stream:  watch every step live in browser",        c:WHITE},
  ];
  var rih = Math.floor((CB - TH - 32) / 7);
  outcomes.forEach(function(o, i) {
    var ry = TH + 32 + i * rih;
    _txt(s, "✓  " + o.t, rx+12, ry+2, rw-20, rih-2, 7.5, o.c, true);
    if (i < outcomes.length-1)
      _line(s, rx+16, ry+rih, rx+rw-16, ry+rih, BORDER);
  });
}

// ── SLIDE 06: PROTOCOL STACK ─────────────────────────────────────────────────
// 5 protocols x402 / EIP-4337 / AgentKit / HCS-10 / Hedera EVM
function s06(pres) {
  var s = pres.appendSlide(SlidesApp.PredefinedLayout.BLANK);
  _chrome(s, HEDERA);
  _title(s, "05  PROTOCOLS", "Built on Open Standards — Not Duct Tape", HEDERA);

  var lh = Math.floor((CB - TH - 4) / 5); // 64
  var lw = W - P*2; var dl = 150;

  var protos = [
    {icon:"⬡", l:"x402",            sub:"HTTP Payment Protocol",
     spec:"USDCFaucet.sol",
     d:"Standard HTTP 402 response triggers 1 HBAR payment before quest execution.\nNo custodian. No escrow. Direct wallet. Works with any HTTP client.", c:GOLD},
    {icon:"◉", l:"EIP-4337",         sub:"Account Abstraction",
     spec:"Chain 296  ·  userOp",
     d:"Agent session keys sign TXs without exposing the master wallet.\nBundler on Hedera EVM — gas sponsored by guild treasury (LYSS).", c:PURPLE},
    {icon:"◈", l:"Hedera AgentKit",  sub:"Official Hedera SDK",
     spec:"HashConnect  ·  Mirror",
     d:"Official SDK wrapping HCS, HTS, Mirror Node, EVM in one interface.\nNEXUS, LYSS, and VEX all call AgentKit for every onchain operation.", c:CYAN},
    {icon:"▲", l:"HCS-10",           sub:"Agent Messaging Standard",
     spec:"Topic 0.0.5940171",
     d:"Every agent decision published as a tamper-proof consensus message.\n847 msgs/min — deterministic ordering, publicly auditable forever.", c:HEDERA},
    {icon:"▶", l:"Hedera EVM",       sub:"EVM-Compatible, Chain 296",
     spec:"Remix  ·  ethers.js v6",
     d:"5 Solidity contracts deployed via Remix IDE — real addresses, public.\nVEX simulates gas in tinyhbar before every single submit.", c:GREEN},
  ];
  protos.forEach(function(p, i) {
    var y = TH + i * (lh + 1);
    _card(s, P, y, lw, lh, p.c);
    _rect(s, P, y, 3, lh, p.c);
    _txt(s, p.icon + "  " + p.l, P+10, y+5,  dl-10, 18, 10, p.c, true);
    _txt(s, p.sub,                P+10, y+25, dl-10, 12, 6.5, DIM);
    _txt(s, p.spec,               P+10, y+40, dl-10, 12, 5.5, MUTED);
    _line(s, P+dl, y+4, P+dl, y+lh-4, BORDER);
    _txt(s, p.d, P+dl+10, y+5, lw-dl-16, lh-12, 7.5, DIM);
  });
}

// ── SLIDE 07: CONTRACTS ──────────────────────────────────────────────────────
// 4 deployed contracts with addresses
function s07(pres) {
  var s = pres.appendSlide(SlidesApp.PredefinedLayout.BLANK);
  _chrome(s, PURPLE);
  _title(s, "06  CONTRACTS", "5 Smart Contracts — Deployed, Public, Auditable", PURPLE);

  var lh = Math.floor((CB - TH - 12) / 4); // 78
  var lw = W - P*2; var dl = 248;

  var contracts = [
    {n:"AgentRegistry.sol",  a:"0x8B90AA6D…CC4",
     d:"Agent identities, reputations 0–1000, quest history.\nDynamic registration — anyone can onboard a new agent.", c:CYAN},
    {n:"QuestReceipt.sol",   a:"0x444f5895…C7D",
     d:"Immutable quest log: inputHash, outputHash, txHash, timestamp.\nPublicly readable. Nobody can delete or edit it. Ever.", c:GREEN},
    {n:"PolicyManager.sol",  a:"0xdBc14F4c…11E4",
     d:"DRAX enforces: max 5% position, slippage ≤ 0.25%.\nBlocks any quest that fails policy check before TX fires.", c:RED},
    {n:"MockUSDC + Faucet",  a:"0x152B…BF7  ·  0xCA05…B3953",
     d:"Testnet USDC with one-click drip faucet → 100 USDC.\nNo external service needed. Fully self-contained on testnet.", c:GOLD},
  ];
  contracts.forEach(function(ct, i) {
    var y = TH + i * (lh + 4);
    _card(s, P, y, lw, lh, ct.c);
    _rect(s, P, y, 3, lh, ct.c);
    _txt(s, ct.n, P+10, y+8,  dl-16, 18, 10, ct.c, true);
    _txt(s, ct.a, P+10, y+30, dl-16, 14, 6.5, MUTED);
    _line(s, P+dl, y+6, P+dl, y+lh-6, BORDER);
    _txt(s, ct.d, P+dl+10, y+8, lw-dl-16, lh-16, 8, DIM);
  });
}

// ── SLIDE 08: LIVE DEMO ──────────────────────────────────────────────────────
// 3×3 grid of live features — all working right now
function s08(pres) {
  var s = pres.appendSlide(SlidesApp.PredefinedLayout.BLANK);
  _chrome(s, ORANGE);
  _title(s, "07  LIVE DEMO", "Everything You're About to See Is REAL", ORANGE);

  var tw = Math.floor((W - P*2 - 16) / 3); // 216
  var th = Math.floor((CB - TH - 16) / 3); // 103

  var features = [
    {icon:"◈", t:"Pixel World Map",
     d:"NPCs patrol live.\nEach building = Hedera module.\nClick to enter.", c:CYAN},
    {icon:"▲", t:"Quest Runner",
     d:"Type intent → 7-agent stream\nfires instantly, live in browser.", c:GOLD},
    {icon:"◆", t:"Guild Vote Panel",
     d:"Watch each agent debate.\nDRAX can VETO in real-time.\nAnimated onchain.", c:GREEN},
    {icon:"⬡", t:"x402 Pay Gate",
     d:"MetaMask popup: 1 HBAR.\nNo payment = no quest.\nReal wallet, real TX.", c:PURPLE},
    {icon:"▶", t:"Live TX Timeline",
     d:"Every step streams via SSE.\nTX hash → HashScan link.\nNo mock data.", c:ORANGE},
    {icon:"▣", t:"Agent Dashboard",
     d:"Recharts quest history.\nReputation scores pulled\nlive from chain.", c:RED},
    {icon:"★", t:"Register an Agent",
     d:"Your agent ID → onchain.\nNPC spawns in pixel map.\nReal wallet required.", c:CYAN},
    {icon:"◉", t:"USDC Faucet",
     d:"100 testnet USDC in one\nclick. Cooldown enforced\nonchain. No backend.", c:GOLD},
    {icon:"⚡", t:"Auto-Quest Mode",
     d:"Fires every 9 minutes.\nGuild is always alive.\nDemo always running.", c:GREEN},
  ];
  features.forEach(function(f, i) {
    var col = i % 3; var row = Math.floor(i / 3);
    var x = P + col * (tw + 8);
    var y = TH + row * (th + 8);
    _card(s, x, y, tw, th, f.c);
    _rect(s, x, y, tw, 2, f.c);
    _txt(s, f.icon + "  " + f.t, x+8, y+6,  tw-14, 16, 8.5, f.c, true);
    _line(s, x+8, y+26, x+tw-8, y+26, BORDER);
    _txt(s, f.d, x+8, y+32, tw-14, th-40, 7.5, DIM);
  });
}

// ── SLIDE 09: WHY WE WIN ─────────────────────────────────────────────────────
// 6 judging criteria rows
function s09(pres) {
  var s = pres.appendSlide(SlidesApp.PredefinedLayout.BLANK);
  _chrome(s, GREEN);
  _title(s, "08  WHY WE WIN", "Every Judging Criterion. Checked.", GREEN);

  _sprite(s, "strategist", P, TH-2, 26);
  _sprite(s, "sentinel",   W-P-26, TH-2, 26);
  _txt(s, '"Autonomous actors that think, transact, and collaborate — leveraging Hedera fast, low-cost microtransactions"',
       P+32, TH, W-P*2-64, 18, 7, MUTED, false, "C", true);
  _line(s, P, TH+20, W-P, TH+20, BORDER);

  var rStart = TH + 24;
  var rh = Math.floor((CB - rStart - 4) / 6); // 59
  var lw = W - P*2; var dl = 156; var evW = lw - dl - 74;

  var rows = [
    {c:"Think",             ev:"Any LLM per agent. Confidence %, multi-branch reasoning, in-character philosophy.",    col:CYAN},
    {c:"Transact",          ev:"Real EVM TXs on Hedera Chain 296. Simulate→Sign→Submit. HashScan link every time.",    col:GREEN},
    {c:"Collaborate",       ev:"6+ agent guild vote. Sequential handoff. DRAX VETO. Consensus before any TX fires.",   col:GOLD},
    {c:"Consensus",         ev:"HCS-10: every action is a consensus message. QuestReceipt.sol: permanent audit trail.", col:HEDERA},
    {c:"Microtransactions", ev:"x402: 1 HBAR gate per quest. Agent session wages: 0.001–0.05 USDC per operation.",     col:ORANGE},
    {c:"Transparency",      ev:"100% streamed live + archived onchain. Mirror Node + HashScan: public, forever.",       col:PURPLE},
  ];
  rows.forEach(function(r, i) {
    var y = rStart + i * (rh + 1);
    _card(s, P, y, lw, rh, r.col);
    _rect(s, P, y, 3, rh, r.col);
    _txt(s, r.c, P+10, y + rh/2 - 8, dl-16, 16, 9, r.col, true);
    _line(s, P+dl, y+4, P+dl, y+rh-4, BORDER);
    _txt(s, r.ev, P+dl+10, y + rh/2 - 8, evW, 16, 7.5, WHITE);
    _txt(s, "✓✓✓", W-P-66, y + rh/2 - 8, 58, 16, 8.5, r.col, true, "R");
  });
}

// ── SLIDE 10: CLOSING ────────────────────────────────────────────────────────
function s10(pres) {
  var s = pres.appendSlide(SlidesApp.PredefinedLayout.BLANK);
  _bg(s, BG);
  _rect(s, 0, 0, 3, H, CYAN);
  _rect(s, W-3, 0, 3, H, CYAN);

  _txt(s, "The Guild is Live.", W/2-210, 32, 420, 52, 34, WHITE, true, "C");
  _txt(s, "6+ agents  ·  5 contracts  ·  every decision onchain  ·  right now",
       W/2-200, 88, 400, 16, 8.5, DIM, false, "C");
  _line(s, P, 108, W-P, 108, BORDER);

  // 6 sprites evenly spaced
  var sprSz = 44; var sprSpace = (W - P*2) / 6;
  var agents10 = ["scout","strategist","sentinel","treasurer","executor","archivist"];
  for (var i = 0; i < 6; i++) {
    var sx = P + i * sprSpace + (sprSpace - sprSz) / 2;
    _sprite(s, agents10[i], Math.round(sx), 116, sprSz);
  }

  // 4 roadmap cards
  var nx = Math.floor((W - P*2 - 8) / 2); // 328
  var nh = 56;
  var next = [
    {icon:"◈", l:"HCS-10 Agent Standard", sub:"Full Hashgraph Online compliance",      c:CYAN},
    {icon:"⬡", l:"Account Abstraction",    sub:"Gasless TXs with session key signing", c:GOLD},
    {icon:"▲", l:"Agent Marketplace",      sub:"Custom workflows minted as NFTs",      c:PURPLE},
    {icon:"★", l:"Cross-Chain Quests",     sub:"Hedera + EVM via Wormhole bridge",     c:GREEN},
  ];
  next.forEach(function(n, i) {
    var x = P + (i % 2) * (nx + 8);
    var y = 170 + Math.floor(i / 2) * (nh + 4);
    _card(s, x, y, nx, nh, n.c);
    _txt(s, n.icon + "  " + n.l, x+10, y+8,  nx-16, 18, 9, n.c, true);
    _txt(s, n.sub, x+10, y+30, nx-16, 14, 7, DIM);
  });

  // CTA
  var ctaY = CB - 38;
  _card(s, W/2-160, ctaY, 320, 28, CYAN);
  _txt(s, "aslanpixel.vercel.app  —  try it now", W/2-148, ctaY+7, 296, 14, 9, CYAN, true, "C");

  _rect(s, 0, CB, W, FT, CARD);
  _line(s, 0, CB, W, CB, CYAN);
  _txt(s, "ASLAN PIXEL  //  Hedera Hello Future Apex Hackathon 2026",
       P, CB+5, W-P*2, FT-7, 6, MUTED, false, "C");
}

// ── MAIN ─────────────────────────────────────────────────────────────────────
var PRESENTATION_ID = "1E_9oPIpxl9yY_QnZnfGX155Nw0J850B3BHxSUPB6c4g";

function createAslanDeck() {
  var pres = PRESENTATION_ID
    ? SlidesApp.openById(PRESENTATION_ID)
    : SlidesApp.create("AslanPixel — Hedera Hello Future Apex Hackathon 2026");

  var slides = pres.getSlides();
  slides.forEach(function(sl) { sl.remove(); });

  s01(pres);
  s02(pres);
  s03(pres);
  s04(pres);
  s05(pres);
  s06(pres);
  s07(pres);
  s08(pres);
  s09(pres);
  s10(pres);

  Logger.log("Done: " + pres.getUrl());
}
