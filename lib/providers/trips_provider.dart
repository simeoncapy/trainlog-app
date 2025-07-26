import 'package:flutter/material.dart';
import 'package:trainlog_app/data/trips_repository.dart';


class TripsProvider extends ChangeNotifier {
  TripsRepository? _repository;
  bool _loading = true;

  bool get isLoading => _loading;
  TripsRepository? get repository => _repository;

  Future<void> loadTrips({String csvPath = ""}) async {
    _loading = true;
    notifyListeners();

    if (csvPath == "")
    {
      _repository = await TripsRepository.loadFromDatabase();
    }
    else
    {
      try {
        _repository = await TripsRepository.loadFromCsv(csvPath);
      } catch (e, stack) {
        debugPrintStack(stackTrace: stack);
      }
    }

    print("✅ Finished loading trips.");
    final count = await _repository!.count();
    print("${count} rows");
    _loading = false;
    notifyListeners();
  }
}
