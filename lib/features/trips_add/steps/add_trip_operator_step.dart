import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/services/operator_suggestion_service.dart';
import 'package:trainlog_app/utils/style_utils.dart';
import 'package:trainlog_app/features/trips_add/widgets/full_screen_search_overlay.dart';
import 'package:trainlog_app/widgets/monogram.dart';

/// Step 3 of the "Add Trip" wizard: operator selection.
///
/// Shows a search field opening the app's full-screen search overlay, the
/// "Selected operators" block (with a trailing cross to remove each entry)
/// and, below it, route-relevant suggestions from the local trips database
/// ([OperatorSuggestionService]). Selecting a suggestion moves it up into
/// the selected block. Custom operators are created from inside the overlay
/// via a dashed button that appears once the user has typed something; they
/// get the app's [Monogram] as placeholder logo.
class AddTripOperatorStep extends StatefulWidget {
  const AddTripOperatorStep({super.key});

  @override
  State<AddTripOperatorStep> createState() => _AddTripOperatorStepState();
}

class _AddTripOperatorStepState extends State<AddTripOperatorStep> {
  static const _suggestionService = OperatorSuggestionService();

  final TextEditingController _searchCtl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  List<String> _searchResults = [];

  List<OperatorSuggestion> _suggestions = [];
  String? _suggestionInputsKey;
  bool _operatorsLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_operatorsLoaded) {
      _operatorsLoaded = true;
      context.read<TrainlogProvider>().reloadOperatorList();
    }
    _reloadSuggestionsIfNeeded();
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _searchCtl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // Suggestions
  // ─────────────────────────────────────────────────────────────

  /// Re-queries the suggestion service when the inputs it depends on
  /// (vehicle type and trip ends) have changed.
  void _reloadSuggestionsIfNeeded() {
    final model = context.read<TripFormModel>();
    final repository = context.read<TripsProvider>().repository;
    if (repository == null) return;

    final key = [
      model.vehicleType?.name,
      model.departureLat, model.departureLong, model.departureStationName,
      model.arrivalLat, model.arrivalLong, model.arrivalStationName,
    ].join('|');
    if (key == _suggestionInputsKey) return;
    _suggestionInputsKey = key;

    _suggestionService
        .suggest(
      repository: repository,
      vehicleType: model.vehicleType ?? VehicleType.train,
      departureLat: model.departureLat,
      departureLong: model.departureLong,
      departureName: model.departureStationName,
      arrivalLat: model.arrivalLat,
      arrivalLong: model.arrivalLong,
      arrivalName: model.arrivalStationName,
    )
        .then((results) {
      if (!mounted) return;
      setState(() => _suggestions = results);
    });
  }

  // ─────────────────────────────────────────────────────────────
  // Selection
  // ─────────────────────────────────────────────────────────────

  void _addOperator(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final model = context.read<TripFormModel>();
    if (model.selectedOperators.contains(trimmed)) return;

    model.setOperators([...model.selectedOperators, trimmed]);
    model.clearOperatorError();
  }

  void _removeOperator(String name) {
    final model = context.read<TripFormModel>();
    model.setOperators(
        model.selectedOperators.where((op) => op != name).toList());
  }

  /// Adds a raw string, matching it to a known operator when possible.
  void _commitRawOperator(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return;

    final trainlog = context.read<TrainlogProvider>();
    final closest = trainlog.getClosestOperators(trimmed, limit: 1);
    final toAdd = (closest.isNotEmpty &&
            closest.first.toLowerCase() == trimmed.toLowerCase())
        ? closest.first
        : trimmed;

    _addOperator(toAdd);
  }

  // ─────────────────────────────────────────────────────────────
  // Search overlay
  // ─────────────────────────────────────────────────────────────

  void _openOverlay() {
    if (_overlayEntry != null) return;

    _overlayEntry = _buildOverlay();
    Overlay.of(context).insert(_overlayEntry!);

    _searchCtl.clear();
    _searchResults = [];

    Future.microtask(() => _searchFocusNode.requestFocus());
  }

  void _closeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _searchCtl.clear();
    _searchResults = [];
    _searchFocusNode.unfocus();
    if (mounted) setState(() {});
  }

  void _onOverlayTextChanged(String value) {
    final query = value.trim();
    final trainlog = context.read<TrainlogProvider>();
    _searchResults =
        query.isEmpty ? [] : trainlog.getClosestOperators(query, limit: 10);
    _overlayEntry?.markNeedsBuild();
  }

  OverlayEntry _buildOverlay() {
    final loc = AppLocalizations.of(context)!;

    return OverlayEntry(
      builder: (context) {
        final query = _searchCtl.text.trim();

        return FullScreenSearchOverlay<String>(
          controller: _searchCtl,
          focusNode: _searchFocusNode,
          items: _searchResults,
          hintText: loc.addTripOperatorHint,
          onChanged: _onOverlayTextChanged,
          onSubmitted: (value) {
            _commitRawOperator(value);
            _closeOverlay();
          },
          onSelected: (op) {
            _addOperator(op);
            _closeOverlay();
          },
          onClose: _closeOverlay,
          // Dashed "add as custom" action: hidden until the user has typed
          // at least one character.
          belowSearchField: query.isEmpty
              ? null
              : _DashedAddCustomButton(
                  label: loc.addTripAddCustomOperator,
                  onTap: () {
                    _addOperator(query);
                    _closeOverlay();
                  },
                ),
          itemBuilder: (context, op) => ListTile(
            leading: _OperatorLogo(name: op),
            title: Text(op),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final model = context.watch<TripFormModel>();
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;

    _reloadSuggestionsIfNeeded();

    final selected = model.selectedOperators;
    final suggestions =
        _suggestions.where((s) => !selected.contains(s.name)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.addTripOperatorTitle,
            style: AppTheme.displayFont.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          // Search field: opens the full-screen search overlay.
          TextFormField(
            readOnly: true,
            onTap: _openOverlay,
            decoration: InputDecoration(
              hintText: loc.addTripOperatorHint,
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 20),

          // Selected operators — directly above the suggestions.
          if (selected.isNotEmpty) ...[
            _SectionLabel(text: loc.addTripSelectedOperators),
            const SizedBox(height: 8),
            _OperatorCard(
              children: [
                for (final op in selected)
                  _OperatorRow(
                    name: op,
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      tooltip:
                          MaterialLocalizations.of(context).deleteButtonTooltip,
                      onPressed: () => _removeOperator(op),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // Suggestions from the local trips database.
          if (suggestions.isNotEmpty) ...[
            _SectionLabel(text: loc.addTripSuggestedOperators),
            const SizedBox(height: 8),
            _OperatorCard(
              children: [
                for (final suggestion in suggestions)
                  _OperatorRow(
                    name: suggestion.name,
                    subtitle:
                        loc.addTripOperatorTripCount(suggestion.tripCount),
                    trailing: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(
                        Icons.radio_button_unchecked,
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    onTap: () => _addOperator(suggestion.name),
                  ),
              ],
            ),
            const SizedBox(height: 8,),
            Text(
              loc.addTripSuggestedOperatorsHelper,
              softWrap: true,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

/// Small uppercase section label ("SELECTED OPERATORS", "SUGGESTED FOR THIS
/// ROUTE"), consistent with the endpoint block headers of the route step.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
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
}

/// Rounded card grouping operator rows, separated by hairline dividers.
class _OperatorCard extends StatelessWidget {
  const _OperatorCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: theme.dividerColor),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// One operator line: logo, name (with optional subtitle) and a trailing
/// action or indicator.
class _OperatorRow extends StatelessWidget {
  const _OperatorRow({
    required this.name,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final String name;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            _OperatorLogo(name: name),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

/// Operator logo, falling back to the app [Monogram] when no logo is known
/// (e.g. custom operators created by the user).
class _OperatorLogo extends StatelessWidget {
  const _OperatorLogo({required this.name});

  static const double _size = 40;

  final String name;

  @override
  Widget build(BuildContext context) {
    final trainlog = context.read<TrainlogProvider>();

    if (trainlog.hasOperatorLogo(name)) {
      return SizedBox(
        width: _size,
        height: _size,
        child: withOperatorLogoBg(
          context,
          trainlog.getOperatorImage(name, maxWidth: _size, maxHeight: _size),
          radius: 8,
        ),
      );
    }

    return SizedBox(
      width: _size,
      height: _size,
      child: FittedBox(child: Monogram(username: name, highlight: false)),
    );
  }
}

/// "+ Add as a custom operator" action with a dashed outline, rendered
/// inside the search overlay under the search field.
class _DashedAddCustomButton extends StatelessWidget {
  const _DashedAddCustomButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: CustomPaint(
        painter: _DashedRRectPainter(
          color: theme.colorScheme.outline,
          radius: 12,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(Icons.add, size: 18, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints a dashed rounded-rectangle outline.
class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(radius),
      ));

    const dashLength = 6.0;
    const gapLength = 4.0;

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashLength),
          paint,
        );
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
