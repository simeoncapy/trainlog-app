import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:trainlog_app/features/map/cupertino/map_controls_cupertino.dart';
import 'package:trainlog_app/features/map/material/map_controls_material.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/design.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

// The controls floating over the map. Each picks its Material rendering
// (material/map_controls_material.dart) or its iOS 26 one
// (cupertino/map_controls_cupertino.dart). They return Positioned widgets:
// put them directly in the map's Stack.

/// Bottom-right: recenter on the user, follow the user.
class MapLocationControls extends StatelessWidget {
  const MapLocationControls({
    super.key,
    required this.following,
    required this.onRecenter,
    required this.onFollow,
  });

  /// The map follows the user: the follow button turns it off.
  final bool following;
  final VoidCallback onRecenter;
  final VoidCallback onFollow;

  @override
  Widget build(BuildContext context) => PlatformView(
    material: (_) => MaterialMapLocationControls(
      following: following,
      onRecenter: onRecenter,
      onFollow: onFollow,
    ),
    cupertino: (_) => CupertinoMapLocationControls(
      following: following,
      onRecenter: onRecenter,
      onFollow: onFollow,
    ),
  );
}

/// Top-right column: search and filter, then the compass while the map is
/// rotated away from north (tapping it brings north back up, which hides it
/// again). Android shows separate round buttons; iOS groups search and
/// filter in one glass capsule, with the compass apart below it.
class MapTopControls extends StatelessWidget {
  const MapTopControls({
    super.key,
    required this.rotation,
    required this.onSearch,
    required this.onFilter,
    required this.onResetOrientation,
  });

  /// Map rotation in degrees.
  final ValueListenable<double> rotation;
  final VoidCallback onSearch;
  final VoidCallback onFilter;
  final VoidCallback onResetOrientation;

  @override
  Widget build(BuildContext context) {
    final filterTooltip = AppLocalizations.of(context)!.filterButton;
    return PlatformView(
      material: (_) => MapTopControlsLayout(
        top: 12,
        buttons: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MaterialMapSearchButton(onPressed: onSearch),
            const SizedBox(height: 10),
            MaterialMapSmallButton(
              icon: Icon(AdaptiveIcons.filter),
              tooltip: filterTooltip,
              onPressed: onFilter,
            ),
          ],
        ),
        compassButton: MaterialMapSmallButton.new,
        controls: this,
      ),
      cupertino: (_) => MapTopControlsLayout(
        top: 8,
        buttons: CupertinoMapSearchFilterGroup(
          onSearch: onSearch,
          onFilter: onFilter,
        ),
        compassButton: CupertinoMapSmallButton.new,
        controls: this,
      ),
    );
  }
}

/// Builds the round compass button of one design.
typedef MapSmallButtonBuilder =
    Widget Function({
      Key? key,
      required Widget icon,
      required String tooltip,
      required VoidCallback onPressed,
    });

/// The column of [MapTopControls]: the search and filter [buttons] of one
/// design, then the compass.
class MapTopControlsLayout extends StatelessWidget {
  const MapTopControlsLayout({
    super.key,
    required this.top,
    required this.buttons,
    required this.compassButton,
    required this.controls,
  });

  /// Distance under the status bar.
  final double top;
  final Widget buttons;
  final MapSmallButtonBuilder compassButton;
  final MapTopControls controls;

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final compass = ValueListenableBuilder<double>(
      valueListenable: controls.rotation,
      builder: (context, rotation, _) {
        final r = rotation % 360;
        final isNorth = r < 0.5 || r > 359.5;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: isNorth
              ? const SizedBox.shrink()
              : Padding(
                  key: const ValueKey('compass'),
                  padding: const EdgeInsets.only(top: 10),
                  child: compassButton(
                    icon: Transform.rotate(
                      angle: -(rotation + 45.0) * (math.pi / 180.0),
                      child: Icon(AdaptiveIcons.compass),
                    ),
                    tooltip: appLocalizations.mapResetOrientation,
                    onPressed: controls.onResetOrientation,
                  ),
                ),
        );
      },
    );

    return Positioned(
      top: MediaQuery.of(context).padding.top + top,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [buttons, compass],
      ),
    );
  }
}

/// Safe area of the loading screen: the iOS map runs under the status bar
/// and the floating tab bar, so the message keeps clear of them; Android's
/// shell already keeps the page clear.
class MapLoadingSafeArea extends StatelessWidget {
  const MapLoadingSafeArea({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => PlatformView(
    material: (_) => SafeArea(
      top: false,
      bottom: false,
      left: false,
      right: false,
      child: child,
    ),
    cupertino: (_) => SafeArea(left: false, right: false, child: child),
  );
}
