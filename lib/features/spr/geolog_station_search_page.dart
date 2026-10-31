import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/pre_record_provider.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/utils/number_formatter.dart';
import 'package:trainlog_app/widgets/primary_action_button.dart';

/// Picks the station of a Geolog among the stations around its position,
/// with a field filtering them by name. Pops with the chosen
/// [StationChoice] — `(null, null, VehicleType.unknown)` for an unknown
/// station — or null when closed.
class GeologStationSearchPage extends StatefulWidget {
  const GeologStationSearchPage({
    super.key,
    required this.lat,
    required this.long,
  });

  final double lat;
  final double long;

  /// The search reaches at least this far, whatever the Geolog radius
  /// setting, so a station the recording missed can still be found.
  static const int minimumRadiusMeters = 1000;

  @override
  State<GeologStationSearchPage> createState() =>
      _GeologStationSearchPageState();
}

class _GeologStationSearchPageState extends State<GeologStationSearchPage> {
  final TextEditingController _query = TextEditingController();
  List<StationCandidate>? _stations;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final trainlog = context.read<TrainlogProvider>();
    final radius = math.max(
      context.read<SettingsProvider>().sprRadius,
      GeologStationSearchPage.minimumRadiusMeters,
    );
    try {
      final stations = await trainlog.findStationsFromCoordinate(
        widget.lat,
        widget.long,
        distanceLimitMeters: radius,
      );
      stations.sort((a, b) => a.$4.compareTo(b.$4));
      if (!mounted) return;
      setState(() => _stations = stations);
    } catch (e) {
      debugPrint('GeologStationSearchPage: station search failed: $e');
      if (!mounted) return;
      setState(() {
        _stations = const [];
        _failed = true;
      });
    }
  }

  List<StationCandidate> get _filtered {
    final stations = _stations ?? const [];
    final query = _query.text.trim().toLowerCase();
    if (query.isEmpty) return stations;
    return stations
        .where(
          (s) =>
              (s.$1 ?? '').toLowerCase().contains(query) ||
              (s.$2 ?? '').toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.geologNoteStationSearchTitle)),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _query,
                autofocus: false,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: loc.geologNoteStationSearchHint,
                  suffixIcon: _query.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _query.clear,
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${widget.lat.toStringAsFixed(6)}, ${widget.long.toStringAsFixed(6)}',
                    style: AppTheme.monoFont.copyWith(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _list(loc, theme)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: PrimaryActionButton(
                icon: Icons.not_listed_location,
                label: loc.prerecorderUnknownStation,
                variant: PrimaryActionButtonVariant.outlined,
                onPressed: () => Navigator.of(
                  context,
                ).pop<StationChoice>((null, null, VehicleType.unknown)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(AppLocalizations loc, ThemeData theme) {
    if (_stations == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final stations = _filtered;
    if (stations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _failed
                ? loc.prerecorderErrorFetchingStation
                : loc.geologNoteNoStationFound,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ),
      );
    }

    final settings = context.read<SettingsProvider>();
    final palette = MapColorPaletteHelper.getPalette(settings.mapColorPalette);

    return ListView.separated(
      itemCount: stations.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        indent: 16,
        endIndent: 16,
        color: theme.colorScheme.outline,
      ),
      itemBuilder: (context, index) {
        final (name, address, type, distance) = stations[index];
        final typeColor = palette[type] ?? theme.colorScheme.primary;

        return InkWell(
          onTap: () =>
              Navigator.of(context).pop<StationChoice>((name, address, type)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: typeColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: IconTheme(
                      data: const IconThemeData(color: Colors.white, size: 20),
                      child: type.icon(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name ?? '',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        loc.prerecorderAway(formatNumber(context, distance)),
                        style: AppTheme.monoFont.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
