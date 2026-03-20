# Aslan Pixel -- Complete UI/UX Design Prompt for Stitch AI

> Generate every screen of the Aslan Pixel mobile app. This is a social financial network + idle pixel world + broker-connected portfolio app, targeting Thai retail investors aged 18-35 who love gaming aesthetics. The app is built in Flutter for iOS and Android.

---

## 1. App Overview

**Name:** Aslan Pixel
**Tagline (TH):** เครือข่ายการเงินสังคม และโลกพิกเซลที่รอคุณ
**Tagline (EN):** Social Financial Network + Idle Pixel World + Portfolio App

**Core Pillars:**
1. **Home Dashboard** -- daily streak, agents, predictions, market snapshot, ranking
2. **Pixel World** -- a private room powered by a Flame game engine, with NPC characters, room items, and AI agent missions
3. **Portfolio / Finance** -- prediction events, AI market insights, crypto prices from Binance, broker demo account
4. **Social Feed** -- user posts, likes, follows, bilingual content (Thai + English)
5. **Profile** -- avatar, badges, XP/level, privacy settings, coin balance

**Target Audience:** Thai retail investors / crypto enthusiasts who like gamified experiences
**Primary Language:** Thai (all labels in Thai with English fallback)
**Platform:** Mobile-first (iPhone + Android), portrait orientation only

---

## 2. Design System

### 2.1 Color Palette (AslanWealth Brand)

> Based on the AslanWealth.com brand identity. Dark mode is the primary theme.
> The app blends the professional AslanWealth fintech palette with pixel art game accents.

**Brand Core (from AslanWealth)**

| Token | Hex | Usage |
|-------|-----|-------|
| `aslanBlue` | `#1842DD` | Brand primary — buttons, links, active nav (light mode) |
| `aslanBlueDark` | `#4B8BF5` | Brand primary — buttons, links, active nav (dark mode) |
| `aslanBlueLight` | `#79B8FF` | Hover/highlight states |
| `aslanBlueAccent` | `#58A6FF` | Selected nav items (dark mode) |
| `aslanGold` | `#C9A056` | Premium, wealth, VIP features, accent |
| `aslanYellow` | `#FBBD23` | Warnings, coins, rewards |
| `aslanError` | `#FF2323` | Errors, losses, sell buttons |
| `aslanSuccess` | `#10B981` | Profit, success, gains |
| `indigo` | `#6366F1` | AslanWealth web brand highlight (loading spinner) |

**Dark Mode (Primary Theme)**

| Token | Hex | Usage |
|-------|-----|-------|
| `background` | `#0D1117` | Primary scaffold/background (GitHub-style dark) |
| `surface` | `#161B22` | Card backgrounds, input fields |
| `surfaceElevated` | `#1C2128` | Elevated/modal surfaces, shimmer base |
| `border` | `#2A2F36` | Card borders, dividers |
| `borderAccent` | `#30363D` | Chart grid, chat borders, AppBar border |
| `textPrimary` | `#E6EDF3` | Main body text |
| `textSecondary` | `#CDD5DE` | Subtitles, descriptions |
| `textTertiary` | `#ADB5BD` | Muted labels, timestamps |
| `textDisabled` | `#7D8590` | Disabled text, placeholders, unselected nav |
| `appBarBg` | `#161B22` | AppBar background |
| `bottomNavBg` | `#0D1117` | Bottom navigation background |

**Light Mode (Secondary)**

| Token | Hex | Usage |
|-------|-----|-------|
| `background` | `#F5F5F5` | Primary scaffold/background |
| `surface` | `#FFFFFF` | Card backgrounds |
| `textPrimary` | `#000000` | Main body text |
| `textSecondary` | `#303030` | Subtitles |
| `textTertiary` | `#504F5A` | Muted labels |
| `inputBg` | `#FFF7E0` | Input field warm background |
| `border` | `#EDE7D8` | Card borders |

**Pixel Game Accents (layered on top of brand palette)**

| Token | Hex | Usage |
|-------|-----|-------|
| `neonGreen` | `#00F5A0` | Game CTA buttons, profit indicators, analyst agent |
| `coinGold` | `#FFD700` | Coin icon, reward amounts |
| `cyberPurple` | `#7B2FFF` | Risk agent, premium, weekly quests |
| `cyan` | `#00D9FF` | Social agent, XP, info elements |
| `gameBackground` | `#081020` | Flame game canvas backdrop |
| `xpBlue` | `#4FC3F7` | XP progress bars |
| `fireOrange` | `#FF6B35` | Streak fire, urgent |
| `heartRed` | `#FF4D6A` | Likes, hearts |

**Status Colors (consistent both modes)**

| Token | Hex | Usage |
|-------|-----|-------|
| `statusWaiting` | `#E1C363` | Pending tasks |
| `statusCancelled` | `#D4444E` | Failed/cancelled |
| `statusCompleted` | `#C5DA9E` | Completed tasks |

**Chart Colors (dark mode)**

| Token | Hex | Usage |
|-------|-----|-------|
| `chartBg` | `#161B22` | Chart canvas |
| `chartGrid` | `#30363D` | Grid lines |
| `chartText` | `#8B949E` | Axis labels |
| `chartCrosshair` | `#E6EDF3` | Crosshair/pointer |

**Web Brand Reference**

| Token | Hex | Source |
|-------|-----|-------|
| `webIndigo` | `#6366F1` | AslanWealth.com spinner/accent |
| `webLavender` | `#E5E4FF` | AslanWealth.com border/light accent |
| `webDark` | `#1A1A1A` | AslanWealth.com text |
| `webGray` | `#666666` | AslanWealth.com secondary text |
| `webFont` | DM Sans | AslanWealth.com font family |

### 2.2 Typography

