import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/data/trips_repository.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:intl/intl.dart';
import 'package:trainlog_app/utils/date_utils.dart';

class TripsPage extends StatefulWidget {
  final void Function(FloatingActionButton? fab) onFabReady;
  const TripsPage({super.key, required this.onFabReady});  

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  int _sortColumnIndex = 2;
  bool _sortAscending = false;
  TripsDataSource? _dataSource;
  late List<String> _columnKeys;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final tripsProvider = Provider.of<TripsProvider>(context, listen: false);
      if (tripsProvider.repository == null) {
        await tripsProvider.loadTrips();
      }

      if (!mounted) return;
      setState(() {
        _dataSource = TripsDataSource(context, tripsProvider.repository!);
        _dataSource!.sort(_sortColumnIndex, _sortAscending);
        widget.onFabReady(buildFloatingActionButton(context)!);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final tripsProvider = Provider.of<TripsProvider>(context);
    final width = MediaQuery.of(context).size.width;

    if (tripsProvider.isLoading || _dataSource == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final visibleColumns = _getVisibleColumns(width);
    _dataSource!.setVisibleColumns(visibleColumns);

    return LayoutBuilder(
      builder: (context, constraints) {
        final visibleColumns = _getVisibleColumns(width);
        _dataSource!.setVisibleColumns(visibleColumns);

        final double availableHeight = constraints.maxHeight;
        const double headingHeight = 56.0;
        const double rowHeight = 48.0;
        const double footerHeight = 180.0;

        // Estimate how many rows fit in the remaining height
        final rowsPerPage = ((availableHeight - headingHeight - footerHeight) ~/ rowHeight).clamp(5, 50);

        return DataTableTheme(
          data: DataTableTheme.of(context).copyWith(
            headingRowColor: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) =>
                  Theme.of(context).colorScheme.primaryContainer,
            ),
            headingTextStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
          ),
          child: PaginatedDataTable(
            header: const Text('Trips'),
            columns: _buildDataColumns(visibleColumns, width),
            source: _dataSource!,
            sortColumnIndex: _sortColumnIndex,
            sortAscending: _sortAscending,
            horizontalMargin: 5,
            columnSpacing: 5,
            showFirstLastButtons: true,
            rowsPerPage: rowsPerPage,
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
    return columns;
  }

  List<DataColumn> _buildDataColumns(List<String> keys, double width) {
    return List.generate(keys.length, (index) {
      final label = _getLabel(keys[index]);
      return DataColumn(
        label: Text(label),
        columnWidth: (index == 0 && width < 750) ? FixedColumnWidth(32) : null,
        onSort: (columnIndex, ascending) => setState(() {
          _sortColumnIndex = columnIndex;
          _sortAscending = ascending;
          _dataSource!.sort(columnIndex, ascending);
        }),
      );
    });
  }

  String _getLabel(String key) {
    switch (key) {
      case 'type':
        return 'Type';
      case 'origin_destination':
        return 'Origin/Destination';
      case 'origin':
        return 'Origin';
      case 'destination':
        return 'Destination';
      case 'startTime':
        return 'Start Time';
      case 'endTime':
        return 'End Time';
      case 'operator':
        return 'Operator';
      case 'lineName':
        return 'Line Name';
      case 'tripLength':
        return 'Trip Length';
      default:
        return key;
    }
  }

  FloatingActionButton? buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        setState(() {
        });
      },
      child: Icon(Icons.add),
    );
  }
}


class TripsDataSource extends DataTableSource {
  final BuildContext context;
  final TripsRepository _repository;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  final List<Trips?> _cache = [];
  int _rowCount = 0;
  List<String> _visibleColumns = [];

  TripsDataSource(this.context, this._repository) {
    _fetchRowCount();
  }

  void setVisibleColumns(List<String> columns) {
    _visibleColumns = columns;
    notifyListeners();
  }

  Future<void> _fetchRowCount() async {
    _rowCount = await _repository.count();
    _cache.addAll(List.generate(_rowCount, (_) => null));
    notifyListeners();
  }

  @override
  DataRow getRow(int index) {
    final bkgColor = WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) => index.isEven ? Theme.of(context).colorScheme.surfaceContainerHighest : null,
        );

    if (_cache[index] == null) {
      _fetchPage(index ~/ 50);
      return DataRow(
        color: bkgColor,
        cells: List.generate(
          _visibleColumns.length,
          (_) => const DataCell(SizedBox.shrink()),
        ),
      );
    }

    final trip = _cache[index]!;
    final cells = _visibleColumns.map((key) {
      switch (key) {
        case 'type':
          return DataCell(trip.type.icon());
        case 'origin_destination':
          return DataCell(Text("${trip.originStation}\n${trip.destinationStation}"));
        case 'origin':
          return DataCell(Text(trip.originStation));
        case 'destination':
          return DataCell(Text(trip.destinationStation));
        case 'startTime':
          return DataCell(Text(formatDateTime(context, trip.startDatetime).replaceAll(RegExp(r" "), "\n")));
        case 'endTime':
          return DataCell(Text(formatDateTime(context, trip.endDatetime).replaceAll(RegExp(r" "), "\n")));
        case 'operator':
          return DataCell(Text(trip.operatorName));
        case 'lineName':
          return DataCell(Text(trip.lineName));
        case 'tripLength':
          return DataCell(Text("${(trip.tripLength/1000).round()} km", textAlign: TextAlign.end,));
        default:
          return const DataCell(SizedBox.shrink());
      }
    }).toList();

  //   return DataCell(  // To align the distance on the right
  //   Align(
  //     alignment: Alignment.centerRight,
  //     child: Text(
  //       "${(trip.tripLength / 1000).round()} km",
  //       textAlign: TextAlign.right,
  //     ),
  //   ),
  // );

    return DataRow(color: bkgColor, cells: cells);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _rowCount;

  @override
  int get selectedRowCount => 0;

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

    final page = await _repository.getAllTrips(
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
      default:
        return 'start_datetime';
    }
  }
}

