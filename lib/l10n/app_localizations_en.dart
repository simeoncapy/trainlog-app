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
  String get logoutButton => 'Log out';

  @override
  String get createAccountButton => 'Create an account';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get emailHelper => 'In case you forget your password';

  @override
  String get emailRequiredLabel => 'Email is required';

  @override
  String get emailValidLabel => 'Enter a valid email';

  @override
  String get usernameLabel => 'Username';

  @override
  String get usernameRequiredLabel => 'Username is required';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordShowLabel => 'Show password';

  @override
  String get passwordHideLabel => 'Hide password';

  @override
  String get passwordRequiredLabel => 'Password is required';

  @override
  String get createAccountButtonShort => 'Create';

  @override
  String get loginToYourAccount => 'Log in to your account';

  @override
  String menuHello(Object username) {
    return 'Hello $username';
  }

  @override
  String get connectionError => 'Login failed, please check your credentials';

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
  String get settingsDisplayUserMarker => 'Display current position';

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
  String get typeAerialway => 'Aerialway';

  @override
  String get typeWalk => 'Walk';

  @override
  String get typePoi => 'Point of interest';

  @override
  String get typeCycle => 'Bicycle';

  @override
  String get typeHelicopter => 'Helicopter';

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
  String get tripsDetailsEditButton => 'Edit';

  @override
  String get tripsDetailsDeleteButton => 'Delete';

  @override
  String get tripsFilterAllCountry => 'All';

  @override
  String get tripsFilterAllOperator => 'All';

  @override
  String get tripsFilterAllYears => 'All Years';

  @override
  String get tripsFilterKeyword => 'Keyword';

  @override
  String get tripsFilterDateFrom => 'On';

  @override
  String get tripsFilterDateTo => 'to (optional)';

  @override
  String get tripsFilterCountry => 'Country';

  @override
  String get tripsFilterOperator => 'Operator';

  @override
  String get tripsFilterType => 'Vehicle Type';

  @override
  String get filterClearButton => 'Clear filter';

  @override
  String get graphTypeOperator => 'Operator';

  @override
  String get graphTypeCountry => 'Country';

  @override
  String get graphTypeYears => 'Years';

  @override
  String get graphTypeMaterial => 'Material';

  @override
  String get graphTypeItinerary => 'Itinerary';

  @override
  String graphTypeStations(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'train': 'Stations',
      'plane': 'airports',
      'bus': 'Stops',
      'tram': 'Stations',
      'metro': 'Stations',
      'ferry': 'Ports',
      'other': 'Locations',
    });
    return '$_temp0';
  }

  @override
  String get statisticsGraphUnitTrips => 'Trips';

  @override
  String get statisticsGraphUnitDistance => 'Distance';

  @override
  String get statisticsGraphUnitDuration => 'Duration';

  @override
  String get statisticsGraphUnitCo2 => 'CO2';

  @override
  String get statisticsDisplayFilters => 'Display the filters';

  @override
  String get statisticsHideFilters => 'Hide the filters';

  @override
  String get statisticsTripsUnitBase => 'trips';

  @override
  String get statisticsTripsUnitKilo => 'thousand trips';

  @override
  String get statisticsTripsUnitMega => 'million trips';

  @override
  String get statisticsTripsUnitGiga => 'billion trips';

  @override
  String get statisticsOtherLabel => 'Other';

  @override
  String get statisticsTotalLabel => 'Total';

  @override
  String get statisticsUnitLabel => 'Unit:';

  @override
  String get statisticsNoDataLabel => 'No data';

  @override
  String get internationalWaters => 'International waters';

  @override
  String get addTripPageTitle => 'Add a Trip';

  @override
  String get addTripStepDetails => 'Details';

  @override
  String get addTripStepPath => 'Path';

  @override
  String get addTripStepValidate => 'Validate';
}
