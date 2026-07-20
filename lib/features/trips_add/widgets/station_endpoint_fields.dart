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
/// Renders the middle rows of an endpoint card as grouped-card line items in
/// the style of the details step tiles: leading icon (tinted with the
/// primary colour once the row has a value), uppercase micro-label and a
/// borderless value underneath. In by-name mode that is a tappable row
/// opening the full-screen suggestion overlay, with the resolved address as
/// plain text below; in manual mode a free-text name row and a divided
/// double cell with the monospaced latitude / longitude inputs. The parent
/// card draws the hairline dividers around this widget. Unlike the
/// deprecated StationFieldsSwitcher, the mode
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

  /// Borderless collapsed decoration for inputs living inside a card line
  /// item, matching the details step tiles.
  InputDecoration _lineItemDecoration({String? hint}) {
    return InputDecoration(
      isCollapsed: true,
      filled: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      hintText: hint,
    );
  }

  /// Uppercase micro-label above a value, matching the line-item labels of
  /// the other wizard steps.
  Widget _fieldLabel(String text) {
    final theme = Theme.of(context);
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  /// Leading icon colour: primary once the field has a value, muted
  /// otherwise — same behaviour as the detail and ticket line items.
  Color _iconColour(ThemeData theme, bool hasValue) {
    return hasValue
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
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
  // Line-item building blocks (details step tile style)
  // ------------------------------

  /// One card line item: leading icon, uppercase label and the value widget
  /// underneath. Optionally tappable across the whole row.
  Widget _lineItem({
    required IconData icon,
    required bool hasValue,
    required String label,
    required Widget child,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _iconColour(theme, hasValue)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel(label),
                const SizedBox(height: 4),
                child,
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(onTap: onTap, child: content);
  }

  /// One half of the LAT/LONG double cell: uppercase label above a
  /// borderless monospaced coordinate input.
  Widget _coordCell(String label, TextEditingController controller) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(label),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            style: AppTheme.monoFont.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _lineItemDecoration(),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*$')),
            ],
            onChanged: (_) => _emitValues(),
          ),
        ],
      ),
    );
  }

  // ------------------------------
  // Build UI
  // ------------------------------
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final valueStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );

    // ---------------- BY NAME MODE ------------------
    final hasStation = _nameCtl.text.isNotEmpty;
    final nameMode = Column(
      key: const ValueKey('name-mode'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tappable station row opening the search overlay.
        _lineItem(
          icon: Icons.search,
          hasValue: hasStation,
          label: loc.nameField,
          onTap: _openOverlay,
          child: Text(
            hasStation
                ? _nameCtl.text
                : loc.searchStationHint(widget.vehicleType.name),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: valueStyle?.copyWith(
              color: hasStation
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        // Resolved address: plain annotation text, aligned with the value
        // column, clearly not a field.
        Padding(
          padding: const EdgeInsets.fromLTRB(46, 0, 16, 12),
          child: Row(
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
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    // ---------------- MANUAL MODE ------------------
    final geoMode = Column(
      key: const ValueKey('geo-mode'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _lineItem(
          icon: Icons.label_outline,
          hasValue: _manualNameCtl.text.isNotEmpty,
          label: loc.nameField,
          child: TextFormField(
            controller: _manualNameCtl,
            style: valueStyle,
            decoration: _lineItemDecoration(hint: widget.manualNameFieldHint),
            onChanged: (_) {
              setState(() {});
              _emitValues();
            },
          ),
        ),
        Divider(height: 1, color: theme.dividerColor),
        // LAT/LONG double cell with a vertical separation. A fixed-height
        // separator keeps the cells at their natural, compact height
        // (IntrinsicHeight would let the text fields inflate the row).
        Row(
          children: [
            Expanded(
              child: _coordCell(loc.addTripLatitudeShort, _latCtl),
            ),
            Container(width: 1, height: 44, color: theme.dividerColor),
            Expanded(
              child: _coordCell(loc.addTripLongitudeShort, _longCtl),
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
