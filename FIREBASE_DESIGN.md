# Aslan Pixel — Firebase & Firestore Backend Design

> Canonical backend architecture reference. Region: asia-southeast1 (Singapore).
> Firestore: Native mode. Cloud Functions: Node.js 22.
> Last updated: 2026-03-18

---

## Firestore Collections

### `users/{uid}`
| Field | Type | Notes |
|-------|------|-------|
| displayName | string | 1–50 chars |
| email | string | From Firebase Auth |
| photoUrl | string? | Google/Apple sign-in URL |
| avatarId | string? | Preset key e.g. `A1`–`A8` |
| role | string | USER/ADMIN/BLOCK/GUEST — server-only write |
| privacyMode | string | `public`/`private` |
| marketFocus | string? | crypto/fx/stocks/mixed |
| riskStyle | string? | calm/balanced/bold |
| onboardingComplete | bool | Gates feature access |
| createdAt | Timestamp | Set once on creation |

**Subcollections:**
- `economy/balance` — coins, xp, unlockPoints, lastUpdated (server-only write)
- `economy/balance/transactions/{id}` — ledger: type, amount, reason, timestamp
- `agents/{agentId}` — type, level, xp, status, activeTaskId, taskCompletesAt, personalityKey
- `quests/active/{questId}` — type, objective, objectiveTh, reward map, expiresAt, progress, target, completed
- `quests/history/{questId}` — archived completed quests
- `badges/{badgeId}` — badgeId, grantedAt, category
- `notifications/{notifId}` — type, titleTh, bodyTh, isRead, createdAt
- `settings/quests` — lastQuestDate, notificationsEnabled, themeMode, language

**Rules:** owner read/write; role field server-only; economy subcollection server-only write.

---

### `agentTasks/{uid}/tasks/{taskId}`
| Field | Type | Notes |
|-------|------|-------|
| taskId | string | Mirrors doc ID |
| agentId | string | FK to agents |
| agentType | string | analyst/scout/risk/social |
| taskType | string | research/scoutMission/analysis/socialScan |
| tier | string | basic/standard/advanced/elite |
| startedAt | Timestamp | |
| completesAt | Timestamp | Lazy settlement: isComplete = now > completesAt |
| baseReward | int | Deterministic coin base |
| xpReward | int | |
| isSettled | bool | Filter for pending tasks |
| actualReward | int? | Set on settlement |
| settledAt | Timestamp? | Server timestamp |

**Index:** `isSettled ASC + completesAt ASC`
**Cleanup:** Settled tasks >7 days old batch-deleted on app open.

---

### `rooms/{uid}`
Single document per user. Items stored as embedded array (always loaded whole).
| Field | Type | Notes |
|-------|------|-------|
| layoutVersion | int | Schema version |
| items | array of map | {itemId, type, assetKey, slotX, slotY, isUnlocked} |
| updatedAt | Timestamp | |

**Rules:** owner read/write; public read if user privacyMode=public.

---

### `feedPosts/{postId}`
| Field | Type | Notes |
|-------|------|-------|
| type | string | user/system/achievement/prediction/ranking |
| authorUid | string? | Null for system posts |
| content | string | English, 1–500 chars |
| contentTh | string? | Thai — set by composeFeedCaption function |
| reactions | map | emoji → count e.g. `{"❤️": 3}` |
| createdAt | Timestamp | |

**Indexes:** createdAt DESC; authorUid ASC + createdAt DESC
**Rules:** authenticated read; author create; reactions-only update; author/admin delete.

---

### `plazaPresence/{uid}`
Ephemeral. TTL via scheduled Cloud Function + client removeMyPresence on dispose.
| Field | Type | Notes |
|-------|------|-------|
| avatarId | string? | |
| displayName | string? | |
| position | map | {x: double, y: double} normalized 0.0–1.0 |
| lastSeen | Timestamp | Updated every position write |

