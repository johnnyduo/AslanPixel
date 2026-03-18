# Aslan Pixel — Engineering Plan

> **Product**: Social Financial Network + Idle Pixel World + Broker-connected Portfolio App
> **Stack**: Flutter 3.x · BLoC · Firebase · Flame · Claude/Gemini AI · Manual Broker Trading
> **Target**: iOS + Android
> **Reference codebase**: `/Library/WebServer/Documents/aslanapp/` (read before building any shared pattern)

---

## 1. Architecture

### 1.1 Folder Structure

```
lib/
├── core/
│   ├── app/                    # AppBloc, app lifecycle (mirror aslanapp/lib/app/)
│   ├── config/                 # app_colors, env_config, constants, theme_provider
│   ├── routing/                # RootPage, route_generator (mirror aslanapp/lib/router/)
│   ├── extensions/             # l10n_extension, context_ext
│   └── utils/                  # crash_reporter, globals, validators
├── features/
│   ├── auth/                   # sign_in, sign_up, otp, forgot_password (mirror aslanapp/lib/screens/authen/)
│   ├── onboarding/             # avatar pick, interest, risk style, room spawn
│   ├── home/                   # private room, agent dashboard (Flame embedded)
│   ├── world/                  # public plaza, friend visit (Flame + presence)
│   ├── agents/                 # agent BLoC, idle engine, simulation engine
│   ├── quests/                 # quest engine, reward distribution
│   ├── feed/                   # social feed, AI feed composer
│   ├── profile/                # avatar, stats, badges, privacy
│   ├── finance/                # market summary, predictions, AI insights
│   ├── broker/                 # connector interface, portfolio, manual order
│   └── inventory/              # coins, XP, items, unlocks
├── shared/
│   ├── widgets/                # appbar, loader, field, chart, style (from aslanapp/lib/widgets/)
│   └── models/                 # shared Dart models
└── data/
    ├── repositories/           # abstract contracts (AuthRepository, AgentRepository…)
    └── datasources/            # FirebaseAuthDatasource, FirestoreDatasource, AIService…
```

### 1.2 State Management

- **BLoC per feature** — no god-state, no cross-BLoC direct dependency
- Feature BLoC communicates via repository only
- AppBloc handles: auth state, global user, crashlytics, performance (mirror AslanApp AppBloc)
- Shared state (currentUser, authStatus) lives in `core/config/constant.dart` globals (mirror AslanApp pattern)

### 1.3 AI Model Routing

| Task | Model | Reason |
|------|-------|--------|
| Quest text, NPC dialogue, feed captions | Gemini Flash-Lite | Cheap, high volume |
| Market summary, prediction context | Gemini Flash | Balance |
| Portfolio explanation, deep analysis, post-trade | Claude Sonnet | Reasoning quality |
| All AI calls | via `AIService` abstraction | Swappable, cacheable, cost-tracked |

**Rule**: LLMs generate content/flavor text only. Deterministic engine controls rewards, scores, progression outcomes.

### 1.4 Pixel / Game Layer

- **Flutter + Flame**: sprites, tile maps, animations, game loop
- **Sprite system**: 4-direction walk, idle, interact, celebrate, fail per character
- **Room**: local state + Firestore sync on app open (lazy settlement)
- **Plaza**: ghost players from Firestore snapshots, update every 3–5s (not realtime tick)
- **Pixel art tool**: `image` package for canvas/palette operations; export PNG → Firebase Storage

### 1.5 Broker Integration

- `BrokerConnector` abstract interface — all broker implementations conform to this
- `DemoBrokerConnector` ships in MVP (mock/paper data)
- Real broker connectors added per integration without changing app code
- Broker tokens: encrypted server-side, never stored in client
- All order submissions: explicit user confirmation required, audit logged

---

## 2. Data Model

### 2.1 Firestore Schema

