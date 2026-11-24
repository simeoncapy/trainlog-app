import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/core/data/models/time_moment.dart';
import 'package:trainlog_app/core/data/models/trips.dart';
import 'package:trainlog_app/core/data/models/trips_filter.dart';
import 'package:trainlog_app/core/data/trips_repository.dart';
import 'package:trainlog_app/core/providers/settings_provider.dart';
import 'package:trainlog_app/core/providers/trainlog_provider.dart';
import 'package:trainlog_app/features/trips/detail_sheet/cupertino/trip_actions_cupertino_view.dart';
import 'package:trainlog_app/features/trips/detail_sheet/trip_details_actions.dart';
import 'package:trainlog_app/features/trips/trips_list_controller.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_progress_indicator.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_trip_card.dart';
import 'package:trainlog_app/ui/cupertino/app_context_menu.dart';
import 'package:trainlog_app/ui/cupertino/swipe_actions.dart';
import 'package:trainlog_app/ui/tokens/app_colors.dart';
import 'package:trainlog_app/ui/tokens/app_theme.dart';
import 'package:trainlog_app/utils/date_utils.dart' as date_utils;
import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/utils/platform_utils.dart';
import 'package:trainlog_app/utils/style_utils.dart';

const double _groupRadius = 26;
const double _rowPadding = 16;
const double _tileSize = 36;
const double _tileGap = 12;
const double _separatorIndent = _rowPadding + _tileSize + _tileGap;
const double _headerHeight = 44;
const Radius _corner = Radius.circular(_groupRadius);

/// Trips list, iOS: an inset grouped list with one group per month, as in
/// Wallet's transactions. The month names stay pinned at the top while their
/// trips scroll under them. A row swipes left for Duplicate and Delete, and
/// a long press opens its context menu (Edit, Duplicate, Share, Delete).
class TripsListCupertino extends StatefulWidget {
  const TripsListCupertino({
    super.key,
    required this.repo,
    required this.filter,
    required this.timeMoment,
    required this.revision,
  });

  final TripsRepository repo;
  final TripsFilterResult? filter;
  final TimeMoment timeMoment;

  /// `TripsProvider.revision`: when it changes, the trips on screen are
  /// re-read in place.
  final int revision;

  @override
  State<TripsListCupertino> createState() => _TripsListCupertinoState();
}

class _TripsListCupertinoState extends State<TripsListCupertino> {
  late TripsListController _list = _newController();
  final _scroll = ScrollController();

  TripsListController _newController() => TripsListController(
    repo: widget.repo,
    filter: widget.filter,
    timeMoment: widget.timeMoment,
  )..load();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(TripsListCupertino old) {
    super.didUpdateWidget(old);
    if (old.repo != widget.repo ||
        old.filter != widget.filter ||
        old.timeMoment != widget.timeMoment) {
      _list.dispose();
      _list = _newController();
    } else if (old.revision != widget.revision) {
      _list.load(showLoader: false);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _list.dispose();
    super.dispose();
  }

  void _onScroll() {
    final p = _scroll.position;
    if (p.pixels >= p.maxScrollExtent - 400) _list.loadMore();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _list,
      builder: (context, _) {
        if (_list.isLoading) {
          return const Center(child: AdaptiveProgressIndicator());
        }
        if (_list.isEmpty) {
          return Center(
            child: Text(
              AppLocalizations.of(context)!.tripsEmptyList,
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          );
        }
        // A short first page cannot be scrolled to its end: load on.
        if (_list.hasMore) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _scroll.hasClients) _onScroll();
          });
        }

        final bottom = MediaQuery.of(context).padding.bottom;
        return SwipeActionsScope(
          child: CustomScrollView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              for (final month in _list.months)
                SliverMainAxisGroup(
                  slivers: [
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _MonthHeader(month),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      sliver: SliverToBoxAdapter(
                        child: _MonthGroup(month: month),
                      ),
                    ),
                  ],
                ),
              if (_list.isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CupertinoActivityIndicator()),
                  ),
                ),
              SliverToBoxAdapter(child: SizedBox(height: bottom + 8)),
            ],
          ),
        );
      },
    );
  }
}

/// The month's name, pinned above its group while it scrolls, on a blurred
/// band of the page's background.
class _MonthHeader extends SliverPersistentHeaderDelegate {
  _MonthHeader(this.month);

