import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:trainlog_app/data/models/location_search_result.dart';

/// Icon shown next to each map search result.
extension LocationCategoryIcon on LocationCategory {
  IconData get icon => switch (this) {
        LocationCategory.railStation => Symbols.train,
        LocationCategory.metro => Symbols.subway,
        LocationCategory.tram => Symbols.tram,
        LocationCategory.busStop => Symbols.directions_bus,
        LocationCategory.ferry => Symbols.directions_boat,
        LocationCategory.airport => Symbols.flight,
        LocationCategory.aerialway => Symbols.gondola_lift,
        LocationCategory.hotel => Symbols.hotel,
        LocationCategory.food => Symbols.restaurant,
        LocationCategory.shop => Symbols.storefront,
        LocationCategory.publicBuilding => Symbols.account_balance,
        LocationCategory.health => Symbols.local_hospital,
        LocationCategory.education => Symbols.school,
        LocationCategory.tourism => Symbols.museum,
        LocationCategory.religion => Symbols.church,
        LocationCategory.nature => Symbols.park,
        LocationCategory.sport => Symbols.stadium,
        LocationCategory.city => Symbols.location_city,
        LocationCategory.district => Symbols.holiday_village,
        LocationCategory.region => Symbols.map,
        LocationCategory.street => Symbols.road,
        LocationCategory.address => Symbols.home,
        LocationCategory.other => Symbols.location_on,
      };

  /// Zoom used when centring on a result that has no extent.
  double get focusZoom => switch (this) {
        LocationCategory.region => 7,
        LocationCategory.city => 12,
        LocationCategory.district => 14,
        LocationCategory.airport => 13,
        LocationCategory.street => 16,
        _ => 17,
      };
}
