---
description: Copy and adapt a UI component from AslanApp (/Library/WebServer/Documents/aslanapp/) to Aslan Pixel. Reads the original file, adapts imports, colors, and naming for the new project structure. Use when building auth screens, widgets, loaders, appbar, fields, theme, routing, BLoC, or any component that mirrors AslanApp patterns.
argument-hint: "[component path relative to aslanapp/lib, e.g. widgets/appbar/appbar_header.dart]"
---

# Copy AslanApp Component — Aslan Pixel

Read an AslanApp component and produce an adapted version for Aslan Pixel.

**AslanApp reference root**: `/Library/WebServer/Documents/aslanapp/`
**Aslan Pixel target root**: `/Library/WebServer/Documents/AslanPixel/lib/`

## Key reference map

| AslanApp path | Aslan Pixel target | Notes |
|--------------|-------------------|-------|
| `lib/widgets/appbar/appbar_header.dart` | `lib/shared/widgets/appbar/` | Adapt colors |
| `lib/widgets/loader/loaderX.dart` | `lib/shared/widgets/loader/` | Direct copy |
| `lib/widgets/loader/color_loader_3.dart` | `lib/shared/widgets/loader/` | Direct copy |
| `lib/widgets/field/custom_text_field.dart` | `lib/shared/widgets/field/` | Adapt theme |
| `lib/widgets/field/custom_dropdown_field.dart` | `lib/shared/widgets/field/` | Adapt theme |
| `lib/widgets/style.dart` | `lib/core/theme/style.dart` | Adapt palette |
| `lib/config/app_colors.dart` | `lib/core/config/app_colors.dart` | New pixel palette |
| `lib/config/env_config.dart` | `lib/core/config/env_config.dart` | Add pixel vars |
| `lib/config/constant.dart` | `lib/core/config/constant.dart` | Adapt |
| `lib/app/bloc/` | `lib/core/app/bloc/` | Mirror exactly |
| `lib/router/route.dart` | `lib/core/routing/route.dart` | Mirror exactly |
| `lib/router/route_generator.dart` | `lib/core/routing/route_generator.dart` | Mirror exactly |
| `lib/screens/authen/` | `lib/features/auth/` | Mirror pattern |
| `lib/extensions/l10n_extension.dart` | `lib/core/extensions/` | Direct copy |
| `lib/services/notification_service.dart` | `lib/data/datasources/notification_service.dart` | Adapt |
| `lib/main.dart` | `lib/main.dart` | Mirror Firebase+BLoC init |
| `lib/widgets/chart/` | `lib/shared/widgets/chart/` | Copy, use for finance screens |
| `lib/widgets/animated_sparkline.dart` | `lib/shared/widgets/` | Copy for portfolio chart |

## Workflow

1. Read the source file at `/Library/WebServer/Documents/aslanapp/lib/[argument]`
2. Identify all imports — map to Aslan Pixel package name (`aslan_pixel`)
3. Replace `aslanapp` → `aslan_pixel` package references
4. Update color references: map `AppColors.X` to Aslan Pixel's pixel-themed palette
5. Update folder path references to match Aslan Pixel structure
6. Keep BLoC logic identical — only change imports and naming
7. Write to the appropriate target path in Aslan Pixel

## Adaptation Rules

- Package: `aslanapp` → `aslan_pixel`
- Import root: `package:aslanapp/` → `package:aslan_pixel/`
- Colors: read `aslanapp/lib/config/app_colors.dart` for reference, then map to Aslan Pixel pixel-themed palette (navy, neon, gold, cyber-finance motifs)
- Fonts: swap to pixel-appropriate fonts (e.g. Press Start 2P for headings, clean sans for body)
- Do NOT copy screen-specific business logic — only shared infrastructure
- BLoC events/states: keep identical structure, rename domain if needed

## Never copy

- Real financial data or user data
- Hardcoded API keys or secrets
- Feature-specific BLoC state that is AslanApp-specific
