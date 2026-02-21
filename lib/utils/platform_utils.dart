import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class AppPlatform {
  static const bool isWeb = kIsWeb;

  static final bool isApple = 
      !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  static final bool isMaterial = !isApple;
}

class AdaptiveIcons {
  static final bool isA = AppPlatform.isApple; // condense writting

  // General
  static final IconData delete =      isA ? CupertinoIcons.delete : Icons.delete;
  static final IconData copy =        isA ? CupertinoIcons.doc_on_doc : Icons.copy;
  static final IconData share =       isA ? CupertinoIcons.share : Icons.share;
  static final IconData mail =        isA ? CupertinoIcons.mail : Icons.mail;
  
  // Sort
  static final IconData sortAscending = isA ? CupertinoIcons.sort_up : Icons.arrow_upward;
  static final IconData sortDescending = isA ? CupertinoIcons.sort_down : Icons.arrow_downward;

  // Nav bar
  static final IconData map =         isA ? CupertinoIcons.map_fill : Icons.map;
  static final IconData trips = Icons.commute;
  static final IconData ranking =     isA ? CupertinoIcons.rosette : Icons.emoji_events;
  static final IconData statistics =  isA ? CupertinoIcons.chart_bar_alt_fill : Icons.bar_chart;
  static final IconData other =       isA ? CupertinoIcons.ellipsis : Icons.more_horiz;

  // Drawer menu
  static final IconData coverage =    isA ? CupertinoIcons.percent : Icons.percent;
  static final IconData tags =        isA ? CupertinoIcons.tag_fill : Icons.label;
  static final IconData tickets =     isA ? CupertinoIcons.ticket_fill : Icons.confirmation_number;
  static final IconData friends =     isA ? CupertinoIcons.person_2_fill : Icons.people;
  static final IconData smartPrerecorder = isA ? CupertinoIcons.pencil_ellipsis_rectangle : Symbols.checkbook;
  static final IconData settings =    isA ? CupertinoIcons.settings_solid : Icons.settings;
  static final IconData info =        isA ? CupertinoIcons.info_circle_fill : Icons.info;

  // Header menu
  static final IconData logout =      isA ? CupertinoIcons.square_arrow_right_fill : Icons.logout;
  static final IconData inbox =       isA ? CupertinoIcons.tray : Icons.inbox;
  static final IconData ok =          isA ? CupertinoIcons.check_mark_circled_solid : Icons.check_circle;
  static final IconData warning =     isA ? CupertinoIcons.exclamationmark_triangle_fill : Icons.warning;
  static final IconData error =       isA ? CupertinoIcons.exclamationmark_octagon_fill : Icons.error;

  // Settings
  static final IconData theme =       isA ? CupertinoIcons.moon : Icons.dark_mode;
  static final IconData language =    isA ? CupertinoIcons.globe : Icons.language;
  static final IconData date =        isA ? CupertinoIcons.calendar : Icons.date_range;
  static final IconData hour =        isA ? CupertinoIcons.clock : Icons.watch;
  static final IconData currency =    isA ? CupertinoIcons.money_dollar_circle : Icons.currency_exchange;
  static final IconData radar =       isA ? CupertinoIcons.location_circle : Icons.radar;
  static final IconData warningMsg =  isA ? CupertinoIcons.exclamationmark_triangle : Icons.warning;
  static final IconData layers =      isA ? CupertinoIcons.layers : Icons.layers;
  static final IconData palette =     isA ? CupertinoIcons.paintbrush : Icons.palette;
  static final IconData position =    isA ? CupertinoIcons.location : Icons.my_location;
  static final IconData visibility =  isA ? CupertinoIcons.eye : Icons.visibility;
  static final IconData world =       isA ? CupertinoIcons.map : Icons.public;
  static final IconData cache =       isA ? CupertinoIcons.cloud_download : Icons.cloud_download;
  static final IconData deleteAccount =isA ? CupertinoIcons.person_crop_circle_badge_xmark : Icons.no_accounts;
  static final IconData version =     isA ? CupertinoIcons.info_circle : Icons.info_outline;
  static final IconData instance =    isA ? CupertinoIcons.link : Icons.http;

  // Pages
  static final IconData add = isA ? CupertinoIcons.add : Icons.add;
  static final IconData filter = isA ? CupertinoIcons.line_horizontal_3_decrease : Icons.filter_alt;
  static final IconData edit = isA ? CupertinoIcons.pen : Icons.edit;
  static final IconData compass = isA ? CupertinoIcons.compass :  Icons.explore;
}

class AdaptiveTextStyle {
  static final bool isA = AppPlatform.isApple; // condense writting
  
  static TextStyle? title(BuildContext context) => isA ? CupertinoTheme.of(context).textTheme.navTitleTextStyle : Theme.of(context).textTheme.titleLarge;
}

class AdaptiveThemeColor {
  static final bool isA = AppPlatform.isApple; // condense writting

  //static final Color seed = isA ? CupertinoColors.systemBlue : Colors.blue;
  static Color seed(BuildContext context) =>
      isA ? CupertinoTheme.of(context).primaryColor : Theme.of(context).colorScheme.primary;

  // ---- Helpers ----

  static Brightness _brightness(BuildContext context) =>
      isA ? CupertinoTheme.brightnessOf(context) : Theme.of(context).brightness;

  static Color _label(BuildContext context) => isA
      ? CupertinoColors.label.resolveFrom(context)
      : Theme.of(context).colorScheme.onSurface;

