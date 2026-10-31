import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/app/theme/app_colors.dart';
import 'package:trainlog_app/data/models/geolog_note.dart';
import 'package:trainlog_app/data/models/pre_record_model.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/features/spr/geolog_station_search_page.dart';
import 'package:trainlog_app/features/spr/widgets/geolog_note_station_section.dart';
import 'package:trainlog_app/features/spr/widgets/geolog_note_when_section.dart';
import 'package:trainlog_app/features/trips_edit_copy/edit_trip_section.dart';
import 'package:trainlog_app/features/trips_edit_copy/sections/edit_trip_details_section.dart';
import 'package:trainlog_app/features/trips_edit_copy/sections/edit_trip_operator_section.dart';
import 'package:trainlog_app/features/trips_edit_copy/sections/edit_trip_ticket_section.dart';
import 'package:trainlog_app/features/trips_edit_copy/widgets/edit_trip_app_bar_title.dart';
import 'package:trainlog_app/features/trips_edit_copy/widgets/edit_trip_section_bar.dart';
import 'package:trainlog_app/features/trips_edit_copy/widgets/edit_trip_vehicle_card.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/platform/adaptive_dialog.dart';
import 'package:trainlog_app/platform/adaptive_page_route.dart';
import 'package:trainlog_app/providers/pre_record_provider.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/widgets/primary_action_button.dart';
import 'package:trainlog_app/widgets/vehicle_energy_selector.dart';

/// What the note page hands back when it is saved.
class GeologNoteResult {
  /// The note to keep; null when it was deleted (or left empty).
  final GeologNote? note;

  /// The station picked on the page; null when the station was not changed.
  final StationChoice? station;

  const GeologNoteResult({required this.note, this.station});
}

/// Note page of a Geolog, laid out like the trip edit/duplicate page: a
/// single station (searched among the stations around the Geolog), its
/// date, time and delay, and the trip details, ticket and operators. There
/// is no path, and the vehicle type only follows the station.
///
/// The page pops with a [GeologNoteResult] when saved or deleted, and with
/// null when closed.
class GeologNotePage extends StatefulWidget {
  const GeologNotePage({super.key, required this.record});

  final PreRecordModel record;

  /// App bar tint of the page, set apart from the edit (red) and duplicate
  /// (blue) pages.
  static Color appBarColour(BuildContext context) =>
      AppColors.amber.withValues(alpha: 0.25);

  @override
  State<GeologNotePage> createState() => _GeologNotePageState();
}

class _GeologNotePageState extends State<GeologNotePage> {
  /// The trip form behind the shared operator, details and ticket blocks.
  late final TripFormModel _form = _seedForm(widget.record.note);

  late StationChoice _station = (
    widget.record.stationName,
    widget.record.address,
    widget.record.type,
  );
  bool _stationChanged = false;

