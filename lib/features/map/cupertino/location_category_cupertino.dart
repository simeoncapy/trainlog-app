import 'package:flutter/cupertino.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:trainlog_app/core/data/models/location_search_result.dart';
import 'package:trainlog_app/ui/tokens/app_colors.dart';

/// iOS look of a map search result's category, drawn like a Settings icon:
/// a white glyph on a coloured rounded square. Transport takes the app's
/// mode colours, every other family one colour, places are grey.
extension LocationCategoryCupertino on LocationCategory {
  /// The glyph: an SF-like Cupertino icon where one exists, else a filled
  /// Material Symbol (see [cupertinoIconFilled]).
  IconData get cupertinoIcon => switch (this) {
    LocationCategory.railStation => CupertinoIcons.train_style_one,
    LocationCategory.metro => Symbols.subway,
    LocationCategory.tram => CupertinoIcons.tram_fill,
    LocationCategory.busStop => CupertinoIcons.bus,
    LocationCategory.ferry => Symbols.directions_boat,
    LocationCategory.airport => CupertinoIcons.airplane,
    LocationCategory.aerialway => Symbols.gondola_lift,
    LocationCategory.hotel => CupertinoIcons.bed_double_fill,
    LocationCategory.food => Symbols.restaurant,
    LocationCategory.shop => CupertinoIcons.bag_fill,
    LocationCategory.publicBuilding => Symbols.account_balance,
    LocationCategory.health => CupertinoIcons.bandage_fill,
    LocationCategory.education => CupertinoIcons.book_fill,
    LocationCategory.tourism => Symbols.museum,
    LocationCategory.religion => Symbols.church,
    LocationCategory.nature => CupertinoIcons.tree,
    LocationCategory.sport => CupertinoIcons.sportscourt_fill,
    LocationCategory.city => CupertinoIcons.building_2_fill,
    LocationCategory.district => Symbols.holiday_village,
    LocationCategory.region => CupertinoIcons.map_fill,
    LocationCategory.street => Symbols.road,
    LocationCategory.address => CupertinoIcons.house_fill,
    LocationCategory.other => CupertinoIcons.location_solid,
  };

  /// The glyph is a Material Symbol, to draw filled.
  bool get cupertinoIconFilled => switch (this) {
    LocationCategory.metro ||
    LocationCategory.ferry ||
    LocationCategory.aerialway ||
    LocationCategory.food ||
    LocationCategory.publicBuilding ||
    LocationCategory.tourism ||
    LocationCategory.religion ||
    LocationCategory.district ||
    LocationCategory.street => true,
    _ => false,
  };

  Color get cupertinoColor => switch (this) {
    LocationCategory.railStation => AppColors.modeTrain,
    LocationCategory.metro => AppColors.modeMetro,
    LocationCategory.tram => AppColors.modeTram,
    LocationCategory.busStop => AppColors.modeBus,
    LocationCategory.ferry => AppColors.modeFerry,
    LocationCategory.airport || LocationCategory.aerialway => AppColors.modeAir,
    LocationCategory.food => CupertinoColors.systemOrange,
    LocationCategory.hotel => CupertinoColors.systemIndigo,
    LocationCategory.shop => CupertinoColors.systemYellow,
    LocationCategory.health => CupertinoColors.systemRed,
    LocationCategory.education ||
    LocationCategory.publicBuilding => CupertinoColors.systemBlue,
    LocationCategory.tourism || LocationCategory.religion =>
      CupertinoColors.systemPink,
    LocationCategory.nature || LocationCategory.sport =>
      CupertinoColors.systemGreen,
    LocationCategory.city ||
    LocationCategory.district ||
    LocationCategory.region ||
    LocationCategory.street ||
    LocationCategory.address ||
    LocationCategory.other => CupertinoColors.systemGrey,
  };
}
