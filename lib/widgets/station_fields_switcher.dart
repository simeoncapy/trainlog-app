import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/widgets/full_screen_search_overlay.dart';

class StationFieldsSwitcher extends StatefulWidget {
  const StationFieldsSwitcher({
    super.key,

    required this.trainlog,
    required this.vehicleType,
    required this.addressDefaultText,
    required this.manualNameFieldHint,

    // Initial values (for restore)
    this.initialGeoMode = false,
    this.initialStationName,
    this.initialLat,
    this.initialLng,
    this.initialAddress,

    this.onChanged,
    this.searchIcon,
    this.globePinIcon,
  });

  final TrainlogProvider trainlog;
  final VehicleType vehicleType;

  final bool initialGeoMode;
  final String? initialStationName;
  final double? initialLat;
  final double? initialLng;
  final String? initialAddress;

  final String addressDefaultText;
  final String manualNameFieldHint;

  final ValueChanged<Map<String, String>>? onChanged;

  final IconData? searchIcon;
  final IconData? globePinIcon;

  @override
  State<StationFieldsSwitcher> createState() => _StationFieldsSwitcherState();
}

class _StationFieldsSwitcherState extends State<StationFieldsSwitcher>
    with TickerProviderStateMixin {

  late final TextEditingController _nameCtl = TextEditingController();
  late final TextEditingController _latCtl = TextEditingController();
  late final TextEditingController _longCtl = TextEditingController();
  late final TextEditingController _manualNameCtl = TextEditingController();

  late bool _geoMode = widget.initialGeoMode;
  double? _savedLat;
  double? _savedLng;

  static const double _extraFieldHeight = 48;
  int _direction = -1;

  String _currentAddress = "";

  OverlayEntry? _overlayEntry;
  final TextEditingController _searchCtl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<StationInfo> _stationResults = [];
  bool _isSearching = false;
  int _searchRequestId = 0;

  bool _updatingFromSelf = false;

  // ------------------------------
  // INIT: restore values properly
  // ------------------------------
  @override
  void initState() {
    super.initState();

    _geoMode = widget.initialGeoMode;

    if (_geoMode) {
      _latCtl.text = (widget.initialLat ?? 0.0).toString();
      _longCtl.text = (widget.initialLng ?? 0.0).toString();
      _manualNameCtl.text = widget.initialStationName ?? "";
    } else {
      _nameCtl.text = widget.initialStationName ?? "";
      _savedLat = widget.initialLat;
      _savedLng = widget.initialLng;
    }
    _currentAddress = widget.initialAddress ?? '';
  }

  @override
  void didUpdateWidget(covariant StationFieldsSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Do NOT resync if this widget triggered the update
    if (_updatingFromSelf) return;

    // Detect a meaningful external change (switch or reset)
    final shouldUpdate =
        widget.initialGeoMode != oldWidget.initialGeoMode ||
        widget.initialStationName != oldWidget.initialStationName ||
        widget.initialLat != oldWidget.initialLat ||
        widget.initialLng != oldWidget.initialLng ||
        widget.initialAddress != oldWidget.initialAddress;

    if (!shouldUpdate) return;

    // --- sync geo mode ---
    _geoMode = widget.initialGeoMode;

    if(_geoMode) {
      _manualNameCtl.text = widget.initialStationName ?? '';
      _latCtl.text = widget.initialLat?.toString() ?? '0.0';
      _longCtl.text = widget.initialLng?.toString() ?? '0.0';
      _nameCtl.text = "";
      _savedLat = null;
      _savedLng = null;
    }
    else {
      _nameCtl.text = widget.initialStationName ?? '';
      _manualNameCtl.text = "";
      _latCtl.text = "0.0";
      _longCtl.text = "0.0";
      _savedLat = widget.initialLat;
      _savedLng = widget.initialLng;
    }

    _currentAddress = widget.initialAddress ?? '';

    setState(() {});
  }

  // ------------------------------
  // Emit updated values to parent
  // ------------------------------
  void _emitValues() {
    _updatingFromSelf = true;

    widget.onChanged?.call({
      'mode': _geoMode ? "geo" : "name",
      'name': _geoMode ? _manualNameCtl.text : _nameCtl.text,
      'lat': _geoMode ? _latCtl.text : _savedLat?.toString() ?? "",
      'long': _geoMode ? _longCtl.text : _savedLng?.toString() ?? "",
      'address': _geoMode ? '' : _currentAddress,
    });

    // Let the parent rebuild first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatingFromSelf = false;
    });
  }

  // ------------------------------
  // Toggle mode
  // ------------------------------
  void _toggleMode() {
    setState(() {
      _geoMode = !_geoMode;
      _direction = _geoMode ? -1 : 1;
    });
    _emitValues();
  }

  // ------------------------------
  // Search overlay
  // ------------------------------
  OverlayEntry _buildOverlay() {
    final loc = AppLocalizations.of(context)!;

    return OverlayEntry(
      builder: (context) {
        return FullScreenSearchOverlay<StationInfo>(
          controller: _searchCtl,
          focusNode: _searchFocusNode,
          items: _stationResults,
          isLoading: _isSearching,
          hintText: loc.searchStationHint(widget.vehicleType.toString()),

          onChanged: _performStationSearch,

          itemBuilder: (context, station) {
            final (label, coords, address, isManual) = station;
            return ListTile(
              tileColor: isManual ? Colors.red.withOpacity(0.1) : null,
              title: Text(label),
              trailing: isManual
                  ? Text(loc.manual, style: const TextStyle(color: Colors.red))
                  : null,
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

  void _openOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = _buildOverlay();
    Overlay.of(context).insert(_overlayEntry!);

    _searchCtl.clear();
    _stationResults = [];

    Future.microtask(() => _searchFocusNode.requestFocus());
  }

  void _closeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _searchFocusNode.unfocus();
    setState(() {});
  }

  // ------------------------------
  // Perform search
  // ------------------------------
  Future<void> _performStationSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _stationResults = [];
        _isSearching = false;
      });
      _overlayEntry?.markNeedsBuild();
      return;
    }

    final int requestId = ++_searchRequestId;

    setState(() => _isSearching = true);
    _overlayEntry?.markNeedsBuild();

    final results =
        await widget.trainlog.fetchStations(query, widget.vehicleType);

    if (!mounted || _overlayEntry == null || requestId != _searchRequestId) {
      return;
    }

    setState(() {
      _stationResults = results;
      _isSearching = false;
    });

    _overlayEntry?.markNeedsBuild();
  }

  // ------------------------------
  // Select station
  // ------------------------------
  void _selectStation(StationInfo station) {
    final (label, coords, address, isManual) = station;

    _nameCtl.text = label;
    _savedLat = coords.latitude;
    _savedLng = coords.longitude;

    _currentAddress = isManual
        ? AppLocalizations.of(context)!.manual
        : address;

    _emitValues();
    setState(() {});
  }

  // ------------------------------
  // Build UI
  // ------------------------------
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final border = const OutlineInputBorder();
    final searchIcon = widget.searchIcon ?? Icons.search;
    final globeIcon = widget.globePinIcon ?? Symbols.globe_location_pin;

    Widget actionButton(IconData icon, VoidCallback onTap) {
      final theme = Theme.of(context);

      return IconButton(
        onPressed: onTap,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          fixedSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }


    // ---------------- NAME MODE ------------------
    final nameMode = Column(
      key: const ValueKey('name-mode'),
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _nameCtl,
                readOnly: true,
                onTap: _openOverlay,
                decoration: InputDecoration(
                  labelText: loc.nameField,
                  border: border,
                ),
              ),
            ),
            const SizedBox(width: 8),
            actionButton(globeIcon, _toggleMode),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: _extraFieldHeight,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _currentAddress.isEmpty
                  ? widget.addressDefaultText
                  : _currentAddress,
              style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );

    // ---------------- GEO MODE ------------------
    final geoMode = Column(
      key: const ValueKey('geo-mode'),
      children: [
        Row(
          children: [
            actionButton(searchIcon, _toggleMode),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _latCtl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: loc.addTripLatitudeShort,
                  border: border,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*$')),
                ],
                onChanged: (_) => _emitValues(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _longCtl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: loc.addTripLongitudeShort,
                  border: border,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*$')),
                ],
                onChanged: (_) => _emitValues(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: _extraFieldHeight,
          child: TextFormField(
            controller: _manualNameCtl,
            decoration: InputDecoration(
              labelText: widget.manualNameFieldHint,
              border: border,
            ),
            onChanged: (_) => _emitValues(),
          ),
        ),
      ],
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween(
            begin: Offset(_direction * 0.15, 0),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: _geoMode ? geoMode : nameMode,
    );
  }
}