  static Color _secondaryLabel(BuildContext context) => isA
      ? CupertinoColors.secondaryLabel.resolveFrom(context)
      : Theme.of(context).colorScheme.onSurfaceVariant;

  static Color _surface(BuildContext context) => isA
      ? CupertinoTheme.of(context).scaffoldBackgroundColor
      : Theme.of(context).colorScheme.surface;

  static Color _surfaceVariant(BuildContext context) => isA
      ? CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context)
      : Theme.of(context).colorScheme.surfaceContainerHighest;

  static Color _tint(BuildContext context) =>
      isA ? CupertinoTheme.of(context).primaryColor : Theme.of(context).colorScheme.primary;

  static Color _tintedFill(
    BuildContext context, {
    required double lightOpacity,
    required double darkOpacity,
    Color? base,
  }) {
    final tint = _tint(context);
    final b = _brightness(context);
    final bg = base ?? _surface(context);
    final opacity = b == Brightness.dark ? darkOpacity : lightOpacity;
    return Color.alphaBlend(tint.withValues(alpha: opacity), bg);
  }

  // ---- Core (Material-like) roles ----

  static Color primary(BuildContext context) =>
      isA ? CupertinoTheme.of(context).primaryColor : Theme.of(context).colorScheme.primary;

  static Color onPrimary(BuildContext context) =>
      isA ? CupertinoColors.white : Theme.of(context).colorScheme.onPrimary;

  static Color secondary(BuildContext context) =>
      isA ? CupertinoColors.systemIndigo.resolveFrom(context) : Theme.of(context).colorScheme.secondary;

  static Color onSecondary(BuildContext context) =>
      isA ? CupertinoColors.white : Theme.of(context).colorScheme.onSecondary;

  static Color tertiary(BuildContext context) =>
      isA ? CupertinoColors.systemTeal.resolveFrom(context) : Theme.of(context).colorScheme.tertiary;

  static Color onTertiary(BuildContext context) =>
      isA ? CupertinoColors.white : Theme.of(context).colorScheme.onTertiary;

  static Color error(BuildContext context) =>
      isA ? CupertinoColors.systemRed.resolveFrom(context) : Theme.of(context).colorScheme.error;

  static Color onError(BuildContext context) =>
      isA ? CupertinoColors.white : Theme.of(context).colorScheme.onError;

  // ---- Containers ----
  // Cupertino approximation: "container" = softly tinted background (or iOS system fill)

  static Color primaryContainer(BuildContext context) => isA
      ? primary(context) //_tintedFill(context, lightOpacity: 0.14, darkOpacity: 0.28, base: _surface(context))
      : Theme.of(context).colorScheme.primaryContainer;

  static Color onPrimaryContainer(BuildContext context) => isA
      ? CupertinoColors.white //_label(context)
      : Theme.of(context).colorScheme.onPrimaryContainer;

  static Color secondaryContainer(BuildContext context) => isA
      ? secondary(context) //CupertinoColors.secondarySystemFill.resolveFrom(context)
      : Theme.of(context).colorScheme.secondaryContainer;

  static Color onSecondaryContainer(BuildContext context) => isA
      ? CupertinoColors.white //_label(context)
      : Theme.of(context).colorScheme.onSecondaryContainer;

  static Color tertiaryContainer(BuildContext context) => isA
      ? CupertinoColors.tertiarySystemFill.resolveFrom(context)
      : Theme.of(context).colorScheme.tertiaryContainer;

  static Color onTertiaryContainer(BuildContext context) => isA
      ? _label(context)
      : Theme.of(context).colorScheme.onTertiaryContainer;

  static Color errorContainer(BuildContext context) => isA
      ? CupertinoColors.destructiveRed.resolveFrom(context)
      // Color.alphaBlend(
      //     CupertinoColors.systemRed.resolveFrom(context).withValues(
      //           alpha: _brightness(context) == Brightness.dark ? 0.30 : 0.16,
      //         ),
      //     _surface(context),
      //   )
      : Theme.of(context).colorScheme.errorContainer;

  static Color onErrorContainer(BuildContext context) => isA
      ? CupertinoColors.white //_label(context)
      : Theme.of(context).colorScheme.onErrorContainer;

  // ---- Surfaces ----

  static Color surface(BuildContext context) => _surface(context);

  static Color onSurface(BuildContext context) =>
      isA ? _label(context) : Theme.of(context).colorScheme.onSurface;

  static Color surfaceVariant(BuildContext context) => _surfaceVariant(context);

  static Color onSurfaceVariant(BuildContext context) =>
      isA ? _secondaryLabel(context) : Theme.of(context).colorScheme.onSurfaceVariant;

  static Color outline(BuildContext context) => isA
      ? CupertinoColors.separator.resolveFrom(context)
      : Theme.of(context).colorScheme.outline;

  // ---- Convenience fills (nice for tiles/chips) ----

  /// A blue-ish normal tile background that adapts to light/dark.
  static Color softTintFill(BuildContext context) => _tintedFill(
        context,
        lightOpacity: 0.10,
        darkOpacity: 0.20,
        base: _surfaceVariant(context),
      );

  /// A more emphasised selected background (still adaptive).
  static Color softTintFillSelected(BuildContext context) => _tintedFill(
        context,
        lightOpacity: 0.18,
        darkOpacity: 0.32,
        base: _surfaceVariant(context),
      );
}