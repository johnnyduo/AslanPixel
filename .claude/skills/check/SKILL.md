---
name: check
description: "Enterprise-grade Flutter code audit and test suite. Use when verifying code quality, before commit/deploy, after feature work, or when user says check, audit, test, QA, verify, or review code."
disable-model-invocation: false
user-invocable: true
---

# Aslan Pixel — Full QA/QC Pipeline

Run this as a senior Flutter engineer at a big tech firm would.
Do NOT just report problems — FIX them. Re-run until everything passes.

---

## Phase 1: Static Analysis (Code Quality Audit)

### 1.1 Flutter Analyze
```bash
flutter analyze lib/ --no-fatal-infos
flutter analyze test/ --no-fatal-infos --no-fatal-warnings
```
- Fix ALL errors and warnings (not infos)
- Re-run after fixes to confirm clean

### 1.2 Import/Export Hygiene
Scan ALL Dart files for:
- **Unused imports**: `import` statements that are never referenced — REMOVE them
- **Duplicate imports**: same file imported twice or via different paths — DEDUPLICATE
- **Redundant exports**: re-exports that serve no purpose — REMOVE
- **Circular imports**: A imports B imports A — REFACTOR to break cycles
- **Missing part/part of**: files that should be parts but use full imports
- **Barrel file bloat**: barrel files (index exports) pulling in unused transitive deps
- **Package vs relative**: inconsistent import style (prefer `package:aslan_pixel/` for cross-directory)
Run: `dart fix --apply` first to auto-fix what Dart tooling can handle, then manually review remaining.

### 1.3 Code Quality Review
Scan changed/recent files for:
- **Security**: hardcoded secrets, API keys in source, SQL/XSS injection vectors, insecure HTTP
- **Memory leaks**: unclosed streams, missing dispose() on controllers/subscriptions/timers
- **Race conditions**: async gaps between state checks and usage, unguarded BuildContext after await
- **Null safety**: force unwraps (!), unchecked nullable access, missing null guards
- **State management**: BLoC anti-patterns (emit after close, missing error states, unhandled edge cases)
- **Platform issues**: iOS/Android-specific crashes, missing permission checks, lifecycle issues
- **Performance**: unnecessary rebuilds, missing const constructors, O(n²) in lists, large widget trees without repaint boundaries
- **Dead code**: unused imports, unreachable branches, deprecated API usage
- **Duplicate code**: repeated logic that should be extracted
- **Error handling**: empty catch blocks, swallowed exceptions, missing user-facing error messages

### 1.4 Architecture Review
- Verify BLoC pattern compliance (no business logic in widgets)
- Check service layer separation (no direct Firestore calls from UI)
- Verify proper dependency injection patterns
- Check route guard consistency (auth state, feature flags via Remote Config)
- Verify `LLM rule`: LLMs must NOT control rewards/scores/progression — deterministic engine only
- Verify broker security: no broker tokens in client code, all broker calls via Cloud Functions

---

## Phase 2: Test Suite Execution

### 2.1 Run All Tests with Coverage
```bash
flutter test --coverage --no-pub --reporter expanded
```

### 2.2 Test Categories to Verify
- **Unit tests** (`test/unit/`): Services, BLoCs, models, helpers, controllers
- **Widget tests** (`test/widget/`): Screen rendering, user interaction, state display
- **Flow/E2E tests** (`test/flow/`): Multi-screen user journeys, auth flows, purchase flows
- **Integration tests** (`test/integration/`): Cross-module integration

### 2.3 Coverage Gap Analysis
After running tests, identify MISSING test coverage:
- New/modified files without corresponding tests
- BLoC states/events without test cases
- Service methods without unit tests
- Screen widgets without widget tests
- Edge cases: error states, empty states, loading states, offline scenarios
- Auth flows: login, logout, guest mode, token refresh, session expiry
- Boundary conditions: empty lists, max limits, special characters in Thai text

### 2.4 Create Missing Tests
For any gap found, create proper tests following existing patterns:
- Use `test/helpers/test_helpers.dart` for mock setup
- Follow existing naming: `*_test.dart`
- Include setup/teardown for global state reset
- Use `Future.delayed(Duration(milliseconds: 500-800))` for async BLoC settling
- Test both success AND failure paths
- Test Thai language content rendering where applicable