- **Font family:** DM Sans (AslanWealth brand font) for headings + UI labels; system default (SF Pro / Roboto) for Thai body text. Google Fonts: `fonts.googleapis.com/css2?family=DM+Sans:wght@400;600&display=swap`
- **Heading 1:** 34px, w900, letterSpacing -0.5 (app name on onboarding)
- **Heading 2:** 26px, w900 (section titles on onboarding steps)
- **Heading 3:** 22px, bold (welcome banner greeting)
- **Title:** 18-20px, w700 (AppBar titles, section headers)
- **Body:** 14-15px, w400/w500 (card content, descriptions)
- **Caption:** 11-12px, w400/w600 (labels, timestamps, chip text)
- **Micro:** 9-10px, w500 (badge labels, disclaimer text)

### 2.3 Spacing

- **Page padding:** 16px horizontal
- **Card padding:** 14-20px
- **Card margin between:** 8-14px vertical
- **Card border radius:** 10-16px
- **Button border radius:** 10-14px
- **Button height:** ~48-56px (full-width CTAs)
- **Bottom nav bar height:** standard + 95% opacity navy background

### 2.4 Icon System

All icons are **8-bit pixel art PNGs** loaded from `assets/sprites/ui/`. Available icons:
- `coin` -- gold coin (used with amounts)
- `star` -- XP star
- `quest` -- scroll/quest icon
- `xp` -- experience badge
- `lock` -- locked content
- `home` -- house (tab bar)
- `world` -- globe/pixel world (tab bar)
- `chart` -- candlestick chart (tab bar)
- `social` -- people/chat (tab bar)
- `profile` -- person silhouette (tab bar)
- `trophy` -- gold trophy
- `fire` -- streak fire
- `heart` -- like/heart
- `bell` -- notification bell
- `settings` -- gear
- `store` -- shop bag
- `sword` -- agent weapon
- `shield` -- security/privacy
- `potion` -- boost item

**Rendering rule:** All pixel art images must use `FilterQuality.none` -- NO anti-aliasing, NO smoothing. Pixels must be crisp and blocky.

### 2.5 Component Library

**Cards:** Dark navy (`#162040`) background, 1px `#1E3050` border, 12-16px border radius. Active/highlighted cards get a colored border glow (0.2-0.3 alpha of the accent color, blurRadius 12-16).

**Buttons:**
- Primary: Neon green `#00F5A0` background, dark navy `#0A1628` text
- Secondary/Outlined: Transparent background, 1px colored border, colored text
- Destructive: Red `#FF4D4F` border and text
- Disabled: 40% alpha of the active color

**Text Fields:** `#0D1F3C` fill, `#1E3050` border, 10px border radius. Focused: `#00F5A0` border 1.5px. Prefix icon in `#3D5A78`. Placeholder text in `#3D5A78`.

**Chips/Badges:** Colored background at 12-15% alpha, 1px border at 40-50% alpha, 6-8px border radius.

**Bottom Sheets:** Background `#0F2040` or `#12213A`, top radius 20px, drag handle bar (40x4px, white 20% alpha).

**Shimmer/Loading:** Base `#162040`, highlight `#1C2A4E`, pulsing animation.

**Glow Effect:** Colored `BoxShadow` with blurRadius 8-24 and alpha 0.2-0.4 on active/selected elements.

---

## 3. Screen-by-Screen Specifications

---

### 3.1 ONBOARDING (5 Steps)

**Route:** `/onboarding`
**Transition:** Horizontal page swipe (programmatic, no free-swipe)

**Shared Layout (all 5 steps):**
- Top bar: 5 animated progress dots (active dot = 28px wide neon green with glow, inactive = 8px circle in `#1E3050`) + "ข้าม" (Skip) text link on the right (hidden on last step)
- Content area (Expanded)
- Bottom: Full-width CTA button, 56px tall, neon green, 14px border radius

#### Step 1: Intro
- **Purpose:** Welcome splash
- **Layout:**
  - Centered vertically
  - Animated logo: 140x140px circular container with `#162040` background, pulsing glow effect (neon green + cyber purple shadows, alternating 0.35-1.0 alpha over 1800ms)
  - Inside logo: `assets/images/logo_280.png` clipped to circle
  - Below: "Aslan Pixel" text (34px, w900, textPrimary)
  - Below: Thai tagline "เครือข่ายการเงินสังคม และโลกพิกเซลที่รอคุณ" (17px, textSecondary, centered, 2 lines)
  - Below: 4 feature chips in a `Wrap` layout:
    - "วิเคราะห์พอร์ต" with chart icon
    - "โลกพิกเซล" with gamepad icon
    - "Social Feed" with people icon
    - "AI Agents" with robot icon
  - Each chip: `#162040` background, `#1E3050` border, 20px radius, neon green icon, textSecondary label
- **Button text:** "เริ่มต้น"
- **States:** Default only (no data loading)

#### Step 2: Avatar Picker
- **Purpose:** Choose pixel art character
- **Layout:**
  - Title: "เลือกตัวละครของคุณ" (26px, w900)
  - Subtitle: "ตัวละครนี้จะปรากฏในโลกพิกเซลของคุณ" (14px, textSecondary)
  - 4x2 grid of avatar cards (crossAxisCount=4, aspectRatio 0.72)
  - 8 avatars: Nexus (Analyst), Valen (Scout), Lyra (Trader), Sora (Hacker), Riven (Influencer), Kai (Wizard), Specter (Agent), Drako (Tycoon)
  - Each card: pixel art sprite image (FilterQuality.none), name below (11px, w800), role (9.5px, w500)
  - **Selected state:** Scale 1.05x, gradient border (neon green to gold), gold+green glow shadows, name turns neon green, role turns gold
  - **Unselected state:** `#1E3050` border, `#162040` background
- **Button text:** "เลือกแล้ว!"

