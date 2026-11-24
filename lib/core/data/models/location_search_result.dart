import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Broad kind of place returned by the location search, used to pick the
/// icon and label shown in the results and the zoom level on selection.
enum LocationCategory {
  // Transport
  railStation,
  metro,
  tram,
  busStop,
  ferry,
  airport,
  aerialway,
  // Points of interest
  hotel,
  food,
  shop,
  publicBuilding,
  health,
  education,
  tourism,
  religion,
  nature,
  sport,
  // Areas and addresses
  city,
  district,
  region,
  street,
  address,
  other,
}

enum LocationSearchSource { photon, airport }

/// One entry of the map location search.
class LocationSearchResult {
  final String name;
  final String subtitle;
  final String countryCode;
  final LatLng point;

  /// Bounding box of the place when it is an area (city, region, park...).
  final LatLngBounds? extent;

  final LocationCategory category;
  final String? osmKey;
  final String? osmValue;
  final String? osmType;
  final int? osmId;
  final String? iata;
  final LocationSearchSource source;

  const LocationSearchResult({
    required this.name,
    required this.subtitle,
    required this.countryCode,
    required this.point,
    required this.category,
    required this.source,
    this.extent,
    this.osmKey,
    this.osmValue,
    this.osmType,
    this.osmId,
    this.iata,
  });

  /// Identity used to drop duplicates when merging several result lists.
  String get dedupeKey {
    if (iata != null && iata!.isNotEmpty) return 'iata:$iata';
    if (osmType != null && osmId != null) return '$osmType$osmId';
    return '$name@${point.latitude.toStringAsFixed(5)},${point.longitude.toStringAsFixed(5)}';
  }

  /// Builds a result from one GeoJSON feature of `/stationAutocomplete`
  /// (Photon output, with the Trainlog server's name rewriting).
  /// Returns `null` when the feature has no usable coordinates.
  static LocationSearchResult? fromPhotonFeature(Map<String, dynamic> feature) {
    final geometry = feature['geometry'];
    final coords = geometry is Map ? geometry['coordinates'] : null;
    if (coords is! List || coords.length < 2) return null;
    final lng = coords[0], lat = coords[1];
    if (lng is! num || lat is! num) return null;

    final rawProps = feature['properties'];
    final props = rawProps is Map ? rawProps.cast<String, dynamic>() : <String, dynamic>{};
    String str(String key) => (props[key] as Object?)?.toString().trim() ?? '';

    final osmKey = str('osm_key');
    final osmValue = str('osm_value');
    final type = str('type');
    final city = str('city');
    final name = cleanServerName(str('name'), city);

    final street = [str('street'), str('housenumber')]
        .where((e) => e.isNotEmpty)
        .join(' ');
    final subtitleParts = <String>[];
    for (final part in [
      street,
      str('locality').isNotEmpty ? str('locality') : str('district'),
      city,
      str('state'),
      str('country'),
    ]) {
      if (part.isEmpty || part == name || subtitleParts.contains(part)) continue;
      subtitleParts.add(part);
    }

    final osmId = props['osm_id'];

    return LocationSearchResult(
      name: name.isNotEmpty ? name : subtitleParts.firstOrNull ?? '',
      subtitle: subtitleParts.join(', '),
      countryCode: str('countrycode').toUpperCase(),
      point: LatLng(lat.toDouble(), lng.toDouble()),
      extent: _parseExtent(props['extent']),
      category: categorize(osmKey, osmValue, type),
      osmKey: osmKey.isEmpty ? null : osmKey,
      osmValue: osmValue.isEmpty ? null : osmValue,
      osmType: str('osm_type').isEmpty ? null : str('osm_type'),
      osmId: osmId is num ? osmId.toInt() : int.tryParse('${osmId ?? ''}'),
      source: LocationSearchSource.photon,
    );
  }

  /// Builds a result from one entry of `/api/airportAutocomplete/`.
  static LocationSearchResult? fromAirportJson(Map<String, dynamic> json) {
    final lat = json['latitude'], lng = json['longitude'];
    if (lat is! num || lng is! num) return null;

    final iata = (json['iata'] as String? ?? '').trim();
    final name = (json['name'] as String? ?? '').trim();

    return LocationSearchResult(
      name: iata.isEmpty ? name : '$name ($iata)',
      subtitle: (json['city'] as String? ?? '').trim(),
      countryCode: (json['iso_country'] as String? ?? '').trim().toUpperCase(),
      point: LatLng(lat.toDouble(), lng.toDouble()),
      category: LocationCategory.airport,
      iata: iata.isEmpty ? null : iata,
      source: LocationSearchSource.airport,
    );
  }

  /// The Trainlog server prefixes names with `"<city> - "` when the city
  /// differs from the name. The city is already in the subtitle, so drop it.
  static String cleanServerName(String name, String city) {
    if (city.isEmpty) return name;
    final prefix = '$city - ';
    return name.startsWith(prefix) && name.length > prefix.length
        ? name.substring(prefix.length)
        : name;
  }

