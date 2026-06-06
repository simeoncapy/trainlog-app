import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/data/trips_repository.dart';
import 'package:trainlog_app/platform/adaptive_trip_card.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/utils/platform_utils.dart';
import 'package:trainlog_app/utils/style_utils.dart';
import 'package:trainlog_app/widgets/past_future_selector.dart';
import 'package:trainlog_app/widgets/trips_filter_dialog.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';

class TripTableView extends StatefulWidget {
  final TripsRepository repo;
  final TrainlogProvider trainlog;
  final TripsFilterResult? filter;
  final TimeMoment timeMoment;

  const TripTableView({
    super.key,
    required this.repo,
    required this.trainlog,
    required this.filter,
    required this.timeMoment,
  });

  @override
  State<TripTableView> createState() => _TripTableViewState();
}

class _TripTableViewState extends State<TripTableView> {
  int _sortColumnIndex = 2;
  bool _sortAscending = false;
  _TripsDataSource? _dataSource;
  Key _tableKey = UniqueKey();

  @override
  void didUpdateWidget(TripTableView old) {
    super.didUpdateWidget(old);
    if (old.filter != widget.filter ||
        old.timeMoment != widget.timeMoment ||
        old.repo != widget.repo) {
      _dataSource = null;
      _tableKey = UniqueKey();
    }
  }

