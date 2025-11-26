import 'dart:async';

import 'package:flutter/material.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/widgets/full_screen_search_overlay.dart';

class StationFieldsSwitcher extends StatefulWidget {
  const StationFieldsSwitcher({
    Key? key,
    this.nameController,
    this.latController,
    this.longController,
    this.initialGeoMode = false,
    this.onModeChanged,
    this.onChanged,
    this.searchIcon,
    this.globePinIcon,
    required this.addressDefaultText,
    required this.manualNameFieldHint,
    required this.trainlog,
    required this.vehicleType,
  }) : super(key: key);

  final TextEditingController? nameController;
  final TextEditingController? latController;
  final TextEditingController? longController;

  final bool initialGeoMode;
  final ValueChanged<bool>? onModeChanged;

  final IconData? searchIcon;
  final IconData? globePinIcon;

  final ValueChanged<Map<String, String>>? onChanged;

  final String addressDefaultText;
  final String manualNameFieldHint;

  final TrainlogProvider trainlog;
  final VehicleType vehicleType;

  @override
  State<StationFieldsSwitcher> createState() => _StationFieldsSwitcherState();
}

class _StationFieldsSwitcherState extends State<StationFieldsSwitcher>
    with TickerProviderStateMixin {
  late final TextEditingController _nameCtl =
      widget.nameController ?? TextEditingController();
  late final TextEditingController _latCtl =
      widget.latController ?? TextEditingController();
  late final TextEditingController _longCtl =
      widget.longController ?? TextEditingController();
  late final TextEditingController _manualNameCtl = TextEditingController();

  late bool _geoMode = widget.initialGeoMode;
  int _direction = -1;

  /// Use a fixed height so mode switching doesn’t change widget height
  static const double _extraFieldHeight = 48.0;

  OverlayEntry? _overlayEntry;

  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchCtl = TextEditingController();

  List<StationInfo> _stationResults = [];

  String _currentAddress = "";
  double? _savedLat;
  double? _savedLng;
  bool _isSearching = false;


  void _toggleMode() {
    setState(() {
      _geoMode = !_geoMode;
      _direction = _geoMode ? -1 : 1;
    });
    widget.onModeChanged?.call(_geoMode);
  }

  void _emitValues() {
    widget.onChanged?.call({
      'mode': _geoMode ? "geo" : "name",
      'name': _geoMode ? _manualNameCtl.text : _nameCtl.text,
      'lat': _geoMode ? _latCtl.text : "0.0",
      'long': _geoMode ? _longCtl.text : "0.0",
    });
  }

  OverlayEntry _buildStationSearchOverlay() {
    return OverlayEntry(
      builder: (context) {
        return FullScreenSearchOverlay<StationInfo>(
          controller: _searchCtl,
          focusNode: _searchFocusNode,
          items: _stationResults,
          hintText: "Search station...",
          isLoading: _isSearching,
          onChanged: _performStationSearch,   // dynamic async search

          itemBuilder: (context, station) {
            final (label, coords, address, isManual) = station;

            return Container(
              color: isManual
                  ? Colors.red.withOpacity(0.12)
                  : Colors.transparent,
              child: ListTile(
                leading: isManual
                    ? const Icon(Icons.edit, color: Colors.red)
                    : null,
                title: Text(label),
              ),
            );
          },

          onSelected: (station) {
            _selectStation(station);
            _closeOverlay();
          },

          onClose: _closeOverlay,
        );
      },
    );
  }

  Future<void> _performStationSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _stationResults = [];
        _isSearching = false;
      });
      _overlayEntry?.markNeedsBuild();
      return;
    }

    setState(() => _isSearching = true);
    _overlayEntry?.markNeedsBuild();

    final results = await widget.trainlog.fetchStations(
      query,
      widget.vehicleType,
    );

    if (!mounted || _overlayEntry == null) return;

    setState(() {
      _stationResults = results;
      _isSearching = false;
    });

    _overlayEntry?.markNeedsBuild();
  }

  void _selectStation(StationInfo station) {
    final (label, coords, address, isManual) = station;

    // Update name field
    _nameCtl.text = label;

    // Update lat/lng fields
    _latCtl.text = coords.latitude.toString();
    _longCtl.text = coords.longitude.toString();

    // Persist coordinates separately (so they survive mode switches)
    _savedLat = coords.latitude;
    _savedLng = coords.longitude;

    // Update extra field (manual vs normal)
    setState(() {
      _currentAddress = isManual ? "manual station" : address;
    });

    // Emit values to parent
    _emitValues();
  }

  void _openStationOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = _buildStationSearchOverlay();
    Overlay.of(context).insert(_overlayEntry!);

    _searchCtl.clear();
    _stationResults = [];

    // Ensure the search field gets focus *after* the overlay is attached
    Future.microtask(() => _searchFocusNode.requestFocus());
  }

  void _closeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;

    _searchFocusNode.unfocus();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final border = const OutlineInputBorder();
    final searchIcon = widget.searchIcon ?? Icons.search;
    final globeIcon = widget.globePinIcon ?? Icons.public;
    final loc = AppLocalizations.of(context)!;

    Widget actionButton(IconData icon, VoidCallback onTap) => Material(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(icon, color: Theme.of(context).colorScheme.onPrimary),
            ),
          ),
        );

    /// ---------- NAME MODE ----------
    final nameMode = Column(
      key: const ValueKey('name-mode'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: TextFormField(
                  controller: _nameCtl,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: loc.nameField,
                    border: border,
                  ),
                  //onChanged: (_) => _emitValues(),
                  onTap: _openStationOverlay,
                ),
              ),
            ),
            const SizedBox(width: 8),
            actionButton(globeIcon, _toggleMode),
          ],
        ),
        const SizedBox(height: 4),
        /// Extra fixed-height area (text only)
        SizedBox(
          height: _extraFieldHeight,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _currentAddress.isEmpty
                ? widget.addressDefaultText
                : _currentAddress,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );

    /// ---------- GEO MODE ----------
    final geoMode = Column(
      key: const ValueKey('geo-mode'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            actionButton(searchIcon, _toggleMode),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: TextFormField(
                  controller: _latCtl,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: loc.addTripLatitudeShort,
                    border: border,
                  ),
                  onChanged: (_) => _emitValues(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: TextFormField(
                  controller: _longCtl,
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: loc.addTripLongitudeShort,
                    border: border,
                  ),
                  onChanged: (_) => _emitValues(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        /// Extra fixed-height area → manual station name
        SizedBox(
          height: _extraFieldHeight,
          child: TextFormField(
            controller: _manualNameCtl,
            decoration: InputDecoration(
              labelText: widget.manualNameFieldHint,
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _emitValues(),
          ),
        ),
      ],
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final beginOffset =
            _direction == -1 ? const Offset(0.15, 0) : const Offset(-0.15, 0);
        return ClipRect(
          child: SlideTransition(
            position: Tween(begin: beginOffset, end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic))
                .animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          ),
        );
      },
      child: _geoMode ? geoMode : nameMode,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.centerLeft,
        children: [
          ...previousChildren,
          if (currentChild != null) currentChild,
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (widget.nameController == null) _nameCtl.dispose();
    if (widget.latController == null) _latCtl.dispose();
    if (widget.longController == null) _longCtl.dispose();
    _manualNameCtl.dispose();
    super.dispose();
  }
}
