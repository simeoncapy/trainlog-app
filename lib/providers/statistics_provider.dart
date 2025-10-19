import 'dart:collection';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:country_picker/country_picker.dart';
import 'package:diacritic/diacritic.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/utils/text_utils.dart'; // for countryCodeToName(...)
import 'package:trainlog_app/widgets/logo_bar_chart.dart'; // for UnitFactor

/// Graph categories aligned with the UI page.
enum GraphType {
  operator,
  country,
  years,
  material,
  itinerary, // API key is "routes"
  stations;

  String label(BuildContext context, VehicleType vehicleType) {
    final loc = AppLocalizations.of(context)!;
    switch (this) {
      case GraphType.operator:  return loc.graphTypeOperator;
      case GraphType.country:   return loc.graphTypeCountry;
      case GraphType.years:     return loc.graphTypeYears;
      case GraphType.material:  return loc.graphTypeMaterial;
      case GraphType.itinerary: return loc.graphTypeItinerary;
      case GraphType.stations:  return loc.graphTypeStations(vehicleType.name.toLowerCase());
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
      case GraphUnit.duration: return loc.statisticsGraphUnitDuration;
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
  StatisticsProvider(this._trainlog);

  // -------------------------------------------------------------------
  // Dependencies
  // -------------------------------------------------------------------
  final TrainlogProvider _trainlog;

  // -------------------------------------------------------------------
  // State
  // -------------------------------------------------------------------
  VehicleType _vehicle = VehicleType.train;
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

  // -------------------------------------------------------------------
  // Public getters
  // -------------------------------------------------------------------
  bool get isLoading => _isLoading;
  String? get error => _error;

  VehicleType get vehicle => _vehicle;
  GraphType get graph => _graph;
  GraphUnit get unit => _unit;
  int? get year => _year;

  set vehicle(VehicleType v) {
    if (_vehicle == v) return;
    _vehicle = v;
    load(); // refetch for new vehicle
  }

  set graph(GraphType g) {
    if (_graph == g) return;
    _graph = g;
    notifyListeners();
  }

  set unit(GraphUnit u) {
    if (_unit == u) return;
    _unit = u;
    notifyListeners();
  }

  set year(int? y) {
    final normalized = (y == 0) ? null : y;
    if (_year == normalized) return;
    _year = normalized;
    load(); // refetch when year changes
  }

  // -------------------------------------------------------------------
  // Fetch & cache
  // -------------------------------------------------------------------
  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final key = _cacheKey(_vehicle, _year);
      if (!_cache.containsKey(key)) {
        final data = await _trainlog.fetchStatsForVehicleType(_vehicle, _year);
        _cache[key] = data;
      }
      // If unit is duration, decide best readable base (min/h/d/mo/y)
      if (_unit == GraphUnit.duration) {
        _durationBase = _decideDurationBase(_rawForCurrentKey());
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  String _cacheKey(VehicleType v, int? y) => "${v.name}|${y ?? 'all'}";

  Map<String, dynamic> _rawForCurrentKey() =>
      _cache[_cacheKey(_vehicle, _year)] ?? const {};

  // -------------------------------------------------------------------
  // Data extraction for the current graph/unit
  // Returns values already converted for duration base unit when needed.
  // The LogoBarChart will still apply UnitFactor scaling on top.
  // -------------------------------------------------------------------
  LinkedHashMap<String, ({double past, double future})> get currentStats {
    final raw = _rawForCurrentKey();
    final listKey = _jsonKeyForGraphType(_graph);
    final list = raw[listKey];
    final out = <String, ({double past, double future})>{};

    if (list is! List) return LinkedHashMap.of(out);

    final field = unit.apiFieldChunk(); // "Trips", "Km", "Duration", "CO2"

    // if duration, pick a base that keeps max < 1000 AFTER conversion
    if (unit == GraphUnit.duration) {
      _durationBase = _decideDurationBase(raw);
    }

    for (final e in list) {
      if (e is! Map<String, dynamic>) continue;

      final label = _extractLabel(e);

      double past = (e["past$field"] ?? 0).toDouble();
      double future = (e["plannedFuture$field"] ?? 0).toDouble();

      // JSON units:
      // trips: trips (no change)
      // distance: meters → kilometers
      // co2: kg (no change)
      // duration: seconds -> convert to selected readable base (min/h/d/mo/y)
      if (unit == GraphUnit.distance) {
        past /= 1000;
        future /= 1000;
      } else if (unit == GraphUnit.duration) {
        final f = _durationBase.secondsPerUnit;
        past /= f;
        future /= f;
      }

      out[label] = (past: past, future: future);
    }

    // IMPORTANT: do NOT apply any UnitFactor scaling here.
    // LogoBarChart will do the k/M/G scaling automatically for non-duration units.
    // For duration, our chosen base ensures bars remain < 1000 so no prefix is used.

    return LinkedHashMap.of(out);
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
      case GraphUnit.duration: return _durationBase.localizedShort(context); // "min", "h", "d", "mo", "y"
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
            _shortLabel(data[i], maxLen: 5),
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
    }
  }

  /// Build graph images for a given ordered list of keys (so it matches `stats.keys`).
  List<Widget> graphImagesForKeys(BuildContext context, List<String> keys) {
    // Use the same logic you already have in the provider for building images.
    // This version reuses your graphImages() behavior but for a provided key order.
    List<Widget> forGraph(List<String> data) {
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

      switch (graph) {
        case GraphType.operator:
          return List.generate(keys.length, (i) {
          final name = keys[i];
          if (name == AppLocalizations.of(context)!.statisticsOtherLabel) {
            // Just display text for "Other"
            return Text(
              name,
              //style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            );
          }
          // Otherwise display operator logo
          return _trainlog.getOperatorImage(name, maxWidth: 48, maxHeight: 48);
        });
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
              _shortLabel(data[i], maxLen: 5),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
      }
    }

    return forGraph(keys);
  }

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
  _DurationBase _decideDurationBase(Map<String, dynamic> raw) {
    final list = raw[_jsonKeyForGraphType(graph)];
    if (list is! List) return _DurationBase.hours;

    // find the maximum total duration (seconds) among entries (past + future)
    double maxSeconds = 0;
    for (final e in list) {
      if (e is! Map<String, dynamic>) continue;
      final past = (e["pastDuration"] ?? 0).toDouble();
      final future = (e["plannedFutureDuration"] ?? 0).toDouble();
      final total = past + future;
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
  String humanizeSeconds(BuildContext context, double seconds) {
    final s = seconds.round(); // whole seconds

    final secPerMin = _DurationBase.minutes.secondsPerUnit.toInt();
    final secPerHour = _DurationBase.hours.secondsPerUnit.toInt();
    final secPerDay = _DurationBase.days.secondsPerUnit.toInt();
    final secPerMonth = _DurationBase.months.secondsPerUnit.toInt();
    final secPerYear = _DurationBase.years.secondsPerUnit.toInt();

    int years   = s ~/ secPerYear;
    int rem     = s %  secPerYear;
    int months  = rem ~/ secPerMonth;  rem %= secPerMonth;
    int days    = rem ~/ secPerDay;    rem %= secPerDay;
    int hours   = rem ~/ secPerHour;   rem %= secPerHour;
    int minutes = rem ~/ secPerMin;

    // You can replace these tokens with AppLocalizations if you have them.
    String y(int v)   => v == 0 ? "" : (v == 1 ? "1 year"   : "$v years");
    String mo(int v)  => v == 0 ? "" : (v == 1 ? "1 month"  : "$v months");
    String d(int v)   => v == 0 ? "" : (v == 1 ? "1 day"    : "$v days");
    String h(int v)   => v == 0 ? "" : "$v h";
    String m(int v)   => v == 0 ? "" : "$v min";

    final parts = [y(years), mo(months), d(days), h(hours), m(minutes)]
        .where((p) => p.isNotEmpty)
        .toList();

    // Edge case: extremely small values (< 1 min)
    if (parts.isEmpty) return "0 min";

    return parts.join(" ");
  }

  /// Raw duration (in seconds) directly from the JSON.
  ///
  /// Returns: {label: (past, future)} in the **same label keys**
  /// as currentStats/current ordering logic.
  LinkedHashMap<String, ({double past, double future})> currentDurationRawSeconds() {
    final raw = _rawForCurrentKey();
    final listKey = _jsonKeyForGraphType(graph);
    final list = raw[listKey];
    final out = <String, ({double past, double future})>{};

    if (list is! List) return LinkedHashMap.of(out);

    for (final e in list) {
      if (e is! Map<String, dynamic>) continue;
      final label = _extractLabel(e);
      final past   = (e["pastDuration"] ?? 0).toDouble();
      final future = (e["plannedFutureDuration"] ?? 0).toDouble();
      out[label] = (past: past, future: future);
    }
    return LinkedHashMap.of(out);
  }

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

    int count = 0;
    for (final entry in shortConverted.entries) {
      final k = entry.key;
      if (k == otherLabel) continue; // accumulate at the end
      final r = raw[k];
      out[k] = (past: r?.past ?? 0, future: r?.future ?? 0);
      count++;
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
}

/// Readable base units for duration (we convert seconds into one of these)
enum _DurationBase { minutes, hours, days, months, years }

extension on _DurationBase {
  double get secondsPerUnit {
    switch (this) {
      case _DurationBase.minutes: return 60.0;
      case _DurationBase.hours:   return 3600.0;
      case _DurationBase.days:    return 86400.0;
      case _DurationBase.months:  return 2592000.0;   // ~30 days
      case _DurationBase.years:   return 31536000.0;  // 365 days
    }
  }

  /// Short, localized label (axis): e.g., "min", "h", "d", "mo", "y"
  String localizedShort(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    switch (this) {
      case _DurationBase.minutes: return "min";//loc.durationShortMinutes; // provide in ARB
      case _DurationBase.hours:   return "h";//loc.durationShortHours;
      case _DurationBase.days:    return "d";//loc.durationShortDays;
      case _DurationBase.months:  return "mo.";//loc.durationShortMonths;
      case _DurationBase.years:   return "y";//loc.durationShortYears;
    }
  }
}
