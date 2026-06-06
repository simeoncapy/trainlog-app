import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/app/theme/app_colors.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/data/trips_repository.dart';
import 'package:trainlog_app/platform/adaptive_trip_card.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/utils/style_utils.dart';
import 'package:trainlog_app/widgets/past_future_selector.dart';
import 'package:trainlog_app/widgets/trips_filter_dialog.dart';

class TripCardView extends StatefulWidget {
  final TripsRepository repo;
  final TrainlogProvider trainlog;
  final TripsFilterResult? filter;
  final TimeMoment timeMoment;

  const TripCardView({
    super.key,
    required this.repo,
    required this.trainlog,
    required this.filter,
    required this.timeMoment,
  });

  @override
  State<TripCardView> createState() => _TripCardViewState();
}

class _TripCardViewState extends State<TripCardView> {
  static const _pageSize = 20;

  final List<Trips?> _items = [];
  int _totalCount = 0;
  bool _isLoadingMore = false;
  bool _initialLoading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void didUpdateWidget(TripCardView old) {
    super.didUpdateWidget(old);
    if (old.filter != widget.filter ||
        old.timeMoment != widget.timeMoment ||
        old.repo != widget.repo) {
      _loadInitial();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _initialLoading = true;
      _items.clear();
      _totalCount = 0;
    });

    _totalCount = await widget.repo.countFilteredTrips(
      showFutureTrips: widget.timeMoment == TimeMoment.future,
      filter: widget.filter,
    );
    _items.addAll(List.generate(_totalCount, (_) => null));

    if (_totalCount > 0) {
      await _loadPage(0);
    }

