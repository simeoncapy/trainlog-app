import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/data/controllers/trainlog_web_controller.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/features/trips_add/widgets/route_itinerary_card.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/utils/number_formatter.dart';
import 'package:trainlog_app/widgets/error_banner.dart';
import 'package:trainlog_app/widgets/shimmer_box.dart';
import 'package:trainlog_app/widgets/trainlog_router_page.dart';

/// Final step of the "Add Trip" wizard: route check and trip summary.
///
/// A "Check the route" headline followed by the router configuration card
/// (old/new engine toggle with its technical info dialog), the routing web
/// map, the trip itinerary card and the analytical summary card. The map is
/// shown inline and can expand to a full-screen immersive overlay; the same
/// web view instance is reparented between the two presentations so the
/// routing state (peg adjustments, computed path) is never lost.
///
/// Validation logic is unchanged from the former TripFormPath: the wizard
/// submits the trip through [routingController] and the footer buttons are
/// disabled while the router is loading or in error.
class AddTripCheckRouteStep extends StatefulWidget {
  final TrainlogWebPageController routingController;
  final ValueChanged<bool>? onLoading;
  final ValueChanged<bool>? onRoutingError;

  const AddTripCheckRouteStep({
    super.key,
    required this.routingController,
    this.onLoading,
    this.onRoutingError,
  });

  @override
  State<AddTripCheckRouteStep> createState() => _AddTripCheckRouteStepState();
}

class _AddTripCheckRouteStepState extends State<AddTripCheckRouteStep> {
  static const _nbsp = '\u00A0'; // non-breaking space
  static const double _inlineMapHeight = 280;

  bool _isNewRouter = false;
  bool _isLoading = false;
  bool _hasRoutingError = false;

  double? _routeDistanceM;
  double? _routeDurationS;

  /// Keeps the web view subtree alive while it moves between the inline map
  /// slot and the full-screen overlay.
  final GlobalKey _webViewKey = GlobalKey();
  final OverlayPortalController _fullScreenController =
      OverlayPortalController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  bool get _isFullScreen => _fullScreenController.isShowing;

  void _enterFullScreen() {
    setState(() => _fullScreenController.show());
  }

  void _exitFullScreen() {
    setState(() => _fullScreenController.hide());
  }

  void _showHelpDialog(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.helpTitle),
          content: SingleChildScrollView(
            child: Text(
              loc.addTripPathHelp,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(MaterialLocalizations.of(context).closeButtonLabel),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final model = context.watch<TripFormModel>();
    final settings = context.watch<SettingsProvider>();
    final colours = MapColorPaletteHelper.getPalette(settings.mapColorPalette);

    final vType = model.vehicleType ?? VehicleType.train;
    final routeColour = colours[vType] ?? theme.colorScheme.primary;

    final routerControls = _routerControls(vType, loc, theme);

    // Built once per frame and placed either inline or in the full-screen
    // overlay; the GlobalKey preserves the web view state across moves.
    final mapContent = KeyedSubtree(
      key: _webViewKey,
      child: _mapContent(model, vType, loc),
    );

    return OverlayPortal(
      controller: _fullScreenController,
      overlayChildBuilder: (context) => _fullScreenOverlay(mapContent),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.addTripCheckRouteTitle,
              style: AppTheme.displayFont.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              loc.addTripCheckRouteSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            // --- Router configuration (above the map) ---
            if (routerControls != null) ...[
              routerControls,
              const SizedBox(height: 12),
            ],

            // --- Adaptive web map ---
            _inlineMapBox(theme, _isFullScreen ? null : mapContent),
            const SizedBox(height: 20),

            // --- Itinerary ---
            RouteItineraryCard(
              stops: _itineraryStops(context, model, loc),
              markerColour: routeColour,
            ),
            const SizedBox(height: 20),

            // --- Summary ---
            _sectionLabel(theme, loc.addTripSummaryTitle),
            const SizedBox(height: 8),
            _summaryCard(context, model, vType, routeColour, loc, theme),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ROUTER CONFIGURATION
  // ---------------------------------------------------------------------------

  /// Routing engine controls for the current vehicle type, or null when the
  /// type has no configurable engine.
  Widget? _routerControls(
    VehicleType vehicleType,
    AppLocalizations loc,
    ThemeData theme,
  ) {
    switch (vehicleType) {
      case VehicleType.train:
      case VehicleType.metro:
      case VehicleType.tram:
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            children: [
              Icon(
                Icons.alt_route,
                size: 18,
                color: _isNewRouter
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  loc.addTripPathUseNewRouter,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _showHelpDialog(context),
                icon: const Icon(Icons.help_outline),
                iconSize: 20,
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  foregroundColor: theme.colorScheme.onSecondaryContainer,
                  shape: const CircleBorder(),
                ),
              ),
              const SizedBox(width: 4),
              Switch(
                value: _isNewRouter,
                onChanged: (value) {
                  setState(() {
                    _isNewRouter = value;
                    // Reset routing error state and metrics when switching
                    // router: a new route computation starts.
                    _hasRoutingError = false;
                    _routeDistanceM = null;
                    _routeDurationS = null;
                  });
                  widget.onRoutingError?.call(_hasRoutingError);
                },
              ),
            ],
          ),
        );
      case VehicleType.plane:
      case VehicleType.helicopter:
        return null; // TODO: Put FR24 options here
      default:
        return null;
    }
  }

