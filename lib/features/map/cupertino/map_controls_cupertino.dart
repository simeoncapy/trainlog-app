import 'package:flutter/cupertino.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_bottom_navbar.dart'
    show kNavBarActionRight, kNavBarActionSize, navBarActionBottom;
import 'package:trainlog_app/ui/cupertino/liquid_glass.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// Recenter / follow, iOS 26: one vertical glass capsule, like Apple Maps.
/// It sits above "New trip".
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
      // Above "New trip", which floats above the tab bar's menu button, and
      // centred on the same line.
      bottom: navBarActionBottom(context) + kNavBarActionSize + 12,
      right: kNavBarActionRight + (kNavBarActionSize - 44) / 2,
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

/// Search and filter, iOS 26: one vertical glass capsule at the top of the
/// map's top-right column, like the recenter / follow one.
class CupertinoMapSearchFilterGroup extends StatelessWidget {
  const CupertinoMapSearchFilterGroup({
    super.key,
    required this.onSearch,
    required this.onFilter,
  });

  final VoidCallback onSearch;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return GlassButtonGroup(
      direction: Axis.vertical,
      children: [
        GlassGroupItem(
          icon: AdaptiveIcons.search,
          onPressed: onSearch,
          semanticLabel: appLocalizations.mapSearchLocationButton,
        ),
        GlassGroupItem(
          icon: AdaptiveIcons.filter,
          onPressed: onFilter,
          semanticLabel: appLocalizations.filterButton,
        ),
      ],
    );
  }
}

/// Round glass button under the search and filter capsule (the compass), at
/// the default size.
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