  final TripsMonth month;

  @override
  double get minExtent => _headerHeight;

  @override
  double get maxExtent => _headerHeight;

  @override
  bool shouldRebuild(_MonthHeader old) =>
      old.month.year != month.year || old.month.month != month.month;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    final l10n = AppLocalizations.of(context)!;
    final theme = CupertinoTheme.of(context);
    final String label;
    if (month.isUnknownDate) {
      label = l10n.tripCardDateUndefined;
    } else {
      final locale = Localizations.localeOf(context).toString();
      final raw = DateFormat.yMMMM(locale).format(month.date);
      // Month names are lower case in some languages (French): sentence
      // case, as the other section titles.
      label = raw[0].toUpperCase() + raw.substring(1);
    }
    final background = theme.scaffoldBackgroundColor;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: background.withValues(alpha: overlaps ? 0.85 : 1),
          padding: const EdgeInsets.fromLTRB(_rowPadding + 4, 0, 16, 6),
          alignment: Alignment.bottomLeft,
          child: Text(
            label,
            style: AppTheme.displayFont.copyWith(
              fontSize: Theme.of(context).textTheme.titleMedium?.fontSize,
              color: theme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }
}

/// One month's trips: a rounded group with hairlines between the rows.
class _MonthGroup extends StatelessWidget {
  const _MonthGroup({required this.month});

  final TripsMonth month;