```
users/{uid}
  displayName, avatarId, email, createdAt, privacyMode
  economy/           (subcollection)
    coins, xp, unlockPoints, lastUpdated
  settings/          (subcollection)
    notifications, theme, language

agents/{uid}/{agentId}
  type (analyst|scout|risk|social), level, xp
  status (idle|working|returning|celebrating|fail)
  activeTask { taskId, startedAt, completesAt, rewardPreview }
  personality, dialogueSet

rooms/{uid}
  layoutVersion, items[], lastSnapshot, updatedAt

quests/{uid}/
  active/   { questId, type, objective, reward, expiresAt, progress }
  history/  { questId, completedAt, rewardGranted }

feedPosts/{postId}
  type (system|user|achievement|prediction|ranking)
  authorUid, content, contentTh, metadata{}, createdAt, reactions{}

follows/{uid}/
  following/ { targetUid, followedAt }

predictionEvents/{eventId}
  symbol, title, titleTh, options[], coinCost
  settlementAt, settlementRule{}, status (open|closed|settled)
  context, difficulty, createdAt

predictionEntries/{eventId}/{uid}
  selectedOptionId, coinStaked, enteredAt, result, rewardGranted

rankings/{period}/   (period = daily|weekly|alltime)
  entries/ { uid, score, rank, category }

brokerAccounts/{uid}/{brokerId}    ← server-side only
  connectorType, encryptedToken, syncedAt, status

portfolios/{uid}/{brokerId}
  equity, balance, unrealizedPnl, currency
  positions[ { symbol, side, lots, entryPrice, currentPnl } ]
  fetchedAt

orderHistory/{uid}/{orderId}
  symbol, side, lots, sl, tp, submittedAt, status, brokerRef, auditHash

aiInsights/{uid}
  type, content, contentTh, modelUsed, generatedAt, expiresAt

notifications/{uid}/{notifId}
  type, title, body, read, createdAt
```

### 2.2 Key Indexes Required (plan early)

- `feedPosts` → `createdAt DESC` + `authorUid`
- `predictionEvents` → `status + settlementAt`
- `quests/{uid}/active` → `expiresAt`
- `rankings/{period}/entries` → `score DESC`
- `aiInsights/{uid}` → `type + expiresAt`

---

## 3. Phase Plan

### Phase 0 — Project Bootstrap
*Duration estimate: 1–2 days*
*Owner: Lead dev*

**Goal**: Repo exists, compiles, CI green, team can commit.

#### Tasks
- [ ] `flutter create aslan_pixel --org com.aslanwealth --project-name aslan_pixel`
- [ ] Git remote: `https://github.com/aslanwealth/AslanPixel.git`
- [ ] `pubspec.yaml`: full dependency set (see §4)
- [ ] `.gitignore`: copy from AslanApp (covers `*.pepk`, `*.jks`, `.env*`, `google-services.json`, `GoogleService-Info.plist`)
- [ ] `.env.example` with all required keys (no real values)
- [ ] `CLAUDE.md`: knowledge bridge pointing to AslanApp reference paths
- [ ] `analysis_options.yaml`: lints from AslanApp
- [ ] `.github/workflows/dart.yml`: copy from AslanApp CI
- [ ] Firebase project created: `aslanpixel-[id]`
- [ ] `flutterfire configure` → generates `firebase_options.dart`
- [ ] Firebase services enabled: Auth, Firestore, Storage, Messaging, Crashlytics, Analytics, Remote Config

**Exit criteria**:
```bash
flutter analyze lib/ --no-fatal-infos   # 0 errors, 0 warnings
flutter build apk --debug               # green
flutter build ios --debug --no-codesign # green
```

---

### Phase 1 — Core Foundation
*Depends on: Phase 0*
*Goal: runnable app, auth works end-to-end, theme system ready, navigation shell done*

