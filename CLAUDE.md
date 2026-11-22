# Trainlog app: notes for Claude

Flutter app for Trainlog, on Android (Material 3) and iOS (Apple HIG, iOS 26 Liquid Glass). The maintainer writes in French: reply in French. Code, comments and commit messages are in English.

## The one principle

The model and the controller are written once; only the view changes per platform.

- **Model**: `lib/core/data` (models, database, `TripsRepository`) and `lib/core/services` (API).
- **Controller**: the app-wide providers in `lib/core/providers`, and one controller per screen (`<screen>_controller.dart`, a `ChangeNotifier`) for that screen's state and actions.
- **View**: one Material view and one iOS view per screen, reading the same controller.

A bug fixed in a controller is fixed on both platforms. A change to the iOS view cannot change Android, because it is not in the same file.

## Structure

```
lib/
  core/
    data/ services/ providers/    shared by both platforms
  features/<screen>/
    <screen>.dart                 entry: picks the view with PlatformView
    <screen>_controller.dart      state + actions (foundation.dart only)
    material/                     the Material 3 view (Android)
    cupertino/                    the iOS view (HIG + Liquid Glass)
  ui/
    design.dart                   DesignLanguage, AppDesign, PlatformView
    tokens/                       AppColors, AppTheme (Material + Cupertino), palettes
    adaptive/                     one API, two renderings: AdaptiveDialog,
                                  showAdaptiveContentSheet, AdaptiveSwitch,
                                  AdaptiveSegmentedButton, AdaptivePopup…
    cupertino/                    iOS-only components: liquid_glass.dart,
                                  glass_filter_parts.dart, AppleBrandFont
  navigation/                     MaterialShell / CupertinoShell, picked by PlatformShell
  widgets/                        shared widgets not yet sorted into ui/
  app/                            AppRoot, provider wiring, globals
```

`core/` is not a catch-all: it only holds the former `data/`, `services/` and `providers/` folders, kept apart.

Most screens are not migrated yet (see "Migration status"). When you touch one, move it towards this layout rather than adding another platform branch to it.

## Rules

1. **A controller imports `foundation.dart` only**, never `material.dart`, `cupertino.dart` or `widgets.dart`, and holds no translated text: it exposes state and error codes, the view turns them into words.
2. **`lib/core` never imports a view** (`features/`, `ui/`, `navigation/`, `widgets/`, `app/`), Cupertino or Liquid Glass.
3. **`liquid_glass_widgets` is imported only in `lib/ui/cupertino/` and `lib/ui/adaptive/`** (and `main.dart`, which starts it).
4. **A `material/` folder never imports a `cupertino/` folder**, and the other way round.
5. **Screens do not test the platform.** No `AppPlatform.isApple` in `features/`, `widgets/` or `navigation/`: the entry file picks the view once with `PlatformView`.
6. **Dialogs, alerts, action sheets and sheets go through `lib/ui/adaptive/`.** The iOS font, tint and destructive style are applied there once; screens never call `showCupertinoDialog`, `CupertinoAlertDialog` or `AppleBrandFont` themselves.
7. **No raw `fontSize` or `Color(0x…)` in a new view**: take them from `lib/ui/tokens/` or the theme.

`test/architecture_test.dart` enforces rules 1 to 5 on every `flutter test`. Each rule lists the files that broke it when it was introduced (`known`). A new file breaking a rule fails the test; a listed file that no longer breaks it also fails, so remove it from the list when you fix it. Never add a file to a `known` list.

## Design decisions

- **Fonts**: Hanken Grotesk for all interface and body text, on both platforms (iOS included, never San Francisco). Space Grotesk for titles, always bold (`FontWeight.w700`) on both platforms; `AppTheme.displayFont` is already bold. Space Mono for figures.
- **iOS letter spacing**: Hanken Grotesk keeps its own spacing (`letterSpacing: 0`); do not copy San Francisco's tracking.
- **iOS segmented controls** show text only or an icon only, never both (Apple guideline).
- **iOS primary button** (e.g. "Show N trips" in the filter sheets) is solid amber, not tinted glass (tinted glass looks yellow or red), and keeps its icon.
- **iOS settings**: one icon colour per section.
- **Map theme**: the map has its own light / dark / same-as-app setting; on iOS the map page chrome and its sheets follow it (`MapThemeScope`).
- **Android must not change by accident.** A refactor moves Material code without editing it; compare Android screenshots before and after when a Material file is touched.
- `PastFutureSelector`, `VehicleEnergySelector` and `TripVisibilitySelector` (`lib/widgets/`) are unused but kept on purpose for now.
- In-app account deletion stays disabled until the Trainlog website supports it.

## Adding or migrating a screen

1. Put the state and actions in `<screen>_controller.dart` (a `ChangeNotifier`, `foundation.dart` only). Calls to the API and to the providers go there, not in a widget.
2. Write `material/<screen>_material_view.dart` and `cupertino/<screen>_cupertino_view.dart`, each reading the controller. Move the existing Material code as is.
3. In `<screen>.dart`, provide the controller and pick the view:

   ```dart
   ChangeNotifierProvider(
     create: (_) => TripsFilterController(repo),
     child: PlatformView(
       material: (_) => const TripsFilterMaterialView(),
       cupertino: (_) => const TripsFilterCupertinoView(),
     ),
   )
   ```
4. Remove the screen from the `known` lists it no longer breaks in `test/architecture_test.dart`.
5. Add controller unit tests, and widget tests for both views.

## Testing

```sh
flutter test
flutter analyze
```

The app normally draws the design of the device. In a widget test, force one with `AppPlatform.debugDesignOverride = DesignLanguage.cupertino;` (reset it in `tearDown`) to test the iOS view on any machine; see `test/adaptive_dialog_test.dart`. `AppDesign` can also override the design for one subtree.

## Migration status

Done (branch `ios-material-adaptation-refactor`):

- Foundation: `lib/core`, `lib/ui`, `AppDesign` / `PlatformView`, the architecture test, iOS dialogs through `AdaptiveDialog`, Hanken Grotesk everywhere, bold titles.
- Map filter (`features/map/filter/`): entry `MapFilterSheet`, state in `PolylineProvider`.
- Trips search & filter (`features/trips/search_filter_sheet/`): `TripsFilterController`, one view per design.
- Trip details actions (`features/trips/detail_sheet/`): `TripActionsController`, one view per design.
- Settings (`features/settings/`): one page built from facade rows (`widgets/settings_group.dart`), each picking its Material or iOS rendering (`widgets/material/`, `widgets/cupertino/`). A row that behaves differently on iOS takes an `apple…` parameter (`appleIconColor`, `appleOnTap`). `SettingsVm` still imports Flutter (known exception).

Still branching on the platform inside (see the `known` lists): the trips filter pickers (`GroupPickerView`, `WhenSection`, `sheet_common`), `AppStepsTabBar`, `BottomSheetPicker`, the map page, the trip details sheet, the Smart Prerecorder, the trip editor and the trips page. Migrate them one per branch as they are redesigned.

## Branches

- Feature branches merge into `general-improvement`, which merges into `main`.
- iOS redesign: sub-branches merge into `ios-redesign-liquid-glass`.
- Architecture refactor: sub-branches start from and merge into `ios-material-adaptation-refactor`, which merges into `ios-redesign-liquid-glass`.
