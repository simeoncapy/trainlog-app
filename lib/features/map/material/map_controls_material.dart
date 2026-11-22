import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_widget.dart';
import 'package:trainlog_app/ui/tokens/app_colors.dart';
import 'package:trainlog_app/ui/tokens/app_nav_bar_theme.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

/// Recenter / follow, Material: two blurred round buttons stacked in one
/// rounded card, above the 56 px tall "New trip" FAB.
class MaterialMapLocationControls extends StatelessWidget {
  const MaterialMapLocationControls({
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
    final navColors = Theme.of(context).extension<AppNavBarColors>()!;
    return Positioned(
      bottom: 16 + MediaQuery.of(context).padding.bottom + 56 + 12,
      right: 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: navColors.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Recenter user
                AdaptiveFilledIconButton(
                  onPressed: onRecenter,
                  colorScheme: FilledButtonColorScheme.floating,
                  child: const Icon(Icons.my_location),
                ),
                // Follow user
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: navColors.inactive, width: 0.5),
                    ),
                  ),
                  child: AdaptiveFilledIconButton(
                    onPressed: onFollow,
                    colorScheme: FilledButtonColorScheme.floating,
                    child: Icon(
                      following
                          ? Symbols.frame_person_off
                          : Symbols.frame_person,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Round blurred search button, at the top of the map's top-right column.
class MaterialMapSearchButton extends StatelessWidget {
  const MaterialMapSearchButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final navColors = Theme.of(context).extension<AppNavBarColors>()!;
    return Tooltip(
      message: AppLocalizations.of(context)!.mapSearchLocationButton,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            color: navColors.background,
            child: AdaptiveFilledIconButton(
              onPressed: onPressed,
              colorScheme: FilledButtonColorScheme.floating,
              child: Icon(AdaptiveIcons.search),
            ),
          ),
        ),
      ),
    );
  }
}

/// Smaller round blurred button under the search one (filter, compass).
class MaterialMapSmallButton extends StatelessWidget {
  const MaterialMapSmallButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final Widget icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final navColors = Theme.of(context).extension<AppNavBarColors>()!;
    final (_, fg) = FilledButtonColorScheme.resolveColors(
      context,
      FilledButtonColorScheme.floating,
    );

    return Tooltip(
      message: tooltip,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: navColors.background,
            child: InkWell(
              onTap: onPressed,
              child: SizedBox.square(
                dimension: 36,
                child: Center(
                  child: IconTheme(
                    data: IconThemeData(size: 20, color: fg),
                    child: icon,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
