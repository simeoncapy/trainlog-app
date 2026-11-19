import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;
import 'package:trainlog_app/utils/platform_utils.dart';

/// Shared presentation of the app's bottom sheets.
///
/// Android keeps the plain Material `showModalBottomSheet`. Apple platforms
/// get iOS 26 Liquid Glass sheets drawn by liquid_glass_widgets:
///
/// - [showAdaptiveContentSheet] for sheets that size to their content
///   (pickers, small forms): a floating glass [lg.GlassSheet].
/// - [showAppleDetentSheet] for large, scrollable sheets with resting heights
///   (trip details, search & filter): a [lg.GlassModalSheet] that is glass at
///   its medium detent and turns opaque at the large one, like UIKit sheets.

/// Space the sheet's own grab handle needs above the content. The glass
/// sheets overlay their handle on the content's top edge, so content padded
/// by this starts just below the pill, as on native iOS sheets.
const double kAppleSheetHandleInset = 20;

/// Shows a modal sheet that sizes to its content.
///
/// The builder's content must not paint its own background or grab handle on
/// Apple (check `AppPlatform.isApple`): the glass surface supplies both. Its
/// height is capped at [maxHeightFactor] of the screen, so a scroll view inside
/// a `Flexible` keeps working.
///
/// [useSafeArea] only applies to Material; the glass sheet always floats
/// above the home indicator.
Future<T?> showAdaptiveContentSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool useRootNavigator = false,
  bool useSafeArea = false,
  bool isDismissible = true,
  double maxHeightFactor = 0.9,
  Color? materialBackgroundColor,
}) {
  if (!AppPlatform.isApple) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: useRootNavigator,
      useSafeArea: useSafeArea,
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      backgroundColor: materialBackgroundColor,
      builder: builder,
    );
  }

  final surface = Theme.of(context).colorScheme.surface;

  return lg.GlassSheet.show<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    // Forms and lists sit on these sheets: tint the glass well enough that
    // small and muted text stays readable over a busy background.
    settings: _readableGlass(surface, tint: 0.85),
    isDismissible: isDismissible,
    enableDrag: isDismissible,
    // The content brings its own scroll view (in a Flexible) where it needs
    // one; a second, outer one would leave it with unbounded height.
    isScrollable: false,
    // Taps on rows and buttons shouldn't pulse the whole sheet.
    enableSaturationGlow: false,
    interactionScale: 1.0,
    builder: (sheetContext) {
      final mq = MediaQuery.of(sheetContext);
      // Content with text fields pads itself above the keyboard, so with the
      // keyboard up the sheet may use the whole height below the status bar;
      // otherwise the form gets squeezed into a scroll view behind it.
      final maxHeight = mq.viewInsets.bottom > 0
          ? mq.size.height - mq.padding.top - _glassSheetChrome
          : (mq.size.height - mq.padding.top - mq.padding.bottom) *
                maxHeightFactor;
      return _MaterialHost(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          // The sheet never reaches the status bar: drop the top inset so a
          // SafeArea in the content doesn't add a gap under the grab handle.
          child: MediaQuery.removePadding(
            context: sheetContext,
            removeTop: true,
            child: Builder(builder: builder),
          ),
        ),
      );
    },
  );
}

/// Shows an Apple-only Liquid Glass sheet with resting heights (detents).
///
/// The content is given the sheet's full current height, so a `Column` with
/// an `Expanded` scroll area and a pinned footer lays out as expected. Inner
/// vertical scroll views must not force their own `physics`: the sheet
/// installs physics that grow the sheet before the list starts scrolling.
///
/// [halfSize] and [fullSize] are fractions of the screen height for the
/// medium and large detents. The content is padded below the sheet's grab
/// handle; content with text fields must keep itself above the keyboard
/// (`MediaQuery.viewInsetsOf`), as the sheet does not move for it.
Future<T?> showAppleDetentSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Set<lg.GlassSheetDetent> detents = const {
    lg.GlassSheetDetent.medium,
    lg.GlassSheetDetent.large,
  },
  lg.GlassSheetState initialState = lg.GlassSheetState.half,
  double halfSize = 0.5,
  double? fullSize,
  bool useRootNavigator = true,
}) {
  // The large detent turns opaque; fill it with the app's own surface so it
  // matches the rest of the UI in both light and dark mode.
  final surface = Theme.of(context).colorScheme.surface;

  return lg.GlassModalSheet.show<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    detents: detents,
    initialState: initialState,
    halfSize: halfSize,
    fullSize: fullSize,
    expandedColor: surface,
    expandedDarkColor: surface,
    // Lighter tint at the medium detent, so the map still shows through.
    settings: _readableGlass(surface, tint: 0.72),
    enableSaturationGlow: false,
    interactionScale: 1.0,
    builder: (sheetContext) => _MaterialHost(
      // At the large detent the sheet sinks below the screen's bottom edge to
      // hide its lower corners; lift the content by that much so pinned
      // footers stay on screen.
      child: Builder(
        builder: (ctx) {
          final submerged =
              lg.GlassModalSheetStateProvider.of(ctx)?.submergedBottom ?? 0;
          return Padding(
            padding: EdgeInsets.only(
              top: kAppleSheetHandleInset,
              bottom: submerged,
            ),
            child: builder(ctx),
          );
        },
      ),
    ),
  );
}

/// Height GlassSheet adds around its content (grab handle row, bottom spacer,
/// outer margins) plus a small gap, kept free below the status bar.
const double _glassSheetChrome = 72;

/// The package's sheet glass is a ~12% white tint, which leaves muted text
/// unreadable over the map or a form. Tint it with the app's surface colour
/// instead (light and dark mode alike) and frost it a little more.
lg.LiquidGlassSettings _readableGlass(Color surface, {required double tint}) {
  return lg.LiquidGlassSettings(
    glassColor: surface.withValues(alpha: tint),
    thickness: 10,
    blur: 20,
    lightIntensity: 0.7,
    lightAngle: 2.356194,
    chromaticAberration: 0,
    refractiveIndex: 0.15,
    saturation: 1.2,
    ambientStrength: 0.4,
  );
}

/// The glass sheets are pushed as plain (non-Material) routes. Material
/// widgets inside (InkWell, TextField, ListTile…) need a Material ancestor,
/// and text needs the theme's default style instead of the debug fallback.
class _MaterialHost extends StatelessWidget {
  const _MaterialHost({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        child: child,
      ),
    );
  }
}
