# Aslan Pixel — Test Strategy

> BLoC unit tests · Repository mocks · Widget tests · Integration smoke tests
> Tools: `flutter_test`, `bloc_test`, `mocktail`

**Rule**: test business logic (BLoCs, repositories, engines) — not widgets or Firebase.
Use `mocktail` fakes for all external deps. No real Firebase calls in unit tests.

---

## Phase 1 — Auth & Core

### AppBloc
```dart
// auth_status transitions
blocTest('emits authenticated when Firebase user present');
blocTest('emits unauthenticated on sign out');
blocTest('emits unauthenticated on auth error');
```

### AuthRepository
```dart
test('signInWithGoogle returns User on success');
test('signInWithGoogle throws AuthException on cancel');
test('signOut clears session');
test('currentUser returns null when not signed in');
```

### EnvConfig
```dart
test('loads FIREBASE_PROJECT_ID from .env');
test('throws on missing required key');
```

---

## Phase 2 — Agent & Quest Engine

### AgentBloc
```dart
blocTest('emits working state when task dispatched');
blocTest('emits idle state after task completes');
blocTest('emits returning state when idle timer expires');
blocTest('does not transition to working when already working');
```

### IdleTaskEngine (unit)
```dart
test('settleTasks returns empty list when no tasks expired');
test('settleTasks settles tasks past their completedAt timestamp');
test('settleTasks does not settle future tasks');
test('rewardFor returns correct coins for task tier');
```

### QuestRepository
```dart
test('generateDailyQuests returns 3 quests');
test('completeQuest marks quest done and grants reward');
test('completeQuest throws if quest already completed');
```

### EconomyBloc
```dart
blocTest('emits updated coins after reward collected');
blocTest('emits updated XP after quest completed');
blocTest('does not go below 0 coins on spend');
```

---

## Phase 3 — Social & Feed

### FeedRepository
```dart
test('getSystemFeed returns list of FeedPost');
test('getUserFeed filters by follows correctly');
test('createPost stores post with correct uid');
```

### FollowRepository
```dart
test('follow adds uid to following collection');
test('unfollow removes uid from following');
test('isFollowing returns true when relationship exists');
```

### PredictionBloc
```dart
blocTest('emits entered state after placing prediction');
blocTest('emits settled state when event resolves');
blocTest('rejects entry when insufficient coins');
blocTest('grants reward when prediction correct');
blocTest('deducts coins when prediction wrong');
```

### NotificationService
```dart
test('subscribeTopic calls FCM with correct topic');
test('requestPermission returns granted on iOS mock');
```

---

## Phase 4 — Finance & Broker

### BrokerConnector interface
```dart
// DemoBrokerConnector (mock provider)
test('getPortfolio returns PortfolioSnapshot');
test('getPositions returns list of Position');
test('submitOrder returns OrderResult with orderId');
test('submitOrder throws BrokerException on invalid lot size');
```

### ManualOrderBloc
```dart
blocTest('emits reviewing state after user fills ticket');
blocTest('emits submitted state after confirmed');
blocTest('emits error state on connector failure');
blocTest('does not submit without explicit user confirmation event');
```

### AiInsightRepository
```dart
test('getMarketSummary returns cached result within TTL');
test('getMarketSummary calls AI service on cache miss');
test('AI service routes cheap task to Gemini provider');
test('AI service routes deep analysis to Claude provider');
```

### PortfolioRepository
```dart
test('getSnapshot returns latest Firestore snapshot');
test('syncPortfolio stores new snapshot correctly');
```

---

## Phase 5 — Simulation Engine & Pixel Art

### DemoTradingEngine (pure unit, no Firebase)
```dart
test('computeOutcome returns win for trend strategy on trending market');
test('computeOutcome returns loss probability within configured range');
test('outcome is deterministic given same seed + inputs');
test('high risk profile increases reward AND loss variance');
test('LLM result has no effect on final score (engine ignores it)');
test('upgrades affect speed modifier not win probability directly');
```

### RankingRepository
```dart
test('updateScore increments score correctly');
test('getLeaderboard daily returns top 20 sorted descending');
test('getLeaderboard friends filters by follow graph');
```

### PixelArtRepository
```dart
test('saveArtwork uploads PNG to Storage and saves metadata to Firestore');
test('getUserGallery returns artworks sorted by createdAt desc');
test('deleteArtwork removes Storage file and Firestore doc');
```

### PixelCanvasBloc
```dart
blocTest('emits updated pixel when drawPixel event dispatched');
blocTest('emits reverted state after undo');
blocTest('clears canvas on reset');
blocTest('exports PNG bytes on export event');
```

### AiPixelGenerationBloc
```dart
blocTest('emits generating state on prompt submitted');
blocTest('emits result state with image bytes on success');
blocTest('emits error state on Cloud Function timeout');
```

---

## Widget Tests (selected)

```dart
// ManualOrderTicketWidget
testWidgets('submit button disabled until all fields filled');
testWidgets('shows confirmation modal before submitting');
testWidgets('displays "REAL ORDER" warning label');

// PredictionCard
testWidgets('shows coin cost before entry');
testWidgets('shows result badge after event settled');

// AgentCard
testWidgets('shows working animation when agent in working state');
testWidgets('shows reward badge when task complete');
```

---

## Integration Smoke Tests

Run against Firebase Emulator Suite:

```bash
# Start emulators
firebase emulators:start --only auth,firestore,storage,functions

# Run integration tests
flutter test integration_test/
```

```dart
// integration_test/auth_flow_test.dart
testWidgets('sign in → home → agent visible → sign out');

// integration_test/quest_flow_test.dart
testWidgets('complete daily quest → coins update in Firestore');

// integration_test/prediction_flow_test.dart
testWidgets('place prediction → settle → reward granted');

// integration_test/broker_flow_test.dart
testWidgets('connect demo broker → view portfolio → submit manual order');
```

---

## Running Tests

```bash
# Unit + widget
flutter test --no-pub

# With coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Integration (requires emulators)
flutter test integration_test/ --no-pub

# Analyze
flutter analyze lib/ --no-fatal-infos
```

**Coverage target**: BLoC logic and repository layer ≥ 80%