### 2.5 Integration Test Validation
Integration tests (`test/integration/`) verify cross-module contracts:
- **Service ↔ BLoC**: service responses correctly mapped to BLoC states
- **BLoC ↔ Widget**: state changes trigger correct UI updates
- **Auth ↔ Guard ↔ Navigation**: auth state changes route correctly
- **API ↔ Model**: JSON deserialization matches actual API responses
- **Firebase ↔ Service**: Firestore/Auth/Storage interactions work end-to-end
- **Agent engine**: same seed + inputs → same simulation outcome (determinism)
- **Broker ↔ ManualOrder**: order submission only via Cloud Function, never direct from client
- **Economy ↔ Quest**: quest completion correctly grants coins/XP, cannot go negative

If integration tests are missing for recently changed modules, CREATE them:
- Test the full chain: user action → BLoC event → service call → state update → UI response
- Mock external deps (Firebase, HTTP) but test internal wiring for real
- Verify error propagation across module boundaries

---

## Phase 3: Memory Leak & Resource Cleanup Audit

### 3.1 Dispose Pattern Scan
Scan ALL StatefulWidget classes for resources that MUST be disposed:
- **StreamSubscription**: `.cancel()` in `dispose()`
- **StreamController**: `.close()` in `dispose()`
- **AnimationController**: `.dispose()` in `dispose()`
- **TextEditingController**: `.dispose()` in `dispose()`
- **ScrollController**: `.dispose()` in `dispose()`
- **FocusNode**: `.dispose()` in `dispose()`
- **Timer / Timer.periodic**: `.cancel()` in `dispose()`
- **WebSocketChannel**: `.sink.close()` in `dispose()`
- **VideoPlayerController / ChewieController**: `.dispose()` in `dispose()`
- **PageController**: `.dispose()` in `dispose()`
- **TabController**: `.dispose()` in `dispose()`

For each: grep for creation (constructor/`.listen()`), then verify matching cleanup in `dispose()`.
Pattern to detect:
```bash
# Find all StreamSubscription fields, then check their dispose
grep -rn 'StreamSubscription' lib/ --include='*.dart'
grep -rn 'Timer\.' lib/ --include='*.dart'
grep -rn '\.listen(' lib/ --include='*.dart'
```

### 3.2 BLoC Close Safety
- Verify all BLoCs call `super.close()` and cancel internal subscriptions in `close()`
- Check that no `emit()` is called after `close()` — guard with `if (isClosed) return;`
- Verify BlocProvider uses `create` (auto-close) not `value` (manual close) where appropriate

### 3.3 High-Risk Leak Surfaces (Aslan Pixel-specific)
Focus extra attention on these files:
- `features/home/` — Flame `GameWidget`, Timer.periodic for idle task polling, OverlayEntry for dialogue bubbles
- `features/world/` — Firestore plaza presence listeners, ghost player update timer (5s interval)
- `features/agents/` — StreamSubscription for agent state updates, BLoC close safety
- `features/broker/` — StreamSubscription for portfolio sync, order status polling
- `features/feed/` — Firestore paginated stream, ScrollController for infinite scroll
- `data/datasources/ai_service.dart` — HTTP request cancellation on widget dispose
- Any screen using `WidgetsBindingObserver` — must remove observer in `dispose()`

### 3.4 Async Lifecycle Safety
- **BuildContext after await**: Any `await` in a widget method must check `if (!mounted) return;` before using `context`
- **setState after dispose**: Any async callback must guard `if (mounted) setState(...)`
- **Navigator after async**: `Navigator.push/pop` after `await` must check `mounted`
- **Subscription callbacks**: Callbacks registered via `.listen()` must not reference disposed widget state

### 3.5 Memory Leak Tests
Create or verify tests exist for leak-prone screens:
```dart
testWidgets('HomeScreen (Flame room) disposes all resources', (tester) async {
  await tester.pumpWidget(MaterialApp(home: HomeScreen()));
  await tester.pumpAndSettle();
  // Navigate away — triggers dispose
  await tester.pumpWidget(MaterialApp(home: Container()));
  await tester.pumpAndSettle();
  // Verify no timers/subscriptions remain active
});
```

