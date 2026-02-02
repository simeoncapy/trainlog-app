import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainlog_app/data/models/trip_form_model.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/data/trips_repository.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/pages/add_trip_page.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/providers/settings_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/utils/date_utils.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';
import 'package:trainlog_app/widgets/past_future_selector.dart';
import 'package:trainlog_app/widgets/trip_details_bottom_sheet.dart';
import 'package:trainlog_app/widgets/trips_filter_dialog.dart';

class TripsPage extends StatefulWidget {
  final void Function(FloatingActionButton? fab) onFabReady;
  const TripsPage({super.key, required this.onFabReady});  

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  int _seenRevision = -1;
  int _sortColumnIndex = 2;
  bool _sortAscending = false;
  TripsDataSource? _dataSource;
  Key _tableKey = UniqueKey();
  late TrainlogProvider trainlog;
  TripsFilterResult? _activeFilter;
  final _refreshKey = GlobalKey<RefreshIndicatorState>(); // DELETE ON MOBILE
  bool _refreshTriggered = false; // DELETE ON MOBILE

  @override
  void initState() {
    super.initState();
    trainlog = Provider.of<TrainlogProvider>(context, listen: false);
  }

  @override // temp for test // DELETE ON MOBILE
  void didChangeDependencies() {
    super.didChangeDependencies();

    // This depends on Theme, so it belongs here
    if (!_refreshTriggered && Theme.of(context).platform == TargetPlatform.windows) {
      _refreshTriggered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        //_refreshKey.currentState?.show(); // 👈 triggers the refresh
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripsProvider = Provider.of<TripsProvider>(context);
    final scaffMsg = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context)!;
    final revision = context.select((TripsProvider p) => p.revision);
    final repo = context.select((TripsProvider p) => p.repository);
    final isLoading = context.select((TripsProvider p) => p.isLoading);

    if (repo == null || isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // revision changed => provider has new data/repo => rebuild table source
    if (_seenRevision != revision) {
      _seenRevision = revision;
      _dataSource = null;
      _tableKey = ValueKey(revision); // forces PaginatedDataTable internal reset too
    }

    if (_dataSource == null) {
      // Create it synchronously; pass the (currently empty) map
      _dataSource = TripsDataSource(context, repo, trainlog);
      _dataSource!.sort(_sortColumnIndex, _sortAscending);

      // If you need to (re)expose the FAB after first layout:
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onFabReady(buildFloatingActionButton(context)!);
      });
    }

    //final width = MediaQuery.of(context).size.width;
    // Using SingleChildScrollView then we don't need to adapt the column to the size
    // To not delete the code, and keep it in case later use, we just force the width parameter
    final width = 1500.0;     

    final visibleColumns = _getVisibleColumns(width);
    _dataSource!.setVisibleColumns(visibleColumns);

    return RefreshIndicator(
      key: _refreshKey,
      onRefresh: () async {
        //final settings = context.read<SettingsProvider>();        
        // Force reloading data from repository
        //settings.setShouldReloadPolylines(true);
        await tripsProvider.loadTrips(locale: Localizations.localeOf(context), loadFromApi: true);
        
        if (!mounted) return;
        setState(() {
          _dataSource = null; // rebuild data source
          _tableKey = UniqueKey();
        });

        if (mounted) {
          scaffMsg.showSnackBar(
            SnackBar(content: Text('✅ ${loc.refreshCompleted}')),
          );
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final visibleColumns = _getVisibleColumns(width);
          _dataSource!.setVisibleColumns(visibleColumns);
      
          final double availableHeight = constraints.maxHeight;
          const double headingHeight = 56.0;
          const double rowHeight = 48.0;
          const double footerHeight = 180.0;
      
          // Estimate how many rows fit in the remaining height
          final rowsPerPage = ((availableHeight - headingHeight - footerHeight) ~/ rowHeight).clamp(5, 50);
      
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: DataTableTheme(
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
                      header: _tableGeneralHeaderBuilder(tripsProvider),
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
      ),
    );
  }

  Widget _tableGeneralHeaderBuilder(TripsProvider tripsProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        PastFutureSelector(
          initialValue: _dataSource!.timeMoment,
          onChanged: (newMoment) {
            setState(() {
              _dataSource!.setTimeMoment(newMoment);
              _tableKey = UniqueKey();
            });
          },
        ),
        const SizedBox(width: 8),
        if (_activeFilter != null)
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 1,
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () {
                setState(() {
                  _activeFilter = null;
                  _dataSource!.setFilter(null);
                  _tableKey = UniqueKey();
                });
              },
              icon: const Icon(Icons.search_off),
              tooltip: AppLocalizations.of(context)!.filterClearButton,
            ),
          ),
        const SizedBox(width: 8),
        Material(
          elevation: 4,
          shape: const CircleBorder(),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: IconButton(
            onPressed: () async {
              final operators = tripsProvider.operators;
              final countries = tripsProvider.mapCountryCodes;
              final types = tripsProvider.vehicleTypes;

              final result = await showDialog<TripsFilterResult>(
                context: context,
                builder: (context) => TripsFilterDialog(
                  operatorOptions: operators,
                  countryOptions: countries,
                  typeOptions: types,
                  initialFilter: _activeFilter,
                ),
              );

              if (result != null) {
                setState(() {
                  _activeFilter = result;
                  _dataSource!.setFilter(result);
                  _tableKey = UniqueKey();
                });
              }
            },
            icon: const Icon(Icons.filter_alt),
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            tooltip: AppLocalizations.of(context)!.filterButton,
          ),
        ),
      ],
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
    final appLocalizations = AppLocalizations.of(context)!;
    switch (key) {
      case 'type':
        return '';
      case 'origin_destination':
        return appLocalizations.tripsTableHeaderOriginDestination;
      case 'origin':
        return appLocalizations.tripsTableHeaderOrigin;
      case 'destination':
        return appLocalizations.tripsTableHeaderDestination;
      case 'startTime':
        return appLocalizations.tripsTableHeaderStartTime;
      case 'endTime':
        return appLocalizations.tripsTableHeaderEndTime;
      case 'operator':
        return appLocalizations.tripsTableHeaderOperator;
      case 'lineName':
        return appLocalizations.tripsTableHeaderLineName;
      case 'tripLength':
        return appLocalizations.tripsTableHeaderTripLength;
      default:
        return key;
    }
  }

  FloatingActionButton? buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () async {
        final didSave = await Navigator.of(context).push<bool>(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => ChangeNotifierProvider(
              create: (_) => TripFormModel(),
              child: const AddTripPage(),
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );

        if (!context.mounted) return;

        if (didSave == true) {
          // refresh trips after returning
          final tripsProvider = context.read<TripsProvider>();
          await tripsProvider.loadTrips(
            locale: Localizations.localeOf(context),
            loadFromApi: true, // or false if you want DB-only refresh
          );

          // force rebuild datasource
          setState(() {
            _dataSource = null;
            _tableKey = UniqueKey();
          });

          // (optional) re-emit the FAB
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onFabReady(buildFloatingActionButton(context));
          });
        }
      },
      child: const Icon(Icons.add),
    );
  }
}