#### 1A — Theme & Config
- [ ] `core/config/app_colors.dart` — semantic color system (read AslanApp version, adapt to pixel palette: navy `#0a1628`, neon `#00f5a0`, gold `#f5c518`, cyber `#7b2fff`)
- [ ] `core/config/theme_provider.dart` — light/dark theme (mirror AslanApp structure)
- [ ] `core/config/env_config.dart` — `.env` loader (copy AslanApp, add pixel-specific keys)
- [ ] `core/config/constant.dart` — global state vars: `authStatus`, `currentUser`, `accessToken` (mirror AslanApp)
- [ ] `shared/widgets/style.dart` — typography, spacing tokens (mirror AslanApp `widgets/style.dart`, swap font to `Google Fonts: Space Grotesk` body + `Press Start 2P` pixel headings)

#### 1B — Routing & App Shell
- [ ] `core/routing/route.dart` — `RootPage` StatefulWidget with `FirebaseAuth.authStateChanges()` listener + 5s safety timer (copy AslanApp exactly, adapt routes)
- [ ] `core/routing/route_generator.dart` — named route map (all feature routes pre-registered)
- [ ] `core/app/app_bloc.dart` — `AppBloc` class: `setCrashlytics`, `setPerformance`, `setStatusBarColor`, `requestCheckSignin` (copy AslanApp, adapt service deps)
- [ ] `main.dart` — Firebase init + BLoC providers + EasyLoading + l10n (mirror AslanApp main.dart)

#### 1C — Auth Feature
- [ ] `features/auth/` — BLoC: `AuthBloc`, `AuthEvent`, `AuthState`
- [ ] `features/auth/data/` — `AuthRepository` interface + `FirebaseAuthDatasource` impl
- [ ] Sign-in screen: Google + Apple + Email (copy AslanApp `screens/authen/signin/`, adapt UI colors)
- [ ] Sign-up screen (copy AslanApp `screens/authen/signup/`)
- [ ] OTP screen (copy AslanApp `screens/authen/otp/`)
- [ ] Enums: `AuthStatus`, `UserRoleType` (copy AslanApp `enum/user.dart`)
- [ ] User model: `UserModel` (copy AslanApp `model/users.dart`, strip AslanApp-specific fields, keep core)

#### 1D — Shared Widgets
- [ ] `shared/widgets/appbar/` (copy AslanApp `widgets/appbar/appbar_header.dart`, adapt colors)
- [ ] `shared/widgets/loader/` (copy AslanApp `widgets/loader/loaderX.dart` + `color_loader_3.dart`)
- [ ] `shared/widgets/field/` (copy AslanApp `widgets/field/custom_text_field.dart` + `custom_dropdown_field.dart`)
- [ ] `shared/widgets/chart/` (copy AslanApp `widgets/chart/animated_sparkline.dart` + `chart_widgets.dart` — used for finance screens)

#### 1E — l10n
- [ ] `l10n/app_th.arb` — Thai strings (primary)
- [ ] `l10n/app_en.arb` — English strings
- [ ] `core/extensions/l10n_extension.dart` (copy AslanApp)

**Exit criteria**:
- Sign in with Google → lands on placeholder home
- Sign out → returns to sign-in
- Theme tokens render correctly light/dark
- `flutter analyze` 0 errors

---

### Phase 2 — Pixel Room + Agent Core
*Depends on: Phase 1*
*Goal: user has a living private room with an idle agent that works and returns rewards*

#### 2A — Flame Setup
- [ ] Add `flame` to pubspec, create `core/game/` module
- [ ] `AslanPixelGame` extends `FlameGame` — base game class
- [ ] `GameWidget` embedded inside `HomeScreen` Flutter widget (not full-screen takeover)
- [ ] Sprite atlas loader: PNG sheet → `SpriteAnimation` helper
- [ ] Tile map renderer: room floor + walls from tile data

#### 2B — Private Room Screen
- [ ] `features/home/view/home_screen.dart` — scaffold with Flame `GameWidget` + overlay UI
- [ ] Player character: idle + walk animations (4-direction), spawns at room center
- [ ] Room items: desk, plant, chest — tap-interactive `SpriteComponent`s
- [ ] Camera: fixed room view, no scrolling for MVP

