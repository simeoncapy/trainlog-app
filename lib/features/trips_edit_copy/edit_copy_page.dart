import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/features/trips_edit_copy/edit_trip_section.dart';
import 'package:trainlog_app/features/trips_edit_copy/edit_trip_vehicle_type_page.dart';
import 'package:trainlog_app/features/trips_edit_copy/edit_trip_when_page.dart';
import 'package:trainlog_app/features/trips_edit_copy/sections/edit_trip_details_section.dart';
import 'package:trainlog_app/features/trips_edit_copy/sections/edit_trip_operator_section.dart';
import 'package:trainlog_app/features/trips_edit_copy/sections/edit_trip_path_section.dart';
import 'package:trainlog_app/features/trips_edit_copy/sections/edit_trip_route_section.dart';
import 'package:trainlog_app/features/trips_edit_copy/sections/edit_trip_ticket_section.dart';
import 'package:trainlog_app/features/trips_edit_copy/sections/edit_trip_when_section.dart';
import 'package:trainlog_app/features/trips_edit_copy/widgets/edit_trip_app_bar_title.dart';
import 'package:trainlog_app/features/trips_edit_copy/widgets/edit_trip_section_bar.dart';
import 'package:trainlog_app/features/trips_edit_copy/widgets/edit_trip_vehicle_card.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/platform/adaptive_page_route.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/services/api/trips_api.dart';
import 'package:trainlog_app/services/trip_edit_copy_service.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/widgets/error_banner.dart';
import 'package:trainlog_app/widgets/primary_action_button.dart';

/// Page backing both "Edit" and "Duplicate" on a trip.
///
/// The trip is loaded through [TripEditCopyService], which reconciles the
/// locally cached copy with the server's; anything that reconciliation has to
/// report (a cache refreshed from a newer server version, a fallback on local
/// data because the server is unreachable) surfaces as an [ErrorBanner] above
/// the section bar.
///
/// The loaded trip seeds a [TripFormModel] shared with the add-trip wizard, so
/// the form blocks are the same widgets. The blocks are laid out in one scroll
/// view and the sticky [EditTripSectionBar] anchors to them. Submitting is not
/// wired yet — the API is not ready.
class EditCopyPage extends StatefulWidget {
  /// Id of the trip to edit, or of the trip to copy from.
  final int tripId;

  /// Whether the page edits [tripId] in place or seeds a new trip from it.
  final EditCopy mode;

  const EditCopyPage({
    super.key,
    required this.tripId,
    required this.mode,
  });

  @override
  State<EditCopyPage> createState() => _EditCopyPageState();
}

class _EditCopyPageState extends State<EditCopyPage> {
  bool _loading = true;
  TripEditCopyResult? _result;
  bool _warningDismissed = false;

  /// Form state seeded from the loaded trip; null until it has loaded (or
  /// when there is no trip to show at all).
  TripFormModel? _form;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _scrollViewKey = GlobalKey();
  final Map<EditTripSection, GlobalKey> _sectionKeys = {
    for (final section in EditTripSection.values) section: GlobalKey(),
  };

  EditTripSection _activeSection = EditTripSection.route;

