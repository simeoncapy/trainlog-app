import 'package:flutter/widgets.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// The two design languages the app is drawn with.
///
/// - [material]: Material 3, on Android (and every non-Apple platform).
/// - [cupertino]: Apple's Human Interface Guidelines with iOS 26 Liquid
///   Glass, on iOS and macOS.
enum DesignLanguage { material, cupertino }

/// Gives the design language to the widgets below it.
///
/// [AppRoot] puts one at the top of the app, built from
/// [AppPlatform.design]. Read it with [AppDesign.of]; with no [AppDesign]
/// above, [AppPlatform.design] is used.
class AppDesign extends InheritedWidget {
  const AppDesign({super.key, required this.language, required super.child});

  final DesignLanguage language;

  static DesignLanguage of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppDesign>()?.language ??
      AppPlatform.design;

  @override
  bool updateShouldNotify(AppDesign oldWidget) =>
      language != oldWidget.language;
}

/// Picks a screen's view for the current design language.
///
/// This is the one place a screen decides between its two views: the
/// Material one (`material/` folder) and the iOS one (`cupertino/` folder).
/// Both read the same controller; neither tests the platform itself.
///
/// ```dart
/// PlatformView(
///   material: (context) => const MapFilterMaterialView(),
///   cupertino: (context) => const MapFilterCupertinoView(),
/// )
/// ```
class PlatformView extends StatelessWidget {
  const PlatformView({
    super.key,
    required this.material,
    required this.cupertino,
  });

  final WidgetBuilder material;
  final WidgetBuilder cupertino;

  @override
  Widget build(BuildContext context) => switch (AppDesign.of(context)) {
    DesignLanguage.material => material(context),
    DesignLanguage.cupertino => cupertino(context),
  };
}

/// The imperative form of [PlatformView], for what is not a widget (opening
/// a dialog, a sheet): runs [material] or [cupertino] for the current design
/// language.
T byDesign<T>(
  BuildContext context, {
  required T Function() material,
  required T Function() cupertino,
}) => switch (AppDesign.of(context)) {
  DesignLanguage.material => material(),
  DesignLanguage.cupertino => cupertino(),
};

/// [PlatformView] for a Scaffold's app bar, which must give its height
/// before it is built: shows [material] or [cupertino], and takes the
/// preferred size of the one the app is drawn with ([AppPlatform.design]).
class PlatformAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PlatformAppBar({
    super.key,
    required this.material,
    required this.cupertino,
  });

  final PreferredSizeWidget material;
  final PreferredSizeWidget cupertino;

  @override
  Size get preferredSize => switch (AppPlatform.design) {
    DesignLanguage.material => material.preferredSize,
    DesignLanguage.cupertino => cupertino.preferredSize,
  };

  @override
  Widget build(BuildContext context) =>
      PlatformView(material: (_) => material, cupertino: (_) => cupertino);
}