#### 2C — Agent System
- [ ] `features/agents/bloc/` — `AgentBloc`, `AgentEvent`, `AgentState`
- [ ] Agent states: `idle | working | returning | celebrating | fail`
- [ ] `AgentComponent` extends `SpriteAnimationComponent` — renders in Flame world
- [ ] Dialogue bubble overlay: Flutter widget positioned over agent sprite
- [ ] `AgentRepository` interface + `FirestoreAgentDatasource`
- [ ] Starter agent: **Analyst** — spawned on first room load
- [ ] Idle task assignment: tap agent → select task → stores `completesAt` timestamp in Firestore

#### 2D — Idle Task Engine
- [ ] `features/agents/engine/idle_task_engine.dart` — pure Dart, no Firebase dependency
- [ ] `settleTasks(List<AgentTask> tasks, DateTime now)` → returns settled tasks
- [ ] Lazy settlement: called on app open, not on schedule (cost-efficient)
- [ ] Task types: `research`, `scout_mission`, `analysis`, `social_scan`
- [ ] Reward formula: `baseReward × tierMultiplier × (1 + agentLevel * 0.05)`

#### 2E — Economy & Rewards
- [ ] `features/inventory/bloc/` — `EconomyBloc`, `EconomyEvent`, `EconomyState`
- [ ] `EconomyRepository` — read/write `users/{uid}/economy/`
- [ ] Reward chest animation: particle burst + coin/XP counter increment
- [ ] `features/quests/` — scaffold: `QuestBloc`, 3 quest types (idle, daily, prediction placeholder)
- [ ] Daily quest generator: runs on app open if `lastQuestDate != today`

#### 2F — Room Customization (basic)
- [ ] Item placement system: tap slot → open item picker → store in `rooms/{uid}`
- [ ] 3 starter items: floor tile variant A/B/C, desk style, plant

**Exit criteria**:
- User opens app → room renders with Flame game widget
- Agent walks idle loop
- Tap agent → assign task → agent shows "working" state
- Re-open app after task `completesAt` → chest appears → collect → Firestore coins/XP updated
- Daily quests appear on first open of day

---

### Phase 3 — Social + Feed
*Depends on: Phase 2*
*Goal: users are connected — feed, profiles, follow, friend visits, predictions, notifications*

#### 3A — Social Feed
- [ ] `features/feed/bloc/` — `FeedBloc`, infinite scroll with Firestore pagination
- [ ] Feed card types: `SystemEvent`, `UserAchievement`, `PredictionResult`, `RankingUpdate`
- [ ] AI feed composer: Cloud Function `composeFeedCaption(event)` → Gemini Flash-Lite → stored as `contentTh`
- [ ] Feed screen: `ListView.builder` with shimmer placeholder (copy AslanApp shimmer pattern)

#### 3B — Profile
- [ ] `features/profile/bloc/` — `ProfileBloc`
- [ ] Profile screen: avatar, display name, stats (quest streak, prediction wins), badges, agent lineup preview
- [ ] Privacy settings: public / friends-only / private (stored in `users/{uid}.privacyMode`)
- [ ] Edit profile: change display name, avatar selection

#### 3C — Follow System
- [ ] `data/repositories/follow_repository.dart` — `follow`, `unfollow`, `isFollowing`, `getFollowing`
- [ ] Firestore path: `follows/{uid}/following/{targetUid}`
- [ ] Follow/unfollow button in profile screen
- [ ] Feed filters by followed users when `privacyMode != public`

#### 3D — Friend Room Visit
- [ ] Async room visit: load `rooms/{friendUid}` snapshot → render read-only Flame scene
- [ ] Presence indicator: if friend online (Firestore `users/{uid}.lastSeen < 2min`), show "online" badge
- [ ] Emote interaction: tap emote → writes to `rooms/{friendUid}/visitors/{myUid}` (ephemeral, 30s TTL)

#### 3E — Public Plaza
- [ ] `features/world/bloc/` — `PlazaBloc`
- [ ] Ghost player system: Firestore query `users` ordered by `lastSeen DESC`, limit 20
- [ ] Player snapshot rendered as `SpriteComponent` in plaza Flame scene, updated every 5s
- [ ] Plaza buildings as tap-destinations: News Tower, Prediction Board, Leaderboard Billboard
- [ ] 3 basic emotes: wave, celebrate, shrug

