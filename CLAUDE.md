# Aslan Pixel — Claude Code Knowledge Bridge

> This file is loaded into every Claude Code session for this project.
> Keep it up to date as the codebase evolves.

## Project Overview
Aslan Pixel is a Flutter mobile app: Social Financial Network + Idle Pixel World + Broker-connected Portfolio App.
- **Platform**: iOS + Android (Flutter 3.x)
- **State management**: BLoC per feature (flutter_bloc + equatable)
- **Backend**: Firebase (Auth, Firestore, Storage, FCM, Crashlytics, Analytics, Remote Config)
- **Game engine**: Flame (private room, pixel world)
- **AI**: Gemini Flash-Lite (cheap) / Gemini Flash (balanced) — all via GeminiAiService
- **Language**: Thai primary (contentTh fields), English fallback

## Reference Codebase
AslanApp (same patterns): `/Library/WebServer/Documents/aslanapp/`
- Read it before implementing any shared pattern (BLoC, navigation, Firebase)
- Key files to reference: `lib/app/`, `lib/router/`, `lib/widgets/`

## Architecture Rules
1. **BLoC per feature** — no cross-BLoC direct calls, communicate via repository only
2. **Package imports only** — `import 'package:aslan_pixel/...'` not relative `'../../'` between features
3. **Dark-first** — default ThemeMode.dark, test all screens in dark before light
4. **Color system** — use `AppColors.of(context)` or color constants from `core/config/app_colors.dart`
   Primary palette: navy `#0a1628`, neon green `#00f5a0`, gold `#f5c518`, cyber purple `#7b2fff`
5. **No .withOpacity()** — use `.withValues(alpha: X)` (Dart 3.x API)
6. **LLM rule** — AI generates content/flavor text only. Deterministic engine handles all rewards/scores/progression
7. **Broker security** — never store broker tokens client-side, all broker API calls via Cloud Functions
8. **Economy writes** — coins/xp changes ONLY via Firestore transactions, never direct sets

## Folder Structure
```
lib/
├── core/           # config, enums, extensions, routing, utils
├── features/       # one folder per feature
│   ├── agents/     # agent BLoC, idle engine, task engine
│   ├── auth/       # sign in/up, AuthBloc, UserModel
│   ├── broker/     # connector interface, DemoConnector, BrokerBloc
│   ├── feed/       # social feed, FeedBloc, FeedPostCard
│   ├── finance/    # predictions, AI insights, FinancePage
│   ├── follows/    # follow/unfollow, FollowRepository
│   ├── home/       # Flame game, room, HomePage, RoomBloc
│   ├── inventory/  # economy model, EconomyDatasource
│   ├── notifications/ # FCM, NotificationBloc, NotificationPage
│   ├── onboarding/ # 3-step PageView, OnboardingBloc
│   ├── pixel_art/  # canvas editor, PixelArtBloc, export
│   ├── profile/    # ProfileBloc, badges, EditProfilePage
│   ├── quests/     # QuestBloc, QuestGenerator, daily quests
│   └── world/      # public plaza, PlazaBloc, CustomPaint map
├── shared/
│   └── widgets/    # AppBar, loader, field, chart, CoinBadge, EmptyState
└── data/
    └── services/   # AIService, GeminiAiService, CachedAiService
```

## Key Files
| Purpose | File |
|---------|------|
| Color constants | `lib/core/config/app_colors.dart` |
| Global state | `lib/core/config/constant.dart` |
| Route map | `lib/core/routing/route_generator.dart` |
| App entry | `lib/main.dart` |
| Auth BLoC | `lib/features/auth/bloc/auth_bloc.dart` |
| Agent engine | `lib/features/agents/engine/idle_task_engine.dart` |
| AI service | `lib/data/services/gemini_ai_service.dart` |
| Economy writes | `lib/features/inventory/data/datasources/firestore_economy_datasource.dart` |

## Common Patterns

### BLoC template
```dart
class FeatureBloc extends Bloc<FeatureEvent, FeatureState> {
  FeatureBloc(this._repository) : super(FeatureInitial()) {
    on<FeatureStarted>(_onStarted);
  }
  final FeatureRepository _repository;
  StreamSubscription<List<FeatureModel>>? _sub;

  Future<void> _onStarted(FeatureStarted event, Emitter<FeatureState> emit) async {
    emit(FeatureLoading());
    await emit.forEach(
      _repository.watchItems(event.uid),
      onData: (items) => FeatureLoaded(items),
      onError: (e, _) => FeatureError(e.toString()),
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}
```

### Firestore transaction pattern (economy write)
```dart
await _firestore.runTransaction((transaction) async {
  final ref = _firestore.collection('users').doc(uid).collection('economy').doc('balance');
  final snap = await transaction.get(ref);
  final current = snap.data()?['coins'] as int? ?? 0;
  if (current < amount) throw InsufficientCoinsException();
  transaction.update(ref, {'coins': current - amount});
});
```

## What NOT to do
- Don't use `context.read<BLoC>()` inside `build()` — use `BlocBuilder`/`BlocListener`
- Don't commit `.env`, `google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`
- Don't mock Firebase in integration tests — use Firebase Emulator
- Don't add `accessToken` check in `RootPage` for onboarding check — use `onboardingComplete` field
- Don't put business logic in widgets — put in BLoC or repository

## Firebase Setup (one-time manual steps)
1. `flutterfire configure` → generates `lib/firebase_options.dart` (gitignored)
2. Enable: Auth (Google + Apple + Email), Firestore, Storage, Messaging, Crashlytics, Analytics, Remote Config
3. Deploy rules: `firebase deploy --only firestore:rules,firestore:indexes`
4. Set Remote Config defaults: `pixel_world_enabled=true`, `social_feed_enabled=true`, `broker_connect_enabled=false`

## Testing
- Unit tests: `flutter test test/` — BLoC tests with bloc_test, repository mocks with mocktail
- Widget tests: `flutter test test/widget/` — golden tests for agent cards, prediction cards
- Integration: Firebase Emulator Suite (`firebase emulators:start`)
- Run check skill: `/check` — runs full quality audit
