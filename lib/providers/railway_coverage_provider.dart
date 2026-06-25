import 'package:flutter/widgets.dart';

import 'package:trainlog_app/data/models/country_detail.dart';
import 'package:trainlog_app/data/models/ranking_model.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';

/// The two sub-views of the Railway Coverage feature.
enum RailCoverageTab { countries, regions }

/// A country offered in the Regions-tab dropdown: its [code], localized [name]
/// and the number of subdivisions ([count]) the leaderboard has data for.
class RailCountryOption {
  final String code;
  final String name;
  final int count;

  const RailCountryOption({
    required this.code,
    required this.name,
    required this.count,
  });
}

/// The current user's overall standing on the railway-coverage leaderboard:
/// their [rank] among all leaders, the total number of [contenders] (distinct
/// leaders) and how many areas they [ledCount].
typedef RailUserStanding = ({int rank, int contenders, int ledCount});

/// Drives the Railway Coverage feature: which sub-view is shown
/// (Countries / Regions), how the list is ordered, the selected country for the
/// Regions view, and the loaded [RailPercentageResult].
///
/// Data is fetched once through [TrainlogProvider.fetchRankingForRailPercentage]
/// (the `train_countries` leaderboard). The competitive ordering — highest
/// coverage first, ties broken alphabetically — is the default; the
/// alphabetical and direction toggles are display-only.
class RailwayCoverageProvider extends ChangeNotifier {
  final TrainlogProvider _trainlog;

  RailwayCoverageProvider(this._trainlog);

  // ── UI state ───────────────────────────────────────────────────────────────

  RailCoverageTab _tab = RailCoverageTab.countries;
  bool _alphabetical = false;
  bool _descending = true;
  String? _selectedCountry;

  RailCoverageTab get tab => _tab;
  bool get alphabetical => _alphabetical;
  bool get descending => _descending;
  String? get selectedCountry => _selectedCountry;

  /// Whether the sorting controls should be enabled. They are disabled on the
  /// Regions tab until a country is picked (nothing to sort yet).
  bool get sortingEnabled =>
      _tab == RailCoverageTab.countries || _selectedCountry != null;

  String? get currentUsername => _trainlog.username;

  // ── Data state ─────────────────────────────────────────────────────────────

  bool _loading = false;
  String? _error;
  RailPercentageResult? _result;

  bool get isLoading => _loading;
  String? get error => _error;
  bool get hasData => _result != null && _result!.isNotEmpty;

  // ── Mutations ──────────────────────────────────────────────────────────────

  void setTab(RailCoverageTab tab) {
    if (tab == _tab) return;
    _tab = tab;
    notifyListeners();
  }

  void toggleAlphabetical() {
    _alphabetical = !_alphabetical;
    notifyListeners();
  }

  void toggleDirection() {
    _descending = !_descending;
    notifyListeners();
  }

  void selectCountry(String? code) {
    if (code == _selectedCountry) return;
    _selectedCountry = code;
    notifyListeners();
  }

  // ── Loading ────────────────────────────────────────────────────────────────

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    _result = null;
    _safeNotify();

    try {
      final res = await _trainlog.fetchRankingForRailPercentage();
      if (_disposed) return;
      _result = res;
    } catch (e) {
      if (_disposed) return;
      _error = e.toString();
      _result = null;
    }

    _loading = false;
    _safeNotify();
  }

  // ── Derived lists ────────────────────────────────────────────────────────────

  /// The country-level entries in display order.
  List<RailPercentageEntry> countries(BuildContext context) =>
      _ordered(_result?.countries ?? const [], (e) => e.country(context).name);

  /// The subdivisions of [selectedCountry] in display order (empty when no
  /// country is selected).
  List<RailPercentageEntry> regions() {
    final sel = _selectedCountry;
    final result = _result;
    if (sel == null || result == null) return const [];
    return _ordered(result.subdivisionsOf(sel), (e) => e.code);
  }

  /// Countries that have subdivision data, for the Regions-tab dropdown, sorted
  /// alphabetically by localized name.
  List<RailCountryOption> regionCountryOptions(BuildContext context) {
    final result = _result;
    if (result == null) return const [];

    final counts = <String, int>{};
    for (final s in result.subdivisions) {
      counts.update(s.countryCode, (v) => v + 1, ifAbsent: () => 1);
    }

    final options = counts.entries.map((e) {
      final detail = CountryDetail.fromCode(e.key, context);
      return RailCountryOption(code: e.key, name: detail.name, count: e.value);
    }).toList();
    options.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return options;
  }

  /// Applies the alphabetical / direction toggles to [list]. The natural order
  /// is "best first" (highest coverage, ties alphabetical) or A→Z when
  /// alphabetical; the direction toggle reverses it.
  List<RailPercentageEntry> _ordered(
    List<RailPercentageEntry> list,
    String Function(RailPercentageEntry entry) name,
  ) {
    final copy = List<RailPercentageEntry>.of(list);
    if (_alphabetical) {
      copy.sort((a, b) => name(a).toLowerCase().compareTo(name(b).toLowerCase()));
    } else {
      copy.sort((a, b) {
        final cmp = b.highestPercent.compareTo(a.highestPercent);
        if (cmp != 0) return cmp;
        return name(a).toLowerCase().compareTo(name(b).toLowerCase());
      });
    }
    return _descending ? copy : copy.reversed.toList();
  }

  // ── Current-user standing ────────────────────────────────────────────────────

  /// The country-level areas where the current user is a leader (reached the
  /// top coverage tier), highest coverage first.
  List<RailPercentageEntry> userLedCountries() {
    final me = currentUsername?.toLowerCase();
    final result = _result;
    if (me == null || result == null) return const [];
    final led = result.countries
        .where((e) => e.leaders.any((u) => u.username.toLowerCase() == me))
        .toList();
    led.sort((a, b) => b.highestPercent.compareTo(a.highestPercent));
    return led;
  }

  /// The current user's overall standing — their rank among all leaders by the
  /// number of areas led. `null` when the user leads nothing (or is logged out).
  RailUserStanding? userStanding() {
    final me = currentUsername?.toLowerCase();
    final result = _result;
    if (me == null || result == null) return null;

    final counts = <String, int>{};
    for (final e in result.countries) {
      for (final u in e.leaders) {
        counts.update(u.username.toLowerCase(), (v) => v + 1, ifAbsent: () => 1);
      }
    }

    final myCount = counts[me] ?? 0;
    if (myCount == 0) return null;

    var rank = 1;
    for (final v in counts.values) {
      if (v > myCount) rank++;
    }
    return (rank: rank, contenders: counts.length, ledCount: myCount);
  }
}
