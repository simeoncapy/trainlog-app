import 'package:flutter/material.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';

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
                  decoration: InputDecoration(
                    labelText: loc.nameField,
                    border: border,
                  ),
                  onChanged: (_) => _emitValues(),
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
              widget.addressDefaultText,
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
