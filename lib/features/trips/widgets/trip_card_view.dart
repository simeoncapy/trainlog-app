import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/app/theme/app_colors.dart';
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/data/trips_repository.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/platform/adaptive_trip_card.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/utils/date_utils.dart' as date_utils;
import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/utils/style_utils.dart';
import 'package:trainlog_app/widgets/divider_with_widget.dart';
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
      // Order by UTC time so trips crossing time zones (e.g. the IDL)
      // are sorted chronologically; display still uses local time.
      orderBy: widget.timeMoment == TimeMoment.future
          ? 'COALESCE(utc_start_datetime, start_datetime) ASC'
          : 'COALESCE(utc_start_datetime, start_datetime) DESC',
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
          AppLocalizations.of(context)!.tripsEmptyList,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    final bottomInset = MediaQuery.of(context).padding.bottom;
    final cs = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();

    // Build a flat list of items (dividers + cards) from loaded trips.
    final List<Widget> listItems = [];
    String? lastMonthKey;
    DateTime? lastMonthDate; // date of the month above (newer, already processed)
    bool isFirstDivider = true;

    for (int index = 0; index < _totalCount; index++) {
      final trip = index < _items.length ? _items[index] : null;

      if (trip == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _loadMoreIfNeeded());
        listItems.add(const _TripCardSkeleton());
        lastMonthKey = null;
        lastMonthDate = null;
        continue;
      }

      final dt = trip.startDatetime;
      final monthKey = '${dt.year}-${dt.month}';

      if (monthKey != lastMonthKey) {
        final Widget dividerChild;

        final l10n = AppLocalizations.of(context)!;
        final isUnknown = dt.year == 0 || dt.year == 9999;

        if (isFirstDivider || lastMonthDate == null) {
          // Top of the list: year only (or "Undefined" for unknown dates).
          dividerChild = Text(
            isUnknown ? l10n.tripCardDateUndefined : '${dt.year}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          );
          isFirstDivider = false;
        } else {
          // Between two months: "↓ belowMonth / aboveMonth ↑"
          // dt            = month below the divider (just entered)
          // lastMonthDate = month above the divider (previously processed)
          final aboveDt = lastMonthDate!;
          final isAboveUnknown = aboveDt.year == 0 || aboveDt.year == 9999;
          final yearTransition = !isUnknown && !isAboveUnknown && dt.year != aboveDt.year;
          final bold = yearTransition ? FontWeight.bold : FontWeight.normal;
          final color = yearTransition ? cs.primary : cs.onSurfaceVariant;
          final baseStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: bold,
              );

          String monthLabel(DateTime d, bool unknown, {required bool showYear}) {
            if (unknown) return l10n.tripCardDateUndefined;
            final raw = DateFormat('MMMM', locale).format(d);
            final capitalized = raw[0].toUpperCase() + raw.substring(1);
            return showYear ? '$capitalized ${d.year}' : capitalized;
          }

          final belowLabel = monthLabel(dt, isUnknown, showYear: yearTransition);
          final aboveLabel = monthLabel(aboveDt, isAboveUnknown, showYear: yearTransition);

          dividerChild = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 16, color: color),
              const SizedBox(width: 2),
              Text(belowLabel, style: baseStyle),
              Text('  /  ', style: baseStyle),
              Text(aboveLabel, style: baseStyle),
              const SizedBox(width: 2),
              Icon(Icons.keyboard_arrow_up_rounded,
                  size: 16, color: color),
            ],
          );
        }

        listItems.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
            child: DividerWithWidget(child: dividerChild),
          ),
        );
        lastMonthKey = monthKey;
        lastMonthDate = dt;
      }

      listItems.add(_TripCard(trip: trip, trainlog: widget.trainlog));
    }

    if (_isLoadingMore) {
      listItems.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return ListView(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 90),
      children: listItems,
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
                          .bodySmall
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

    final String depTime = showTimes
        ? date_utils.formatDateTime(context, trip.startDatetime,
            hasTime: true, timeOnly: true)
        : '';
    final String arrTime = showTimes
        ? date_utils.formatDateTime(context, trip.endDatetime,
            hasTime: true, timeOnly: true)
        : '';

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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final metaStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: cs.onSurface.withValues(alpha: 0.6),
        );
    final iconColor = cs.onSurface.withValues(alpha: 0.5);

    final dateStr = trip.isDateOnly
        ? date_utils.formatDateShort(context, trip.startDatetime)
        : date_utils.formatDateRange(
            context, trip.startDatetime, trip.endDatetime);

    final duration = trip.utcEndDatetime?.difference(trip.utcStartDatetime ?? trip.startDatetime); // UTC start shouldn't be NULL if UTC end is not NULL, so startDatetime shouldn't be used (placed here to avoid NULL error)
    final durationStr = date_utils.formatSecondsToHMS(
        (trip.manualTripDuration ?? duration?.inSeconds ?? trip.estimatedTripDuration).round().toInt()
    );

    return Row(
      children: [
        if (trip.tripLength > 0) ...[
          Icon(Icons.route_outlined, size: 13, color: iconColor),
          const SizedBox(width: 4),
          Text('${(trip.tripLength / 1000).round()} km', style: metaStyle),
          const SizedBox(width: 12),
        ],
        if (!trip.isUnknownPastFuture) ...[
          Icon(Icons.schedule_outlined, size: 13, color: iconColor),
          const SizedBox(width: 4),
          Text(durationStr, style: metaStyle),
          const SizedBox(width: 12),
          Icon(Icons.calendar_today_outlined, size: 13, color: iconColor),
          const SizedBox(width: 4),
          Text(dateStr, style: metaStyle),
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
