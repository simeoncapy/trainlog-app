import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/data/trips_repository.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:intl/intl.dart';

class TripsPage extends StatefulWidget {
  const TripsPage({super.key});

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  int _sortColumnIndex = 3; // Default sort by start time
  bool _sortAscending = false; // Default to descending
  TripsDataSource? _dataSource;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tripsProvider = Provider.of<TripsProvider>(context, listen: false);
      if (tripsProvider.repository == null) {
        tripsProvider.loadTrips().then((_) {
          if (mounted) {
            setState(() {
              _dataSource = TripsDataSource(
                context,
                tripsProvider.repository!,
              );
              _dataSource!.sort(_sortColumnIndex, _sortAscending);
            });
          }
        });
      } else {
        setState(() {
          _dataSource = TripsDataSource(
            context,
            tripsProvider.repository!,
          );
          _dataSource!.sort(_sortColumnIndex, _sortAscending);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tripsProvider = Provider.of<TripsProvider>(context);

    if (tripsProvider.isLoading || _dataSource == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(builder: (context, constraints) {
      return PaginatedDataTable(
        header: const Text('Trips'),
        columns: _getColumns(constraints.maxWidth),
        source: _dataSource!,
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _sortAscending,
        onSort: (columnIndex, ascending) {
          setState(() {
            _sortColumnIndex = columnIndex;
            _sortAscending = ascending;
            _dataSource!.sort(columnIndex, ascending);
          });
        },
      );
    });
  }

  List<DataColumn> _getColumns(double width) {
    final List<DataColumn> columns = [
      DataColumn(label: const Text('Type'), onSort: onSort),
      DataColumn(label: const Text('Origin'), onSort: onSort),
      DataColumn(label: const Text('Destination'), onSort: onSort),
      DataColumn(label: const Text('Start Time'), onSort: onSort),
    ];

    if (width > 800) {
      columns.add(DataColumn(label: const Text('Operator'), onSort: onSort));
    }
    if (width > 1000) {
      columns.add(DataColumn(label: const Text('Line Name'), onSort: onSort));
    }
    if (width > 1200) {
      columns.add(DataColumn(label: const Text('Trip Length'), onSort: onSort));
    }
    return columns;
  }

  void onSort(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _dataSource!.sort(columnIndex, ascending);
    });
  }
}

class TripsDataSource extends DataTableSource {
  final BuildContext context;
  final TripsRepository _repository;
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  final List<Trips?> _cache = [];
  int _rowCount = 0;

  TripsDataSource(this.context, this._repository) {
    _fetchRowCount();
  }

  Future<void> _fetchRowCount() async {
    _rowCount = await _repository.count();
    _cache.addAll(List.generate(_rowCount, (index) => null));
    notifyListeners();
  }

  @override
  DataRow getRow(int index) {
    if (_cache[index] == null) {
      _fetchPage(index ~/ 50);
      return DataRow(cells: List.generate(_getColumns(MediaQuery.of(context).size.width).length, (index) => const DataCell(SizedBox.shrink())));
    }

    final trip = _cache[index]!;

    final cells = [
      DataCell(Text(trip.type.toShortString())),
      DataCell(Text(trip.originStation)),
      DataCell(Text(trip.destinationStation)),
      DataCell(Text(DateFormat.yMd().add_Hms().format(trip.startDatetime))),
    ];

    final width = MediaQuery.of(context).size.width;
    if (width > 800) {
      cells.add(DataCell(Text(trip.operatorName)));
    }
    if (width > 1000) {
      cells.add(DataCell(Text(trip.lineName)));
    }
    if (width > 1200) {
      cells.add(DataCell(Text(trip.tripLength.toString())));
    }
    return DataRow(cells: cells);
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
    _cache.addAll(List.generate(_rowCount, (index) => null));
    notifyListeners();
  }

  String _getColumnName(int index) {
    final width = MediaQuery.of(context).size.width;
    final columns = _getColumns(width);
    final label = (columns[index].label as Text).data;
    switch (label) {
      case 'Type':
        return 'type';
      case 'Origin':
        return 'origin_station';
      case 'Destination':
        return 'destination_station';
      case 'Start Time':
        return 'start_datetime';
      case 'Operator':
        return 'operator';
      case 'Line Name':
        return 'line_name';
      case 'Trip Length':
        return 'trip_length';
      default:
        return 'start_datetime';
    }
  }

  Future<void> _fetchPage(int pageKey) async {
    final orderBy = '${_getColumnName(_sortColumnIndex)} ${_sortAscending ? "ASC" : "DESC"}';
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

  List<DataColumn> _getColumns(double width) {
    final List<DataColumn> columns = [
      const DataColumn(label: Text('Type')),
      const DataColumn(label: Text('Origin')),
      const DataColumn(label: Text('Destination')),
      const DataColumn(label: Text('Start Time')),
    ];

    if (width > 800) {
      columns.add(const DataColumn(label: Text('Operator')));
    }
    if (width > 1000) {
      columns.add(const DataColumn(label: Text('Line Name')));
    }
    if (width > 1200) {
      columns.add(const DataColumn(label: Text('Trip Length')));
    }
    return columns;
  }
}
