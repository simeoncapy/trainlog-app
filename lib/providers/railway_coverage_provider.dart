import 'dart:async';

import 'package:diacritic/diacritic.dart';
import 'package:flutter/widgets.dart';

import 'package:trainlog_app/data/models/country_detail.dart';
import 'package:trainlog_app/data/models/ranking_model.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/services/flag_cache.dart';

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

  /// Optional flag cache; when provided, every area's flag is preloaded in the
  /// background once the leaderboard data arrives.
  final FlagCache? _flagCache;

  RailwayCoverageProvider(this._trainlog, {FlagCache? flagCache})
      : _flagCache = flagCache;

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
      _preloadFlags(res);
    } catch (e) {
      if (_disposed) return;
      _error = e.toString();
      _result = null;
    }

    _loading = false;
    _safeNotify();
  }

  /// Warms the flag cache for every country and subdivision in [result] so the
  /// list rows render instantly from memory instead of fetching while scrolling.
  void _preloadFlags(RailPercentageResult result) {
    final cache = _flagCache;
    if (cache == null) return;
    final codes = <String>{
      for (final e in result.countries) e.countryCode,
      for (final e in result.subdivisions) e.code,
    };
    if (codes.isNotEmpty) unawaited(cache.preload(codes));
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
    return _ordered(result.subdivisionsOf(sel), (e) => e.subdivision.name);
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
    options.sort((a, b) => _collate(a.name).compareTo(_collate(b.name)));
    return options;
  }

  /// Normalises a name for alphabetical comparison: case- and diacritic-
  /// insensitive, so e.g. "Île de Man" and "États-Unis" sort under I and E
  /// rather than at the end of the list.
  static String _collate(String s) => removeDiacritics(s).toLowerCase();

  /// Applies the alphabetical / direction toggles to [list]. The natural order
  /// is "best first" (highest coverage, ties alphabetical) or A→Z when
  /// alphabetical; the direction toggle reverses it. Alphabetical comparisons
  /// ignore case and diacritics.
  List<RailPercentageEntry> _ordered(
    List<RailPercentageEntry> list,
    String Function(RailPercentageEntry entry) name,
  ) {
    final copy = List<RailPercentageEntry>.of(list);
    if (_alphabetical) {
      copy.sort((a, b) => _collate(name(a)).compareTo(_collate(name(b))));
    } else {
      copy.sort((a, b) {
        final cmp = b.highestPercent.compareTo(a.highestPercent);
        if (cmp != 0) return cmp;
        return _collate(name(a)).compareTo(_collate(name(b)));
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