#### Step 3: Market Focus
- **Purpose:** Choose investment market interest
- **Layout:**
  - Title: "คุณสนใจตลาดแบบไหน?" (26px, w900)
  - Subtitle: "เลือกตลาดที่คุณอยากติดตาม" (14px, textSecondary)
  - 2x2 grid of option cards (crossAxisCount=2, spacing 14):
    - คริปโต (bitcoin icon)
    - อัตราแลกเปลี่ยน (swap icon)
    - หุ้น (chart icon)
    - ทุกตลาด (globe icon)
  - Each card: 40px centered icon, 15px bold label below
  - **Selected:** Primary border 2px, primary tint background (8% alpha), green glow shadow, icon + text turn neon green
  - **Unselected:** `#1E3050` border 1px, `#162040` background
- **Button text:** "ถัดไป"

#### Step 4: Risk Style
- **Purpose:** Choose investment risk tolerance
- **Layout:**
  - Title: "สไตล์การลงทุนของคุณ?" (26px, w900)
  - Subtitle: "เราจะปรับ Agent ให้เข้ากับคุณ" (14px, textSecondary)
  - 3 vertical option cards (full-width, 20px horizontal padding, 20px vertical):
    - สุขุม (meditation icon) -- "เน้นมั่นคง ความเสี่ยงต่ำ"
    - สมดุล (balance icon) -- "เติบโตพอดี ความเสี่ยงปานกลาง"
    - กล้าหาญ (fire icon) -- "ผลตอบแทนสูง ความเสี่ยงสูง"
  - Each: 36px icon left, title (17px, w800) + subtitle (13px, w500) right
  - **Selected:** Same glow treatment as Step 3, plus green checkmark icon on right
- **Button text:** "ถัดไป"

#### Step 5: Username
- **Purpose:** Set display name
- **Layout:**
  - Title: "ตั้งชื่อตัวละคร" (26px, w900, centered)
  - Subtitle: "ชื่อที่คนอื่นในโลกพิกเซลจะเห็น" (14px, textSecondary, centered)
  - Avatar preview card: 130x160px, gradient border (neon green to gold), green+gold glow, character sprite + name + role inside
  - TextField: Max 20 chars, @ prefix icon, hint "เช่น PixelTrader99"
  - Helper text: "ไม่ต้องห่วง — แก้ไขได้ภายหลังในโปรไฟล์" (12px, textDisabled)
- **Button text:** "เข้าสู่โลก"
- **States:** Loading (spinner replaces button text when submitting)

---

### 3.2 SIGN IN

**Route:** `/signin`
**Transition:** Fade

**Layout (top to bottom):**
1. **Header background:** Top 32% of screen, gradient from primary at 10% alpha down to scaffold background, overlaid with subtle pixel grid (20px step, 7% alpha lines)
2. **Pixel Logo:** 56x56px CustomPaint 5x5 diamond pattern in neon green with glow
3. **App name:** "ASLAN PIXEL" (20sp, w900, neon green, letterSpacing 4, text shadow)
4. **Subtitle:** "ตลาดการเงิน · โลกพิกเซล · โปรไฟล์นักลงทุน" (9sp, textSecondary)
5. **Form card:** `#162040` background, `#1E3050` border, 16px radius, containing:
   - "เข้าสู่ระบบ" title (15sp, bold)
   - Email field (hint: "อีเมล", @ icon)
   - Password field (hint: "รหัสผ่าน", lock icon, show/hide toggle)
   - "ลืมรหัสผ่าน?" link (neon green, right-aligned)
   - "เข้าสู่ระบบ" primary button (full-width)
   - OR divider: "หรือ" between two `#1E3050` lines
   - "เข้าสู่ระบบด้วย Google" outlined button with white circle G icon
   - "เข้าสู่ระบบด้วย Apple" outlined button with Apple icon (iOS only)
   - "เข้าใช้แบบผู้เยี่ยมชม" underlined text link (textSecondary)
   - "ยังไม่มีบัญชี? สมัครสมาชิก" text + neon green link

**States:**
- Loading: Black 54% overlay with staggered dots wave animation in neon green
- Error: Floating SnackBar with red background
- Success: Navigate to `/home`

---

### 3.3 SIGN UP

**Route:** `/signup`
**Transition:** Right-to-left slide

**Layout:**
- AppBar: Transparent, back arrow, title "สมัครสมาชิก"
- Header: "สร้างบัญชีใหม่" (18sp, w900, neon green), subtitle "กรอกข้อมูลเพื่อเริ่มต้นใช้งาน Aslan Pixel"
- Fields:
  - ชื่อแสดง (display name, person icon)
  - อีเมล (email, @ icon)
  - รหัสผ่าน (password, lock icon, show/hide)
  - ยืนยันรหัสผ่าน (confirm password, lock icon, show/hide)
- Terms checkbox: "ฉันยอมรับ ข้อกำหนดการใช้งาน และ นโยบายความเป็นส่วนตัว" (linked text in neon green with underline)
- "สมัครสมาชิก" primary button
- "มีบัญชีอยู่แล้ว? เข้าสู่ระบบ" link

**States:** Same loading overlay as Sign In

---

### 3.4 FORGOT PASSWORD

**Route:** `/forgot-password`
**Transition:** Right-to-left slide

**Layout (Form view):**
- AppBar: "ลืมรหัสผ่าน" title with bottom border
- Lock reset icon (56px, neon green, centered)
- "รีเซ็ตรหัสผ่าน" title (16sp, bold, centered)
- "กรอกอีเมลของคุณ เราจะส่งลิงก์สำหรับตั้งรหัสผ่านใหม่" (12sp, textSecondary, centered)
- Email field
- "ส่งลิงก์รีเซ็ต" primary button

**Layout (Success view):**
- Email read icon (72px, neon green, centered)
- "ส่งอีเมลเรียบร้อยแล้ว!" title
- "กรุณาตรวจสอบกล่องจดหมายของคุณ และคลิกลิงก์เพื่อตั้งรหัสผ่านใหม่"
- "กลับไปหน้าเข้าสู่ระบบ" outlined button (neon green border)

---

### 3.5 MAIN TABS PAGE (Tab Bar Shell)

**Route:** `/home`
**This is the main container with 5 tabs.**