    if (mounted) setState(() => _initialLoading = false);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMoreIfNeeded();
    }
  }

  Future<void> _loadMoreIfNeeded() async {
    if (_isLoadingMore) return;
    final nextNull = _items.indexWhere((t) => t == null);
    if (nextNull == -1) return;
    final pageIndex = nextNull ~/ _pageSize;
    setState(() => _isLoadingMore = true);
    await _loadPage(pageIndex);
    if (mounted) setState(() => _isLoadingMore = false);
  }

  Future<void> _loadPage(int pageIndex) async {
    final trips = await widget.repo.getTripsFiltered(
      showFutureTrips: widget.timeMoment == TimeMoment.future,
      filter: widget.filter,
      limit: _pageSize,
      offset: pageIndex * _pageSize,
      orderBy: 'start_datetime DESC',
    );
    for (int i = 0; i < trips.length; i++) {
      final idx = pageIndex * _pageSize + i;
      if (idx < _items.length) _items[idx] = trips[i];
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_initialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_totalCount == 0) {
      return Center(
        child: Text(
          'No trips',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: _totalCount + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _totalCount) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final trip = index < _items.length ? _items[index] : null;
        if (trip == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _loadMoreIfNeeded());
          return const _TripCardSkeleton();
        }
        return _TripCard(trip: trip, trainlog: widget.trainlog);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Card widget
// ---------------------------------------------------------------------------

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip, required this.trainlog});

  final Trips trip;
  final TrainlogProvider trainlog;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final settings = context.read<SettingsProvider>();
    final palette = MapColorPaletteHelper.getPalette(settings.mapColorPalette);
    final typeColor = palette[trip.type] ?? AppColors.amber;

    final operators = trip.operatorName.isEmpty
        ? <String>[]
        : trip.operatorName
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

    return GestureDetector(
      onTap: () => showAdaptiveTripBottomSheet(context, trip: trip),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerLow : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: vehicle icon + line name | operator logo
            Row(
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
                      child: trip.type.icon(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (trip.lineName.isNotEmpty)
                  Expanded(
                    child: Text(
                      trip.lineName,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  const Spacer(),
                if (operators.isNotEmpty)
                  _CardOperatorLogo(operators: operators, trainlog: trainlog),
              ],
            ),

            const SizedBox(height: 12),

            // Rows 2+3: times (lighter) and stations with a single chevron
            _RouteSection(trip: trip),

            const SizedBox(height: 10),
            Divider(height: 1, color: cs.outline.withValues(alpha: 0.3)),
            const SizedBox(height: 10),

            // Row 4: metadata (distance · duration · date)
            _MetaRow(trip: trip),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Route section: times (small/muted) + station names, with a single chevron
// spanning both rows
// ---------------------------------------------------------------------------

class _RouteSection extends StatelessWidget {
  const _RouteSection({required this.trip});
  final Trips trip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final showTimes = !trip.isUnknownPastFuture && !trip.isDateOnly;

    final String depTime =
        showTimes ? DateFormat('HH:mm').format(trip.startDatetime) : '';
    final String arrTime =
        showTimes ? DateFormat('HH:mm').format(trip.endDatetime) : '';

    final timeStyle = AppTheme.monoFont.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: cs.onSurface.withValues(alpha: 0.5),
    );
    final stationStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left column: departure time + origin station
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showTimes)
                _TimeLabel(
                  time: depTime,
                  delay: trip.departureDelayInMinutes,
                  delayText: trip.departureDelayFormatted,
                  style: timeStyle,
                  textAlign: TextAlign.start,
                ),
              Text(
                trip.originStation,
                style: stationStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Centre chevron (primary colour), spans both rows
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.chevron_right, size: 22, color: cs.primary),
        ),

        // Right column: arrival time + destination station
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (showTimes)
                _TimeLabel(
                  time: arrTime,
                  delay: trip.arrivalDelayInMinutes,
                  delayText: trip.arrivalDelayFormatted,
                  style: timeStyle,
                  textAlign: TextAlign.end,
                ),
              Text(
                trip.destinationStation,
                style: stationStyle,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimeLabel extends StatelessWidget {
  const _TimeLabel({
    required this.time,
    required this.style,
    required this.textAlign,
    this.delay,
    this.delayText,
  });

  final String time;
  final TextStyle? style;
  final TextAlign textAlign;
  final int? delay;
  final String? delayText;

  @override
  Widget build(BuildContext context) {
    if (delay != null && delayText != null) {
      return Text.rich(
        TextSpan(children: [
          TextSpan(text: time, style: style),
          TextSpan(
            text: ' ($delayText)',
            style: (style ?? const TextStyle()).copyWith(
              color: delay! > 0 ? Colors.red : Colors.green,
              fontSize: 10,
            ),
          ),
        ]),
        textAlign: textAlign,
      );
    }
    return Text(time, style: style, textAlign: textAlign);
  }
}

// ---------------------------------------------------------------------------
// Metadata row: distance · duration · date
// ---------------------------------------------------------------------------

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.trip});
  final Trips trip;

  String _formatDate(BuildContext context, Trips trip) {
    final locale = Localizations.localeOf(context);
    // British date formatting only for English; all other locales use their own.
    final localeStr =
        locale.languageCode == 'en' ? 'en_GB' : locale.toString();

    final start = trip.startDatetime;
    final end = trip.endDatetime;

    final isSameDay = start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;

    if (isSameDay || trip.isDateOnly) {
      return DateFormat('d MMM', localeStr).format(start);
    }

    if (start.month == end.month && start.year == end.year) {
      return '${start.day}–${end.day} ${DateFormat('MMM', localeStr).format(start)}';
    }

    return '${DateFormat('d MMM', localeStr).format(start)}–'
        '${DateFormat('d MMM', localeStr).format(end)}';
  }

  String _formatDuration(Trips trip) {
    final minutes = (trip.manualTripDuration ?? trip.estimatedTripDuration).round();
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final metaStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: cs.onSurface.withValues(alpha: 0.6),
        );

    return Row(
      children: [
        if (trip.tripLength > 0) ...[
          Icon(Icons.route_outlined, size: 13, color: cs.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 4),
          Text('${(trip.tripLength / 1000).round()} km', style: metaStyle),
          const SizedBox(width: 12),
        ],
        if (!trip.isUnknownPastFuture) ...[
          Icon(Icons.schedule_outlined, size: 13, color: cs.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 4),
          Text(_formatDuration(trip), style: metaStyle),
          const SizedBox(width: 12),
        ],
        if (!trip.isUnknownPastFuture) ...[
          Icon(Icons.calendar_today_outlined, size: 13, color: cs.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 4),
          Text(_formatDate(context, trip), style: metaStyle),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Operator logo widget (single or stacked with badge)
// ---------------------------------------------------------------------------

class _CardOperatorLogo extends StatelessWidget {
  const _CardOperatorLogo({required this.operators, required this.trainlog});

  final List<String> operators;
  final TrainlogProvider trainlog;

  @override
  Widget build(BuildContext context) {
    final count = operators.length;
    const size = 36.0;

    final logo = withOperatorLogoBg(
      context,
      trainlog.getOperatorImage(
        operators.join('&&'),
        maxWidth: size,
        maxHeight: size,
      ),
    );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Center(child: logo),
          if (count > 1)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  count > 9 ? '9+' : '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading skeleton card
// ---------------------------------------------------------------------------

class _TripCardSkeleton extends StatelessWidget {
  const _TripCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 120,
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerLow : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
