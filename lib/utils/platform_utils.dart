import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:trainlog_app/ui/design.dart';

class AppPlatform {
  static const bool isWeb = kIsWeb;

  /// Design language of the device: Apple HIG on iOS and macOS, Material 3
  /// everywhere else.
  static final DesignLanguage nativeDesign =
      !kIsWeb && (Platform.isIOS || Platform.isMacOS)
          ? DesignLanguage.cupertino
          : DesignLanguage.material;

  /// Forces one design language, for widget tests (the iOS views can then be
  /// tested on any machine). Null uses [nativeDesign]. Reset it in tearDown.
  ///
  /// The choice is global: [AppRoot] picks CupertinoApp or MaterialApp from
  /// it, so set it before the app is built.
  @visibleForTesting
  static DesignLanguage? debugDesignOverride;

  /// The design language the app is drawn with.
  static DesignLanguage get design => debugDesignOverride ?? nativeDesign;

  /// Shorthand for `design == DesignLanguage.cupertino`.
  ///
  /// Feature code should not test it: pick the view once with
  /// [PlatformView] instead (see CLAUDE.md).
  static bool get isApple => design == DesignLanguage.cupertino;

  static bool get isMaterial => !isApple;

  static final isMobile = Platform.isIOS || Platform.isAndroid;

  static Widget bottomPadding(BuildContext context, {double? offset}) {
    if(AppPlatform.isApple) {
      final mq = MediaQuery.of(context);
      final p = mq.padding.bottom;
      return SizedBox(height: p + (offset ?? 0.0),);
    }
      return const SizedBox.shrink();
  }
}

class AdaptiveIcons {
  static bool get isA => AppPlatform.isApple; // condense writting

  // General
  static IconData get delete =>      isA ? CupertinoIcons.delete : Icons.delete;
  static IconData get copy =>        isA ? CupertinoIcons.doc_on_doc : Icons.copy;
  static IconData get share =>       isA ? CupertinoIcons.share : Icons.share;
  static IconData get mail =>        isA ? CupertinoIcons.mail : Icons.mail;
  static IconData get add =>         isA ? CupertinoIcons.add : Icons.add;
  static IconData get filter =>      isA ? CupertinoIcons.line_horizontal_3_decrease : Icons.filter_alt;
  static IconData get search =>      isA ? CupertinoIcons.search : Icons.search;
  static IconData get edit =>        isA ? CupertinoIcons.square_pencil : Icons.edit;
  static IconData get refresh =>     isA ? CupertinoIcons.refresh : Icons.refresh;
  static IconData get license =>     isA ? CupertinoIcons.doc_text : Icons.article;
  static IconData get chevronDown => isA ? CupertinoIcons.chevron_down : Icons.keyboard_arrow_down;
  static IconData get debug =>       isA ? CupertinoIcons.ant_fill : Icons.bug_report;
  
  // Sort
  static IconData get sortAscending => isA ? CupertinoIcons.sort_up : Icons.arrow_upward;
  static IconData get sortDescending => isA ? CupertinoIcons.sort_down : Icons.arrow_downward;

  // Nav bar
  static IconData get map =>         isA ? CupertinoIcons.map_fill : Icons.map;
  static IconData get trips => Icons.commute;
  static IconData get ranking =>     isA ? CupertinoIcons.rosette : Icons.emoji_events;
  static IconData get statistics =>  isA ? CupertinoIcons.chart_bar_alt_fill : Icons.bar_chart;
  static IconData get other =>       isA ? CupertinoIcons.ellipsis : Icons.more_horiz;

