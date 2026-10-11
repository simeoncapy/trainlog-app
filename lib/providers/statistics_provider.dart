import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:diacritic/diacritic.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/utils/number_formatter.dart';
import 'package:trainlog_app/utils/style_utils.dart';
import 'package:trainlog_app/utils/text_utils.dart'; // for countryCodeToName(...)
import 'package:trainlog_app/app/theme/app_theme.dart';
import 'package:duration/duration.dart';
import 'package:duration/locale.dart';

/// Number of leading items shown with a numbered indicator (1..10) instead of
/// a short text label.
const _numberedRankCount = 10;

/// Past and planned-future value of one stat entry.
typedef StatValue = ({double past, double future});

/// Graph categories aligned with the UI page.
enum GraphType {
  operator,
  country,
  years,
  material,
  itinerary, // API key is "routes"
  stations;

  /// [vehicleType] is `null` when all modes are merged.
  String label(BuildContext context, VehicleType? vehicleType) {
    final loc = AppLocalizations.of(context)!;
    switch (this) {
      case GraphType.operator:  return loc.operator;
      case GraphType.country:   return loc.graphTypeCountry;
      case GraphType.years:     return loc.graphTypeYears;
      case GraphType.material:  return loc.material;
      case GraphType.itinerary: return loc.graphTypeItinerary;
      case GraphType.stations:  return loc.typeStations(vehicleType?.name.toLowerCase() ?? 'other');
    }
  }

  Icon icon() {
    switch (this) {
      case GraphType.operator:  return const Icon(Icons.business);
      case GraphType.country:   return const Icon(Icons.flag);
      case GraphType.years:     return const Icon(Icons.calendar_today);
      case GraphType.material:  return const Icon(Symbols.car_tag, fill: 1);
      case GraphType.itinerary: return const Icon(Icons.route);
      case GraphType.stations:  return const Icon(Icons.villa);
    }
  }
}

enum GraphUnit { 
  trip, 
  distance, 
  duration, 
  co2; 

  /// Suffix chunk used by the API field names (pastKm, plannedFutureTrips, …)
  String apiFieldChunk() {
    switch (this) {
      case GraphUnit.trip:     return "Trips";
      case GraphUnit.distance: return "Km";
      case GraphUnit.duration: return "Duration";
      case GraphUnit.co2:      return "CO2";
    }
  }

  /// Localized label for UI pickers
  String label(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    switch (this) {
      case GraphUnit.trip:     return loc.statisticsGraphUnitTrips;
      case GraphUnit.distance: return loc.statisticsGraphUnitDistance;
      case GraphUnit.duration: return loc.duration;
      case GraphUnit.co2:      return loc.statisticsGraphUnitCo2;
    }
  }

  Icon icon() {
    switch (this) {
      case GraphUnit.trip:     return const Icon(Icons.confirmation_num);
      case GraphUnit.distance: return const Icon(Icons.straighten);
      case GraphUnit.duration: return const Icon(Symbols.timer, fill: 1);
      case GraphUnit.co2:      return const Icon(Icons.co2);
    }
  }  
}

class StatisticsProvider extends ChangeNotifier {
  StatisticsProvider(this._trainlog, {List<VehicleType> allVehicles = const []})
      : _allVehicles = _fetchableVehicles(allVehicles);

  /// Vehicle selected when the page opens. `null` merges all modes.
  /// Set to e.g. `VehicleType.train` if fetching every mode is too slow.
  static const VehicleType? defaultVehicle = null;

  bool _disposed = false;
  int _loadToken = 0;

  // -------------------------------------------------------------------
  // Dependencies
  // -------------------------------------------------------------------
  final TrainlogProvider _trainlog;

  // -------------------------------------------------------------------
  // State
  // -------------------------------------------------------------------
  VehicleType? _vehicle = defaultVehicle; // null = all modes
  /// Modes merged when [vehicle] is null, in selection-list order.
  List<VehicleType> _allVehicles;
  /// Modes whose fetch failed during the last load (shown as a warning).
  List<VehicleType> _failedVehicles = const [];
  GraphType _graph = GraphType.operator;
  GraphUnit _unit = GraphUnit.trip;
  int? _year; // null = all years

  bool _isLoading = false;
  String? _error;

