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
    design.dart                   DesignLanguage, AppDesign, PlatformView,
                                  PlatformAppBar, byDesign
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

Every screen follows this layout (see "Migration status"). Keep it that way: a new difference between the designs goes in the two views, never in a platform branch.

## Rules

1. **A controller imports `foundation.dart` only**, never `material.dart`, `cupertino.dart` or `widgets.dart`, and holds no translated text: it exposes state and error codes, the view turns them into words.
2. **`lib/core` never imports a view** (`features/`, `ui/`, `navigation/`, `widgets/`, `app/`), Cupertino or Liquid Glass.
3. **`liquid_glass_widgets` is imported only in `lib/ui/cupertino/` and `lib/ui/adaptive/`** (and `main.dart`, which starts it).
4. **A `material/` folder never imports a `cupertino/` folder**, and the other way round.
5. **Screens do not test the platform.** No `AppPlatform.isApple`, `AppPlatform.design` or `AppDesign.of` in `features/`, `widgets/` or `navigation/`. The entry file picks the view with `PlatformView`; for what is not a widget (opening a dialog or a sheet) use `byDesign(context, material: …, cupertino: …)`, and for a Scaffold app bar `PlatformAppBar`. A small row or control that differs per design is a facade picking a `Material…` or `Cupertino…` widget with `PlatformView` (see the settings rows, the map controls). A design token used by shared sections comes from an inherited style the iOS view provides (see `TripDetailsStyle`), not from a platform test.
6. **Dialogs, alerts, action sheets and sheets go through `lib/ui/adaptive/`.** The iOS font, tint and destructive style are applied there once; screens never call `showCupertinoDialog`, `CupertinoAlertDialog` or `AppleBrandFont` themselves.
7. **No raw `fontSize` or `Color(0x…)` in a new view**: take them from `lib/ui/tokens/` or the theme.
8. **Short messages go through `AdaptiveInformationMessage`** (`showInfo`, or `showInfoWithIcon` for the package's toast with an icon): a SnackBar on Android, the Liquid Glass `AppGlassToast` on iOS. Screens never build a `SnackBar` themselves (only a `material/` folder or the Material shell may).

`test/architecture_test.dart` enforces rules 1 to 5 and 8 on every `flutter test`, and every file under `lib/` follows them. A rule added later may list the files that break it when it is introduced (`known`); that list only shrinks. Never add a file to a `known` list.

## Design decisions

- **Fonts**: Hanken Grotesk for all interface and body text, on both platforms (iOS included, never San Francisco). Space Grotesk for titles, always bold (`FontWeight.w700`) on both platforms; `AppTheme.displayFont` is already bold. Space Mono for figures.
- **iOS letter spacing**: Hanken Grotesk keeps its own spacing (`letterSpacing: 0`); do not copy San Francisco's tracking.
- **iOS segmented controls** show text only or an icon only, never both (Apple guideline).
- **iOS filter sheets** (map filter, trips search & filter) have no "Show N trips" button: the ✕ closes, the trip count is a live line under the title (`GlassSheetHeader.subtitle`), and closing the trips filter (✕ or swipe down) applies it. Android keeps its button.
- **iOS tab bar**: four tabs only (Map, Trips, Ranking, Statistics); the Trainlog menu ("Home") is the round glass button at the trailing end of the bar, on every page. "New trip" is the page's own action: on Trips the amber button at the top right of the navigation bar, on the map a round amber button at the top right, with the search on its left and the filter under it (the compass joins the filter in one capsule while the map is rotated). Android keeps its centre menu button and its FAB.
- **iOS primary button**, where one is needed (`GlassPrimaryButton`), is solid amber, not tinted glass (tinted glass looks yellow or red), and keeps its icon.
- **iOS trip details sheet**: the actions are a row of four tiles pinned under the content, as on Android (icon above label, Apple Maps' place action row): Edit filled amber, Duplicate and Share tinted amber, Delete tinted red. Glass ✕ and glass visibility chip of the same height; duration without pill; distance and speed as captioned stats, not cards, scrolled sideways when they overflow (`TripDetailsStyle`).
- **Titles' capitalisation lives in the ARB**, per language (title case in English, sentence case in French); code never title-cases. iOS shows section titles as written (no all-caps, Space Grotesk bold, amber); Android may upper-case them (trip details: `TripDetailsStyle.capsTitles`).
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

Done for the whole app (branch `ios-material-adaptation-refactor`): every `known` list of the architecture test is empty.

- Foundation: `lib/core`, `lib/ui`, `AppDesign` / `PlatformView` / `PlatformAppBar` / `byDesign`, the architecture test, iOS dialogs through `AdaptiveDialog`, Hanken Grotesk everywhere, bold titles.
- `lib/core` holds no view: the ranking model (`core/data/models/ranking.dart`), `TripVisibility`, `EnergyType` and `TimeMoment` moved there; their labels and icons are view extensions in `features/`. The statistics graph images are an extension in `features/statistics`.
- Screens with a controller and two views: map page (`MapPageController`: position, follow, place search — full-screen overlay on Android, glass search bar above the keyboard with a blurred results panel on iOS; the flutter_map camera stays in the entry, which applies the controller's camera requests; shared `MapCanvas`), trips page (`TripsPageController`), trips search & filter (`TripsFilterController`, When section, country / operator picker), trip details actions (`TripActionsController`).
- Screens with an entry picking two views around an existing provider: Smart Prerecorder (`PreRecordProvider`, `SprPageActions`), trip details sheet (shared `TripDetailsSections`, iOS `TripDetailsStyle`), map filter (`PolylineProvider`).
- Facades over Material / iOS renderings: settings rows (`SettingsController`), map controls, trip form app bar and section bar.
- Adaptive components moved to `lib/ui/adaptive`: `AppStepsTabBar`, the bottom sheet picker, `AdaptiveSearchField`, `AdaptiveProgressIndicator`, `AdaptiveSheetHandle`; to `lib/ui/cupertino`: `GlassPopUpButton`, the glass date popover.

Not done, worth doing as screens are redesigned: the trip editor still keeps its state in the widget rather than in a controller.

## Branches

- Feature branches merge into `general-improvement`, which merges into `main`.
- iOS redesign: sub-branches merge into `ios-redesign-liquid-glass`.
- Architecture refactor: sub-branches start from and merge into `ios-material-adaptation-refactor`, which merges into `ios-redesign-liquid-glass`.
