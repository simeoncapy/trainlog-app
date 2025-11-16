import 'package:flutter/material.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';

/// A reusable widget that toggles between:
///  - Mode A: [ Name | (Globe Location Pin) ]
///  - Mode B: [ (Search button) | Lat | Long ]
/// with a sliding animation left/right when the user taps the button.
///
/// Notes about icons:
///  - By default it uses [Icons.search] and [Icons.public] (globe).
///  - If you use the Material Symbols icon font, you can pass custom icons via
///    [searchIcon] and [globePinIcon] (e.g., Symbols.search, Symbols.globe_location).
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
  }) : super(key: key);

  /// Optional controllers (will be created internally if null).
  final TextEditingController? nameController;
  final TextEditingController? latController;
  final TextEditingController? longController;

  /// Start in geo mode (Lat/Long) or name mode.
  final bool initialGeoMode;

  /// Callback fired when mode changes (true = geo mode).
  final ValueChanged<bool>? onModeChanged;

  /// Override icons if you use Material Symbols:
  /// e.g., `Symbols.search`, `Symbols.globe_location`.
  final IconData? searchIcon;
  final IconData? globePinIcon;

  final ValueChanged<Map<String, String>>? onChanged;

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

  late bool _geoMode = widget.initialGeoMode;

  // We’ll use different slide offsets depending on the direction.
  // When switching to geo mode, slide content from right -> left.
  // When switching back to name mode, slide content from left -> right.
  int _direction = -1; // -1 = to left, +1 = to right

  void _toggleMode() {
    setState(() {
      _geoMode = !_geoMode;
      _direction = _geoMode ? -1 : 1;
    });
    widget.onModeChanged?.call(_geoMode);
  }

  @override
  Widget build(BuildContext context) {
    final border = const OutlineInputBorder();
    final searchIcon = widget.searchIcon ?? Icons.search;
    final globeIcon = widget.globePinIcon ?? Icons.public; // globe pin-like
    final loc = AppLocalizations.of(context)!;

    // Button style used on both sides for consistency
    button(IconData icon, VoidCallback onTap) => Material(
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

    // Two distinct layouts wrapped in keys so AnimatedSwitcher can animate.
    final nameMode = Row(
      key: const ValueKey('name-mode'),
      children: [
        // Name field
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
            child: TextFormField(
              controller: _nameCtl,
              decoration: InputDecoration(
                labelText: loc.nameField,
                border: border,
              ),
              onChanged: (_) {
                widget.onChanged?.call({
                  'name': _nameCtl.text,
                  'lat': _latCtl.text,
                  'long': _longCtl.text,
                  'mode': _geoMode ? "geo" : "name",
                });
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Toggle to geo (Globe button on the right)
        button(globeIcon, _toggleMode),
      ],
    );

    final geoMode = Row(
      key: const ValueKey('geo-mode'),
      children: [
        // Toggle back to name (Search on the left)
        button(searchIcon, _toggleMode),
        const SizedBox(width: 8),
        // Lat field
        Expanded(
          child: TextFormField(
            controller: _latCtl,
            keyboardType:
                const TextInputType.numberWithOptions(signed: true, decimal: true),
            decoration: InputDecoration(
              labelText: loc.addTripLatitudeShort,
              border: border,
            ),
            onChanged: (_) {
              widget.onChanged?.call({
                'name': _nameCtl.text,
                'lat': _latCtl.text,
                'long': _longCtl.text,
                'mode': _geoMode ? "geo" : "name",
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        // Long field
        Expanded(
          child: TextFormField(
            controller: _longCtl,
            keyboardType:
                const TextInputType.numberWithOptions(signed: true, decimal: true),
            decoration: InputDecoration(
              labelText: loc.addTripLongitudeShort,
              border: border,
            ),
            onChanged: (_) {
              widget.onChanged?.call({
                'name': _nameCtl.text,
                'lat': _latCtl.text,
                'long': _longCtl.text,
                'mode': _geoMode ? "geo" : "name",
              });
            },
          ),
        ),
      ],
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        // Slide from the desired direction.
        final beginOffset =
            _direction == -1 ? const Offset(0.15, 0) : const Offset(-0.15, 0);
        final tween = Tween<Offset>(begin: beginOffset, end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic));
        return ClipRect( // avoid overflow during animation
          child: SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(opacity: animation, child: child),
          ),
        );
      },
      child: _geoMode ? geoMode : nameMode,
      layoutBuilder: (currentChild, previousChildren) {
        // Keep height stable during animation
        return Stack(
          alignment: Alignment.centerLeft,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    if (widget.nameController == null) _nameCtl.dispose();
    if (widget.latController == null) _latCtl.dispose();
    if (widget.longController == null) _longCtl.dispose();
    super.dispose();
  }
}