// *************************************************
// *************************************************
// *************************************************

class TripsDataSource extends DataTableSource {
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

  TripsDataSource(this.context, this._repository, this._trainlog, [this._filter]) {
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
      showFutureTrips: _timeMoment == TimeMoment.future, filter: _filter,
    );
    _cache.clear();
    _cache.addAll(List.generate(_rowCount, (_) => null));
    notifyListeners();
  }

  @override
  DataRow getRow(int index) {
    final bkgColor = WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) => index.isEven ? Theme.of(context).colorScheme.surfaceContainerHighest : null,
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

    try{
        if (_cache[index] == null) {
        _fetchPage(index ~/ 50);
        return emptyRow;
      }
    }
    catch (_)
    {
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
            Text("${trip.originStation}\n${trip.destinationStation}"),
            // onTap: () {
            //   showModalBottomSheet(
            //     context: context,
            //     builder: (ctx) => TripDetailsBottomSheet(trip: trip),
            //     isScrollControlled: true,
            //   );
            // },
          );
        case 'origin':
          return DataCell(Text(trip.originStation));
        case 'destination':
          return DataCell(Text(trip.destinationStation));
        case 'startTime':
          return DataCell(
            Text(trip.isUnknownPastFuture
              ? ""
              : formatDateTime(context, trip.startDatetime, hasTime: !trip.isDateOnly).replaceAll(RegExp(r" "), "\n"))
            );
        case 'endTime':
          return DataCell(
            Text(trip.isDateOnly 
              ? "" 
              : formatDateTime(context, trip.endDatetime).replaceAll(RegExp(r" "), "\n")
            )
          );
        case 'operator':
          final raw = Uri.decodeComponent(trip.operatorName);
          final operators = raw.split('&&').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
          final count = operators.length;

          return DataCell(
            Tooltip(
              message: operators.join(', '),
              child: _OperatorLogoWithCount(
                image: _trainlog.getOperatorImage(
                  raw,
                  maxWidth: 45,
                  maxHeight: 45,
                ),
                count: count,
              ),
            ),
          );
          //return DataCell(_operatorLogos[Uri.decodeComponent(trip.operatorName)] ?? Text(Uri.decodeComponent(trip.operatorName))); // _operatorLogos
          //return DataCell(Text(Uri.decodeComponent(trip.operatorName))); // _operatorLogos
        case 'lineName':
          return DataCell(Text(Uri.decodeComponent(trip.lineName)));
        case 'tripLength':
          return DataCell(Text("${(trip.tripLength/1000).round()} km", textAlign: TextAlign.end,));
        default:
          return const DataCell(SizedBox.shrink());
      }
    }).toList();

  //   return DataCell(  // To align the distance on the right, replace the current DataCell by this code
  //   Align(
  //     alignment: Alignment.centerRight,
  //     child: Text(
  //       "${(trip.tripLength / 1000).round()} km",
  //       textAlign: TextAlign.right,
  //     ),
  //   ),
  // );

    return DataRow(
      color: bkgColor, 
      onSelectChanged: (_) {
        showModalBottomSheet(
          useSafeArea: true,
          context: context,
          builder: (ctx) {
            final mq = MediaQuery.of(ctx);
            final bottom = math.max(mq.viewPadding.bottom, mq.viewInsets.bottom);

            return Padding(
              padding: EdgeInsets.only(bottom: bottom),
              child: TripDetailsBottomSheet(trip: trip),
            );
          },
          //builder: (ctx) => TripDetailsBottomSheet(trip: trip),
          isScrollControlled: true,
        );
      },
      cells: cells,
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _rowCount;

  @override
  int get selectedRowCount => 0;
  
  get timeMoment => _timeMoment;

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
      default:
        return 'start_datetime';
    }
  }
}

class _OperatorLogoWithCount extends StatelessWidget {
  const _OperatorLogoWithCount({
    required this.image,
    required this.count,
  });

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
              child: _Badge(
                text: count > 9 ? '9+' : '$count',
              ),
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
        //border: Border.all(color: Colors.white, width: 1.5),
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


