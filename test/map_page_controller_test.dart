import 'dart:async';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:trainlog_app/core/data/models/location_search_result.dart';
import 'package:trainlog_app/features/map/map_page_controller.dart';

class FakeLocation implements MapLocationSource {
  FakeLocation({this.granted = false, this.grantOnRequest = true, this.fix});

  bool granted;
  bool grantOnRequest;
  LatLng? fix;
  LatLng? remembered;
  int requests = 0;
  final updates = StreamController<LatLng>.broadcast();

  @override
  Future<bool> hasPermission() async => granted;

  @override
  Future<bool> requestPermission() async {
    requests++;
    granted = grantOnRequest;
    return granted;
  }

  @override
  Future<LatLng?> currentPosition() async => fix;

  @override
  Stream<LatLng> positionUpdates() => updates.stream;

  @override
  LatLng? get lastKnownPosition => remembered;

  @override
  void rememberPosition(LatLng position) => remembered = position;
}

LocationSearchResult place(String name, {LatLngBounds? extent}) =>
    LocationSearchResult(
      name: name,
      subtitle: '',
      countryCode: 'JP',
      point: const LatLng(35, 135.7),
      category: LocationCategory.city,
      source: LocationSearchSource.photon,
      extent: extent,
    );

void main() {
  const paris = LatLng(48.85, 2.35);
  const tokyo = LatLng(35.68, 139.76);

  group('location', () {
    test('opens on the remembered position, else Greenwich', () {
      final remembered = MapPageController(
        location: FakeLocation()..remembered = paris,
        search: (_) async => [],
      );
      expect(remembered.center, paris);

      final none = MapPageController(
        location: FakeLocation(),
        search: (_) async => [],
      );
      expect(none.center, MapPageController.greenwich);
    });

    test('start never prompts, and centres on the fix when allowed', () async {
      final denied = FakeLocation(fix: tokyo);
      final c1 = MapPageController(location: denied, search: (_) async => []);
      await c1.start();
      expect(denied.requests, 0);
      expect(c1.userPosition, isNull);

      final allowed = FakeLocation(granted: true, fix: tokyo);
      final c2 = MapPageController(location: allowed, search: (_) async => []);
      await c2.start();
      expect(allowed.requests, 0);
      expect(c2.userPosition, tokyo);
      expect(c2.center, tokyo);
      expect(allowed.remembered, tokyo);
    });

    test(
      'recenter asks for access, moves the camera, then resets the zoom',
      () async {
        final location = FakeLocation(fix: tokyo);
        final c = MapPageController(
          location: location,
          search: (_) async => [],
        );
        final moves = <MapCameraRequest>[];
        c.cameraRequests.listen(moves.add);
        c.onCameraChanged(paris, 8);

        await c.recenter();
        await pumpEventQueue();
        expect(location.requests, 1);
        expect((moves.last as MapCameraMove).point, tokyo);
        expect((moves.last as MapCameraMove).zoom, 8);

        // Already centred on the user: the zoom goes back to the default.
        await c.recenter();
        await pumpEventQueue();
        expect(
          (moves.last as MapCameraMove).zoom,
          MapPageController.defaultZoom,
        );
      },
    );

    test('recenter does nothing when access is refused', () async {
      final location = FakeLocation(fix: tokyo, grantOnRequest: false);
      final c = MapPageController(location: location, search: (_) async => []);
      final moves = <MapCameraRequest>[];
      c.cameraRequests.listen(moves.add);

      await c.recenter();
      await pumpEventQueue();
      expect(moves, isEmpty);
      expect(c.userPosition, isNull);
    });

    test(
      'follow moves the map with each new position until turned off',
      () async {
        final location = FakeLocation(granted: true, fix: tokyo);
        final c = MapPageController(
          location: location,
          search: (_) async => [],
        );
        final moves = <MapCameraRequest>[];
        c.cameraRequests.listen(moves.add);
        await c.start();

        await c.toggleFollow();
        expect(c.following, isTrue);

        location.updates.add(paris);
        await pumpEventQueue();
        expect(c.userPosition, paris);
        expect((moves.last as MapCameraMove).point, paris);
        expect(location.remembered, paris);

        await c.toggleFollow();
        expect(c.following, isFalse);
        final count = moves.length;
        location.updates.add(tokyo);
        await pumpEventQueue();
        expect(moves.length, count);
        expect(c.userPosition, tokyo);
      },
    );
  });

  group('search', () {
    test('searches once typing pauses, and shows "no result"', () async {
      final queries = <String>[];
      final c = MapPageController(
        location: FakeLocation(),
        search: (q) async {
          queries.add(q);
          return q == 'Kyoto' ? [place('Kyoto')] : [];
        },
        searchDebounce: const Duration(milliseconds: 20),
      );
      c.openSearch();
      c.queryChanged('Kyo');
      c.queryChanged('Kyoto');
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(queries, ['Kyoto']);
      expect(c.results.single.name, 'Kyoto');
      expect(c.hasNoResult, isFalse);

      c.queryChanged('zzz');
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(c.results, isEmpty);
      expect(c.hasNoResult, isTrue);
    });

    test(
      'an answer that comes after a newer search or a close is dropped',
      () async {
        final pending = <String, Completer<List<LocationSearchResult>>>{};
        final c = MapPageController(
          location: FakeLocation(),
          search: (q) => (pending[q] = Completer()).future,
        );
        c.openSearch();
        final first = c.submitQuery('first');
        final second = c.submitQuery('second');
        pending['second']!.complete([place('Second')]);
        pending['first']!.complete([place('First')]);
        await Future.wait([first, second]);
        expect(c.results.single.name, 'Second');

        final late = c.submitQuery('late');
        c.closeSearch();
        pending['late']!.complete([place('Late')]);
        await late;
        expect(c.results.single.name, 'Second');
      },
    );

    test('picking a place shows it, pins it and stops following', () async {
      final location = FakeLocation(granted: true, fix: tokyo);
      final c = MapPageController(location: location, search: (_) async => []);
      final moves = <MapCameraRequest>[];
      c.cameraRequests.listen(moves.add);
      await c.start();
      await c.toggleFollow();

      final kyoto = place('Kyoto');
      c.choosePlace(kyoto);
      await pumpEventQueue();
      expect((moves.last as MapCameraShowPlace).place, kyoto);
      expect(c.searchedPlace, kyoto);
      expect(c.following, isFalse);

      c.clearSearchedPlace();
      expect(c.searchedPlace, isNull);
    });
  });
}