**Index:** lastSeen DESC
**Cleanup:** `purgeStalePlazaPresence` (scheduled every 10 min) deletes where lastSeen < now - 5min.

---

### `predictionEvents/{eventId}`
| Field | Type | Notes |
|-------|------|-------|
| symbol | string | BTC/USDT, SET, etc. |
| titleTh | string | Thai question text |
| options | array | {optionId, labelTh} |
| coinCost | int | Entry fee deducted on entry |
| settlementAt | Timestamp | When entries close |
| settlementRule | string | above/below/exact |
| status | string | open/closed/settled |

**Index:** status ASC + settlementAt ASC
**Rules:** authenticated read; ADMIN/server write only.

---

### `userEntries/{uid}/entries/{entryId}`
| Field | Type | Notes |
|-------|------|-------|
| eventId | string | FK to predictionEvents |
| uid | string | Redundant for collection-group queries |
| selectedOptionId | string | |
| coinStaked | int | Deducted via transaction on entry |
| enteredAt | Timestamp | |
| result | string? | win/loss — server-set on settlement |
| rewardGranted | int | 0 until settled |

**Indexes:** uid ASC + enteredAt DESC; eventId ASC + enteredAt DESC

---

### `pixelCanvases/{canvasId}`
| Field | Type | Notes |
|-------|------|-------|
| ownerUid | string | |
| width | int | 16/32/64 |
| height | int | 16/32/64 |
| pixels | array | Flat array of width×height ARGB ints |
| storagePath | string? | Firebase Storage PNG URL after export |
| createdAt | Timestamp | |
| updatedAt | Timestamp | |

**Index:** ownerUid ASC + updatedAt DESC
**Rules:** owner read/create/update; authenticated read if public.

---

### `aiInsights/{uid}/{insightId}`
| Field | Type | Notes |
|-------|------|-------|
| type | string | market_summary/portfolio_explanation/prediction_context/agent_tip |
| contentTh | string | Thai — primary display |
| modelUsed | string | gemini-2.0-flash-lite / gemini-2.0-flash |
| generatedAt | Timestamp | |
| expiresAt | Timestamp | TTL = 6h from generatedAt |

**Index:** type ASC + expiresAt ASC

---

### `follows/{uid}/following/{targetUid}`
| Field | Type | Notes |
|-------|------|-------|
| targetUid | string | Mirrors doc ID |
| followedAt | Timestamp | |

---

### `rankings/{period}/entries/{uid}`
period format: `weekly_2026_W12`, `alltime`
| Field | Type | Notes |
|-------|------|-------|
| displayName | string? | Denormalized |
| avatarId | string? | Denormalized |
| score | int | |
| rank | int | 1-based, pre-computed |

**Index:** score DESC
**Rules:** authenticated read; server-only write.

---

### `brokerAccounts/{uid}/{brokerId}` (server-only)
| Field | Type | Notes |
|-------|------|-------|
| connectorType | string | demo/bitkub/set |
| encryptedToken | string | AES-256-GCM, key in Secret Manager |
| status | string | active/expired/error |
| syncedAt | Timestamp | |

**Rules:** read=false; write=false — Admin SDK only.

---

### `portfolios/{uid}/{brokerId}` (server-only)
| Field | Type | Notes |
|-------|------|-------|
| totalValue | double | |
| dailyPnl | double | |
| positions | array | {symbol, qty, avgCost, currentPrice, unrealizedPnl} |
| snapshotAt | string | ISO 8601 |
| fetchedAt | Timestamp | |

---

## Cloud Functions (Node.js 22, asia-southeast1)