  late DateTime? _dateTime = widget.record.note?.dateTime;
  late int? _delayMinutes = widget.record.note?.delayMinutes;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _scrollViewKey = GlobalKey();
  final Map<EditTripSection, GlobalKey> _sectionKeys = {
    for (final section in EditTripSection.geologNote) section: GlobalKey(),
  };
  EditTripSection _activeSection = EditTripSection.geologNote.first;
  bool _isAnchorScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_syncActiveSection);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _form.dispose();
    super.dispose();
  }

  static TripFormModel _seedForm(GeologNote? note) {
    final form = TripFormModel();
    if (note != null) {
      form.selectedOperators = List.of(note.operators);
      form.line = note.line;
      form.material = note.material;
      form.registration = note.registration;
      form.seat = note.seat;
      form.notes = note.memo;
      form.price = note.price;
      form.currencyCode = note.currency;
      form.purchaseDate = note.purchaseDate;
      if (note.energy != null) form.energyType = note.energy!;
      form.tripVisibility = note.visibility;
    }
    form.initState();
    return form;
  }

  /// The note as the page shows it.
  GeologNote _buildNote() {
    final price = _form.price;
    return GeologNote(
      dateTime: _dateTime,
      delayMinutes: _delayMinutes,
      operators: _form.selectedOperators
          .map((op) => op.trim())
          .where((op) => op.isNotEmpty)
          .toList(),
      line: GeologNote.clean(_form.line),
      material: GeologNote.clean(_form.material),
      registration: GeologNote.clean(_form.registration),
      seat: GeologNote.clean(_form.seat),
      memo: GeologNote.clean(_form.notes),
      price: price,
      // The ticket fields only mean anything alongside a price.
      currency: price == null ? null : GeologNote.clean(_form.currencyCode),
      purchaseDate: price == null ? null : _form.purchaseDate,
      energy: _form.energyType == EnergyType.auto ? null : _form.energyType,
      visibility: _form.tripVisibility,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Anchor navigation (same behaviour as the edit/duplicate page)
  // ─────────────────────────────────────────────────────────────

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

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 8) {
      active = EditTripSection.geologNote.last;
    }

    if (active != null && active != _activeSection) {
      setState(() => _activeSection = active!);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────────────────────

  Future<void> _searchStation() async {
    final lat = widget.record.lat;
    final long = widget.record.long;
    if (lat == null || long == null) return;

    final picked = await Navigator.of(context).push<StationChoice>(
      AdaptivePageRoute.route<StationChoice>(
        (_) => GeologStationSearchPage(lat: lat, long: long),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _station = picked;
      _stationChanged = true;
    });
  }

  void _save() {
    final note = _buildNote();
    Navigator.of(context).pop(
      GeologNoteResult(
        note: note.isEmpty ? null : note,
        station: _stationChanged ? _station : null,
      ),
    );
  }

  Future<void> _delete() async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await AdaptiveDialog.confirm(
      context: context,
      title: loc.geologNoteDeleteButton,
      message: loc.geologNoteDeleteConfirm,
      confirmLabel: MaterialLocalizations.of(context).deleteButtonTooltip,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    Navigator.of(context).pop(const GeologNoteResult(note: null));
  }

  // ─────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final record = widget.record;
    final (stationName, _, _) = _station;

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
          title: loc.geologNoteTitle,
          subtitle: loc.geologNoteSummary(
            stationName ?? loc.prerecorderUnknownStation,
            formatDateTime(context, record.dateTime, hasTime: false),
          ),
        ),
        actions: [
          if (record.hasNote)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: loc.geologNoteDeleteButton,
              onPressed: _delete,
            ),
        ],
        backgroundColor: GeologNotePage.appBarColour(context),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            EditTripSectionBar(
              selected: _activeSection,
              onSelected: _scrollToSection,
              sections: EditTripSection.geologNote,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ChangeNotifierProvider<TripFormModel>.value(
                value: _form,
                child: Builder(builder: _formScrollView),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: PrimaryActionButton(
                label: loc.geologNoteSaveButton,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formScrollView(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    final colours = MapColorPaletteHelper.getPalette(settings.mapColorPalette);
    final (stationName, _, type) = _station;
    final vehicleColour = colours[type] ?? theme.colorScheme.primary;

    return SingleChildScrollView(
      key: _scrollViewKey,
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The vehicle type follows the station: it is not changed here.
          EditTripVehicleCard(
            type: type,
            colour: vehicleColour,
            onChange: () {},
            canChange: false,
          ),
          const SizedBox(height: 24),
          _section(
            EditTripSection.station,
            GeologNoteStationSection(
              stationName: stationName,
              type: type,
              colour: vehicleColour,
              lat: widget.record.lat,
              long: widget.record.long,
              onSearch: _searchStation,
            ),
          ),
          const SizedBox(height: 24),
          _section(EditTripSection.operators, const EditTripOperatorSection()),
          const SizedBox(height: 24),
          _section(
            EditTripSection.when,
            GeologNoteWhenSection(
              recordedDateTime: widget.record.dateTime,
              dateTime: _dateTime,
              delayMinutes: _delayMinutes,
              onDateTimeChanged: (value) => setState(() => _dateTime = value),
              onDelayChanged: (value) => setState(() => _delayMinutes = value),
            ),
          ),
          const SizedBox(height: 24),
          _section(EditTripSection.details, const EditTripDetailsSection()),
          const SizedBox(height: 24),
          _section(EditTripSection.ticket, const EditTripTicketSection()),
        ],
      ),
    );
  }

  Widget _section(EditTripSection section, Widget child) {
    return KeyedSubtree(
      key: _sectionKeys[section],
      child: EditTripSectionBlock(section: section, child: child),
    );
  }
}