  @override
  Widget build(BuildContext context) {
    final separator = CupertinoColors.separator.resolveFrom(context);
    return ClipRSuperellipse(
      borderRadius: const BorderRadius.all(Radius.circular(_groupRadius)),
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < month.trips.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: _separatorIndent,
                  ),
                  child: Container(height: 0.5, color: separator),
                ),
              _TripRowWithActions(
                key: ValueKey(month.trips[i].uid),
                trip: month.trips[i],
                corners: BorderRadius.vertical(
                  top: i == 0 ? _corner : Radius.zero,
                  bottom: i == month.trips.length - 1 ? _corner : Radius.zero,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A trip row with its swipe actions and its context menu.
class _TripRowWithActions extends StatelessWidget {
  const _TripRowWithActions({
    super.key,
    required this.trip,
    required this.corners,
  });

  final Trips trip;

  /// The corners the row shares with its month's group, which it keeps when
  /// lifted by the context menu.
  final BorderRadius corners;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final actions = tripActionCallbacks(context, trip, inSheet: false);
    void delete() =>
        actions.onDelete(() => confirmTripDeleteCupertino(context));

    return SwipeActions(
      actions: [
        SwipeAction(
          icon: AdaptiveIcons.copy,
          label: l10n.duplicateBtnLabel,
          color: CupertinoColors.systemGrey,
          onPressed: actions.onDuplicate,
        ),
        SwipeAction(
          icon: AdaptiveIcons.delete,
          label: l10n.deleteButton,
          isDestructive: true,
          onPressed: delete,
        ),
      ],
      child: AppContextMenu(
        rowCorners: corners,
        slotColor: CupertinoTheme.of(context).scaffoldBackgroundColor,
        rowColor: Theme.of(context).colorScheme.surface,
        actions: [
          AppContextMenuAction(
            label: l10n.tripsDetailsEditButton,
            icon: AdaptiveIcons.edit,
            onPressed: actions.onEdit,
          ),
          AppContextMenuAction(
            label: l10n.duplicateBtnLabel,
            icon: AdaptiveIcons.copy,
            onPressed: actions.onDuplicate,
          ),
          AppContextMenuAction(
            label: CupertinoLocalizations.of(context).shareButtonLabel,
            icon: AdaptiveIcons.share,
            onPressed: actions.onShare,
          ),
          AppContextMenuAction(
            label: l10n.deleteButton,
            icon: AdaptiveIcons.delete,
            isDestructive: true,
            onPressed: delete,
          ),
        ],
        child: _TripRow(trip: trip),
      ),
    );
  }
}

/// One trip: the vehicle tile, "Origin → Destination", times, duration and
/// distance under it; the day and the operator's logo on the trailing side.
/// Opens the trip's details sheet; greys while pressed like a table cell.
class _TripRow extends StatefulWidget {
  const _TripRow({required this.trip});

  final Trips trip;

  @override
  State<_TripRow> createState() => _TripRowState();
}

class _TripRowState extends State<_TripRow> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final textTheme = Theme.of(context).textTheme;
    final label = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final surface = Theme.of(context).colorScheme.surface;
    final pressed = CupertinoColors.systemGrey4.resolveFrom(context);

    final palette = MapColorPaletteHelper.getPalette(
      context.read<SettingsProvider>().mapColorPalette,
    );
    final typeColor = palette[trip.type] ?? AppColors.amber;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: () => showAdaptiveTripBottomSheet(context, trip: trip),
      child: ColoredBox(
        // Opaque: the swipe buttons sit under the row.
        color: _pressed ? pressed : surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _rowPadding,
            vertical: 12,
          ),
          child: Row(
            children: [
              DecoratedBox(
                decoration: ShapeDecoration(
                  color: typeColor,
                  shape: const RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.all(Radius.circular(9)),
                  ),
                ),
                child: SizedBox.square(
                  dimension: _tileSize,
                  child: IconTheme(
                    data: const IconThemeData(
                      color: CupertinoColors.white,
                      size: 20,
                    ),
                    child: trip.type.icon(),
                  ),
                ),
              ),
              const SizedBox(width: _tileGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${trip.originStation} → ${trip.destinationStation}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: label,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _Details(trip: trip, color: secondary),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _Trailing(trip: trip, color: secondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// "TGV 6201 · 08:12 – 10:05 · 2:03 · 465 km", the delays in red or green.
class _Details extends StatelessWidget {
  const _Details({required this.trip, required this.color});

  final Trips trip;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: color);
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final late = isDark ? AppColors.errorDark : AppColors.late;
    final early = isDark ? AppColors.successDark : AppColors.early;

    final parts = <List<InlineSpan>>[];
    if (trip.lineName.isNotEmpty) parts.add([TextSpan(text: trip.lineName)]);

    final showTimes = !trip.isUnknownPastFuture && !trip.isDateOnly;
    if (showTimes) {
      InlineSpan delay(int? minutes, String? text) =>
          minutes == null || minutes == 0 || text == null
          ? const TextSpan()
          : TextSpan(
              text: ' $text',
              style: TextStyle(color: minutes > 0 ? late : early),
            );
      String time(DateTime d) =>
          date_utils.formatDateTime(context, d, timeOnly: true);
      parts.add([
        TextSpan(text: time(trip.startDatetime)),
        delay(trip.departureDelayInMinutes, trip.departureDelayFormatted),
        const TextSpan(text: ' – '),
        TextSpan(text: time(trip.endDatetime)),
        delay(trip.arrivalDelayInMinutes, trip.arrivalDelayFormatted),
      ]);
    }
    if (!trip.isUnknownPastFuture && trip.duration != Duration.zero) {
      parts.add([TextSpan(text: trip.durationFormatted)]);
    }
    if (trip.tripLength > 0) {
      parts.add([TextSpan(text: '${(trip.tripLength / 1000).round()} km')]);
    }
    if (parts.isEmpty) return const SizedBox.shrink();

    return Text.rich(
      TextSpan(
        children: [
          for (int i = 0; i < parts.length; i++) ...[
            if (i > 0) const TextSpan(text: ' · '),
            ...parts[i],
          ],
        ],
      ),
      style: style,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// The day ("Mon 24", "lun. 24") above the operator's logo.
class _Trailing extends StatelessWidget {
  const _Trailing({required this.trip, required this.color});

  final Trips trip;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final d = trip.startDatetime;
    final unknown = d.year == 0 || d.year == 9999 || trip.isUnknownPastFuture;
    final locale = Localizations.localeOf(context).toString();
    final operators = trip.operatorName
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!unknown)
          Text(
            // The month is in the section title: weekday and day only.
            locale.startsWith('ja')
                ? DateFormat('d日(E)', locale).format(d)
                : DateFormat('E d', locale).format(d),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        if (operators.isNotEmpty) ...[
          const SizedBox(height: 4),
          SizedBox(
            width: 40,
            height: 24,
            child: Align(
              alignment: Alignment.centerRight,
              child: withOperatorLogoBg(
                context,
                context.read<TrainlogProvider>().getOperatorImage(
                  operators.join('&&'),
                  maxWidth: 40,
                  maxHeight: 24,
                ),
                radius: 4,
                padding: const EdgeInsets.all(2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
