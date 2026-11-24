import 'package:flutter/material.dart';

import 'package:trainlog_app/core/data/models/ranking.dart';
import 'package:trainlog_app/core/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/tokens/app_colors.dart';

export 'package:trainlog_app/core/data/models/ranking.dart';

// How the ranking model (core/data/models/ranking.dart) is shown: labels,
// icons and accent colours.

extension RankingTypeView on RankingType {
  /// Localized label for the category pill (vehicle pills use the vehicle name).
  String label(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    switch (this) {
      case RankingType.all:
        return loc.rankingTypeTotal;
      case RankingType.vehicles:
        return loc.rankingTypeVehicles;
      case RankingType.railwayCoverage:
        return loc.rankingTypeRailwayCoverage;
      case RankingType.worldSquares:
        return loc.rankingTypeWorld;
      case RankingType.country:
        return loc.rankingTypeCountries;
      case RankingType.carbon:
        return loc.rankingTypeCarbon;
    }
  }

  /// Contextually relevant icon for the non-vehicle categories.
  Icon get icon {
    switch (this) {
      case RankingType.all:
        return const Icon(Icons.emoji_events);
      case RankingType.vehicles:
        return const Icon(Icons.directions_transit);
      case RankingType.railwayCoverage:
        return const Icon(Icons.percent);
      case RankingType.worldSquares:
        return const Icon(Icons.grid_on);
      case RankingType.country:
        return const Icon(Icons.public);
      case RankingType.carbon:
        return const Icon(Icons.eco);
    }
  }

  /// Accent colour: from the user's vehicle [palette] for a vehicle, else
  /// the category's own.
  Color accentColor([VehicleType? vehicle, Map<VehicleType, Color>? palette]) {
    if (this == RankingType.vehicles && vehicle != null && palette != null) {
      return palette[vehicle] ?? AppColors.amber;
    }
    switch (this) {
      case RankingType.all:
        return AppColors.amber;
      case RankingType.worldSquares:
        return AppColors.modeFerry;
      case RankingType.railwayCoverage:
        return AppColors.modeTram;
      case RankingType.country:
        return AppColors.blue;
      case RankingType.carbon:
        return AppColors.successLight;
      case RankingType.vehicles:
        return AppColors.sky;
    }
  }
}

extension RankingSortUnitView on RankingSortUnit {
  String label(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    switch (this) {
      case RankingSortUnit.distance:
        return loc.distance;
      case RankingSortUnit.trips:
        return loc.rankingUnitTrips;
      case RankingSortUnit.totalCarbon:
        return loc.rankingUnitTotalCarbon;
      case RankingSortUnit.carbonPerKm:
        return loc.rankingUnitCarbonPerKm;
    }
  }

  Icon get icon {
    switch (this) {
      case RankingSortUnit.distance:
        return const Icon(Icons.straighten);
      case RankingSortUnit.trips:
        return const Icon(Icons.confirmation_number_outlined);
      case RankingSortUnit.totalCarbon:
        return const Icon(Icons.cloud_outlined);
      case RankingSortUnit.carbonPerKm:
        return const Icon(Icons.eco);
    }
  }
}

extension RankingSelectionView on RankingSelection {
  /// Pill label: the vehicle name for vehicle selections, the type label
  /// otherwise.
  String label(BuildContext context) =>
      isVehicle ? VehicleType.labelOf(vehicle!, context) : type.label(context);

  /// Pill icon: the vehicle icon for vehicle selections, the type icon
  /// otherwise.
  Icon get icon => isVehicle ? VehicleType.iconOf(vehicle!) : type.icon;

  /// Accent colour for the pill.
  ///
  /// Vehicle selections take their colour from the user's vehicle [palette];
  /// the category types use their own fixed accent.
  Color accentColor(Map<VehicleType, Color> palette) {
    return type.accentColor(vehicle, palette);
  }
}

extension CarbonThresholdView on CarbonThreshold {
  Color color() {
    switch (this) {
      case CarbonThreshold.green:
        return AppColors.early;
      case CarbonThreshold.medium:
        return AppColors.amber;
      case CarbonThreshold.high:
        return AppColors.late;
    }
  }
}

/// Colour of a carbon intensity (grams of CO2e per km).
Color carbonColorOf(num value) => CarbonThreshold.forValue(value).color();
