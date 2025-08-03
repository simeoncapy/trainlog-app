// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Trainlog';

  @override
  String get language => 'English';

  @override
  String get mainMenuButtonTooltip => 'Open menu';

  @override
  String get filterButton => 'Filter';

  @override
  String get loginButton => 'Log in';

  @override
  String get createAccountButton => 'Create an account';

  @override
  String get settingsAppCategory => 'App Settings';

  @override
  String get settingsMapCategory => 'Map Settings';

  @override
  String get settingsAccountCategory => 'Account Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsThemeMode => 'Theme Mode';

  @override
  String get settingsDark => 'Dark';

  @override
  String get settingsLight => 'Light';

  @override
  String get settingsSystem => 'System';

  @override
  String get settingsMapPathDisplayOrder => 'Order of trip paths on the map';

  @override
  String get settingMapPathDisplayOrderByCreation => 'By creation date';

  @override
  String get settingMapPathDisplayOrderByTrip => 'By trip date';

  @override
  String get settingMapPathDisplayOrderByTripAndPlane =>
      'By trip date (with flights above)';

  @override
  String get settingsMapColorPalette => 'Colour palette for trips';

  @override
  String get settingsMapColorPaletteTrainlogWeb => 'Trainlog Web';

  @override
  String get settingsMapColorPaletteTrainlogVariation => 'Trainlog Variation';

  @override
  String get settingsMapColorPaletteTrainlogRed => 'Red';

  @override
  String get settingsMapColorPaletteTrainlogGreen => 'Green';

  @override
  String get settingsMapColorPaletteTrainlogBlue => 'Blue';

  @override
  String settingsCache(Object size) {
    return 'Cached data ($size MiB)';
  }

  @override
  String get settingsCacheClearButton => 'Clear';

  @override
  String get settingsCacheClearConfirmTitle => 'Clear cache?';

  @override
  String get settingsCacheClearConfirmMessage =>
      'Are you sure you want to delete the cached data? This action is irreversible. The next loading of the app might take longer.';

  @override
  String get settingsCacheClearedMessage => 'Cache cleared successfully.';

  @override
  String get menuMapTitle => 'Map';

  @override
  String get menuTripsTitle => 'Trips';

  @override
  String get menuRankingTitle => 'Ranking';

  @override
  String get menuStatisticsTitle => 'Statistics';

  @override
  String get menuCoverageTitle => 'Coverage';

  @override
  String get menuTagsTitle => 'Tags';

  @override
  String get menuTicketsTitle => 'Tickets';

  @override
  String get menuFriendsTitle => 'Friends';

  @override
  String get menuSettingsTitle => 'Settings';

  @override
  String get menuAboutTitle => 'About';

  @override
  String get tripPathLoading => 'Trips\' path loading, please wait';

  @override
  String get yearTitle => 'Years';

  @override
  String get yearAllList => 'All';

  @override
  String get yearPastList => 'Past';

  @override
  String get yearFutureList => 'Future';

  @override
  String get yearYearList => 'Years...';

  @override
  String get typeTitle => 'Vehicle Types';

  @override
  String get typeTrain => 'Train';

  @override
  String get typeTram => 'Tramway';

  @override
  String get typeMetro => 'Metro';

  @override
  String get typeBus => 'Bus';

  @override
  String get typeCar => 'Car';

  @override
  String get typePlane => 'Plane';

  @override
  String get typeFerry => 'Ferry';

  @override
  String get tripsTableHeaderOriginDestination => 'Origin/Destination';

  @override
  String get tripsTableHeaderOrigin => 'Origin';

  @override
  String get tripsTableHeaderDestination => 'Destination';

  @override
  String get tripsTableHeaderStartTime => 'Departure Time';

  @override
  String get tripsTableHeaderEndTime => 'Arrival Time';

  @override
  String get tripsTableHeaderOperator => 'Operator';

  @override
  String get tripsTableHeaderLineName => 'Line';

  @override
  String get tripsTableHeaderTripLength => 'Length';

  @override
  String tripsDetailTitle(Object vehicle) {
    return 'Trip in $vehicle';
  }

  @override
  String get tripsDetailsTitleOperator => 'Operator: ';

  @override
  String get tripsDetailsTitleVehicle => 'Vehicle: ';

  @override
  String get tripsDetailsTitleSeat => 'Seat: ';

  @override
  String get tripsDetailsTitlePrice => 'Price: ';

  @override
  String tripsDetailPurchasedDate(Object date) {
    return 'purchased on $date';
  }

  @override
  String get tripsDetailsTitleNotes => 'Notes: ';

  @override
  String get tripsFilterAllCountry => 'All';

  @override
  String get tripsFilterAllOperator => 'All';

  @override
  String get tripsFilterKeyword => 'Keyword';

  @override
  String get tripsFilterDateFrom => 'Date from';

  @override
  String get tripsFilterDateTo => 'to (optional)';

  @override
  String get tripsFilterCountry => 'Country';

  @override
  String get tripsFilterOperator => 'Operator';

  @override
  String get tripsFilterType => 'Vehicle Type';
}