#### 3F — Prediction System
- [ ] `features/finance/prediction/bloc/` — `PredictionBloc`
- [ ] Prediction event list screen: open events sorted by `settlementAt`
- [ ] Entry flow: select option → coin deduction → write `predictionEntries/{eventId}/{uid}`
- [ ] Settlement: Cloud Scheduler job every hour → checks `predictionEvents` with `status=closed` → resolves + writes results + triggers reward
- [ ] Feed card auto-generated on settlement

#### 3G — Push Notifications
- [ ] `data/datasources/notification_service.dart` (copy AslanApp, adapt topic keys)
- [ ] FCM topics: `quest_ready`, `idle_reward`, `prediction_settled`, `friend_visit`
- [ ] In-app notification bell: reads `notifications/{uid}` collection
- [ ] Notification settings screen (granular per type)

**Exit criteria**:
- User sees feed with system + friend posts
- Follow a user → their achievements appear in feed
- Visit friend room → see their agents
- Place a prediction → entry stored in Firestore
- Receive FCM push when idle task completes

---

### Phase 4 — Finance Layer
*Depends on: Phase 3*
*Goal: market data visible, demo broker connected, portfolio shown, manual order flow complete*

#### 4A — Market Summary Screen
- [ ] `features/finance/market/` — asset categories: crypto, FX, stocks, mixed
- [ ] Market overview cards: price, change%, sparkline chart (use AslanApp `widgets/chart/animated_sparkline.dart`)
- [ ] Asset detail screen: mini chart + AI insight card
- [ ] AI insight card: calls `AIService.getMarketInsight(assetClass)` → cached in `aiInsights/{uid}` (TTL 30min)

#### 4B — AI Service Layer
- [ ] `data/datasources/ai_service.dart` — `AIService` abstract interface
- [ ] `GeminiAIService` impl (cheap tasks): uses `google_generative_ai` package (already in AslanApp)
- [ ] `ClaudeAIService` impl (premium): Cloud Function proxy (Claude API never called from client)
- [ ] `AIServiceRouter` — routes by `AITaskType` enum
- [ ] Caching: read `aiInsights/{uid}` before calling AI, skip if `expiresAt > now`
- [ ] Cost tracking: log `{model, tokens, taskType, uid}` per call to Firestore analytics subcollection

#### 4C — Broker Connector
- [ ] `data/repositories/broker_connector.dart` — abstract interface: `getPortfolio`, `getPositions`, `getOrderHistory`, `submitOrder`
- [ ] `DemoBrokerConnector` — mock data, returns realistic paper portfolio (ships in MVP)
- [ ] `BrokerBloc` — manages connector lifecycle, sync state
- [ ] Broker connect flow: select broker → OAuth/API key (secure) → test connection → store encrypted token server-side via Cloud Function
- [ ] Auto-sync: Cloud Function `syncPortfolio(uid, brokerId)` runs every 15min → writes `portfolios/{uid}/{brokerId}`

#### 4D — Portfolio Dashboard
- [ ] `features/broker/portfolio/` screen
- [ ] Components: equity card, balance card, unrealized PnL (green/red), open positions list, order history
- [ ] Sparkline per position (use AslanApp chart widget)
- [ ] AI summary card: calls `portfolio-summary` skill logic via `AIService`
- [ ] Disclaimer: always visible — "ข้อมูลเพื่อการศึกษา ไม่ใช่คำแนะนำทางการเงิน"

#### 4E — Manual Order Ticket
- [ ] `features/broker/order/` — `ManualOrderBloc`
- [ ] Order form: symbol search → buy/sell → lot size → optional SL/TP
- [ ] Validation: lot > 0, symbol exists, balance sufficient (from latest portfolio snapshot)
- [ ] Confirmation modal: shows full order details, "REAL ORDER" warning badge, requires explicit tap
- [ ] Submit → Cloud Function `submitOrder(uid, brokerId, order)` → broker API → write `orderHistory/{uid}/{orderId}` with audit hash
- [ ] AI must not auto-submit — only UI user action triggers submission