**Bottom Navigation Bar:**
- Background: `#0A1628` at 95% opacity
- 5 tabs with pixel art icons (24px) and labels (11px):
  1. **Home** (home icon)
  2. **Pixel** (world icon)
  3. **Portfolio** (chart icon)
  4. **Social** (social icon)
  5. **Profile** (profile icon)
- Selected: Neon green `#00F5A0`, opacity 1.0
- Unselected: `#E8F4F8` at 50% opacity, icon at 40% opacity
- Type: Fixed (all labels always visible)

---

### 3.6 HOME TAB (Dashboard)

**Purpose:** Central dashboard showing streak, economy, agents, predictions, market snapshot, ranking

**Layout (scrollable CustomScrollView with BouncingScrollPhysics):**

1. **Welcome Banner** (16px margin):
   - Gradient card: navy to `#0F2040`, 12px radius
   - Left: 4px neon green accent bar
   - "สวัสดี, Trader!" (22px, bold, textPrimary)
   - "ยินดีต้อนรับสู่ Aslan Pixel" (13px, 55% alpha)
   - Right side: Animated coin counter (gold coin icon + amount), level badge "Lv X" in gold chip

2. **Streak Section:**
   - StreakWarningBanner (if streak about to break)
   - DailyStreakWidget showing flame icon + streak day count

3. **XP Progress Bar:**
   - Shows current level, XP to next level, horizontal progress bar (neon green fill on `#162040` background)

4. **Agent Status Row:**
   - Section title: "เหล่า Agents" (16px, bold)
   - 4 equal-width agent chips in a row:
     - Analyst (neon green)
     - Scout (gold)
     - Risk (cyber purple)
     - Social (cyan)
   - Each chip: `#0F2040` background, colored border at 25% alpha, 10px radius
     - 28px circle with colored border containing pixel sword icon
     - Agent name (11px, w600)
     - Status "ว่าง" / idle label (10px, 45% alpha)

5. **Prediction Section:**
   - Title "Prediction Events" with "ดูทั้งหมด" neon green link (navigates to Finance page)
   - 2 PredictionCards:
     - BTC/USD: "Bitcoin จะทะลุ $100,000 ภายในสิ้นเดือนนี้หรือไม่?" (cost: 50 coins)
     - SET Index: "ดัชนี SET จะปิดบวกในสัปดาห์นี้หรือไม่?" (cost: 20 coins)
   - Each card shows symbol, Thai question, coin cost to participate

6. **Market Snapshot:**
   - Title "Market Snapshot"
   - 3 MarketTickerTiles (tappable, navigate to Crypto page):
     - BTC/USD $67,240 (+2.4%) -- green
     - ETH/USD $3,480 (-1.1%) -- red
     - SET 1,342.5 (+0.3%) -- green
   - Each tile: `#0F2040` background, symbol left, price center, change% badge right (green/red background at 15% alpha)

7. **Ranking Teaser:**
   - Title "อันดับของคุณ"
   - Card with gold border at 20% alpha:
     - 48px gold trophy icon in circle
     - "อันดับ #X" or "ยังไม่ติดอันดับ" (18px, bold)
     - "ประจำสัปดาห์ · Top N" subtitle
     - Chevron right icon
     - Tappable -> navigates to Leaderboard

**States:**
- Loading: Shimmer placeholders for balance
- Empty: Still shows all sections with zero/default values
- Loaded: Live data from Firestore streams

---

### 3.7 PIXEL WORLD TAB (Flame Game Room)

**Purpose:** Private pixel art room with NPC characters, room items, and AI agents

**Layout (full-screen Stack):**

1. **Game Area (full bleed):**
   - Flame `GameWidget` fills entire screen
   - Room background: Portrait 1:2 ratio pixel art PNGs from `assets/sprites/room_backgrounds/` (12 room themes)
   - NPC sprites: 48x48px pixel art, 4-directional walk animation (4 frames per direction)
   - 10 NPCs: banker, trader, champion, merchant, sysbot, pixelcat, analyst_senior, hacker, oracle, intern
   - NPCs auto-walk: random targets every 2-5s, 40px/s speed
   - 20% chance NPC shows quote bubble on arrival (bilingual quotes)
   - Room items positioned on floor grid using slotX/slotY

2. **Loading overlay:** Neon green CircularProgressIndicator centered

3. **Error overlay:** Red error text centered

4. **Agent Status Bar (bottom):**
   - 4 agent chips spanning full width (same style as home but more compact)
   - Each: colored border at 47% alpha, status icon + agent name + status label
   - Tappable -> opens Agent Detail bottom sheet

5. **AI Dialogue Bubble (above status bar):**
   - Appears when agent is tapped and AI responds
   - Rounded bubble with agent type color accent
   - Auto-dismisses

6. **Ready to Collect Badge (top center):**
   - Pulsing badge showing count of completed tasks
   - Appears only when completed tasks exist
   - Tap -> settles all tasks and shows RewardPopup

7. **3 Floating Action Buttons (right side, stacked vertically):**
   - Room Theme Shop FAB (cyan, wallpaper icon) at bottom+180
   - Agent Shop FAB (gold, store icon) at bottom+130
   - Customize Room FAB (cyber purple, customize icon) at bottom+80

**Agent Detail Bottom Sheet:**
- Dark background `#12213A`, top radius 20px
- Drag handle bar
- Agent avatar circle (colored background), name (18px, bold), status label (colored)
- "Send on Mission" button (full-width, agent color background)
- Opens Task Assignment Sheet for mission selection

**Task Assignment Sheet:**
- Full-screen modal bottom sheet (transparent background)
- Mission list with difficulty, duration, expected rewards

**Reward Popup (dialog):**
- Modal dialog with coin + XP rewards
- Confetti overlay animation
- Streak bonus display

---

### 3.8 FINANCE / PORTFOLIO TAB

**Route:** `/finance`
**Transition:** Right-to-left slide

**Layout: TabBar with 2 tabs**

