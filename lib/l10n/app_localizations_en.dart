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
  String get appVersion => 'App version:';

  @override
  String get mainMenuButtonTooltip => 'Open menu';

  @override
  String get filterButton => 'Filter';

  @override
  String get descendingOrder => 'Descending order';

  @override
  String get ascendingOrder => 'Ascending order';

  @override
  String get deleteAll => 'Delete all';

  @override
  String get deleteSelection => 'Delete selection';

  @override
  String get loginButton => 'Log in';

  @override
  String get logoutButton => 'Log out';

  @override
  String get loggedOut => 'Logged out';

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
  String get refreshCompleted => 'Refresh completed';

  @override
  String get nextButton => 'Next';

  @override
  String get previousButton => 'Previous';

  @override
  String get validateButton => 'Validate';

  @override
  String get continueButton => 'Continue';

  @override
  String get nameField => 'Name';

  @override
  String get auto => 'Auto';

  @override
  String get energy => 'Energy';

  @override
  String get energyElectric => 'Electric';

  @override
  String get energyElectricShort => 'Elec.';

  @override
  String get energyThermic => 'Fuel';

  @override
  String get energyThermicShort => 'Fuel';

  @override
  String get energyHydrogen => 'Hydrogen';

  @override
  String get energyHydrogenShort => 'H2';

  @override
  String get manual => 'manual';

  @override
  String get fillRequiredFields => 'Please fill the required fields';

  @override
  String get facultative => 'facultative';

  @override
  String get visibility => 'Visibility';

  @override
  String get visibilityPublic => 'Public';

  @override
  String get visibilityFriends => 'Friends';

  @override
  String get visibilityPrivate => 'Private';

  @override
  String get helpTitle => 'Help';

  @override
  String get pageNotImplementedYet =>
      'This page has not been implemented in the application yet. The website version will be displayed instead. The user interface may not be optimal.';

  @override
  String get departureSingleCharacter => 'D';

  @override
  String get arrivalSingleCharacter => 'A';

  @override
  String get locationServicesDisabled => 'Location services are disabled';

  @override
  String get locationPermissionDenied => 'Location permission denied';

  @override
  String get duplicateBtnLabel => 'Duplicate';

  @override
  String get settingsAppCategory => 'App Settings';

  @override
  String get settingsMapCategory => 'Map Settings';

  @override
  String get settingsAccountCategory => 'Account Settings';

  @override
  String get settingsDangerZoneCategory => 'Danger Zone';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsThemeMode => 'Theme Mode';

  @override
  String get settingsDark => 'Dark';

  @override
  String get settingsLight => 'Light';

  @override
  String get settingsDateFormat => 'Date Format';

  @override
  String get settingsHourFormat12 => '12-hour format';

  @override
  String get settingsExampleShort => 'Ex:';

  @override
  String get settingsCurrency => 'Default Currency';

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
  String get settingsMapColorPaletteColourBlind =>
      'Palette for colour blindness';

  @override
  String get settingsMapColorPaletteTrainlogRed => 'Red';

  @override
  String get settingsMapColorPaletteTrainlogGreen => 'Green';

  @override
  String get settingsMapColorPaletteTrainlogBlue => 'Blue';

  @override
  String get settingsMapColorPaletteVibrantTones => 'Vibrant Tones';

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
  String get settingsDeleteAccount => 'Delete my account';

  @override
  String get settingsDeleteAccountRequest => 'Request';

  @override
  String settingsDeleteAccountError(Object email) {
    return 'Unable to open email client, request at $email';
  }

  @override
  String get settingsHideWarningMessage => 'Hide warning messages';

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
  String get menuSmartPrerecorderTitle => 'WayStamp';

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
  String typeStation(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'train': 'Station',
      'plane': 'Airport',
      'bus': 'Stop',
      'tram': 'Station',
      'metro': 'Station',
      'ferry': 'Port',
      'helicopter': 'Heliport',
      'aerialway': 'Station',
      'other': 'Location',
    });
    return '$_temp0';
  }

  @override
  String typeStations(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'train': 'Stations',
      'plane': 'Airports',
      'bus': 'Stops',
      'tram': 'Stations',
      'metro': 'Stations',
      'ferry': 'Ports',
      'helicopter': 'Heliports',
      'aerialway': 'Stations',
      'other': 'Locations',
    });
    return '$_temp0';
  }

  @override
  String typeStationAddress(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'train': 'Address of the station',
      'plane': 'Address of the airport',
      'bus': 'Address of the stop',
      'tram': 'Address of the station',
      'metro': 'Address of the station',
      'ferry': 'Address of the port',
      'helicopter': 'Address of the heliport',
      'aerialway': 'Address of the station',
      'other': 'Address of the location',
    });
    return '$_temp0';
  }

  @override
  String enterStation(String direction, String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'train': 'Please enter the departure station',
      'plane': 'Please enter the departure airport',
      'bus': 'Please enter the departure stop',
      'tram': 'Please enter the departure station',
      'metro': 'Please enter the departure station',
      'ferry': 'Please enter the departure port',
      'helicopter': 'Please enter the departure heliport',
      'aerialway': 'Please enter the departure station',
      'other': 'Please enter the departure location',
    });
    String _temp1 = intl.Intl.selectLogic(type, {
      'train': 'Please enter the arrival station',
      'plane': 'Please enter the arrival airport',
      'bus': 'Please enter the arrival stop',
      'tram': 'Please enter the arrival station',
      'metro': 'Please enter the arrival station',
      'ferry': 'Please enter the arrival port',
      'helicopter': 'Please enter the arrival heliport',
      'aerialway': 'Please enter the arrival station',
      'other': 'Please enter the arrival location',
    });
    String _temp2 = intl.Intl.selectLogic(type, {
      'train': 'Please enter the station',
      'plane': 'Please enter the airport',
      'bus': 'Please enter the stop',
      'tram': 'Please enter the station',
      'metro': 'Please enter the station',
      'ferry': 'Please enter the port',
      'helicopter': 'Please enter the heliport',
      'aerialway': 'Please enter the station',
      'other': 'Please enter the location',
    });
    String _temp3 = intl.Intl.selectLogic(direction, {
      'departure': '$_temp0',
      'arrival': '$_temp1',
      'other': '$_temp2',
    });
    return '$_temp3';
  }

  @override
  String manualNameStation(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'train': 'Manual name of the station',
      'plane': 'Manual name of the airport',
      'bus': 'Manual name of the stop',
      'tram': 'Manual name of the station',
      'metro': 'Manual name of the station',
      'ferry': 'Manual name of the port',
      'helicopter': 'Manual name of the heliport',
      'aerialway': 'Manual name of the station',
      'other': 'Manual name of the location',
    });
    return '$_temp0';
  }

  @override
  String searchStationHint(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'train': 'Search station...',
      'plane': 'Search airport...',
      'bus': 'Search stop...',
      'tram': 'Search station...',
      'metro': 'Search station...',
      'ferry': 'Search port...',
      'helicopter': 'Search heliport...',
      'aerialway': 'Search station...',
      'other': 'Search location...',
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
  String get statisticsPieWip => 'The pie chart is WIP';

  @override
  String get internationalWaters => 'International waters';

  @override
  String get addTripPageTitle => 'Add a Trip';

  @override
  String get addTripStepBasics => 'Basics';

  @override
  String get addTripStepDate => 'Date';

  @override
  String get addTripStepDetails => 'Details';

  @override
  String get addTripStepPath => 'Path';

  @override
  String get addTripStepValidate => 'Validate';

  @override
  String get addTripTransportationMode => 'Transportation mode';

  @override
  String get addTripImportFr24 => 'Import flight data from FR24';

  @override
  String get addTipSearchStation => 'Search ';

  @override
  String get addTripManualDeparture => 'Manual departure';

  @override
  String get addTripManualArrival => 'Manual arrival';

  @override
  String get addTripDeparture => 'Departure';

  @override
  String get addTripArrival => 'Arrival';

  @override
  String get addTripLatitudeShort => 'Lat';

  @override
  String get addTripLongitudeShort => 'Long';

  @override
  String get addTripMapUsageHelper =>
      'In manual mode you can enter the coordinates directly or move the marker to the desired position after expanding the map.';

  @override
  String get addTripOperator => 'Operator';

  @override
  String get addTripOperatorHelper =>
      'Use a comma or enter to validate an unknown operator';

  @override
  String get addTripOperatorHint => 'Search operator...';

  @override
  String get addTripOperatorPlaceholderLogo => 'Select an operator';

  @override
  String get addTripLine => 'Line';

  @override
  String get addTripDateTypePrecise => 'Precise';

  @override
  String get addTripDateTypeUnknown => 'Unknown';

  @override
  String get addTripDateTypeDate => 'Date';

  @override
  String get addTripStartDate => 'Start of the trip';

  @override
  String get addTripEndDate => 'End of the trip';

  @override
  String get addTripDuration => 'Duration';

  @override
  String get addTripPast => 'Past';

  @override
  String get addTripFuture => 'Future';

  @override
  String get timezoneInformation =>
      'The time zones are based on the coordinates of the departure and the arrival.';

  @override
  String get addTripDepartureAfterArrival => 'Departure after arrival!';

  @override
  String get addTripFacultative => 'Facultative fields';

  @override
  String get addTripMaterial => 'Material';

  @override
  String get addTripRegistration => 'Registration';

  @override
  String get addTripSeat => 'Seat';

  @override
  String get addTripNotes => 'Note';

  @override
  String get addTripTicketTitle => 'Ticket';

  @override
  String get addTripTicketPrice => 'Ticket price';

  @override
  String get addTripPurchaseDate => 'Purchase date';

  @override
  String get continueTripButton => 'Validate and continue the trip';

  @override
  String get addTripPathUseNewRouter => 'Use the new router';

  @override
  String addTripNameEnd(String departure, String arrival) {
    return '$departure to $arrival';
  }

  @override
  String get addTripPathHelp =>
      'The new router is in beta and shows electrification.\n\nThe routers (old and new) are the same for train, tram, and metro. You may need to fine-tune the peg placement to get it to route on the desired path.';

  @override
  String get addTicketPageTitle => 'New Ticket';

  @override
  String get addTagPageTitle => 'New Tag';

  @override
  String get aboutPageAboutSubPageTitle => 'Trainlog';

  @override
  String get aboutPageHowToSubPageTitle => 'How To';

  @override
  String get aboutPagePrivacySubPageTitle => 'Privacy';

  @override
  String get supportTrainlogButton => 'Support Trainlog';

  @override
  String get joinDiscordButton => 'Join the community on Discord';

  @override
  String get websiteRepoButton => 'Repository of the website';

  @override
  String get applicationRepoButton => 'Repository of the application';

  @override
  String get pageNotAvailableInUserLanguage =>
      'This page is currently displayed in English because it is not yet available in **your language**.';

  @override
  String get tableOfContents => 'Table of content';

  @override
  String get prerecorderExplanationTitle => 'Explanation';

  @override
  String get prerecorderExplanation =>
      'The WayStamp tool is a smart pre-recorder. When you click on the record button, it will automatically save your current coordinate with the date and time. Later on, you could select two stamps and use them to create a new trip with the saved data.';

  @override
  String get prerecorderExplanationStation =>
      'This tool will automatically look for the station name and display it if found (this works only for rail, bus, and ferry). The closest station to you will be used.';

  @override
  String get prerecorderExplanationDelete =>
      'After the trip has been created, the two stamps are automatically deleted.';

  @override
  String get prerecorderExplanationPrivacy =>
      'The data are saved on your device only.';

  @override
  String get prerecorderRecordButton => 'Record';

  @override
  String get prerecorderCreateTripButton => 'Create a trip';

  @override
  String get prerecorderNoData => 'No data recorded';

  @override
  String get prerecorderUnknownStation => 'Unknown station';

  @override
  String get prerecorderDeleteSelectionConfirm =>
      'Are you sure to delete the selection? This action is irreversible.';

  @override
  String get prerecorderDeleteAllConfirm =>
      'Are you sure to delete all the recorded stamps? This action is irreversible.';
}