  /// True while an anchor tap animates the scroll view, so the pill the user
  /// asked for is not overridden by the positions scrolled past on the way.
  bool _isAnchorScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_syncActiveSection);
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _form?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final trainlog = context.read<TrainlogProvider>();
    final service = TripEditCopyService(
      api: trainlog.tripsApi,
      trips: context.read<TripsProvider>(),
    );

    final result = await service.load(
      username: trainlog.username,
      tripId: widget.tripId,
      mode: widget.mode,
    );

    if (!mounted) return;
    setState(() {
      _result = result;
      _form = result.trip == null ? null : TripFormModel.fromTrip(result.trip!);
      _loading = false;
    });
  }

  // ─────────────────────────────────────────────────────────────
  // Anchor navigation
  // ─────────────────────────────────────────────────────────────

  /// Drives the form to [section], the way an anchor link would.
  Future<void> _scrollToSection(EditTripSection section) async {
    final target = _sectionKeys[section]?.currentContext;
    if (target == null) return;

    setState(() {
      _activeSection = section;
      _isAnchorScrolling = true;
    });

    await Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );

    if (!mounted) return;
    setState(() => _isAnchorScrolling = false);
  }

  /// Keeps the selected pill in sync with what the user scrolled to: the
  /// active section is the last one whose header has passed the top of the
  /// viewport.
  void _syncActiveSection() {
    if (_isAnchorScrolling || !_scrollController.hasClients) return;

    final viewport =
        _scrollViewKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewport == null) return;

    EditTripSection? active;
    for (final entry in _sectionKeys.entries) {
      final box = entry.value.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) continue;
      if (box.localToGlobal(Offset.zero, ancestor: viewport).dy <= 24) {
        active = entry.key;
      }
    }

    // The last section rarely reaches the top of the viewport; hitting the
    // end of the list counts as reaching it.
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 8) {
      active = EditTripSection.values.last;
    }

    if (active != null && active != _activeSection) {
      setState(() => _activeSection = active!);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────────────────────

  Future<void> _changeVehicleType() async {
    final form = _form;
    if (form == null) return;

    final picked = await Navigator.of(context).push<VehicleType>(
      AdaptivePageRoute.route<VehicleType>(
        (_) => EditTripVehicleTypePage(
          currentType: form.vehicleType ?? VehicleType.train,
        ),
      ),
    );

    // Only the form is updated for now: pushing the new type (and the vehicle
    // material / seat resets that come with it) waits for the API.
    if (picked == null || !mounted) return;
    form.setVehicleType(picked);
  }

  void _openWhenEditor() {
    final form = _form;
    if (form == null) return;

    Navigator.of(context).push(
      AdaptivePageRoute.route<void>(
        (_) => ChangeNotifierProvider<TripFormModel>.value(
          value: form,
          child: const EditTripWhenPage(),
        ),
      ),
    );
  }

  /// Placeholder for the actions whose logic is not implemented yet.
  void _showComingSoon() {
    final loc = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(loc.editTripComingSoon)));
  }

  // ─────────────────────────────────────────────────────────────
  // Header
  // ─────────────────────────────────────────────────────────────

  String _title(AppLocalizations loc) => widget.mode == EditCopy.copy
      ? loc.duplicateTripTitle
      : loc.editTripTitle;

  /// "Frankfurt → Offenburg • 30 Mar 2026" — the trip as it was loaded, so it
  /// keeps identifying the trip whatever the form already changed.
  String? _subtitle(AppLocalizations loc) {
    final trip = _result?.trip;
    if (trip == null) return null;

    final date = trip.isUnknownPastFuture
        ? loc.addTripDateTypeUnknown
        : formatDateTime(context, trip.startDatetime, hasTime: false);

    return loc.editTripRouteSummary(
      trip.originStation,
      trip.destinationStation,
      date,
    );
  }

  /// The banner to show for the current load outcome, or null when the data
  /// came back exactly as cached.
  ({String message, ErrorSeverity severity})? _warning(AppLocalizations loc) {
    final result = _result;
    if (result == null || _warningDismissed) return null;

    switch (result.source) {
      case TripEditCopySource.upToDate:
        return null;
      case TripEditCopySource.refreshedFromServer:
        return (
          message: loc.editCopyTripRefreshedWarning,
          severity: ErrorSeverity.warning,
        );
      case TripEditCopySource.cacheFallback:
        return (
          message: loc.editCopyServerUnreachableWarning,
          severity: ErrorSeverity.warning,
        );
      case TripEditCopySource.unavailable:
        return (
          message: loc.editCopyTripUnavailableError,
          severity: ErrorSeverity.error,
        );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final warning = _warning(loc);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: EditTripAppBarTitle(
          title: _title(loc),
          subtitle: _subtitle(loc),
        ),
        backgroundColor: widget.mode == EditCopy.edit
            ? Theme.of(context).colorScheme.error.withValues(alpha: 0.2)
            : Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
      ),
      body: SafeArea(
        top: false,
        child: _body(loc, warning),
      ),
    );
  }

  Widget _body(
    AppLocalizations loc,
    ({String message, ErrorSeverity severity})? warning,
  ) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final form = _form;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Anything the loader has to report sits above the section bar.
        if (warning != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: ErrorBanner(
              message: warning.message,
              severity: warning.severity,
              onClose: () => setState(() => _warningDismissed = true),
            ),
          ),
        if (form == null)
          const Expanded(child: SizedBox.shrink())
        else ...[
          const SizedBox(height: 12),
          EditTripSectionBar(
            selected: _activeSection,
            onSelected: _scrollToSection,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ChangeNotifierProvider<TripFormModel>.value(
              value: form,
              child: Builder(builder: _formScrollView),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: PrimaryActionButton(
              label: widget.mode == EditCopy.edit ? loc.editTripSaveButton : loc.duplicateTripSaveButton,
              // TODO: submit the form once the edit/copy API is available.
              onPressed: _showComingSoon,
            ),
          ),
        ],
      ],
    );
  }

  /// The scrolling form. Built under the form provider, so [context] here is
  /// the one carrying it.
  Widget _formScrollView(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final colours = MapColorPaletteHelper.getPalette(settings.mapColorPalette);
    final vehicleType = context.watch<TripFormModel>().vehicleType ??
        VehicleType.train;
    final vehicleColour = colours[vehicleType] ?? theme.colorScheme.primary;

    return SingleChildScrollView(
      key: _scrollViewKey,
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EditTripVehicleCard(
            type: vehicleType,
            colour: vehicleColour,
            onChange: _changeVehicleType,
          ),
          const SizedBox(height: 24),
          _section(
            EditTripSection.route,
            EditTripRouteSection(markerColour: vehicleColour),
          ),
          const SizedBox(height: 24),
          _section(
            EditTripSection.operators,
            const EditTripOperatorSection(),
          ),
          const SizedBox(height: 24),
          _section(
            EditTripSection.when,
            EditTripWhenSection(
              markerColour: vehicleColour,
              onEdit: _openWhenEditor,
            ),
          ),
          const SizedBox(height: 24),
          _section(
            EditTripSection.details,
            const EditTripDetailsSection(),
          ),
          const SizedBox(height: 24),
          _section(
            EditTripSection.ticket,
            const EditTripTicketSection(),
          ),
          const SizedBox(height: 24),
          _section(
            EditTripSection.path,
            // TODO: open the path editor once it exists.
            EditTripPathSection(onModifyPath: _showComingSoon),
          ),
        ],
      ),
    );
  }

  /// A form block, keyed so the section bar can scroll to its header.
  Widget _section(EditTripSection section, Widget child) {
    return KeyedSubtree(
      key: _sectionKeys[section],
      child: EditTripSectionBlock(section: section, child: child),
    );
  }
}