  /// Cache: key -> raw API map
  /// key format: "<vehicle>|<year or all>"
  final Map<String, Map<String, dynamic>> _cache = {};

  // For duration base unit (readable): we convert seconds to one of these
  _DurationBase _durationBase = _DurationBase.hours;

  static const int shortLabelSize = 15; //characters

  // -------------------------------------------------------------------
  // Public getters
  // -------------------------------------------------------------------
  bool get isLoading => _isLoading;
  String? get error => _error;

  VehicleType? get vehicle => _vehicle;
  bool get isAllVehicles => _vehicle == null;
  List<VehicleType> get failedVehicles => _failedVehicles;
  GraphType get graph => _graph;
  GraphUnit get unit => _unit;
  int? get year => _year;

  set vehicle(VehicleType? v) {
    if (_vehicle == v) return;
    _vehicle = v;
    load(); // refetch for new vehicle
  }

  /// Update the modes merged in "all" mode (the user's vehicle types, which
  /// may arrive after the first load). Safe to call during build.
  void updateAllVehicles(List<VehicleType> vehicles) {
    final next = _fetchableVehicles(vehicles);
    if (listEquals(next, _allVehicles)) return;
    _allVehicles = next;
    if (_vehicle == null) scheduleMicrotask(load);
  }

  static List<VehicleType> _fetchableVehicles(List<VehicleType> vehicles) => vehicles
      .where((v) => v != VehicleType.poi && v != VehicleType.unknown)
      .toList(growable: false);

  /// Modes making up the current selection, in selection-list order.
  List<VehicleType> get _selectedVehicles =>
      _vehicle == null ? _allVehicles : [_vehicle!];

  set graph(GraphType g) {
    if (_graph == g) return;
    _graph = g;
    _safeNotify();
  }

  set unit(GraphUnit u) {
    if (_unit == u) return;
    _unit = u;
    _safeNotify();
  }

