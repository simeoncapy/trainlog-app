import 'package:flutter_test/flutter_test.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/providers/statistics_provider.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';

/// Serves canned stats per vehicle; vehicles in [failing] throw.
class _FakeTrainlog implements TrainlogProvider {
  _FakeTrainlog(this.stats, {this.failing = const {}});

  final Map<VehicleType, Map<String, dynamic>> stats;
  final Set<VehicleType> failing;
  final List<VehicleType> fetched = [];

  @override
  Future<Map<String, dynamic>> fetchStatsForVehicleType(VehicleType type, int? year) async {
    fetched.add(type);
    if (failing.contains(type)) throw Exception('boom $type');
    return stats[type] ?? const {};
  }

  @override
  Future<({Map<VehicleType, Map<String, dynamic>> data, Map<VehicleType, Object> errors})>
      fetchStatsForVehicleTypes(List<VehicleType> types, int? year) async {
    final data = <VehicleType, Map<String, dynamic>>{};
    final errors = <VehicleType, Object>{};
    for (final t in types) {
      try {
        data[t] = await fetchStatsForVehicleType(t, year);
      } catch (e) {
        errors[t] = e;
      }
    }
    return (data: data, errors: errors);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _op(String name, int past, int future) =>
    {"operator": name, "pastTrips": past, "plannedFutureTrips": future};

/// Wait for the load started by the provider (constructor or setter).
Future<void> _settle(StatisticsProvider p) async {
  while (p.isLoading) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  final stats = {
    VehicleType.train: {
      "operators": [_op("JR East", 10, 1), _op("SNCF", 5, 0)],
    },
    VehicleType.metro: {
      "operators": [_op("JR East", 3, 2), _op("RATP", 1, 0)],
    },
  };

  test('all modes merges entries by label and keeps per-mode split', () async {
    final trainlog = _FakeTrainlog(stats);
    final p = StatisticsProvider(trainlog,
        allVehicles: [VehicleType.train, VehicleType.metro, VehicleType.poi]);
    p.vehicle = null; // in case defaultVehicle is not "all"
    await p.load();

    expect(trainlog.fetched.toSet(), {VehicleType.train, VehicleType.metro});
    expect(p.error, isNull);
    expect(p.currentStats["JR East"], (past: 13.0, future: 3.0));
    expect(p.currentStats["RATP"], (past: 1.0, future: 0.0));

    final byVehicle = p.currentStatsByVehicle();
    expect(byVehicle["JR East"]!.keys.toList(), [VehicleType.train, VehicleType.metro]);
    expect(byVehicle["JR East"]![VehicleType.metro], (past: 3.0, future: 2.0));
    expect(byVehicle["SNCF"]!.keys.toList(), [VehicleType.train]);
  });

  test('"Other" bucket aggregates the remaining entries per mode', () async {
    final p = StatisticsProvider(_FakeTrainlog(stats),
        allVehicles: [VehicleType.train, VehicleType.metro]);
    p.vehicle = null; // in case defaultVehicle is not "all"
    await p.load();

    final short = p.currentStatsByVehicleShort(1, otherLabel: "Other");
    expect(short.keys.toList(), ["JR East", "Other"]);
    expect(short["Other"], {
      VehicleType.train: (past: 5.0, future: 0.0),
      VehicleType.metro: (past: 1.0, future: 0.0),
    });
  });

  test('a failing mode is reported while the others are shown', () async {
    final p = StatisticsProvider(
      _FakeTrainlog(stats, failing: {VehicleType.metro}),
      allVehicles: [VehicleType.train, VehicleType.metro],
    );
    p.vehicle = null; // in case defaultVehicle is not "all"
    await p.load();

    expect(p.error, isNull);
    expect(p.failedVehicles, [VehicleType.metro]);
    expect(p.currentStats["JR East"], (past: 10.0, future: 1.0));
  });

  test('single mode only fetches and shows that mode', () async {
    final trainlog = _FakeTrainlog(stats);
    final p = StatisticsProvider(trainlog,
        allVehicles: [VehicleType.train, VehicleType.metro]);
    p.vehicle = VehicleType.metro;
    await _settle(p);

    expect(trainlog.fetched, [VehicleType.metro]);
    expect(p.currentStats.keys.toList(), ["JR East", "RATP"]);
    expect(p.currentStats["JR East"], (past: 3.0, future: 2.0));
  });
}
