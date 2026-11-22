import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trainlog_app/core/data/models/time_moment.dart';
import 'package:trainlog_app/core/data/models/trips_filter.dart';
import 'package:trainlog_app/core/data/trips_repository.dart';

/// State and actions of the trips page, shared by its Material and iOS
/// views: card or table view (remembered), Past / Future, the active search
/// filter and the number of trips it matches.
class TripsPageController extends ChangeNotifier {
  /// Preference key of the view mode: 'card' or 'table'.
  static const viewPrefKey = 'trips_view_mode';

  TripsRepository? _repo;
  TripsFilterResult? _activeFilter;
  TimeMoment _timeMoment = TimeMoment.past;
  bool _isCardView = true;
  bool _prefsLoaded = false;
  int _summaryCount = 0;
  bool _disposed = false;

  TripsFilterResult? get activeFilter => _activeFilter;
  TimeMoment get timeMoment => _timeMoment;
  bool get isCardView => _isCardView;

  /// The view mode is known (read from the preferences).
  bool get prefsLoaded => _prefsLoaded;

  /// Number of trips matching the filter and Past / Future.
  int get summaryCount => _summaryCount;

  bool get showsFutureTrips => _timeMoment == TimeMoment.future;

  /// The repository the counts are read from; set by the page when the
  /// trips provider has one.
  set repository(TripsRepository? repo) => _repo = repo;

  Future<void> loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(viewPrefKey);
    if (_disposed) return;
    _isCardView = saved != 'table';
    _prefsLoaded = true;
    notifyListeners();
  }

  Future<void> setCardView(bool isCard) async {
    _isCardView = isCard;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(viewPrefKey, isCard ? 'card' : 'table');
  }

  void toggleView() => setCardView(!_isCardView);

  void setTimeMoment(TimeMoment moment) {
    if (moment == _timeMoment) return;
    _timeMoment = moment;
    notifyListeners();
    refreshSummaryCount();
  }

  /// Applies what the filter sheet returned; an all-defaults filter is no
  /// filter.
  void applyFilter(TripsFilterResult result) {
    _activeFilter = result.isEmpty ? null : result;
    notifyListeners();
    refreshSummaryCount();
  }

  void clearFilter() {
    _activeFilter = null;
    notifyListeners();
    refreshSummaryCount();
  }

  /// A trip was added: the views rebuild their lists.
  void tripsChanged() => notifyListeners();

  Future<void> refreshSummaryCount() async {
    final repo = _repo;
    if (repo == null) return;
    final count = await repo.countFilteredTrips(
      showFutureTrips: showsFutureTrips,
      filter: _activeFilter,
    );
    if (_disposed) return;
    _summaryCount = count;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