| Function | Trigger | Purpose |
|----------|---------|---------|
| `composeFeedCaption` | Firestore onCreate `feedPosts/{postId}` | Generate Thai caption via Gemini Flash-Lite, write back to contentTh |
| `settlePredictions` | Scheduled hourly | Fetch market price, determine winner, credit coins, send notifications |
| `generateDailyQuestsServer` | Scheduled daily 00:00 ICT | Pre-generate daily quests for all active users |
| `syncPortfolio` | Scheduled every 15 min | Decrypt broker token, fetch portfolio, write PortfolioSnapshot |
| `submitOrder` | HTTPS Callable (auth required) | Broker order proxy: validate, decrypt, submit, write audit log |
| `getAIInsight` | HTTPS Callable (auth required) | Cache-first AI insight generation (Gemini/Claude via Secret Manager) |
| `recalculateRankings` | Scheduled every hour | Aggregate scores, write rankings/{period}/entries |
| `grantBadge` | Firestore onWrite quests | Check badge eligibility, write badges, send notification |
| `purgeStalePlazaPresence` | Scheduled every 10 min | Delete plazaPresence where lastSeen < now - 5min |
| `connectBroker` | HTTPS Callable (auth required) | Validate + encrypt broker credentials, write brokerAccounts |
| `settleIdleTasks` | HTTPS Callable (auth required) | Server-side task settlement on app open (stronger guarantee than client) |

---

## Firebase Storage Structure

```
gs://aslanpixel-{id}.appspot.com/
├── avatars/{uid}/avatar.png          # 500 KB max, image/*
├── pixel_art/{uid}/{canvasId}.png    # 2 MB max, image/png
├── sprites/v1/                       # Static sprites — read-only client
│   ├── agents/
│   ├── avatars/
│   ├── npcs/
│   ├── room_items/
│   ├── effects/
│   └── ui/
└── feed_media/{postId}/image.png     # 5 MB max, image/*
```

Remote Config `sprite_version` (default `v1`) controls sprite path prefix for hot-swap.

---

## Firebase Project Setup Checklist

### Services to Enable
- Authentication: Google, Apple, Email/Password
- Firestore: Native mode, asia-southeast1
- Storage: asia-southeast1
- Cloud Functions: Node.js 22, asia-southeast1
- FCM: APNs cert for iOS
- Crashlytics + Analytics
- Remote Config defaults: `pixel_world_enabled=true`, `social_feed_enabled=true`, `broker_connect_enabled=false`, `plaza_enabled=true`, `min_app_version=1.0.0`, `sprite_version=v1`
- App Check: PlayIntegrity (Android) + DeviceCheck (iOS), debug provider for CI

### Secret Manager Secrets
| Name | Description |
|------|-------------|
| `broker-encryption-key` | AES-256 for broker token encryption |
| `gemini-api-key` | Google Generative AI API key |
| `claude-api-key` | Anthropic Claude API key |
| `price-oracle-api-key` | CoinGecko/SET price feed |

### IAM Roles (Cloud Functions SA)
- `roles/datastore.user`
- `roles/firebase.sdkAdminServiceAgent`
- `roles/secretmanager.secretAccessor`
- `roles/storage.objectAdmin`

### Emulator Suite (firebase.json)
```json
{
  "emulators": {
    "auth": {"port": 9099},
    "firestore": {"port": 8080},
    "storage": {"port": 9199},
    "functions": {"port": 5001},
    "ui": {"enabled": true, "port": 4000}
  }
}
```

### Firebase project name: `aslan-pixel`
### Firebase project account: `admin@aslanwealth.com`
### Deploy commands:
```bash
firebase deploy --only firestore:rules,firestore:indexes
firebase deploy --only functions
firebase deploy
```

---

## Key Architecture Rules
1. Economy writes (coins/xp) ONLY via Firestore transactions — never direct sets
2. Broker tokens NEVER client-side — only Cloud Functions via Secret Manager
3. AI API keys NEVER in client code — only Cloud Functions via Secret Manager
4. App Check enforced on all HTTPS Callable functions
5. Use `withValues(alpha: X)` not `.withOpacity()` in Flutter
6. Settlement is idempotent — all settle functions check status before writing
