import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/data/trips_repository.dart';

// TODO: Test and probably rationalise the base URL and Token to a common API access class

class TripsApiDataSource implements TripsDataSource {
  final String baseUrl;
  final String Function() getAuthToken;

  TripsApiDataSource({
    required this.baseUrl,
    required this.getAuthToken,
  });

  @override
  Future<List<Trips>> getAllTrips() async {
    final url = Uri.parse('$baseUrl/trips');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer ${getAuthToken()}',
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((item) => Trips.fromJson(item)).toList();
    } else {
      throw Exception('Failed to fetch trips from API');
    }
  }

  @override
  Future<void> saveTrips(List<Trips> trips) async {
    throw UnimplementedError('Saving to API not implemented');
  }
}
