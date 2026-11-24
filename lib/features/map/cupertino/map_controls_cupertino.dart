import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Tooltip;
import 'package:material_symbols_icons/symbols.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/navigation/nav_models.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_bottom_navbar.dart'
    show kNavBarClearance;
import 'package:trainlog_app/ui/cupertino/liquid_glass.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// Recenter / follow, iOS 26: one vertical glass capsule, like Apple Maps,
/// just above the tab bar.
class CupertinoMapLocationControls extends StatelessWidget {
  const CupertinoMapLocationControls({
    super.key,
    required this.following,
    required this.onRecenter,
    required this.onFollow,
  });

  final bool following;
  final VoidCallback onRecenter;
  final VoidCallback onFollow;

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return Positioned(
      bottom: kNavBarClearance + MediaQuery.of(context).padding.bottom + 16,
      right: 16,
      child: GlassButtonGroup(
        direction: Axis.vertical,
        children: [
          GlassGroupItem(
            // The "scope" crosshair, close to Android's my_location icon.
            icon: CupertinoIcons.scope,
            onPressed: onRecenter,
            semanticLabel: appLocalizations.mapRecenter,
          ),
          GlassGroupItem(
            icon: following ? Symbols.frame_person_off : Symbols.frame_person,
            onPressed: onFollow,
            semanticLabel: appLocalizations.mapFollowPosition,
          ),
        ],
      ),
    );
  }
}

/// Top-right controls, iOS 26: "New trip" (round amber glass) with the
/// search (round glass) on its left, and the filter under "New trip". While
/// the map is rotated away from north the compass joins the filter, and the
/// round filter button stretches into a two-item capsule (tapping the
/// compass brings north back up, which hides it again).
class CupertinoMapTopControls extends StatelessWidget {
  const CupertinoMapTopControls({
    super.key,
    required this.rotation,
    required this.onSearch,
    required this.onFilter,
    required this.onResetOrientation,
    this.newTrip,
  });

  /// Map rotation in degrees.
  final ValueListenable<double> rotation;
  final VoidCallback onSearch;
  final VoidCallback onFilter;
  final VoidCallback onResetOrientation;
  final AppPrimaryAction? newTrip;

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final add = newTrip;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      right: 16,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CupertinoMapSmallButton(
            icon: Icon(AdaptiveIcons.search),
            tooltip: appLocalizations.mapSearchLocationButton,
            onPressed: onSearch,
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (add != null) ...[
                GlassIconButton(
                  icon: add.icon,
                  tooltip: add.tooltip ?? add.label,
                  onPressed: add.onPressed,
                  prominent: true,
                ),
                const SizedBox(height: 10),
              ],
              _FilterCompassGroup(
                rotation: rotation,
                onFilter: onFilter,
                onResetOrientation: onResetOrientation,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The filter alone (a round glass button), or the filter and the compass
/// in one vertical capsule while the map is not north up. Rebuilds the glass
/// only when the compass shows or hides; the compass needle alone follows
/// each rotation step.
class _FilterCompassGroup extends StatefulWidget {
  const _FilterCompassGroup({
    required this.rotation,
    required this.onFilter,
    required this.onResetOrientation,
  });

  final ValueListenable<double> rotation;
  final VoidCallback onFilter;
  final VoidCallback onResetOrientation;

  @override
  State<_FilterCompassGroup> createState() => _FilterCompassGroupState();
}

class _FilterCompassGroupState extends State<_FilterCompassGroup> {
  late bool _rotated = _isRotated();

  bool _isRotated() {
    final r = widget.rotation.value % 360;
    return !(r < 0.5 || r > 359.5);
  }

  void _onRotation() {
    final rotated = _isRotated();
    if (rotated != _rotated) setState(() => _rotated = rotated);
  }

  @override
  void initState() {
    super.initState();
    widget.rotation.addListener(_onRotation);
  }

  @override
  void didUpdateWidget(_FilterCompassGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rotation != widget.rotation) {
      oldWidget.rotation.removeListener(_onRotation);
      widget.rotation.addListener(_onRotation);
      _rotated = _isRotated();
    }
  }

  @override
  void dispose() {
    widget.rotation.removeListener(_onRotation);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final color = CupertinoColors.label.resolveFrom(context);
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: GlassButtonGroup(
        direction: Axis.vertical,
        children: [
          _GroupSlot(
            label: appLocalizations.filterButton,
            onPressed: widget.onFilter,
            child: Icon(AdaptiveIcons.filter, size: 20, color: color),
          ),
          if (_rotated)
            _GroupSlot(
              label: appLocalizations.mapResetOrientation,
              onPressed: widget.onResetOrientation,
              child: ValueListenableBuilder<double>(
                valueListenable: widget.rotation,
                builder: (_, rotation, child) => Transform.rotate(
                  angle: -(rotation + 45.0) * (math.pi / 180.0),
                  child: child,
                ),
                child: Icon(AdaptiveIcons.compass, size: 20, color: color),
              ),
            ),
        ],
      ),
    );
  }
}

/// One square, tappable slot of a vertical [GlassButtonGroup] whose icon is
/// not a plain [IconData] (the compass needle turns with the map).
class _GroupSlot extends StatelessWidget {
  const _GroupSlot({
    required this.label,
    required this.onPressed,
    required this.child,
  });

  final String label;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Semantics(
      button: true,
      label: label,
      child: GlassPressable(
        onPressed: onPressed,
        pressedScale: 1.15,
        child: SizedBox.square(dimension: 44, child: Center(child: child)),
      ),
    ),
  );
}

/// Round glass button at the default size (the search, next to "New trip").
class CupertinoMapSmallButton extends StatelessWidget {
  const CupertinoMapSmallButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final Widget icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => GlassIconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    child: IconTheme(
      data: IconThemeData(
        size: 20,
        color: CupertinoColors.label.resolveFrom(context),
      ),
      child: icon,
    ),
  );
}