  // Drawer menu
  static IconData get dashboard =>   isA ? CupertinoIcons.square_grid_2x2_fill : Icons.dashboard;
  static IconData get coverage =>    isA ? CupertinoIcons.percent : Icons.percent;
  static IconData get tags =>        isA ? CupertinoIcons.tag_fill : Icons.label;
  static IconData get tickets =>     isA ? CupertinoIcons.ticket_fill : Icons.confirmation_number;
  static IconData get friends =>     isA ? CupertinoIcons.person_2_fill : Icons.people;
  static IconData get smartPrerecorder => isA ? CupertinoIcons.pencil_ellipsis_rectangle : Symbols.checkbook;
  static IconData get settings =>    isA ? CupertinoIcons.settings_solid : Icons.settings;
  static IconData get info =>        isA ? CupertinoIcons.info_circle_fill : Icons.info;

  // Header menu
  static IconData get logout =>      isA ? CupertinoIcons.square_arrow_right_fill : Icons.logout;
  static IconData get inbox =>       isA ? CupertinoIcons.tray : Icons.inbox;
  static IconData get ok =>          isA ? CupertinoIcons.check_mark_circled_solid : Icons.check_circle;
  static IconData get warning =>     isA ? CupertinoIcons.exclamationmark_triangle_fill : Icons.warning;
  static IconData get error =>       isA ? CupertinoIcons.exclamationmark_octagon_fill : Icons.error;

  // Settings
  static IconData get theme =>       isA ? CupertinoIcons.moon : Icons.dark_mode;
  static IconData get language =>    isA ? CupertinoIcons.globe : Icons.language;
  static IconData get date =>        isA ? CupertinoIcons.calendar : Icons.date_range;
  static IconData get hour =>        isA ? CupertinoIcons.clock : Icons.watch;
  static IconData get currency =>    isA ? CupertinoIcons.money_dollar_circle : Icons.currency_exchange;
  static IconData get radar =>       isA ? CupertinoIcons.location_circle : Icons.radar;
  static IconData get landingPage => isA ? CupertinoIcons.house : Icons.home;
  static IconData get warningMsg =>  isA ? CupertinoIcons.exclamationmark_triangle : Icons.warning;
  static IconData get layers =>      isA ? CupertinoIcons.layers : Icons.layers;
  static IconData get palette =>     isA ? CupertinoIcons.paintbrush : Icons.palette;
  static IconData get position =>    isA ? CupertinoIcons.location : Icons.my_location;
  static IconData get tripDirection => isA ? CupertinoIcons.chevron_right_2 : Icons.double_arrow;
  static IconData get visibility =>  isA ? CupertinoIcons.eye : Icons.visibility;
  static IconData get world =>       isA ? CupertinoIcons.map : Icons.public;
  static IconData get cache =>       isA ? CupertinoIcons.cloud_download : Icons.cloud_download;
  static IconData get deleteAccount =>isA ? CupertinoIcons.person_crop_circle_badge_xmark : Icons.no_accounts;
  static IconData get version =>     isA ? CupertinoIcons.info_circle : Icons.info_outline;
  static IconData get instance =>    isA ? CupertinoIcons.link : Icons.http;

  // Pages  
  static IconData get compass => isA ? CupertinoIcons.compass :  Icons.explore;

  // Visibility
  static IconData get visibilityPublic => isA ? CupertinoIcons.globe : Icons.public;
  static IconData get visibilityFriends => isA ? CupertinoIcons.person_2 : Icons.people;
  static IconData get visibilityPrivate => isA ? CupertinoIcons.lock : Icons.lock;
}

class AdaptiveTextStyle {
  static bool get isA => AppPlatform.isApple; // condense writting
  
  static TextStyle? title(BuildContext context) => isA ? CupertinoTheme.of(context).textTheme.navTitleTextStyle : Theme.of(context).textTheme.titleLarge;
}

class AdaptiveThemeColor {
  static bool get isA => AppPlatform.isApple; // condense writting

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

  static Color? normal(BuildContext context) =>
      isA ? CupertinoColors.systemFill.resolveFrom(context) : null;

  static Color? onNormal(BuildContext context) =>
      isA ? CupertinoTheme.of(context).primaryColor : null;

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
      isA ? CupertinoColors.darkBackgroundGray : Theme.of(context).colorScheme.onTertiary;

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