  /// Photon extent: `[minLon, maxLat, maxLon, minLat]`.
  static LatLngBounds? _parseExtent(Object? raw) {
    if (raw is! List || raw.length != 4 || raw.any((e) => e is! num)) {
      return null;
    }
    final v = raw.cast<num>().map((e) => e.toDouble()).toList();
    return LatLngBounds(LatLng(v[3], v[0]), LatLng(v[1], v[2]));
  }
}

/// Maps Photon's `osm_key` / `osm_value` / `type` to a [LocationCategory].
LocationCategory categorize(String? osmKey, String? osmValue, String? type) {
  final key = osmKey ?? '';
  final value = osmValue ?? '';

  switch (key) {
    case 'railway':
      if (value == 'tram_stop') return LocationCategory.tram;
      if (value == 'subway_entrance') return LocationCategory.metro;
      if (const {'station', 'halt', 'stop', 'platform'}.contains(value)) {
        return LocationCategory.railStation;
      }
      break;
    case 'public_transport':
      return value == 'station' || value == 'stop_area'
          ? LocationCategory.railStation
          : LocationCategory.busStop;
    case 'building':
      if (value == 'train_station') return LocationCategory.railStation;
      break;
    case 'highway':
      return value == 'bus_stop'
          ? LocationCategory.busStop
          : LocationCategory.street;
    case 'aeroway':
      if (const {'aerodrome', 'terminal', 'heliport', 'helipad'}.contains(value)) {
        return LocationCategory.airport;
      }
      break;
    case 'aerialway':
      return LocationCategory.aerialway;
    case 'tourism':
      return const {
        'hotel', 'hostel', 'motel', 'guest_house', 'apartment',
        'chalet', 'camp_site', 'caravan_site', 'alpine_hut', 'wilderness_hut',
      }.contains(value)
          ? LocationCategory.hotel
          : LocationCategory.tourism;
    case 'shop':
      return LocationCategory.shop;
    case 'amenity':
      final amenity = _amenityCategory(value);
      if (amenity != null) return amenity;
      break;
    case 'office':
      if (value == 'government') return LocationCategory.publicBuilding;
      break;
    case 'healthcare':
      return LocationCategory.health;
    case 'historic':
      return LocationCategory.tourism;
    case 'leisure':
      if (const {
        'stadium', 'sports_centre', 'pitch', 'golf_course', 'sports_hall',
        'swimming_pool', 'ice_rink', 'track', 'fitness_centre',
      }.contains(value)) {
        return LocationCategory.sport;
      }
      if (const {'park', 'garden', 'nature_reserve', 'common'}.contains(value)) {
        return LocationCategory.nature;
      }
      break;
    case 'sport':
      return LocationCategory.sport;
    case 'natural':
    case 'waterway':
      return LocationCategory.nature;
    case 'place':
      final place = _placeCategory(value);
      if (place != null) return place;
      break;
    case 'boundary':
      final fromType = _typeCategory(type);
      if (fromType != null && fromType != LocationCategory.other) return fromType;
      return LocationCategory.region;
  }

  return _typeCategory(type) ?? LocationCategory.other;
}

LocationCategory? _amenityCategory(String value) {
  if (value == 'bus_station') return LocationCategory.busStop;
  if (value == 'ferry_terminal') return LocationCategory.ferry;
  if (const {
    'restaurant', 'cafe', 'bar', 'pub', 'fast_food', 'food_court',
    'biergarten', 'ice_cream',
  }.contains(value)) {
    return LocationCategory.food;
  }
  if (const {
    'townhall', 'courthouse', 'police', 'fire_station', 'post_office',
    'library', 'community_centre', 'embassy', 'public_building',
    'social_facility', 'prison', 'post_depot',
  }.contains(value)) {
    return LocationCategory.publicBuilding;
  }
  if (const {'hospital', 'clinic', 'doctors', 'pharmacy', 'dentist'}.contains(value)) {
    return LocationCategory.health;
  }
  if (const {'school', 'university', 'college', 'kindergarten'}.contains(value)) {
    return LocationCategory.education;
  }
  if (const {'place_of_worship', 'monastery'}.contains(value)) {
    return LocationCategory.religion;
  }
  if (const {'theatre', 'cinema', 'arts_centre'}.contains(value)) {
    return LocationCategory.tourism;
  }
  return null;
}

LocationCategory? _placeCategory(String value) {
  if (const {'city', 'town', 'village', 'hamlet', 'municipality'}.contains(value)) {
    return LocationCategory.city;
  }
  if (const {
    'suburb', 'quarter', 'neighbourhood', 'borough', 'city_block', 'locality',
  }.contains(value)) {
    return LocationCategory.district;
  }
  if (const {
    'country', 'state', 'region', 'province', 'county', 'district',
    'island', 'archipelago',
  }.contains(value)) {
    return LocationCategory.region;
  }
  if (value == 'house') return LocationCategory.address;
  return null;
}

/// Fallback on Photon's coarse `type` (house, street, city, ...).
LocationCategory? _typeCategory(String? type) {
  switch (type) {
    case 'house':
      return LocationCategory.address;
    case 'street':
      return LocationCategory.street;
    case 'city':
      return LocationCategory.city;
    case 'district':
    case 'locality':
      return LocationCategory.district;
    case 'county':
    case 'state':
    case 'country':
      return LocationCategory.region;
    case 'other':
      return LocationCategory.other;
  }
  return null;
}