#### 4F — Security & Compliance
- [ ] Broker tokens: never in Dart code, never in client Firestore reads
- [ ] All broker API calls: Cloud Function server-side only
- [ ] `orderHistory` documents: include `auditHash = SHA256(uid + orderId + timestamp + amount)`
- [ ] `firebase.rules` updated: `orderHistory` write = server-only (via Admin SDK)

**Exit criteria**:
- Connect demo broker → portfolio screen shows positions + PnL
- AI insight card renders for market summary
- Manual order ticket: cannot submit without explicit confirmation modal tap
- Order appears in `orderHistory` after submission
- AI service routes correctly: cheap → Gemini, deep → Claude

---

### Phase 5 — Full Agent System + Polish
*Depends on: Phase 4*
*Goal: all 4 agents live, onboarding complete, demo trading engine, rankings, pixel art tool, production-ready performance*

#### 5A — Onboarding Flow
- [ ] `features/onboarding/` — 6-step flow: welcome → avatar pick → market interest → risk style → spawn room → meet first agent → first quest
- [ ] Avatar selection: grid of pixel characters (PNG assets), stored as `avatarId` in Firestore
- [ ] Risk style: calm / balanced / bold → stored as `riskProfile` → affects simulation engine
- [ ] Market interest: crypto / FX / stocks / mixed → stored as `marketFocus` → affects quest types + feed
- [ ] Skip guard: onboarding skippable but `onboardingComplete` flag gates certain features

#### 5B — All 4 Agents
- [ ] **Analyst**: market research tasks, generates AI insight, dialogue about market conditions
- [ ] **Scout**: idle missions, collects coins/XP/item fragments, unlocks event clues
- [ ] **Risk**: affects simulation risk profile, warns on high-exposure scenarios
- [ ] **Social**: surfaces trending feed, suggests follows, social quest triggers
- [ ] Each agent: distinct sprite set (idle, walk, work, return, celebrate, fail animations)
- [ ] Agent XP system: levels 1–10, higher level = faster task completion + better rewards

#### 5C — Demo Trading Simulation Engine
- [ ] `features/agents/engine/simulation_engine.dart` — pure Dart, fully deterministic + seeded random
- [ ] Inputs: `strategyArchetype`, `riskLevel`, `marketFocus`, `agentLevel`, `eventModifier`
- [ ] Output: `SimulationResult { outcome, coinsEarned, xpEarned, streak, logEntry }`
- [ ] LLM generates `logEntry` flavor text only — never controls numeric outcome
- [ ] Balance rules: win rate 45–65% depending on inputs (not skewed to always win)
- [ ] Unit tested exhaustively: same seed → same result, edge cases covered

#### 5D — Rankings
- [ ] `features/profile/rankings/` — daily / weekly / all-time tabs
- [ ] Scoring categories: prediction streak, demo trade score, quest completion rate, social engagement
- [ ] Cloud Scheduler: recalculate rankings every hour → write `rankings/{period}/entries/`
- [ ] Leaderboard billboard in plaza reads from `rankings/daily/entries/`
- [ ] Friends leaderboard: filter by `follows/{uid}/following/`

#### 5E — Pixel Art Tool
- [ ] `features/home/pixel_editor/` — canvas screen
- [ ] `PixelCanvasBloc`: draw, erase, fill, palette selection, undo/redo (max 20 steps)
- [ ] Canvas: `CustomPainter` 16×16 or 32×32 grid
- [ ] Color palette: `flutter_colorpicker` + 16 preset pixel-art colors
- [ ] Export: `image` package → PNG bytes → upload to Firebase Storage → save metadata to Firestore
- [ ] Gallery: `features/home/gallery/` — grid of user's pixel artworks with `photo_view` zoom