  @override
  Widget build(BuildContext context) {
    const width = 1500.0;
    final visibleColumns = _getVisibleColumns(width);

    if (_dataSource == null) {
      _dataSource = _TripsDataSource(context, widget.repo, widget.trainlog, widget.filter);
      _dataSource!.setTimeMoment(widget.timeMoment);
      _dataSource!.sort(_sortColumnIndex, _sortAscending);
    }

    _dataSource!.setVisibleColumns(visibleColumns);

    return LayoutBuilder(
      builder: (context, constraints) {
        final btmPad = MediaQuery.of(context).padding.bottom;
        const double headingHeight = 56.0;
        const double rowHeight = 48.0;
        final double footerHeight = AppPlatform.isApple ? btmPad + 50 : 110.0;
        final rowsPerPage =
            ((constraints.maxHeight - headingHeight - footerHeight) ~/ rowHeight).clamp(5, 50);

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: DataTableTheme(
              data: DataTableTheme.of(context).copyWith(
                headingRowColor: WidgetStateProperty.resolveWith<Color?>(
                  (_) => Theme.of(context).colorScheme.primaryContainer,
                ),
                headingTextStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width,
                    maxWidth: MediaQuery.of(context).size.width,
                  ),
                  child: PaginatedDataTable(
                    showCheckboxColumn: false,
                    key: _tableKey,
                    columns: _buildDataColumns(visibleColumns, width),
                    source: _dataSource!,
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                    horizontalMargin: 5,
                    columnSpacing: 5,
                    showFirstLastButtons: true,
                    rowsPerPage: rowsPerPage,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<String> _getVisibleColumns(double width) {
    final columns = ['type', 'origin_destination', 'startTime', 'endTime'];
    if (width > 800) columns.add('operator');
    if (width > 1000) columns.add('lineName');
    if (width > 1200) columns.add('tripLength');
    if (width > 1100) columns.add('visibility');
    return columns;
  }

  List<DataColumn> _buildDataColumns(List<String> keys, double width) {
    return List.generate(keys.length, (index) {
      final label = _getLabel(keys[index]);
      return DataColumn(
        label: Text(label),
        columnWidth: (index == 0 && width < 750) ? const FixedColumnWidth(32) : null,
        onSort: (columnIndex, ascending) => setState(() {
          _sortColumnIndex = columnIndex;
          _sortAscending = ascending;
          _dataSource!.sort(columnIndex, ascending);
          _tableKey = UniqueKey();
        }),
      );
    });
  }

  String _getLabel(String key) {
    final loc = AppLocalizations.of(context)!;
    switch (key) {
      case 'type':
        return '';
      case 'origin_destination':
        return loc.tripsTableHeaderOriginDestination;
      case 'origin':
        return loc.tripsTableHeaderOrigin;
      case 'destination':
        return loc.tripsTableHeaderDestination;
      case 'startTime':
        return loc.tripsTableHeaderStartTime;
      case 'endTime':
        return loc.tripsTableHeaderEndTime;
      case 'operator':
        return loc.tripsTableHeaderOperator;
      case 'lineName':
        return loc.tripsTableHeaderLineName;
      case 'tripLength':
        return loc.tripsTableHeaderTripLength;
      case 'visibility':
        return loc.tripsTableHeaderVisibility;
      default:
        return key;
    }
  }
}

// ---------------------------------------------------------------------------

class _TripsDataSource extends DataTableSource {
  final BuildContext context;
  final TripsRepository _repository;
  final TrainlogProvider _trainlog;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  final List<Trips?> _cache = [];
  int _rowCount = 0;
  List<String> _visibleColumns = [];
  TimeMoment _timeMoment = TimeMoment.past;
  TripsFilterResult? _filter;

  _TripsDataSource(this.context, this._repository, this._trainlog, [this._filter]) {
    _fetchRowCount();
  }

  void setFilter(TripsFilterResult? filter) {
    _filter = filter;
    _cache.clear();
    _fetchRowCount();
  }

  void setTimeMoment(TimeMoment moment) {
    _timeMoment = moment;
    _cache.clear();
    _fetchRowCount();
  }

  void setVisibleColumns(List<String> columns) {
    if (listEquals(_visibleColumns, columns)) return;
    _visibleColumns = columns;
    notifyListeners();
  }

  Future<void> _fetchRowCount() async {
    _rowCount = await _repository.countFilteredTrips(
      showFutureTrips: _timeMoment == TimeMoment.future,
      filter: _filter,
    );
    _cache.clear();
    _cache.addAll(List.generate(_rowCount, (_) => null));
    notifyListeners();
  }

  Widget _timeDisplayHelper({
    required DateTime datetime,
    int? delay,
    String? delayFormatted,
    bool noTime = false,
    bool shrinkCondition = false,
  }) {
    if (shrinkCondition) return const SizedBox.shrink();

    final date = formatDateTime(context, datetime, hasTime: false);
    final time = formatDateTime(context, datetime, hasTime: true, timeOnly: true).trim();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(date),
        if (!noTime)
          Row(
            children: [
              Text(time),
              if (delay != null && delayFormatted != null)
                Text(
                  ' ($delayFormatted)',
                  style: TextStyle(
                    color: delay > 0 ? Colors.red : Colors.green,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  @override
  DataRow getRow(int index) {
    final bkgColor = WidgetStateProperty.resolveWith<Color?>(
      (states) => index.isEven ? Theme.of(context).colorScheme.surfaceContainerHighest : null,
    );
    final settings = context.read<SettingsProvider>();
    final palette = MapColorPaletteHelper.getPalette(settings.mapColorPalette);

    final emptyRow = DataRow(
      color: bkgColor,
      cells: List.generate(
        _visibleColumns.length,
        (_) => const DataCell(SizedBox.shrink()),
      ),
    );

    try {
      if (_cache[index] == null) {
        _fetchPage(index ~/ 50);
        return emptyRow;
      }
    } catch (_) {
      return emptyRow;
    }

    final trip = _cache[index]!;

    final cells = _visibleColumns.map((key) {
      switch (key) {
        case 'type':
          return DataCell(
            IconTheme(
              data: IconThemeData(color: palette[trip.type]),
              child: trip.type.icon(),
            ),
          );
        case 'origin_destination':
          return DataCell(
            Text('${trip.originStation}\n${trip.destinationStation}'),
          );
        case 'origin':
          return DataCell(Text(trip.originStation));
        case 'destination':
          return DataCell(Text(trip.destinationStation));
        case 'startTime':
          return DataCell(
            _timeDisplayHelper(
              datetime: trip.startDatetime,
              delay: trip.departureDelayInMinutes,
              delayFormatted: trip.departureDelayFormatted,
              noTime: trip.isDateOnly,
              shrinkCondition: trip.isUnknownPastFuture,
            ),
          );
        case 'endTime':
          return DataCell(
            _timeDisplayHelper(
              datetime: trip.endDatetime,
              delay: trip.arrivalDelayInMinutes,
              delayFormatted: trip.arrivalDelayFormatted,
              noTime: trip.isDateOnly,
              shrinkCondition: trip.isDateOnly,
            ),
          );
        case 'operator':
          if (trip.operatorName.isEmpty) return const DataCell(SizedBox.shrink());
          final operators = trip.operatorName
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
          return DataCell(
            Tooltip(
              message: operators.join(', '),
              child: _OperatorLogoWithCount(
                image: withOperatorLogoBg(
                  context,
                  _trainlog.getOperatorImage(
                    operators.join('&&'),
                    maxWidth: 45,
                    maxHeight: 45,
                  ),
                ),
                count: operators.length,
              ),
            ),
          );
        case 'lineName':
          return DataCell(Text(
            trip.lineName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ));
        case 'tripLength':
          return DataCell(Text(
            '${(trip.tripLength / 1000).round()} km',
            textAlign: TextAlign.end,
          ));
        case 'visibility':
          return DataCell(Icon(trip.visibility.icon()));
        default:
          return const DataCell(SizedBox.shrink());
      }
    }).toList();

    return DataRow(
      color: bkgColor,
      onSelectChanged: (_) => showAdaptiveTripBottomSheet(context, trip: trip),
      cells: cells,
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _rowCount;

  @override
  int get selectedRowCount => 0;

  TimeMoment get timeMoment => _timeMoment;

  void sort(int columnIndex, bool ascending) {
    _sortColumnIndex = columnIndex;
    _sortAscending = ascending;
    _cache.clear();
    _cache.addAll(List.generate(_rowCount, (_) => null));
    notifyListeners();
  }

  Future<void> _fetchPage(int pageKey) async {
    final key = _visibleColumns.length > _sortColumnIndex
        ? _visibleColumns[_sortColumnIndex]
        : 'startTime';
    final columnName = _mapKeyToColumnName(key);
    final orderBy = '$columnName ${_sortAscending ? 'ASC' : 'DESC'}';

    final page = await _repository.getTripsFiltered(
      showFutureTrips: _timeMoment == TimeMoment.future,
      filter: _filter,
      limit: 50,
      offset: pageKey * 50,
      orderBy: orderBy,
    );

    for (var i = 0; i < page.length; i++) {
      _cache[pageKey * 50 + i] = page[i];
    }

    notifyListeners();
  }

  String _mapKeyToColumnName(String key) {
    switch (key) {
      case 'type':
        return 'type';
      case 'origin':
        return 'origin_station';
      case 'destination':
        return 'destination_station';
      case 'startTime':
        return 'start_datetime';
      case 'endDatetime':
        return 'end_datetime';
      case 'operator':
        return 'operator';
      case 'lineName':
        return 'line_name';
      case 'tripLength':
        return 'trip_length';
      case 'visibility':
        return 'visibility';
      default:
        return 'start_datetime';
    }
  }
}

// ---------------------------------------------------------------------------

class _OperatorLogoWithCount extends StatelessWidget {
  const _OperatorLogoWithCount({required this.image, required this.count});

  final Widget image;
  final int count;

  static const double _size = 45;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Center(child: image),
          if (count > 1)
            Positioned(
              top: 2,
              right: 0,
              child: _Badge(text: count > 9 ? '9+' : '$count'),
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