For each high-risk screen:
- Pump the widget → interact → navigate away → verify dispose called
- Check that Timer.periodic callbacks stop firing after dispose
- Check that StreamSubscription callbacks stop after cancel

---

## Phase 4: Critical Workflow Validation

### 4.1 Auth Flow Integrity
- Guest → Sign up → Home (room spawn)
- Guest → Sign in (email/Google/Apple) → Home
- Logged in → Logout → Guest mode
- Onboarding: avatar → interest → risk style → room spawn → first agent → first quest
- Token refresh / session expiry handling
- Feature flag gating via Firebase Remote Config (`brokerEnabled`, `plazaEnabled`, `pixelEditorEnabled`)

### 4.2 Navigation & State
- Deep link handling
- Back button behavior
- Tab switching state preservation
- Screen dispose cleanup (verify no leaked controllers between tab switches)

### 4.3 Data Flow
- Loading → Success → Error state transitions
- Optimistic updates with rollback
- Cache invalidation
- Pagination / infinite scroll

### 4.4 Network Resilience
- Timeout handling — verify retry logic with exponential backoff
- No network — verify offline error states display correctly
- Slow network — verify loading indicators show, no double-tap issues
- API error responses (400/401/403/500) — verify proper error messages

---

## Phase 5: Accessibility & Golden Tests

### 5.1 Accessibility Audit
Run on key screens (Home/Room, Feed, Finance, Broker/Portfolio, Auth/SignIn, Profile):
```dart
await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
await expectLater(tester, meetsGuideline(textContrastGuideline));
```
- Tap targets must be >= 48x48dp (Android) / 44x44dp (iOS)
- Text contrast ratio >= 4.5:1 (especially Thai text on dark backgrounds)
- All interactive elements must have semantic labels

### 5.2 Golden Tests (Visual Regression)
Create golden baselines for visually critical widgets:
- Agent card (idle / working / celebrating states)
- Prediction event card
- Portfolio summary card
- AI insight card
- Navigation bar states
```dart
await expectLater(find.byType(AgentCard), matchesGoldenFile('goldens/agent_card_idle.png'));
```
Update goldens: `flutter test --update-goldens`

### 5.3 Service Contract Tests
Verify Flutter models parse data correctly:
- Store fixture JSONs in `test/fixtures/` for Firestore snapshots, broker API responses
- Test `fromJson()` / `fromFirestore()` on every model against real fixture data
- Test edge cases: null fields, empty arrays, missing keys
- Simulation engine: test with fixture inputs, verify output within expected range

### 5.4 Smoke Tests
Tag critical-path tests for fast pre-deploy validation:
- App launches without crash
- Auth flow: sign in → room screen renders
- Flame game widget loads without exception
- Navigation between all main tabs (Home, World, Feed, Finance, Profile)
- Demo broker connects and portfolio renders
Run: `flutter test --tags smoke` (should finish in < 60 seconds)

---

## Phase 6: Fix & Verify Loop

**This is critical — do NOT stop at reporting.**

1. Fix every error, warning, and test failure found
2. Fix every memory leak (missing dispose/cancel/close)
3. Re-run `flutter analyze` — must be clean
4. Re-run `flutter test` — must be 100% green
5. If new fixes break other tests, fix those too
6. Repeat until EVERYTHING passes

---

## Phase 7: Final Report

Present a summary table:

| Category | Status | Details |
|----------|--------|---------|
| Static Analysis (lib/) | PASS/FAIL | errors/warnings count |
| Static Analysis (test/) | PASS/FAIL | errors/warnings count |
| Import/Export Cleanup | count removed | redundant/unused/duplicate |
| Unit Tests | X/Y passed | failures listed |
| Widget Tests | X/Y passed | failures listed |
| Flow/E2E Tests | X/Y passed | failures listed |
| Integration Tests | X/Y passed | failures listed |
| Coverage | X% | gaps identified |
| Memory Leaks Found | count | files + resource type |
| Memory Leaks Fixed | count | dispose/cancel/close added |
| Accessibility Issues | count | tap targets, contrast |
| Security Issues | count | severity levels |
| Performance Issues | count | severity levels |
| Missing Tests Created | count | files listed |
| Fixes Applied | count | files modified |

End with: **READY FOR PRODUCTION** or **NEEDS ATTENTION** with remaining items.
