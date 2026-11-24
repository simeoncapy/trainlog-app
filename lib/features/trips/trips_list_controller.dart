import 'package:flutter/foundation.dart';
import 'package:trainlog_app/core/data/models/time_moment.dart';
import 'package:trainlog_app/core/data/models/trips.dart';
import 'package:trainlog_app/core/data/models/trips_filter.dart';
import 'package:trainlog_app/core/data/trips_repository.dart';

/// One month of trips in the list, newest first for past trips and
/// soonest first for future ones.
class TripsMonth {
  TripsMonth(this.year, this.month);

  /// 0 or 9999 for trips with an unknown date.
  final int year;
  final int month;
  final List<Trips> trips = [];

  bool get isUnknownDate => year == 0 || year == 9999;

  /// The month's first day, for formatting its name.
  DateTime get date => DateTime(isUnknownDate ? 2000 : year, month);
}

/// The trips list (iOS): loads the trips matching a filter and Past / Future
/// page by page, and groups the loaded ones by month.
class TripsListController extends ChangeNotifier {
  TripsListController({
    required TripsRepository repo,
    required this.filter,
    required this.timeMoment,
    this.pageSize = 20,
  }) : _repo = repo;

  final TripsRepository _repo;
  final TripsFilterResult? filter;
  final TimeMoment timeMoment;
  final int pageSize;

  final List<Trips> _trips = [];
  int _total = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _disposed = false;

  /// The first page is loading (nothing to show yet).
  bool get isLoading => _loading;

  /// A further page is loading, at the end of the list.
  bool get isLoadingMore => _loadingMore;

  /// Number of trips matching the filter, loaded or not.
  int get total => _total;

  /// Some trips are not loaded yet.
  bool get hasMore => _trips.length < _total;

  bool get isEmpty => !_loading && _total == 0;

  /// The loaded trips, grouped by month in list order.
  List<TripsMonth> get months {
    final result = <TripsMonth>[];
    for (final trip in _trips) {
      final d = trip.startDatetime;
      final last = result.isEmpty ? null : result.last;
      if (last == null || last.year != d.year || last.month != d.month) {
        result.add(TripsMonth(d.year, d.month)..trips.add(trip));
      } else {
        last.trips.add(trip);
      }
    }
    return result;
  }

  bool get _future => timeMoment == TimeMoment.future;

  /// Loads the first page. With [showLoader] the list empties first; without
  /// it the trips on screen stay until the fresh ones land (a data refresh).
  Future<void> load({bool showLoader = true}) async {
    if (showLoader) {
      _loading = true;
      _trips.clear();
      _total = 0;
      _notify();
    }
    final total = await _repo.countFilteredTrips(
      showFutureTrips: _future,
      filter: filter,
    );
    // A refresh re-reads as many trips as are shown, so the list keeps its
    // length (and the scroll position) instead of shrinking to one page.
    final count = _trips.length > pageSize ? _trips.length : pageSize;
    final first = total == 0 ? const <Trips>[] : await _page(0, count);
    if (_disposed) return;
    _total = total;
    _trips
      ..clear()
      ..addAll(first);
    _loading = false;
    _notify();
  }

  /// Loads the next page, if any and none is loading.
  Future<void> loadMore() async {
    if (_loading || _loadingMore || !hasMore) return;
    _loadingMore = true;
    _notify();
    final next = await _page(_trips.length, pageSize);
    if (_disposed) return;
    _trips.addAll(next);
    _loadingMore = false;
    // The count changed under us (e.g. a sync): stop where the data stops.
    if (next.isEmpty) _total = _trips.length;
    _notify();
  }

  Future<List<Trips>> _page(int offset, int limit) => _repo.getTripsFiltered(
    showFutureTrips: _future,
    filter: filter,
    limit: limit,
    offset: offset,
    // Order by UTC time so trips crossing time zones (e.g. the IDL) are
    // sorted chronologically; display still uses local time.
    orderBy: _future
        ? 'COALESCE(utc_start_datetime, start_datetime) ASC'
        : 'COALESCE(utc_start_datetime, start_datetime) DESC',
  );

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