#### 5F — AI Pixel Art Generation
- [ ] Prompt screen: user types description → Cloud Function → Gemini generates pixel art description → client renders using structured output
- [ ] Or: Gemini generates a pixel grid as JSON `{x, y, color}[]` → client renders on canvas
- [ ] Save generated art same way as hand-drawn

#### 5G — Performance & Production Readiness
- [ ] Sprite atlas: pack all room + character sprites into atlas PNG, load once
- [ ] Firestore: unsubscribe all listeners in `dispose()` (audit every BLoC)
- [ ] Image caching: `cached_network_image` for all remote assets
- [ ] Lazy loading: `lazy_load_scrollview` for feed + gallery (copy AslanApp pattern)
- [ ] Firebase Remote Config: feature flags for `pixelEditorEnabled`, `brokerEnabled`, `plazaEnabled`
- [ ] Firebase Analytics events: `onboarding_complete`, `quest_complete`, `prediction_entered`, `broker_connected`, `order_submitted`
- [ ] Crashlytics: breadcrumb logging on all BLoC state transitions
- [ ] App version check: `app_version_update` package (already in AslanApp)

**Exit criteria**:
- Full onboarding flow end-to-end
- All 4 agents spawn, animate, complete tasks, settle rewards
- Demo trading engine: 100 simulations run, stats within expected distribution
- Rankings update + display correctly
- Pixel art drawn → exported → visible in gallery
- Firebase Analytics shows events in DebugView
- `flutter analyze` 0 errors, test coverage ≥ 80% on engines + BLoCs

---

## 4. Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # State
  flutter_bloc: ^9.1.1
  equatable: ^2.0.7

  # Firebase
  firebase_core: ^4.2.0
  firebase_auth: ^6.1.1
  cloud_firestore: ^6.0.3
  firebase_storage: ^13.0.3
  firebase_crashlytics: ^5.0.3
  firebase_messaging: ^16.0.3
  firebase_analytics: ^12.0.3
  firebase_performance: ^0.11.1+1
  firebase_remote_config: ^6.2.0
  cloud_functions: ^6.0.3

  # Game
  flame: ^1.21.0

  # UI
  sizer: ^3.0.5
  google_fonts: ^8.0.2
  flutter_svg: ^2.2.0
  cached_network_image: ^3.4.1
  shimmer: ^3.0.0
  loading_animation_widget: ^1.3.0
  flutter_easyloading: ^3.0.5
  page_transition: ^2.2.1
  photo_view: ^0.15.0
  dotted_border: ^2.1.0
  animated_text_kit: ^4.3.0

  # Charts (from AslanApp)
  fl_chart: ^1.1.1
  syncfusion_flutter_charts: ^32.1.24

  # Auth
  google_sign_in: ^7.1.1
  sign_in_with_apple: ^7.0.1

  # Pixel art
  image: ^4.6.0
  flutter_colorpicker: ^1.1.0
  image_picker: ^1.1.2

  # AI
  google_generative_ai: ^0.4.7
  firebase_ai: ^3.6.1

  # Utilities
  shared_preferences: ^2.5.3
  flutter_secure_storage: ^10.0.0
  flutter_dotenv: ^6.0.0
  url_launcher: ^6.3.2
  permission_handler: ^12.0.1
  intl: ^0.20.2
  crypto: ^3.0.6
  device_info_plus: ^12.3.0
  package_info_plus: any
  path_provider: ^2.1.5

  # Notifications
  flutter_local_notifications: ^19.5.0
  timezone: ^0.10.1

  # Misc (from AslanApp)
  auto_size_text: ^3.0.0
  lazy_load_scrollview: ^1.3.0
  awesome_dialog: ^3.2.1
  fluttertoast: ^9.0.0
  app_version_update: ^6.2.0
  audioplayers: ^6.1.0
  get: ^4.7.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  bloc_test: ^10.0.0
  mocktail: ^1.0.4
  fake_cloud_firestore: ^4.0.0
  firebase_auth_mocks: ^0.15.0
  build_runner: ^2.4.13