**AppBar:** `#0F2040` background, "Finance" title, TabBar below:
- Tab 1: "Predictions" | Tab 2: "Market"
- Neon green indicator, 2.5px weight

#### Predictions Tab:
- **Loading:** Centered neon green spinner
- **Error:** Red error text with Thai message
- **Empty:** Event note icon (48px, 30% alpha) + "ยังไม่มีกิจกรรมพยากรณ์ในขณะนี้"
- **Loaded:** Scrollable list of PredictionEventCards:
  - Each card: Symbol, question in Thai, deadline, bet amount, YES/NO voting buttons
  - Coin cost badge (gold)
  - Participants count

#### Market Tab:
- **PortfolioChartCard:** Performance sparkline chart
- **MarketInsightCard:** AI-generated market insight text with refresh button
  - Loading state: shimmer placeholder
  - Loaded: AI analysis text with timestamp
- **Crypto Market link card:** Gradient neon green banner, bitcoin icon, "ราคาคริปโตสดจาก Binance" subtitle, arrow right
- **Section label:** "ตลาดโลก"
- **6 MarketTickerTiles:** SET, BTC/USD, ETH/USD, AAPL, TSLA, NVDA
- **Disclaimer footer:** Gold-tinted box with info icon, "ข้อจำกัดความรับผิดชอบ" header, disclaimer text about educational purposes

---

### 3.9 CRYPTO MARKET PAGE

**Route:** `/crypto`
**Transition:** Right-to-left slide

**Layout:**
- **AppBar:** `#0F2040` background, bitcoin icon + "Crypto Market" title, live indicator dot (green=loaded, spinner=loading)
- **Timestamp bar:** "อัปเดตล่าสุด: X วินาทีที่แล้ว" + "Binance" source label
- **Kline Detail Card (when symbol selected):**
  - Symbol name + "24h" badge
  - SparklineChart (close button to deselect)
  - Low/High price labels
  - Border color matches price direction (green up, red down)
- **Ticker List:** Scrollable list with pull-to-refresh
  - Each row: Symbol + volume left, price center, change% badge right
  - Selected row: subtle elevated background
  - Tap -> loads kline chart above
- **Disclaimer footer:** "ข้อมูลเพื่อการศึกษาเท่านั้น ไม่ใช่คำแนะนำการลงทุน"

**States:** Loading, Error (cloud_off icon + retry), Loaded

---

### 3.10 SOCIAL FEED TAB

**Route:** `/feed`
**Transition:** Right-to-left slide

**Layout:**
- **AppBar:** `#0F2040` background, "Social Feed" title (left-aligned), filter chip "ติดตาม" on right
  - Filter chip selected: neon green background, navy text
  - Filter chip unselected: navy background, `#1E3050` border
- **Feed List:** Scrollable ListView with infinite scroll pagination
  - FeedPostCards: Author avatar + name, content text (bilingual), like button + count, timestamp
  - Load more: Spinner at bottom when loading more
- **Empty states:**
  - All feed: "ยังไม่มีโพสต์ เป็นคนแรกที่โพสต์!"
  - Following filter: "ยังไม่มีโพสต์จากคนที่คุณติดตาม"
- **FAB:** Neon green, plus icon, bottom-right -> opens Post Composer

**Post Composer Bottom Sheet:**
- `#0F2040` background, top radius 20px
- "สร้างโพสต์ใหม่" title
- Two text fields:
  - "เนื้อหา (English)" -- 3 lines
  - "เนื้อหา (ภาษาไทย) — ไม่บังคับ" -- 3 lines
- "โพสต์" neon green button (full-width)

---

### 3.11 PROFILE TAB

**Route:** `/profile`
**Transition:** Right-to-left slide (when navigated to, fade when on tab)

**Layout (CustomScrollView):**

1. **SliverAppBar (expandedHeight 200):**
   - Gradient background: `#0A1628` to `#1A2F50`
   - Centered content:
     - Avatar circle: 80x80px, `#0F2040` background, 2px neon green border, avatar ID or initials inside
     - Display name (18px, w700)
     - Email (12px, textSecondary)

2. **Stat Row:**
   - 3 equal-width StatChips:
     - "Lv X" (gold, star icon)
     - "0 Quests" (neon green, assignment icon)
     - "โปรไฟล์ฉัน" (cyan, person icon)
   - XP progress bar: "XP: 500" left, "Lv 5 → Lv 6" right, linear progress bar
   - Coin balance card: `#0F2040` background, gold border at 30% alpha, wallet icon + "ยอดเหรียญ" label + AnimatedCoinCounter