  set year(int? y) {
    final normalized = (y == 0) ? null : y;
    if (_year == normalized) return;
    _year = normalized;
    load(); // refetch when year changes
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  double get total {
    return currentStats.values.fold<double>(
      0,
      (sum, v) => sum + v.past + v.future,
    );
  }

  (double, double) get totalPastFuture {
    return currentStats.values.fold<(double, double)>(
      (0, 0),
      (sum, v) => (sum.$1 + v.past, sum.$2 + v.future),
    );
  }

  String totalFormatted(
    BuildContext context, {
    bool baseUnit = false,
    bool splitPastFuture = false,
  }) {
    String formatValue(double value) {
      // Duration is special
      if (unit == GraphUnit.duration) {
        if (baseUnit) {
          return '${formatNumber(context, value)} '
              '${_durationBase.localizedTimeUnit(context, short: true)}';
        }

        final seconds = value * _durationBase.secondsPerUnit;
        return humanizeSeconds(context, seconds);
      }

      if (baseUnit) {
        return '${formatNumber(context, value)} ${baseUnitLabel(context)}';
      }

      final factor = _factorForValue(value);
      final scaled = factor.apply(value);

      final unitLabel =
          unitsByFactor(context)?[factor] ?? baseUnitLabel(context);

      return '${formatNumber(context, scaled)} $unitLabel';
    }

    if (splitPastFuture) {
      final (past, future) = totalPastFuture;
      return '${formatValue(past)} + ${formatValue(future)}';
    }

    return formatValue(total);
  }

  // -------------------------------------------------------------------
  // Fetch & cache
  // -------------------------------------------------------------------
  Future<void> load() async {
    if (_disposed) return;
    final token = ++_loadToken;
    _isLoading = true;
    _error = null;
    _failedVehicles = const [];
    _safeNotify();

    try {
      final year = _year;
      final missing = _selectedVehicles
          .where((v) => !_cache.containsKey(_cacheKey(v, year)))
          .toList();
      if (missing.isNotEmpty) {
        final result = await _trainlog.fetchStatsForVehicleTypes(missing, year);
        // Abort if this load is outdated or provider disposed
        if (_disposed || token != _loadToken) return;
        result.data.forEach((v, data) => _cache[_cacheKey(v, year)] = data);
        if (result.data.isEmpty && result.errors.isNotEmpty) {
          _error = result.errors.values.first.toString();
        } else {
          _failedVehicles = [
            for (final v in missing) if (result.errors.containsKey(v)) v,
          ];
        }
      }
      // Abort again after await-boundary logic
      if (_disposed || token != _loadToken) return;

      // If unit is duration, decide best readable base (min/h/d/mo/y)
      if (_unit == GraphUnit.duration) {
        _durationBase = _decideDurationBase();
      }
    } catch (e) {
      if (_disposed || token != _loadToken) return;
      _error = e.toString();
    }

    if (_disposed || token != _loadToken) return;
    _isLoading = false;
    _safeNotify();
  }

  String _cacheKey(VehicleType v, int? y) => "${v.name}|${y ?? 'all'}";

  /// Raw API values (trips, m, s, kg) of [field] for the current graph,
  /// per label and split per mode. Breakdowns follow [_selectedVehicles]
  /// order; entries with the same label in several modes are merged.
  LinkedHashMap<String, Map<VehicleType, StatValue>> _rawByVehicle(String field) {
    final listKey = _jsonKeyForGraphType(_graph);
    final out = LinkedHashMap<String, Map<VehicleType, StatValue>>();

    for (final v in _selectedVehicles) {
      final list = _cache[_cacheKey(v, _year)]?[listKey];
      if (list is! List) continue;

      for (final e in list) {
        if (e is! Map<String, dynamic>) continue;
        final past = (e["past$field"] ?? 0).toDouble();
        final future = (e["plannedFuture$field"] ?? 0).toDouble();
        final byVehicle = out.putIfAbsent(_extractLabel(e), () => {});
        final cur = byVehicle[v];
        byVehicle[v] = (
          past: (cur?.past ?? 0) + past,
          future: (cur?.future ?? 0) + future,
        );
      }
    }
    return out;
  }

  /// [_rawByVehicle] with all modes summed.
  LinkedHashMap<String, StatValue> _rawMerged(String field) =>
      LinkedHashMap.fromEntries(_rawByVehicle(field)
          .entries
          .map((e) => MapEntry(e.key, _sum(e.value.values))));

  static StatValue _sum(Iterable<StatValue> values) => values.fold(
        (past: 0.0, future: 0.0),
        (a, b) => (past: a.past + b.past, future: a.future + b.future),
      );

  /// Drop the modes with nothing to show from each breakdown.
  static LinkedHashMap<String, Map<VehicleType, StatValue>> _withoutEmptyModes(
    Map<String, Map<VehicleType, StatValue>> byVehicle,
  ) {
    return LinkedHashMap.fromEntries(byVehicle.entries.map((e) => MapEntry(
          e.key,
          Map.fromEntries(
              e.value.entries.where((m) => m.value.past + m.value.future > 0)),
        )));
  }

  // JSON units:
  // trips: trips (no change)
  // distance: meters → kilometers
  // co2: kg (no change)
  // duration: seconds -> convert to selected readable base (min/h/d/mo/y)
  StatValue _convert(StatValue raw) {
    switch (unit) {
      case GraphUnit.distance:
        return (past: raw.past / 1000, future: raw.future / 1000);
      case GraphUnit.duration:
        final f = _durationBase.secondsPerUnit;
        return (past: raw.past / f, future: raw.future / f);
      case GraphUnit.trip:
      case GraphUnit.co2:
        return raw;
    }
  }

  // -------------------------------------------------------------------
  // Data extraction for the current graph/unit
  // Returns values already converted for duration base unit when needed.
  // The LogoBarChart will still apply UnitFactor scaling on top.
  // -------------------------------------------------------------------
  LinkedHashMap<String, ({double past, double future})> get currentStats {
    // if duration, pick a base that keeps max < 1000 AFTER conversion
    if (unit == GraphUnit.duration) {
      _durationBase = _decideDurationBase();
    }

    // "Trips", "Km", "Duration", "CO2"
    final raw = _rawMerged(unit.apiFieldChunk());

    // IMPORTANT: do NOT apply any UnitFactor scaling here.
    // LogoBarChart will do the k/M/G scaling automatically for non-duration units.
    // For duration, our chosen base ensures bars remain < 1000 so no prefix is used.

    return LinkedHashMap.fromEntries(
        raw.entries.map((e) => MapEntry(e.key, _convert(e.value))));
  }

  /// [currentStats] split per mode, converted the same way. Each breakdown
  /// follows the vehicle selection-list order and omits empty modes.
  LinkedHashMap<String, Map<VehicleType, StatValue>> currentStatsByVehicle() {
    if (unit == GraphUnit.duration) {
      _durationBase = _decideDurationBase();
    }
    final raw = _withoutEmptyModes(_rawByVehicle(unit.apiFieldChunk()));
    return LinkedHashMap.fromEntries(raw.entries.map((e) => MapEntry(
          e.key,
          e.value.map((v, value) => MapEntry(v, _convert(value))),
        )));
  }

  /// Per-mode counterpart of [currentStatsShort]: same keys, with
  /// [otherLabel] aggregating the per-mode values of the remaining entries.
  LinkedHashMap<String, Map<VehicleType, StatValue>> currentStatsByVehicleShort(
    int maxItems, {
    required String otherLabel,
  }) {
    final byVehicle = currentStatsByVehicle();
    final keys = currentStatsShort(maxItems, otherLabel: otherLabel).keys;
    final out = LinkedHashMap<String, Map<VehicleType, StatValue>>();
    for (final k in keys) {
      if (k != otherLabel) out[k] = byVehicle[k] ?? const {};
    }
    if (keys.contains(otherLabel)) {
      final other = <VehicleType, StatValue>{};
      for (final v in _selectedVehicles) {
        final values = [
          for (final e in byVehicle.entries)
            if (!out.containsKey(e.key) && e.value[v] != null) e.value[v]!,
        ];
        if (values.isNotEmpty) other[v] = _sum(values);
      }
      out[otherLabel] = other;
    }
    return out;
  }

  /// Sorted (desc) by total = past + future. Preserves order with LinkedHashMap.
  LinkedHashMap<String, ({double past, double future})> currentStatsSortedDesc() {
    final base = currentStats; // already converted (km / duration base)
    final entries = base.entries.toList();

    entries.sort((a, b) {
      final ta = a.value.past + a.value.future;
      final tb = b.value.past + b.value.future;
      final cmp = tb.compareTo(ta); // desc
      if (cmp != 0) return cmp;
      // tie-breaker: lexicographical by key to keep ordering stable
      return a.key.toLowerCase().compareTo(b.key.toLowerCase());
    });

    return LinkedHashMap.fromEntries(entries);
  }

  /// Return top [maxItems] and aggregate the rest into one "Other" bucket,
  /// **always appended at the end**, even if it's larger than the others.
  LinkedHashMap<String, ({double past, double future})> currentStatsShort(
    int maxItems, {
    required String otherLabel,
  }) {
    final sorted = currentStatsSortedDesc();
    if (sorted.length <= maxItems) return sorted;

    final keys = sorted.keys.toList();
    final headKeys = keys.take(maxItems).toList();
    final tailKeys = keys.skip(maxItems).toList();

    // Build head map
    final head = LinkedHashMap<String, ({double past, double future})>();
    for (final k in headKeys) {
      head[k] = sorted[k]!;
    }

    // Aggregate tail into "Other"
    double pastSum = 0, futureSum = 0;
    for (final k in tailKeys) {
      final v = sorted[k]!;
      pastSum += v.past;
      futureSum += v.future;
    }

    // Append "Other" LAST even if larger
    head[otherLabel] = (past: pastSum, future: futureSum);
    return head;
  }

  // -------------------------------------------------------------------
  // Units the chart should display on the axis
  // - For trips/distance/CO2: we provide UnitFactor map (k/M/G…), like your page.
  // - For duration: we provide a single readable base label; no k/M suffixes.
  // -------------------------------------------------------------------
  // axis base label (right axis in LogoBarChart)
  String baseUnitLabel(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    switch (unit) {
      case GraphUnit.trip:     return loc.statisticsTripsUnitBase; // e.g., "trips"
      case GraphUnit.distance: return "km";
      case GraphUnit.co2:      return "kg";
      case GraphUnit.duration: return _durationBase.localizedTimeUnit(context);
    }
  }

  // per-factor labels (k/M/G) for scalable units only
  Map<UnitFactor, String>? unitsByFactor(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    switch (unit) {
      case GraphUnit.trip:
        return {
          UnitFactor.base:     loc.statisticsTripsUnitBase,
          UnitFactor.thousand: loc.statisticsTripsUnitKilo,
          UnitFactor.million:  loc.statisticsTripsUnitMega,
          UnitFactor.billion:  loc.statisticsTripsUnitGiga,
        };

      case GraphUnit.distance:
        return {
          UnitFactor.base:     "km",
          UnitFactor.thousand: "Mm",
          UnitFactor.million:  "Gm",
          UnitFactor.billion:  "Tm",
        };

      case GraphUnit.co2:
        return {
          UnitFactor.base:     "kg",
          UnitFactor.thousand: "t",
          UnitFactor.million:  "Gg",
          UnitFactor.billion:  "Tg",
        };

      case GraphUnit.duration:
        // duration is handled with readable base (no k/M/G). return null.
        return null;
    }
  }

  // -------------------------------------------------------------------
  // Label builder (used by charts/tables): localize country codes
  // -------------------------------------------------------------------
  String Function(String key)? labelBuilder(BuildContext context) {
    if (graph == GraphType.country) {
      return (String code) => countryCodeToName(code, context);
    }
    return null;
  }

  // -------------------------------------------------------------------
  // Graph images: same behavior as your current StatisticsPage
  // - operator: real logo via TrainlogProvider.getOperatorImage(...)
  // - country: flag emoji
  // - others: short text (first few chars), bold
  // -------------------------------------------------------------------
  List<Widget> graphImages(BuildContext context) {
    final keys = currentStats.keys.toList();
    return _barChartImageBuilder(context, graph, keys);
  }

  List<Widget> _barChartImageBuilder(
    BuildContext context,
    GraphType type,
    List<String> data,
  ) {
    // Convert "JP" -> "🇯🇵"
    String flagEmoji(String code) {
      String normalize(String c) {
        final cc = c.trim().toUpperCase();
        return (cc == 'UK') ? 'GB' : cc;
      }

      final cc = normalize(code);
      if (cc.length != 2) return '🏳️';
      const int base = 0x1F1E6; // Regional Indicator Symbol Letter A
      final int a = cc.codeUnitAt(0);
      final int b = cc.codeUnitAt(1);
      if (a < 65 || a > 90 || b < 65 || b > 90) return '🏳️';
      return String.fromCharCodes([base + (a - 65), base + (b - 65)]);
    }

    switch (type) {
      case GraphType.operator:
        return List.generate(
          data.length,
          (i) => _trainlog.getOperatorImage(data[i], maxWidth: 48, maxHeight: 48),
          // (i) => withOperatorLogoBg(
          //   context,
          //   _trainlog.getOperatorImage(data[i], maxWidth: 48, maxHeight: 48),
          // ),
        );

      case GraphType.country:
        return List.generate(
          data.length,
          (i) => Text(
            flagEmoji(data[i]),
            style: const TextStyle(fontSize: 18),
          ),
        );

      default:
        return List.generate(
          data.length,
          (i) => Text(
            _shortLabel(data[i], maxLen: shortLabelSize),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
    }
  }

  /// Build graph images for a given ordered list of keys (so it matches `stats.keys`).
  ///
  /// [otherLabel] — when a key equals this string, renders a vehicle-type icon
  /// in a coloured square (the "Other" bucket fallback).
  /// [barColor]   — the colour used for the "Other" square background.
  List<Widget> graphImagesForKeys(
    BuildContext context,
    List<String> keys, {
    String? otherLabel,
    Color barColor = Colors.blue,
  }) {
    // Convert "JP" -> "🇯🇵"
    String flagEmoji(String code) {
      String normalize(String c) {
        final cc = c.trim().toUpperCase();
        return (cc == 'UK') ? 'GB' : cc;
      }
      final cc = normalize(code);
      if (cc.length != 2) return '🏳️';
      const int base = 0x1F1E6;
      final int a = cc.codeUnitAt(0);
      final int b = cc.codeUnitAt(1);
      if (a < 65 || a > 90 || b < 65 || b > 90) return '🏳️';
      return String.fromCharCodes([base + (a - 65), base + (b - 65)]);
    }

    Widget otherWidget() {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: barColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: barColor.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Center(
          child: IconTheme(
            data: IconThemeData(size: 16, color: barColor),
            child: vehicleIconOf(_vehicle),
          ),
        ),
      );
    }

    switch (graph) {
      case GraphType.operator:
        return List.generate(keys.length, (i) {
          final name = keys[i];
          if (otherLabel != null && name == otherLabel) return otherWidget();
          return withOperatorLogoBg(
            context,
            _trainlog.getOperatorImage(name, maxWidth: 48, maxHeight: 48)
          );
        });

      case GraphType.country:
        return List.generate(keys.length, (i) {
          final name = keys[i];
          if (otherLabel != null && name == otherLabel) return otherWidget();
          return Text(flagEmoji(name), style: const TextStyle(fontSize: 18));
        });

      default:
        return List.generate(keys.length, (i) {
          final name = keys[i];
          if (otherLabel != null && name == otherLabel) return otherWidget();

          if (i < _numberedRankCount) {
            // Numbered indicator (1..10), styled like the ranking list.
            return Text(
              '${i + 1}',
              textAlign: TextAlign.center,
              style: AppTheme.monoFont.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            );
          }
          return Text(
            _shortLabel(name, maxLen: shortLabelSize),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          );
        });
    }
  }

  /// Icon for a vehicle selection; `null` (all modes) shows a stack.
  static Icon vehicleIconOf(VehicleType? vehicle) => vehicle == null
      ? const Icon(Symbols.stacks, fill: 1)
      : VehicleType.iconOf(vehicle);

  // -------------------------------------------------------------------
  // Internals
  // -------------------------------------------------------------------
  String _jsonKeyForGraphType(GraphType type) {
    switch (type) {
      case GraphType.operator:  return "operators";
      case GraphType.country:   return "countries";
      case GraphType.years:     return "years";
      case GraphType.material:  return "material";
      case GraphType.itinerary: return "routes";
      case GraphType.stations:  return "stations";
    }
  }

  String _extractLabel(Map<String, dynamic> entry) {
    switch (graph) {
      case GraphType.operator:
        return entry["operator"] ?? "Unknown";
      case GraphType.country:
        return (entry["country"] ?? "??").toString().toUpperCase();
      case GraphType.material:
        return entry["material"] ?? "Unknown";
      case GraphType.itinerary:
        // route stored as a JSON-like string → strip brackets/quotes for compact label key
        final r = entry["route"];
        if (r is String && r.contains("[")) {
          return r.replaceAll(RegExp(r'[\[\]"]'), '');
        }
        return r ?? "Unknown";
      case GraphType.stations:
        return entry["station"] ?? "Unknown";
      case GraphType.years:
        return (entry["year"] ?? "???").toString();
    }
  }

  String _shortLabel(String s, {int maxLen = 5}) {
    final clean = removeDiacritics(s.trim());
    if (clean.length <= maxLen) return clean;
    return clean.substring(0, maxLen);
  }

  // ---------------- Duration base selection & formatting --------------
  // Guarantees max value < 1000 after conversion so LogoBarChart won't apply k/M/G.
  _DurationBase _decideDurationBase() {
    final raw = currentDurationRawSeconds();
    if (raw.isEmpty) return _DurationBase.hours;

    // find the maximum total duration (seconds) among entries (past + future)
    double maxSeconds = 0;
    for (final v in raw.values) {
      final total = v.past + v.future;
      if (total > maxSeconds) maxSeconds = total;
    }

    // try from more granular to coarser until max < 1000
    for (final base in const [
      _DurationBase.minutes,
      _DurationBase.hours,
      _DurationBase.days,
      _DurationBase.months,
      _DurationBase.years,
    ]) {
      if ((maxSeconds / base.secondsPerUnit) < 1000) return base;
    }

    // extremely huge numbers: years is the coarsest we'll use
    return _DurationBase.years;
  }

  /// Pretty-print seconds as: "1 year 2 months 15 days 3 h 15 min"
  /// Localize tokens as needed (placeholders provided).
  String humanizeSeconds(BuildContext context, num seconds) {
    final localeCode = Localizations.localeOf(context).languageCode;

    // Create a Duration object
    final duration = Duration(seconds: seconds.round());

    // Pick the correct localized DurationLocale
    final locale = DurationLocale.fromLanguageCode(localeCode) ?? const EnglishDurationLocale();
        
    // Format it nicely
    return prettyDuration(
      duration,
      locale: locale,
      abbreviated: true, // set to true for shorter format (e.g. 3h 15m)
      spacer: ' ',
      delimiter: ' ',
      conjunction: ' ',
    );
  }

  /// Raw duration (in seconds) directly from the JSON.
  ///
  /// Returns: {label: (past, future)} in the **same label keys**
  /// as currentStats/current ordering logic.
  LinkedHashMap<String, ({double past, double future})> currentDurationRawSeconds() =>
      _rawMerged("Duration");

  /// [currentDurationRawSeconds] split per mode (empty modes omitted).
  LinkedHashMap<String, Map<VehicleType, StatValue>> currentDurationRawSecondsByVehicle() =>
      _withoutEmptyModes(_rawByVehicle("Duration"));

  /// Short version for raw duration seconds that mirrors your chart’s “top N + Other”.
  LinkedHashMap<String, ({double past, double future})> currentDurationRawSecondsShort(
    int maxItems, {
    required String otherLabel,
  }) {
    // Sort by total desc using the converted (km/h/…) stats' order logic.
    // We rely on the same keys as currentStatsShort, so we reuse its ordering.
    final shortConverted = currentStatsShort(maxItems, otherLabel: otherLabel);
    final raw = currentDurationRawSeconds();

    // Build in that same order and aggregate "Other" as well.
    final out = LinkedHashMap<String, ({double past, double future})>();
    double otherPast = 0, otherFuture = 0;

    for (final entry in shortConverted.entries) {
      final k = entry.key;
      if (k == otherLabel) continue; // accumulate at the end
      final r = raw[k];
      out[k] = (past: r?.past ?? 0, future: r?.future ?? 0);
    }

    // The original currentStatsShort already aggregated otherLabel’s **converted** values,
    // but we must aggregate raw seconds separately to keep tooltips consistent.
    // Aggregate everything that's not in the top maxItems into "Other":
    final fullRaw = currentDurationRawSeconds();
    final topKeys = out.keys.toSet();
    for (final e in fullRaw.entries) {
      if (!topKeys.contains(e.key)) {
        otherPast  += e.value.past;
        otherFuture+= e.value.future;
      }
    }

    // Append "Other" last, even if bigger
    out[otherLabel] = (past: otherPast, future: otherFuture);
    return out;
  }

  UnitFactor _factorForValue(double value) {
    final abs = value.abs();

    if (abs >= UnitFactor.billion.multiplier) {
      return UnitFactor.billion;
    }
    if (abs >= UnitFactor.million.multiplier) {
      return UnitFactor.million;
    }
    if (abs >= UnitFactor.thousand.multiplier) {
      return UnitFactor.thousand;
    }

    return UnitFactor.base;
  }
}

/// Readable base units for duration (we convert seconds into one of these)
enum _DurationBase { minutes, hours, days, months, years }

extension on _DurationBase {
  double get secondsPerUnit {
    switch (this) {
      case _DurationBase.minutes: return Duration.secondsPerMinute.toDouble();
      case _DurationBase.hours:   return Duration.secondsPerHour.toDouble();
      case _DurationBase.days:    return Duration.secondsPerDay.toDouble();
      case _DurationBase.months:  return 2592000.0;   // ~30 days
      case _DurationBase.years:   return 31536000.0;  // 365 days
    }
  }

  /// Short, localized label (axis): e.g., "min", "h", "d", "mo", "y"
  String localizedTimeUnit(BuildContext context, {short = false}) {
    final localeCode = Localizations.localeOf(context).languageCode;
    final durLoc = DurationLocale.fromLanguageCode(localeCode) ?? const EnglishDurationLocale();
    
    switch (this) {
      case _DurationBase.minutes: return durLoc.minute(0, short);
      case _DurationBase.hours:   return durLoc.hour(0, short);
      case _DurationBase.days:    return durLoc.day(0, short);
      case _DurationBase.months:  return durLoc.month(0, short);
      case _DurationBase.years:   return durLoc.year(0, short);
    }
  }
}