```

---

## 5. Backend Services (Cloud Functions — Node.js 22, asia-southeast1)

| Function | Trigger | Purpose |
|----------|---------|---------|
| `composeFeedCaption` | Firestore onCreate feedPosts | Generate Thai caption via Gemini Flash-Lite |
| `settlePredictions` | Cloud Scheduler (every 1h) | Close + resolve prediction events, distribute rewards |
| `generateDailyQuests` | Cloud Scheduler (00:00 ICT) | Write daily quest set per user |
| `syncPortfolio` | Cloud Scheduler (every 15min) | Pull broker snapshot, write to Firestore |
| `submitOrder` | HTTPS Callable | Server-side order submission to broker API, audit log |
| `getAIInsight` | HTTPS Callable | Claude/Gemini call proxied, cached response returned |
| `recalculateRankings` | Cloud Scheduler (every 1h) | Recompute leaderboard entries |
| `settleIdleTasks` | HTTPS Callable (on app open) | Settle expired agent tasks for a user |

---

## 6. Security Rules (Firestore)

```
// Key rules — full rules.firestore file to be written in Phase 1
users/{uid}: read = authenticated, write = owner only
rooms/{uid}: read = authenticated (for visit), write = owner only
feedPosts/{postId}: read = authenticated, write = owner or server
predictionEntries/{eventId}/{uid}: read = owner, write = owner (once per event)
brokerAccounts/{uid}/{brokerId}: read = DENIED (server only), write = DENIED
orderHistory/{uid}/{orderId}: read = owner, write = DENIED (server Admin SDK only)
aiInsights/{uid}: read = owner, write = DENIED (server only)
```

---

## 7. CI / CD

```yaml
# .github/workflows/dart.yml (copy from AslanApp, adapt)
on: [push, pull_request]
jobs:
  analyze:  flutter analyze lib/ --no-fatal-infos
  test:     flutter test --no-pub
  build_android: flutter build apk --debug
  build_ios: flutter build ios --debug --no-codesign
```

---

## 8. Environment Variables (.env.example)

```
FIREBASE_API_KEY=
FIREBASE_APP_ID=
FIREBASE_MESSAGING_SENDER_ID=
FIREBASE_PROJECT_ID=
FIREBASE_AUTH_DOMAIN=
FIREBASE_STORAGE_BUCKET=
GOOGLE_CLIENT_ID=
GOOGLE_SERVER_CLIENT_ID=
GEMINI_API_KEY=
CLAUDE_API_KEY=
BROKER_ENCRYPTION_SECRET=
```

---

## 9. Definition of Done (per phase)

Every phase is **done** when all of the following pass:

```bash
flutter analyze lib/ --no-fatal-infos   # zero issues
flutter test --no-pub                    # all green
flutter build apk --debug               # build success
flutter build ios --debug --no-codesign # build success
```

Plus phase-specific acceptance criteria listed above.

---

## 10. AslanApp Reference Map

Read these files before building the equivalent in Aslan Pixel:

| What to build | Read in AslanApp first |
|--------------|----------------------|
| AppBloc | `lib/app/bloc/app_bloc.dart` |
| RootPage | `lib/router/route.dart` |
| Route generator | `lib/router/route_generator.dart` |
| Color system | `lib/config/app_colors.dart` |
| Theme | `lib/config/theme_provider.dart` |
| Env config | `lib/config/env_config.dart` |
| Global constants | `lib/config/constant.dart` |
| Auth screens | `lib/screens/authen/` |
| Enums | `lib/enum/user.dart` |
| main.dart init | `lib/main.dart` |
| Notification service | `lib/services/notification_service.dart` |
| AppBar widget | `lib/widgets/appbar/appbar_header.dart` |
| Loader widgets | `lib/widgets/loader/` |
| Field widgets | `lib/widgets/field/` |
| Chart widgets | `lib/widgets/chart/` + `widgets/animated_sparkline.dart` |
| Style tokens | `lib/widgets/style.dart` |
| l10n extension | `lib/extensions/l10n_extension.dart` |
| CI workflow | `.github/workflows/dart.yml` |