  // ---------------------------------------------------------------------------
  // MAP
  // ---------------------------------------------------------------------------

  /// The routing web view with its error banner and loading overlay; fills
  /// whatever slot (inline box or full-screen overlay) hosts it.
  Widget _mapContent(
    TripFormModel model,
    VehicleType vType,
    AppLocalizations loc,
  ) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Positioned.fill(
          child: TrainlogRouterPage(
            tripData: model.toJson(),
            vehicleType: vType,
            isNewRouter: _isNewRouter,
            controller: widget.routingController,
            onRouteInfoChanged: (tripData) {
              if (!mounted) return;
              setState(() {
                _routeDistanceM = tripData.distanceM;
                _routeDurationS = tripData.durationS;
              });
            },
            onLoading: (value) {
              if (!mounted) return;
              setState(() => _isLoading = value);
              widget.onLoading?.call(_isLoading);
            },
            onRoutingError: (value) {
              if (!mounted) return;
              setState(() => _hasRoutingError = value);
              widget.onRoutingError?.call(_hasRoutingError);
            },
          ),
        ),

        if (_hasRoutingError)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ErrorBanner(
              message: loc.addTripPathRoutingErrorBannerMessage,
              severity: ErrorSeverity.error,
              compact: false,
            ),
          ),

        // Overlay spinner above the web page
        if (_isLoading)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: Container(
                color: Colors.black26,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }

  /// Compact inline map card. [mapContent] is null while the full-screen
  /// overlay hosts the web view; a muted placeholder fills the slot so the
  /// page layout stays stable.
  Widget _inlineMapBox(ThemeData theme, Widget? mapContent) {
    return Container(
      height: _inlineMapHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (mapContent != null) Positioned.fill(child: mapContent)
          else
            Center(
              child: Icon(
                Icons.map_outlined,
                size: 32,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

          // Full-screen toggle, matching the mini map pattern.
          Positioned(
            top: 8,
            right: 8,
            child: _mapRoundButton(
              icon: Icons.fullscreen,
              onTap: _enterFullScreen,
            ),
          ),
        ],
      ),
    );
  }

  /// Immersive full-screen presentation of the map with a floating top
  /// button returning to the compact inline layout.
  Widget _fullScreenOverlay(Widget mapContent) {
    final theme = Theme.of(context);

    return Positioned.fill(
      child: Material(
        color: theme.scaffoldBackgroundColor,
        child: Stack(
          children: [
            Positioned.fill(child: mapContent),

            // Exit full screen
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                minimum: const EdgeInsets.only(top: 12, right: 16),
                child: _mapRoundButton(
                  icon: Icons.fullscreen_exit,
                  onTap: _exitFullScreen,
                  iconSize: 28,
                  padding: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Translucent round map action button, same style as the mini map
  /// maximize button.
  Widget _mapRoundButton({
    required IconData icon,
    required VoidCallback onTap,
    double iconSize = 22,
    double padding = 6,
  }) {
    return ClipOval(
      child: Material(
        color: Colors.black.withValues(alpha: 0.5),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Icon(icon, color: Colors.white, size: iconSize),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ITINERARY
  // ---------------------------------------------------------------------------

  /// Departure and arrival rows of the itinerary card. Intermediate "via"
  /// stops can be inserted between the two once waypoints are supported.
  List<RouteItineraryStop> _itineraryStops(
    BuildContext context,
    TripFormModel model,
    AppLocalizations loc,
  ) {
    return [
      RouteItineraryStop(
        title: model.departureStationName ?? '',
        subtitle: _stopSubtitle(
          context,
          loc.addTripDeparture,
          model.dateType == DateType.precise ? model.departureDateLocal : null,
        ),
        marker: RouteItineraryMarker.departure,
      ),
      RouteItineraryStop(
        title: model.arrivalStationName ?? '',
        subtitle: _stopSubtitle(
          context,
          loc.addTripArrival,
          model.dateType == DateType.precise ? model.arrivalDateLocal : null,
        ),
        marker: RouteItineraryMarker.arrival,
      ),
    ];
  }

  /// "Departure" or "Departure · 20:03" when the local time is known.
  String _stopSubtitle(BuildContext context, String label, DateTime? time) {
    if (time == null) return label;
    return '$label · ${formatDateTime(context, time, timeOnly: false)}';
  }

  // ---------------------------------------------------------------------------
  // SUMMARY
  // ---------------------------------------------------------------------------

  Widget _sectionLabel(ThemeData theme, String text) {
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _summaryCard(
    BuildContext context,
    TripFormModel model,
    VehicleType vType,
    Color routeColour,
    AppLocalizations loc,
    ThemeData theme,
  ) {
    final locale = Localizations.localeOf(context);
    final monoValueStyle = AppTheme.monoFont.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onSurface,
    );
    final textValueStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onSurface,
    );
    final notSetStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurfaceVariant,
    );

    final theoretical = _theoreticalDuration(model);

    final rows = <Widget>[
      _SummaryRow(
        leading: IconTheme(
          data: IconThemeData(color: routeColour, size: 18),
          child: vType.icon(),
        ),
        label: loc.addTripSummaryVehicle,
        value: Text(vType.label(context), style: textValueStyle),
      ),
      if (model.selectedOperators.isNotEmpty)
        _SummaryRow(
          leading: Icon(
            Icons.business_outlined,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          label: loc.operator,
          value: Text(
            model.selectedOperators.join(', '),
            style: textValueStyle,
            textAlign: TextAlign.end,
          ),
        ),
      _SummaryRow(
        leading: Icon(
          Icons.straighten,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        label: loc.distance,
        value: _routerMetric(
          _routeDistanceM == null
              ? null
              : _formatDistance(_routeDistanceM!, locale),
          monoValueStyle,
          notSetStyle,
        ),
      ),
      _SummaryRow(
        leading: Icon(
          Icons.schedule,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        label: loc.addTripSummaryTheoreticalDuration,
        value: Text(
          theoretical != null
              ? formatDurationFixed(theoretical)
              : loc.addTripDurationNotSet,
          style: theoretical != null ? monoValueStyle : notSetStyle,
        ),
      ),
      _SummaryRow(
        leading: Icon(
          Icons.route_outlined,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        label: loc.addTripSummaryEstimatedDuration,
        value: _routerMetric(
          _routeDurationS == null
              ? null
              : formatDurationFixed(
                  Duration(seconds: _routeDurationS!.toInt())),
          monoValueStyle,
          notSetStyle,
        ),
      ),
      if (model.price != null)
        _SummaryRow(
          leading: Icon(
            Icons.sell_outlined,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          label: loc.addTripPrice,
          value: Text(
            '${NumberFormatter.precise(model.price ?? 0, locale: locale, maxDecimals: 2)}'
            '$_nbsp${model.currencyCode ?? ''}',
            style: monoValueStyle,
          ),
        ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: theme.dividerColor),
            rows[i],
          ],
        ],
      ),
    );
  }

  /// A router-computed value: shimmer while the router is still computing,
  /// an em dash when routing failed, the formatted value otherwise.
  Widget _routerMetric(
    String? value,
    TextStyle monoValueStyle,
    TextStyle? notSetStyle,
  ) {
    if (value != null) return Text(value, style: monoValueStyle);
    if (_hasRoutingError) return Text('—', style: notSetStyle);
    return const ShimmerBox(width: 60, height: 16);
  }

  String _formatDistance(double distanceM, Locale locale) {
    final distanceFormatted = NumberFormatter.precise(distanceM / 1000, locale: locale, maxDecimals: 1);
    return '$distanceFormatted${_nbsp}km';
  }

  /// Duration derived from the user's manual time inputs: the difference of
  /// the precise date/times (delays included, as on the when step) or the
  /// manually entered duration for the other date modes.
  Duration? _theoreticalDuration(TripFormModel model) {
    switch (model.dateType) {
      case DateType.precise:
        if (model.departureDate == null ||
            model.arrivalDate == null ||
            !model.arrivalIsAfterDeparture()) {
          return null;
        }
        var actual = model.arrivalDate!.difference(model.departureDate!) +
            Duration(
              minutes: (model.delayArrivalMinute ?? 0) -
                  (model.delayDepartureMinute ?? 0),
            );
        if (actual.isNegative) actual = Duration.zero;
        return actual;
      case DateType.date:
      case DateType.unknown:
        final (hour, minute) = model.durationByType(model.dateType);
        if (hour == null && minute == null) return null;
        return Duration(hours: hour ?? 0, minutes: minute ?? 0);
    }
  }
}

/// One line of the summary card: leading icon, muted label and the value
/// right-aligned, matching the layout of the reference design.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.leading,
    required this.label,
    required this.value,
  });

  final Widget leading;
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(child: value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
