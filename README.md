# Trainlog app

Flutter app for [Trainlog](https://trainlog.me): record your trips, see them on a map, browse statistics and rankings. It runs on Android and iOS from one code base:

- **Android** follows Material 3.
- **iOS** follows Apple's Human Interface Guidelines, with the iOS 26 Liquid Glass look (via [`liquid_glass_widgets`](https://pub.dev/packages/liquid_glass_widgets)).

The data, the server calls and the app state are shared by both platforms. Only the views differ.

## Getting started

```sh
flutter pub get
flutter run            # on a connected device or simulator
flutter test           # unit, widget and architecture tests
flutter analyze
```

Firebase configuration files are not in the repository (`lib/firebase_options.dart`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`). Ask the maintainer for them or generate your own with `flutterfire configure`.

Translations live in `lib/l10n/app_*.arb` (English, French, Japanese, Tagalog); `flutter gen-l10n` regenerates the Dart files.

## Project structure

```
lib/
  core/          Model and controller layer shared by both platforms
    data/        Models, local database, TripsRepository
    services/    Trainlog API client and other services
    providers/   App-wide state (ChangeNotifier): trips, settings, map…
  features/      One folder per screen
  ui/            Design system
    design.dart  DesignLanguage, AppDesign, PlatformView, PlatformAppBar, byDesign
    tokens/      Colours, typography, Material and Cupertino themes
    adaptive/    One API, two renderings (dialogs, sheets, switch…)
    cupertino/   iOS-only components (Liquid Glass)
  navigation/    The Material and Cupertino shells (tab bars, routes)
  widgets/       Shared widgets not yet sorted into ui/
  app/           App root, provider wiring, globals
  utils/         Helpers (dates, formatting, platform)
  l10n/          Translations
```

A screen keeps its logic in a controller and has one view per platform, chosen once with `PlatformView`. The full rules, and the reasons for them, are in [CLAUDE.md](CLAUDE.md). `test/architecture_test.dart` checks them on every test run.

## Branches

Feature branches merge into `general-improvement`, which merges into `main`. The iOS redesign has its own integration branch, `ios-redesign-liquid-glass`, and the architecture refactor works on `ios-material-adaptation-refactor` (sub-branches merge into it).