3. **Follow Section (other user's profile only):**
   - FollowButton (follow/unfollow toggle)
   - "เยี่ยมชมห้อง" outlined button (neon green) -> navigates to Friend Room

4. **Privacy Section (own profile only):**
   - Card with "ความเป็นส่วนตัว" neon green label
   - Dropdown: สาธารณะ / เพื่อนเท่านั้น / ส่วนตัว

5. **Badges Section:**
   - Card with "เหรียญตรา" neon green label
   - Wrap of 64x64px badge tiles
   - Earned: gold border, gold glow, emoji + Thai name
   - Unearned: `#3D5A78` border, dimmed emoji

6. **Action Buttons (own profile only):**
   - "แก้ไขโปรไฟล์" outlined (neon green)
   - "ออกจากระบบ" outlined (red)

**States:** Loading, Error (with retry), Loaded

---

### 3.12 EDIT PROFILE PAGE

**Route:** `/edit-profile`
**Transition:** Right-to-left slide

**Layout:**
- **AppBar:** `#0F2040`, "แก้ไขโปรไฟล์" title, back arrow
- **Form fields:**
  - ชื่อที่แสดง (text field, validated 2-30 chars)
  - Avatar dropdown (A1-A8)
  - Market Focus dropdown (Crypto/Forex/Stocks/Mixed)
  - Risk Style dropdown (Calm/Balanced/Bold)
- **"บันทึก" button:** Full-width, neon green, 54px tall
- **Saving state:** Spinner replaces button text

---

### 3.13 SETTINGS PAGE

**Route:** `/settings`
**Transition:** Right-to-left slide

**Layout (ListView):**

**Section: รูปลักษณ์ (Appearance)**
- Theme switcher: "ธีม" label, segmented button (มืด / สว่าง)
  - Selected: neon green background
  - Unselected: `#0F2040` background
- Language switcher: "ภาษา" label, segmented button (ไทย / English)

**Section: การแจ้งเตือน (Notifications)**
- "ตั้งค่าการแจ้งเตือน" row with pixel bell icon + chevron right

**Section: บัญชี (Account)**
- "อัปเกรดบัญชี" (shown only for guest users, neon green icon)
- "ออกจากระบบ" (red text + red logout icon)
- "ลบบัญชี" (red text + red person_remove icon + chevron)

**Section: กฎหมายและข้อมูล (Legal)**
- "นโยบายความเป็นส่วนตัว" (purple shield pixel icon + chevron)
- "ข้อกำหนดการใช้งาน" (cyan description icon + chevron)
- "เวอร์ชัน" (version number display)

**Each row:** 36x36px colored icon container (12% alpha background, 8px radius) + 14px label + trailing widget. Bottom border `#1E3050` 0.5px.

---

### 3.14 NOTIFICATION SETTINGS PAGE

**Route:** `/notification-settings`
**Transition:** Right-to-left slide

**Layout:** Toggle switches for notification categories (quest complete, prediction settled, agent returned, social)

---

### 3.15 ACCOUNT DELETION PAGE

**Route:** `/account-deletion`
**Transition:** Right-to-left slide

**Layout:** Warning text, confirmation field, destructive red "ลบบัญชี" button

---

### 3.16 LEGAL PAGES (Privacy Policy & Terms of Service)

**Routes:** `/privacy-policy`, `/terms-of-service`
**Transition:** Right-to-left slide

**Layout:** AppBar + scrollable text content with Thai legal text

---

### 3.17 AGENT SHOP PAGE

**Route:** `/agent-shop`
**Transition:** Right-to-left slide

**Layout:**
- **AppBar:** "Agent Shop" title, coin balance display on right (coin emoji + amount in gold)
- **Body:** 2-column grid (crossAxisCount=2, aspectRatio 0.72, spacing 12)
- **4 Agent Cards:**
  - Analyst (neon green accent) -- free at Lv 1
  - Scout (gold accent) -- 500 coins at Lv 3
  - Risk (cyber purple accent) -- 1000 coins at Lv 5
  - Social (cyan accent) -- 1500 coins at Lv 8
- **Each card:**
  - `#162040` background, colored border (25% alpha, 2px if owned)
  - Colored glow shadow
  - 40px emoji at top
  - English name (16px, bold) + Thai name (12px, accent color)
  - Description in Thai (11px, textTertiary, 3 lines max)
  - Button states:
    - Owned: "มีแล้ว ✓" green tinted chip
    - Level locked: "ปลดล็อคที่ Lv X" grey chip
    - Can afford: "ซื้อ X 🪙" neon green button
    - Cannot afford: Same button but greyed out

**Purchase Dialog:**
- `#162040` surface, 16px radius, border
- "ซื้อ {name}?" title
- "ใช้ X เหรียญซื้อ {nameTh}?" body
- "ยกเลิก" text button + "ซื้อ 🪙 X" primary button
- Success: Confetti burst + SnackBar

---

### 3.18 ROOM THEME SHOP PAGE

**Route:** `/room-theme-shop`
**Transition:** Right-to-left slide

**Layout:**
- **AppBar:** "Room Themes" title, bottom border, AnimatedCoinCounter on right
- **Body:** Vertical list of theme cards (14px separation)
- **12 room themes:** starter, office, penthouse + 9 Wall Street themes
- **Each Theme Card:**
  - Preview image: 140px tall, room background PNG, top rounded corners
  - If active: "ACTIVE" gold badge overlay top-right
  - If level-locked: Dark overlay with lock icon + "Lv X" text
  - Info row below image: emoji + English name (15px, bold) + Thai name (12px, secondary)
  - Action button (right side):
    - Level locked: "Lv X" grey chip
    - Active: "ใช้งานอยู่" gold tinted chip
    - Owned not active: "ใช้งาน" cyber purple button
    - Free: "ฟรี!" neon green button
    - Not owned: coin icon + price, neon green if affordable, grey if not
  - Active card: 2px gold border with glow shadow

**Purchase Dialog:** Preview image + price + description + cancel/buy buttons

---

### 3.19 QUEST PAGE

**Route:** `/quests`
**Transition:** Right-to-left slide

**Layout:**
- **AppBar:** "Quest" title, TabBar below with neon green indicator:
  - Tab 1: "วันนี้" (Daily)
  - Tab 2: "สัปดาห์" (Weekly)

**Each tab -> Quest List:**
- **Empty:** Pixel quest icon (48px, 50% alpha) + "ยังไม่มี Quest ประจำวัน/สัปดาห์"
- **Populated:** Scrollable list of QuestCards

**QuestCard:**
- `#0F2040` background, 12px radius
- Completed quests: neon green border 1.5px
- Header row: Type badge (daily=cyan, weekly=purple, achievement=gold) + "รับแล้ว" green chip (if claimed)
- Objective text in Thai (15px, w600)
- Progress bar: 7px height, neon green fill, `#1A2F50` background
- Progress count: "X / Y" left, "Z%" right
- Reward row: AnimatedCoinCounter + XP chip (cyan lightning icon) + Claim button
- **Claim button states:**
  - Can claim: "รับรางวัล" neon green background, navy text
  - Already claimed: "รับแล้ว" dark background, muted text
  - Not complete: "ยังไม่ครบ" dark background, muted text
- **On claim:** Confetti burst + FloatingRewardText animation

---

### 3.20 LEADERBOARD PAGE

**Route:** `/leaderboard`
**Transition:** Right-to-left slide

**Layout:**
- **AppBar:** "อันดับ" title (centered), back arrow, TabBar:
  - "รายสัปดาห์" | "ตลอดกาล"
  - Neon green indicator

**Ranking List:**
- Vertical list with 8px separation
- **Top 3 entries:** Larger (46px avatar), medal emoji (gold/silver/bronze), highlighted background
- **Current user:** Neon green tinted background + border, "คุณ" subtitle
- **Each entry:**
  - Rank number or medal emoji (left, 40px wide)
  - Avatar circle with initials (colored border matching rank)
  - Display name + "คุณ" label for self
  - Score (AnimatedCoinCounter for self, static for others)

**States:**
- Loading: 8 shimmer skeleton rows (pulsing 0.35-0.6 alpha)
- Error: wifi_off icon + "เกิดข้อผิดพลาด" + message + "ลองใหม่" button
- Empty: trophy emoji + "ยังไม่มีข้อมูล" + "ทำ Quest เพื่อขึ้นอันดับแรก!"

---

### 3.21 NOTIFICATION PAGE

**Route:** `/notifications`
**Transition:** Right-to-left slide

**Layout:**
- **AppBar:** "การแจ้งเตือน" title, bottom border, "อ่านทั้งหมด" neon green text button (right)
- **Body:** Scrollable list with `#1E3050` dividers

**NotificationTile:**
- 40x40px type icon container (12% alpha background, 10px radius)
  - quest_complete: gold star
  - prediction_settled: neon green chart
  - agent_returned: cyan robot
  - social: purple people
- Title (14px, bold if unread, normal if read)
- Body text (12px, textSecondary, 2 lines max)
- Trailing: Thai time-ago text + green unread dot (8px circle)
- Unread background: `#162040` at 60% alpha

**States:** Loading, Error, Empty ("ยังไม่มีการแจ้งเตือน" with bell emoji)

---

### 3.22 PIXEL ART EDITOR PAGE

**Route:** `/pixel-art-editor`
**Transition:** Right-to-left slide

**Layout:**
- **AppBar:** "Canvas {id}..." title, bottom border
- **Toolbar:** Color palette row, tools (pencil, eraser, fill, undo), save + export buttons
- **Canvas:** Interactive PixelCanvasWidget, 12px cell size, tap to paint
  - Grid of colored cells on `#0A1628` background
  - Each pixel is a crisp square (no anti-aliasing)

**States:** Loading spinner, Editing (interactive), Saved SnackBar, Exported SnackBar, Error SnackBar

---

### 3.23 PIXEL ART GALLERY PAGE

**Route:** `/pixel-art-gallery`
**Transition:** Right-to-left slide

**Layout:**
- **AppBar:** "Pixel Art Gallery" title, bottom border
- **FAB:** Neon green, plus icon -> creates new 32x32 canvas
- **Body:** 2-column grid (12px spacing, 1:1 aspect ratio)
  - Canvas thumbnail cards: `#0F2040` background, `#1E3050` border, 8px radius
  - Miniature PixelCanvasWidget (2px cell size) on top
  - "{width}x{height}" label below
  - Tap -> opens editor

**States:** Loading, Empty ("No canvases yet. Tap + to create one."), Populated with lazy-load pagination

---

### 3.24 PLAZA (Public World)

**Route:** `/plaza`
**Transition:** Right-to-left slide

**Layout (full-screen Stack):**

1. **CustomPaint map (full bleed):**
   - Navy background with 40px grid lines (`#1A2F50`)
   - 5 clickable buildings rendered as colored rectangles:
     - ตลาด / Market (purple) -> Finance page
     - อารีนา / Arena (cyan) -> Leaderboard
     - ธนาคาร / Bank (gold) -> Inventory
     - โซเชียล / Social Hub (neon green) -> Feed
     - กระดานภารกิจ / Quest Board (orange) -> Quest
   - Each building: colored fill at 18% alpha, colored border at 70% alpha, 6px radius, centered Thai label (8px, white, bold)
   - Tapped building: 2.5px gold highlight border
   - Online players: 8px neon green dots with glow ring, initial letter inside

2. **Top overlay:**
   - "Plaza" title (22px, bold, white)
   - Online count chip: "X online" with green dot, neon green border, 12px text

3. **Building Bottom Sheet (on tap):**
   - 48px building icon in colored container
   - Thai name (18px, bold, colored) + English name (13px, 50% alpha)
   - Thai description (14px, 75% alpha)
   - "เข้าไป →" button (building color)

---

### 3.25 FRIEND ROOM PAGE

**Route:** `/friend-room`
**Transition:** Right-to-left slide

**Layout:**
- **AppBar:** `#0F2040`, "ห้องของ {friendName}" title, back arrow
- **Body:** Read-only 8x8 room grid
  - `#0F2040` background, 12px radius, neon green border at 30% alpha
  - Aspect ratio 1:1
  - Grid lines at 8% alpha
  - Room items as colored rectangles (furniture=blue, plant=green, chest=brown, decoration=purple, floor=dark)
  - Item labels centered

**States:** Loading, Error, Empty ("ห้องยังว่างอยู่"), Loaded

---

### 3.26 BROKER CONNECTION PAGE

**Route:** `/broker`
**Transition:** Right-to-left slide

**Layout (Disconnected state):**
- Centered card: `#0F2040`, 16px radius, neon green border at 25% alpha
  - Bank icon (44px, neon green)
  - "เชื่อมต่อ Broker" (20px, bold)
  - "เชื่อมต่อพอร์ตโฟลิโอของคุณเพื่อดูข้อมูลแบบ real-time" (13px, 60% alpha)
  - "Demo Account" primary button with play icon
  - "เชื่อมต่อ Broker จริง (เร็วๆ นี้)" disabled outlined button
  - Disclaimer: "ข้อมูลเพื่อการศึกษา ไม่ใช่คำแนะนำทางการเงิน" (gold, 11px)

**Layout (Connected state):**
- Pull-to-refresh
- **Total Value card:** `#0F2040`, 14px radius, neon green border at 18% alpha
  - "มูลค่าพอร์ตรวม" label
  - "$XXX,XXX.XX" (28px, bold)
  - Daily PnL with arrow icon (green up / red down) + percentage
- **Performance sparkline:** 30-day chart, neon green line
- **Position list:** "สถานะการลงทุน" section header
  - Position tiles: Symbol + Qty + Avg cost left, Current price + Unrealized PnL right
  - PnL color: green/red based on value
- **"สั่งซื้อ/ขาย" outlined button** (neon green) -> Manual Order page
- **"ยกเลิกการเชื่อมต่อ" outlined button** (red)

**Error state:** Red-bordered card with error icon + message + retry button

---

### 3.27 MANUAL ORDER PAGE

**Route:** `/manual-order`
**Transition:** Right-to-left slide

**Layout (order form):**
- **AppBar:** `#0F2040`, "Manual Order" title
- **Fields (scrollable ListView):**
  - สัญลักษณ์ (Symbol): text field, hint "เช่น XAUUSD, EURUSD", uppercase
  - ประเภทคำสั่ง (Order Type): BUY/SELL toggle
    - Two equal buttons, BUY=neon green, SELL=red
    - Selected: colored border 1.5px + tinted background
    - Unselected: `#0D1F3C` background, grey border
  - จำนวน Lot: number field, hint "0.01"
  - Stop Loss (optional): number field
  - Take Profit (optional): number field
  - Validation errors shown below each field in red
- **Submit button:** Full-width, green (buy) or red (sell), "ส่งคำสั่งซื้อ/ขาย"
- **Disclaimer:** Gold text, centered

**Confirmation Dialog:**
- "คำสั่งจริง" gold warning badge
- "ยืนยันคำสั่งซื้อ/ขาย" title
- Summary rows: Symbol, Type, Lots, SL, TP
- "ยกเลิก" + "ยืนยัน BUY/SELL" colored button

---

### 3.28 INVENTORY PAGE

**Route:** `/inventory`
**Transition:** Right-to-left slide

**Layout:**
- **AppBar:** "คลัง" title, bottom border
- **Economy Card:** `#0F2040`, 3 stat columns:
  - Coins (gold coin icon, amount, "Coins")
  - XP (cyan star icon, amount, "XP")
  - Level (purple shield icon, "Lv.X", "Level")
- **Active Quests section:**
  - "Quest ที่กำลังทำ" title (16px, w600)
  - Quest cards (same style as Quest page cards)

**States:** Loading, Error, Empty ("ยังไม่มี Quest โปรดลองใหม่ในภายหลัง"), Loaded

---

## 4. Shared Components

### 4.1 AnimatedCoinCounter
- Gold coin pixel icon + animated counting number
- Smooth tween from previous to new amount
- Used in: Home banner, Profile, Quest rewards, Leaderboard, AppBars

### 4.2 DailyStreakWidget
- Fire pixel icon + "Day X" streak count
- Flame animation when active

### 4.3 StreakWarningBanner
- Warning banner when streak is about to expire
- Gold/warning color theme

### 4.4 XpProgressBar
- Horizontal bar showing XP progress to next level
- "Lv X" left, progress bar center, "Lv X+1" right

### 4.5 SparklineChart
- Thin line chart (2px stroke) for market data
- Color matches trend direction (green up, red down)
- Used in: Crypto page, Broker page, Market tab

### 4.6 ConfettiOverlay
- Burst of colorful confetti particles
- Triggered on: Quest claim, Agent purchase, Room theme purchase

### 4.7 FloatingRewardText
- "+X coins" text that floats upward and fades
- Gold colored, triggered on rewards

### 4.8 RewardPopup
- Modal dialog showing total coins + XP earned
- Used after task settlement in Pixel World

### 4.9 EmptyStateWidget
- Centered layout: emoji (large), titleTh, optional subtitleTh
- Used across multiple screens for empty states

### 4.10 ReadyToCollectBadge
- Pulsing notification badge with count
- Positioned at top of Pixel World screen

---

## 5. Transitions and Animations

- **Page transitions:** Fade (100ms) for tab switches, right-to-left slide (default duration) for pushed pages
- **Bottom sheets:** Slide up with 20px top border radius
- **Selected states:** 220ms ease-out-cubic for border/color/scale changes
- **Progress dots:** 280ms ease-in-out for width animation with glow
- **Onboarding logo:** 1800ms repeating pulse (0.35-1.0 alpha glow)
- **Avatar selection:** 1.05x scale on select
- **Coin counter:** Smooth tween animation between values
- **Streak fire:** Subtle flame flicker
- **Loading:** Staggered dots wave for auth pages, circular progress for data pages
- **Shimmer:** 1100ms repeating reverse for skeleton placeholders

---

## 6. Key Visual Rules

1. **ALWAYS dark theme by default** -- navy `#0A1628` is the base
2. **Pixel art must be crisp** -- FilterQuality.none on all sprite images
3. **Glow borders on active/selected items** -- not drop shadows, but colored BoxShadows with blur
4. **No pure white** -- text is `#E8F4FF`, never `#FFFFFF`
5. **No pure black** -- darkest shade is `#081020` (game background)
6. **Accent colors carry meaning:**
   - Green = profit, success, primary actions
   - Gold = coins, rewards, rankings
   - Purple = AI, premium, risk, weekly
   - Cyan = social, info, XP
   - Red = loss, error, destructive
7. **Thai labels on ALL interactive elements** -- English is secondary/subtitle only
8. **Cards use 1px borders** -- not elevation shadows (this is a pixel art game, not Material Design)
9. **8-bit pixel icons throughout** -- not Material Icons (except where pixel icon unavailable as fallback)
10. **Retro game feeling** -- think GBA/SNES-era UI adapted for modern mobile with glow effects
