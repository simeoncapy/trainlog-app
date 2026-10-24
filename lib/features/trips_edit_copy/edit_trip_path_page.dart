import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/data/controllers/trainlog_web_controller.dart';
import 'package:trainlog_app/data/models/edited_route.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/features/trips_add/widgets/route_itinerary_card.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/utils/number_formatter.dart';
import 'package:trainlog_app/widgets/error_banner.dart';
import 'package:trainlog_app/widgets/shimmer_box.dart';
import 'package:trainlog_app/widgets/trainlog_router_page.dart';
import 'package:trainlog_app/widgets/trip_form/trip_form_card.dart';

enum _EditPathTab { map, details }

/// Path editor of the edit/duplicate form, opened from its path block.
///
/// The routing web page is opened on the trip's current route (its endpoints
/// and the via points it was saved with) and the user redraws it there. The
/// "Details" tab holds what the website shows in the map's side menu: the
/// drawing mode, the router choice and the route's summary.
///
/// Nothing is sent from here. Save reads the route back from the page
/// (`getRouteForApp()`, never `saveTrip()`, which would create a new trip),
/// keeps it in the [TripFormModel] the caller provides above this page, and
/// pops; the route is saved with the rest of the edit. Save only shows once
/// the route differs from the one the page opened with, and leaving with such
/// a change asks first.
class EditTripPathPage extends StatefulWidget {
  const EditTripPathPage({super.key});

  @override
  State<EditTripPathPage> createState() => _EditTripPathPageState();
}

class _EditTripPathPageState extends State<EditTripPathPage> {
  static const _nbsp = ' ';

  /// The types the routing page lets the user pick the router for (its
  /// NEW_ROUTER_TYPES).
  static const _routerChoiceTypes = {
    VehicleType.train,
    VehicleType.tram,
    VehicleType.metro,
    VehicleType.funicular,
    VehicleType.rail,
  };

  final TrainlogWebPageController _controller = TrainlogWebPageController();

  late final VehicleType _vehicleType;

  /// The routing page's input, built once: the page is only loaded once.
  late final String _tripData;

  _EditPathTab _tab = _EditPathTab.map;

  bool _loading = true;
  bool _routingError = false;

  /// The server's routing page cannot hand the route back to the app.
  bool _unsupported = false;

  bool _freehand = false;
  bool? _isNewRouter;
  bool _saving = false;

  /// The latest route read from the page, and the one it opened with, as
  /// comparable text: the route is modified when they differ.
  Map<String, dynamic>? _route;
  String? _initialSignature;
  String? _signature;

  bool get _modified =>
      _freehand || (_signature != null && _signature != _initialSignature);

  bool get _supportsFreehand =>
      !_vehicleType.isAir() && _vehicleType != VehicleType.poi;

  bool get _supportsRouterChoice => _routerChoiceTypes.contains(_vehicleType);

