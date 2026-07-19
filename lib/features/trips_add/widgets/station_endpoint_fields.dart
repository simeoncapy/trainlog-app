import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/features/trips_add/widgets/full_screen_search_overlay.dart';

/// Departure/arrival station fields of the "Add Trip" route step.
///
/// Renders either the by-name search field (read-only; tapping opens the
/// full-screen suggestion overlay) with the resolved address underneath, or
/// the manual fields (name with a label icon, then monospaced latitude /
/// longitude inputs). Unlike the deprecated StationFieldsSwitcher, the mode
/// toggle UI lives in the parent (an AppStepsTabBar in the block header),
/// which calls [StationEndpointFieldsState.setMode] through a [GlobalKey];
/// the mode-switching behaviour itself is identical to the old widget.
class StationEndpointFields extends StatefulWidget {
  const StationEndpointFields({
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

  @override
  State<StationEndpointFields> createState() => StationEndpointFieldsState();
}

class StationEndpointFieldsState extends State<StationEndpointFields> {
  late final TextEditingController _nameCtl = TextEditingController();
  late final TextEditingController _latCtl = TextEditingController();
  late final TextEditingController _longCtl = TextEditingController();
  late final TextEditingController _manualNameCtl = TextEditingController();

  late bool _geoMode = widget.initialGeoMode;
  double? _savedLat;
  double? _savedLng;
  String? _savedBaseName;

  int _direction = -1;

  String _currentAddress = "";

  OverlayEntry? _overlayEntry;
  final TextEditingController _searchCtl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<StationInfo> _stationResults = [];
  bool _isSearching = false;
  int _searchRequestId = 0;

  bool _updatingFromSelf = false;

  Timer? _debounceTimer;

  /// Compact field decoration following the app guidelines (dense fields with
  /// the label inside the decoration).
  InputDecoration _decoration(String label, {Widget? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: prefixIcon,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

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
      _latCtl.text = "0.0";
      _longCtl.text = "0.0";
    }
    _currentAddress = widget.initialAddress ?? '';
  }

  @override
  void didUpdateWidget(covariant StationEndpointFields oldWidget) {
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

    if (_geoMode) {
      _manualNameCtl.text = widget.initialStationName ?? '';
      _latCtl.text = widget.initialLat?.toString() ?? '0.0';
      _longCtl.text = widget.initialLng?.toString() ?? '0.0';
      _nameCtl.text = "";
      _savedLat = null;
      _savedLng = null;
      _savedBaseName = null;
    } else {
      _nameCtl.text = widget.initialStationName ?? '';
      _manualNameCtl.text = "";
      _latCtl.text = "0.0";
      _longCtl.text = "0.0";
      _savedLat = widget.initialLat;
      _savedLng = widget.initialLng;
      _savedBaseName = null;
    }

    _currentAddress = widget.initialAddress ?? '';

    setState(() {});
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;
    _nameCtl.dispose();
    _latCtl.dispose();
    _longCtl.dispose();
    _manualNameCtl.dispose();
    _searchCtl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ------------------------------
  // Toggle mode (same behaviour as the deprecated widget's _toggleMode,
  // but invoked from the parent's tab bar instead of an inline button)
  // ------------------------------
  bool get geoMode => _geoMode;

  void setMode(bool manual) {
    if (manual == _geoMode) return;
    setState(() {
      _geoMode = manual;
      _direction = _geoMode ? -1 : 1;
    });
    _emitValues();
  }

  // ------------------------------
  // Emit updated values to parent
  // ------------------------------
  void _emitValues() {
    _updatingFromSelf = true;

    widget.onChanged?.call({
      'mode': _geoMode ? "geo" : "name",
      'name': _geoMode ? _manualNameCtl.text : _nameCtl.text,
      'baseName': _geoMode ? _manualNameCtl.text : (_savedBaseName ?? _nameCtl.text),
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

          onChanged: (query) {
            _debounceTimer?.cancel();
            _debounceTimer = Timer(const Duration(milliseconds: 400), () {
              _performStationSearch(query);
            });
          },

          itemBuilder: (context, station) {
            final (name, displayName, coords, address, isManual) = station;
            final theme = Theme.of(context);
            return ListTile(
              tileColor: isManual ? Colors.red.withValues(alpha: 0.1) : null,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.place_outlined,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              title: Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: isManual ? Text(loc.manual, style: const TextStyle(color: Colors.red)) :
              address.isEmpty
                  ? null
                  : Text(
                      address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
              // trailing: isManual
              //     ? Text(loc.manual, style: const TextStyle(color: Colors.red))
              //     : null,
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
    final (name, displayName, coords, address, isManual) = station;

    _nameCtl.text = displayName;
    _savedBaseName = name;
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
    final theme = Theme.of(context);
    final monoStyle = AppTheme.monoFont.copyWith(
      fontSize: 14,
      color: theme.colorScheme.onSurface,
    );

    // ---------------- BY NAME MODE ------------------
    final nameMode = Column(
      key: const ValueKey('name-mode'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _nameCtl,
          readOnly: true,
          onTap: _openOverlay,
          decoration: _decoration(
            loc.nameField,
            prefixIcon: const Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 8),
        // Space for the resolved address of the selected station.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.place_outlined,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _currentAddress.isEmpty
                    ? widget.addressDefaultText
                    : _currentAddress,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );

    // ---------------- MANUAL MODE ------------------
    final geoMode = Column(
      key: const ValueKey('geo-mode'),
      children: [
        TextFormField(
          controller: _manualNameCtl,
          decoration: _decoration(
            widget.manualNameFieldHint,
            prefixIcon: const Icon(Icons.label_outline),
          ),
          onChanged: (_) => _emitValues(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _latCtl,
                style: monoStyle,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _decoration(loc.addTripLatitudeShort),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*$')),
                ],
                onChanged: (_) => _emitValues(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _longCtl,
                style: monoStyle,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: _decoration(loc.addTripLongitudeShort),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*$')),
                ],
                onChanged: (_) => _emitValues(),
              ),
            ),
          ],
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