  @override
  void initState() {
    super.initState();
    final form = context.read<TripFormModel>();
    _vehicleType = form.vehicleType ?? VehicleType.train;
    _tripData = form.toJson();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // Route
  // ─────────────────────────────────────────────────────────────

  /// Reads the route drawn on the page, keeping the first one read as the
  /// route the page opened with.
  Future<void> _refreshRoute() async {
    final route = await _controller.readRoute();
    if (!mounted || route == null) return;

    if (route['error'] == 'unsupported') {
      setState(() => _unsupported = true);
      return;
    }
    if (route['ok'] != true) return;

    final signature = jsonEncode([route['path'], route['waypoints']]);
    _isNewRouter ??=
        _supportsRouterChoice ? await _controller.readNewRouter() : null;
    if (!mounted) return;

    setState(() {
      _route = route;
      _signature = signature;
      _initialSignature ??= signature;
    });
  }

  Future<void> _setFreehand(bool value) async {
    if (value == _freehand) return;
    final done = await _controller.setFreehand(value);
    if (!mounted || !done) return;
    setState(() => _freehand = value);
    await _refreshRoute();
  }

  Future<void> _setNewRouter(bool value) async {
    final done = await _controller.setNewRouter(value);
    if (!mounted || !done) return;
    setState(() {
      _isNewRouter = value;
      _routingError = false;
    });
  }

  void _selectTab(_EditPathTab tab) {
    setState(() => _tab = tab);
    // A freehand path changes without telling the app: catch up on it.
    if (tab == _EditPathTab.details) _refreshRoute();
  }

  // ─────────────────────────────────────────────────────────────
  // Save / leave
  // ─────────────────────────────────────────────────────────────

  /// Keeps the drawn route in the form and closes the page.
  Future<void> _save() async {
    if (_saving) return;
    final loc = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final form = context.read<TripFormModel>();

    setState(() => _saving = true);
    final route = await _controller.readRoute();
    if (!mounted) return;

    if (route == null || route['ok'] != true) {
      setState(() => _saving = false);
      final message = switch (route?['error']) {
        'unsupported' => loc.editPathUnsupported,
        'loading' => loc.editPathRouteNotReady,
        _ => loc.addTripPathRoutingErrorBannerMessage,
      };
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    form.setEditedRoute(EditedRoute.fromJson(route));
    Navigator.of(context).pop(true);
  }

  /// Asked when leaving with a route that was changed but not saved.
  Future<void> _confirmLeave() async {
    final loc = AppLocalizations.of(context)!;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.editPathExitDialogTitle),
        content: Text(loc.editPathExitDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(loc.editPathExitDialogConfirm),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  void _showRouterHelp() {
    final loc = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.helpTitle),
        content: SingleChildScrollView(child: Text(loc.addTripPathHelp)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).closeButtonLabel),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return PopScope(
      canPop: !_modified,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Semantics(
            label: loc.editPathTitle,
            child: SegmentedButton<_EditPathTab>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: _EditPathTab.map,
                  icon: const Icon(Icons.map_outlined),
                  label: Text(loc.editPathTabMap),
                ),
                ButtonSegment(
                  value: _EditPathTab.details,
                  icon: const Icon(Icons.tune),
                  label: Text(loc.editPathTabDetails),
                ),
              ],
              selected: {_tab},
              onSelectionChanged: (selection) => _selectTab(selection.first),
            ),
          ),
          actions: [
            if (_modified)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(loc.editPathSaveButton),
                ),
              ),
          ],
        ),
        body: SafeArea(
          top: false,
          // Both tabs stay built: the web view, and the route drawn on it,
          // must survive a look at the details.
          child: IndexedStack(
            index: _tab.index,
            children: [
              _mapTab(loc),
              _detailsTab(loc),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mapTab(AppLocalizations loc) {
    final error = _unsupported
        ? loc.editPathUnsupported
        : _routingError
            ? loc.addTripPathRoutingErrorBannerMessage
            : null;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Positioned.fill(
          child: TrainlogRouterPage(
            tripData: _tripData,
            vehicleType: _vehicleType,
            controller: _controller,
            onRouteInfoChanged: (_) => _refreshRoute(),
            onLoading: (value) {
              if (!mounted) return;
              setState(() => _loading = value);
            },
            onRoutingError: (value) {
              if (!mounted) return;
              setState(() => _routingError = value);
            },
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: ErrorBanner(
              message: error,
              severity: ErrorSeverity.error,
              compact: false,
            ),
          ),
        if (_loading || _saving)
          Positioned.fill(
            child: IgnorePointer(
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

  Widget _detailsTab(AppLocalizations loc) {
    final theme = Theme.of(context);
    final form = context.watch<TripFormModel>();
    final settings = context.watch<SettingsProvider>();
    final colours = MapColorPaletteHelper.getPalette(settings.mapColorPalette);
    final routeColour = colours[_vehicleType] ?? theme.colorScheme.primary;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        if (_routingError) ...[
          ErrorBanner(
            message: loc.addTripPathRoutingErrorBannerMessage,
            severity: ErrorSeverity.error,
            compact: false,
          ),
          const SizedBox(height: 16),
        ],
        if (_supportsFreehand) ...[
          TripFormSectionLabel(loc.editPathModeTitle),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: false,
                icon: const Icon(Icons.alt_route),
                label: Text(loc.editPathModeRouter),
              ),
              ButtonSegment(
                value: true,
                icon: const Icon(Icons.draw_outlined),
                label: Text(loc.editPathModeFreehand),
              ),
            ],
            selected: {_freehand},
            onSelectionChanged: (selection) => _setFreehand(selection.first),
          ),
          const SizedBox(height: 16),
        ],
        if (_supportsRouterChoice && !_freehand && _isNewRouter != null) ...[
          _routerCard(loc, theme),
          const SizedBox(height: 24),
        ],
        TripFormSectionLabel(loc.addTripSummaryTitle),
        const SizedBox(height: 8),
        _summaryCard(loc, theme),
        const SizedBox(height: 24),
        TripFormSectionLabel(loc.editPathRouteTitle),
        const SizedBox(height: 8),
        RouteItineraryCard(
          stops: _itineraryStops(form, loc),
          markerColour: routeColour,
        ),
      ],
    );
  }

  /// The new / legacy router switch, as on the add-trip route check.
  Widget _routerCard(AppLocalizations loc, ThemeData theme) {
    final isNewRouter = _isNewRouter ?? true;

    return TripFormCard(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      children: [
        Row(
          children: [
            Icon(
              Icons.alt_route,
              size: 18,
              color: isNewRouter
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
              onPressed: _showRouterHelp,
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
            Switch(value: isNewRouter, onChanged: _setNewRouter),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(AppLocalizations loc, ThemeData theme) {
    final locale = Localizations.localeOf(context);
    final route = _route;
    final distanceM = (route?['trip_length'] as num?)?.toDouble();
    final durationS = (route?['estimated_trip_duration'] as num?)?.toDouble();

    final valueStyle = AppTheme.monoFont.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onSurface,
    );

    Widget metric(String? value) {
      if (value != null) return Text(value, style: valueStyle);
      if (_routingError) return Text('—', style: valueStyle);
      return const ShimmerBox(width: 60, height: 16);
    }

    return TripFormCard(
      children: [
        _SummaryRow(
          icon: Icons.straighten,
          label: loc.distance,
          value: metric(
            distanceM == null
                ? null
                : '${NumberFormatter.precise(distanceM / 1000, locale: locale, maxDecimals: 1)}${_nbsp}km',
          ),
        ),
        _SummaryRow(
          icon: Icons.route_outlined,
          label: loc.addTripSummaryEstimatedDuration,
          value: metric(
            durationS == null
                ? null
                : formatDurationFixed(Duration(seconds: durationS.toInt())),
          ),
        ),
      ],
    );
  }

  /// Departure, the named intermediate points of the drawn route, arrival.
  List<RouteItineraryStop> _itineraryStops(
    TripFormModel form,
    AppLocalizations loc,
  ) {
    final waypoints = _route?['waypoints'];
    final names = waypoints is List
        ? waypoints
            .whereType<Map>()
            .map((w) => w['name']?.toString() ?? '')
            .where((name) => name.isNotEmpty)
        : form.routeWaypoints
            .map((w) => w['name']?.toString() ?? '')
            .where((name) => name.isNotEmpty);

    return [
      RouteItineraryStop(
        title: form.departureStationName ?? '',
        subtitle: loc.addTripDeparture,
        marker: RouteItineraryMarker.departure,
      ),
      for (final name in names)
        RouteItineraryStop(
          title: name,
          subtitle: loc.editPathVia,
          marker: RouteItineraryMarker.via,
        ),
      RouteItineraryStop(
        title: form.arrivalStationName ?? '',
        subtitle: loc.addTripArrival,
        marker: RouteItineraryMarker.arrival,
      ),
    ];
  }
}

/// One line of the summary card: icon, muted label and the value on the right.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          value,
        ],
      ),
    );
  }
}
