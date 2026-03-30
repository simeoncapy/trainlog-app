// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tagalog (`tl`).
class AppLocalizationsTl extends AppLocalizations {
  AppLocalizationsTl([String locale = 'tl']) : super(locale);

  @override
  String get appTitle => 'Trainlog';

  @override
  String get language => 'Tagalog';

  @override
  String get languageWithEmoji => '🇵🇭 Tagalog';

  @override
  String get appVersion => 'App version';

  @override
  String get appVersionCopied => 'Nakopya na ang version number';

  @override
  String get mainMenuButtonTooltip => 'Ibukas ang menu';

  @override
  String get filterButton => 'Filter';

  @override
  String get descendingOrder => 'I-ayos Pababa';

  @override
  String get ascendingOrder => 'I-ayos Paakyat';

  @override
  String get deleteAll => 'Ibura lahat';

  @override
  String get deleteAllShort => 'Lahat';

  @override
  String get deleteSelection => 'Ibura ang selection';

  @override
  String get deleteSelectionShort => 'Selection';

  @override
  String get loginButton => 'Login';

  @override
  String get logoutButton => 'Logout';

  @override
  String get loggedOut => 'Na log out na';

  @override
  String get createAccountButton => 'Gumawa ng account';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'ikaw@example.com';

  @override
  String get emailHelper => 'Kung sakali nakalimutan ang password';

  @override
  String get emailRequiredLabel => 'Kailangan ang email';

  @override
  String get emailValidLabel => 'Gumamit ng tamang email';

  @override
  String get usernameLabel => 'Username';

  @override
  String get usernameRequiredLabel => 'Kailangan ang username';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordShowLabel => 'Ipakita ang password';

  @override
  String get passwordHideLabel => 'Itago ang password';

  @override
  String get passwordRequiredLabel => 'Kailangan ang password';

  @override
  String get createAccountButtonShort => 'Gumawa';

  @override
  String get loginToYourAccount => 'Mag login sa account ';

  @override
  String menuHello(Object username) {
    return 'Kamusta $username';
  }

  @override
  String get connectionError => 'May mali sa credentials mo';

  @override
  String get refreshCompleted => 'Na refresh na';

  @override
  String get nextButton => 'Sunod';

  @override
  String get previousButton => 'Balik';

  @override
  String get validateButton => 'Validate';

  @override
  String get continueButton => 'Tumuloy';

  @override
  String get nameField => 'Pangalan';

  @override
  String get auto => 'Auto';

  @override
  String get energy => 'Enerhiya';

  @override
  String get energyElectric => 'Kuryente';

  @override
  String get energyElectricShort => 'Elec. ';

  @override
  String get energyThermic => 'Langis';

  @override
  String get energyThermicShort => 'Langis';

  @override
  String get energyHydrogen => 'Hydrogen';

  @override
  String get energyHydrogenShort => 'H2';

  @override
  String get manual => 'manual';

  @override
  String get fillRequiredFields => 'Ipasok ang lahat ng bagay';

  @override
  String get facultative => 'hindi kailangan';

  @override
  String get visibility => 'Visibility';

  @override
  String get visibilityPublic => 'Pampubliko';

  @override
  String get visibilityPublicLong => 'Lakbay pampubiklo';

  @override
  String get visibilityFriends => 'Kaibigan';

  @override
  String get visibilityFriendsLong => 'Ipakita sa kaibigan lamang';

  @override
  String get visibilityPrivate => 'Pribado';

  @override
  String get visibilityPrivateLong => 'Lakbay pribado ';

  @override
  String get visibilityRestricted => 'Tago';

  @override
  String get visibilityRestrictedLong => 'Tagong lakbay';

  @override
  String get helpTitle => 'Tulong';

  @override
  String get pageNotImplementedYet =>
      'Hindi pa nagagawa ang page. Maipapakita lamang ang website version. Hindi optimized ang user interface ';

  @override
  String get departureSingleCharacter => 'D';

  @override
  String get arrivalSingleCharacter => 'A';

  @override
  String get locationServicesDisabled =>
      'Hindi available ang location services';

  @override
  String get locationPermissionDenied => 'Bawal pumasok';

  @override
  String get duplicateBtnLabel => 'Idoble ';

  @override
  String get newBadge => 'BAGO';

  @override
  String nbrPassengers(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pasahero',
      one: '$count pasahero',
      zero: '$count pasahero',
    );
    return '$_temp0';
  }

  @override
  String get dialogueDefaultInfoTitle => 'Impormasyon';

  @override
  String get dialogueChangeInstanceTitle => 'Ibago ang trainlog instance';

  @override
  String get dialogueChangeInstanceButton => 'Ibago';

  @override
  String get dialogueChangeInstanceCustomLabel => 'Custom instance ';

  @override
  String get daySingleCharacter => 'D';

  @override
  String get setBtnLabel => 'Iset';

  @override
  String get settingsAppCategory => 'App Settings';

  @override
  String get settingsMapCategory => 'Map Settings';

  @override
  String get settingsAccountCategory => 'Account Settings';

  @override
  String get settingsDangerZoneCategory => 'Mapanganib na lugar';

  @override
  String get settingsLanguage => 'Lengwahe';

  @override
  String get settingsThemeMode => 'Thema ';

  @override
  String get settingsDark => 'Madilim';

  @override
  String get settingsLight => 'Maliwanag';

  @override
  String get settingsDateFormat => 'Petsa';

  @override
  String get settingsHourFormat12 => '12 oras';

  @override
  String get settingsExampleShort => 'Hal:';

  @override
  String get settingsCurrency => 'Default currency';

  @override
  String get settingsSprRadius =>
      'Pinakamalaking radius para sa paghahanap ng istasyon sa Geolog';

  @override
  String get settingsSystem => 'Sistema';

  @override
  String get settingsMapPathDisplayOrder =>
      'Ayos ng mga ruta ng biyahe sa mapa';

  @override
  String get settingMapPathDisplayOrderByCreation =>
      'Ayusin ayon sa petsa ng paglikha';

  @override
  String get settingMapPathDisplayOrderByTrip =>
      'Ayusin ayon sa petsa ng lakbay';

  @override
  String get settingMapPathDisplayOrderByTripAndPlane =>
      'Ayusin ayon sa petsa ng lakbay (kasama ang flights)';

  @override
  String get settingsMapColorPalette => 'Kulay ng trip';

  @override
  String get settingsMapColorPaletteTrainlogWeb => 'Trainlog Web';

  @override
  String get settingsMapColorPaletteColourBlind => 'Kulay para sa colorblind';

  @override
  String get settingsMapColorPaletteTrainlogRed => 'Pula';

  @override
  String get settingsMapColorPaletteTrainlogGreen => 'Berde';

  @override
  String get settingsMapColorPaletteTrainlogBlue => 'Asul';

  @override
  String get settingsMapColorPaletteVibrantTones => 'Matingkad na kulay';

  @override
  String settingsCache(Object size) {
    return 'Cached data ($size MiB)';
  }

  @override
  String get settingsCacheClearButton => 'Ibura';

  @override
  String get settingsCacheClearConfirmTitle => 'Ibura ang cache?';

  @override
  String get settingsCacheClearConfirmMessage =>
      'Sigurado ka bang gusto mong tanggalin ang naka-cache na data? Hindi na ito maibabalik. Maaaring mas matagal ang susunod na pag-load ng app.';

  @override
  String get settingsCacheClearedMessage => 'Nabura ang cache';

  @override
  String get settingsDisplayUserMarker => 'Ipakita ang kasalukurang lugar';

  @override
  String get settingsDeleteAccount => 'Ibura ang account';

  @override
  String get settingsDeleteAccountRequest => 'Request';

  @override
  String settingsDeleteAccountError(Object email) {
    return 'Hindi kaya ibukas ang email client, request sa $email';
  }

  @override
  String get settingsHideWarningMessage => 'Itago ang babala';

  @override
  String get settingsAccountLeaderboard =>
      'Lumabas sa pampublikong leaderboard';

  @override
  String get settingsAccountFriendSearch => 'Lumabas sa friend search';

  @override
  String get settingsAccountAppearGlobal => 'Lumabas sa global live map';

  @override
  String get settingsAccountAppearGlobalSubtitle =>
      '(byaheng pamubliko lamang)';

  @override
  String get settingsAccountVisibility => 'Visibility sa iba';

  @override
  String get settingsAccountVisibilitPrivateHelper =>
      'Ang iyong account ay nananatiling ganap na pribado. Walang sinuman ang maaaring tumingin sa anumang detalye o nilalaman.';

  @override
  String get settingsAccountVisibilitRestrictedHelper =>
      'Maaaring ibahagi ang mga indibidwal na biyahe gamit ang mga trip-ID, na nagtatago ng personal na data. Ngunit ang pampublikong profile ay nananatiling hindi maa-access.';

  @override
  String get settingsAccountVisibilitPublicHelper =>
      'Ang public profile mo ay maa-access gamit ang username mo.';

  @override
  String get settingsInstanceUrl => 'Trainlog instance';

  @override
  String get settingsInstanceMsg =>
      'Maari mo ibago ang path ng Trainlog instance gamit ang application sa login page';

  @override
  String get menuMapTitle => 'Mapa';

  @override
  String get menuTripsTitle => 'Byahe';

  @override
  String get menuRankingTitle => 'Ranking';

  @override
  String get menuStatisticsTitle => 'Istatistika';

  @override
  String get menuCoverageTitle => 'Sakop';

  @override
  String get menuTagsTitle => 'Tags';

  @override
  String get menuTicketsTitle => 'Tiket';

  @override
  String get menuFriendsTitle => 'Friends';

  @override
  String get menuSmartPrerecorderTitle => 'Geolog';

  @override
  String get menuSettingsTitle => 'Settings';

  @override
  String get menuAboutTitle => 'Tungkol sa app';

  @override
  String get menuIosMore => 'More';

  @override
  String get mapFilterYearsAllBtn => 'Lahat';

  @override
  String get mapFilterYearsNoneBtn => 'Wala';

  @override
  String get mapFilterVehicleTypeAllBtn => 'Lahat';

  @override
  String get mapFilterVehicleTypeNoneBtn => 'Wala';

  @override
  String get tripPathLoading =>
      'Ang byahe mo ay nag loload, mag hintay ng saglit';

  @override
  String get yearTitle => 'Taon';

  @override
  String get yearAllList => 'Lahat';

  @override
  String get yearPastList => 'Nakaraan';

  @override
  String get yearFutureList => 'Kinabukasan';

  @override
  String get yearYearList => 'Taon...';

  @override
  String get typeTitle => 'Uri ng sasakyan';

  @override
  String get typeTrain => 'Tren';

  @override
  String get typeTram => 'Tramway';

  @override
  String get typeMetro => 'Subway';

  @override
  String get typeBus => 'Bus';

  @override
  String get typeCar => 'Kotse';

  @override
  String get typePlane => 'Eroplano';

  @override
  String get typeFerry => 'Ferry';

  @override
  String get typeAerialway => 'Cable car';

  @override
  String get typeWalk => 'Lakad';

  @override
  String get typePoi => 'Lugar na pinuntahan';

  @override
  String get typeCycle => 'Bisikleta';

  @override
  String get typeHelicopter => 'Helikopter';

  @override
  String get tripsTableHeaderOriginDestination => 'Pinagmulan/Patutunguhan';

  @override
  String get tripsTableHeaderOrigin => 'Pinagmulan';

  @override
  String get tripsTableHeaderDestination => 'Patutunguhan';

  @override
  String get tripsTableHeaderStartTime => 'Oras ng pag alis';

  @override
  String get tripsTableHeaderEndTime => 'Oras ng pagdating';

  @override
  String get tripsTableHeaderOperator => 'Operator';

  @override
  String get tripsTableHeaderLineName => 'Linya';

  @override
  String get tripsTableHeaderTripLength => 'Haba';

  @override
  String get tripsTableHeaderVisibility => 'Bisi.';

  @override
  String tripsDetailTitle(Object vehicle) {
    return 'Ang byahe sa $vehicle';
  }

  @override
  String get tripsDetailsTitleOperator => 'Operator: ';

  @override
  String get tripsDetailsTitleVehicle => 'Sasakyan: ';

  @override
  String get tripsDetailsTitleSeat => 'Upuan: ';

  @override
  String get tripsDetailsTitlePrice => 'Presyo: ';

  @override
  String tripsDetailPurchasedDate(Object date) {
    return 'binili sa $date';
  }

  @override
  String get tripsDetailsTitleNotes => 'Notes: ';

  @override
  String get tripsDetailsEditButton => 'Edit';

  @override
  String get tripsDetailsDeleteButton => 'Ibura';

  @override
  String get tripsDetailsDeleteDialogTitle => 'Ibura ang byahe?';

  @override
  String get tripsDetailsDeleteDialogMessage =>
      'SIgurado ka na gusto mo ibura ang byahe?';

  @override
  String get tripsDetailsDeleteDialogConfirmButton => 'Ibura';

  @override
  String get tripsDetailsDeleteFailed => 'Hindi mabura ang byahe';

  @override
  String get tripsDetailsDeleteSuccess => 'Nabura ang byahe';

  @override
  String get tripsFilterAllCountry => 'Lahat';

  @override
  String get tripsFilterAllOperator => 'Lahat';

  @override
  String get tripsFilterAllYears => 'Lahat ng Taon';

  @override
  String get tripsFilterKeyword => 'Keyword';

  @override
  String get tripsFilterDateFrom => 'Sa';

  @override
  String get tripsFilterDateTo => 'Sa (opsyonal)';

  @override
  String get tripsFilterCountry => 'Bansa';

  @override
  String get tripsFilterOperator => 'Operator';

  @override
  String get tripsFilterType => 'Uri ng sasakyan';

  @override
  String get filterClearButton => 'Ibura ang filter';

  @override
  String get graphTypeOperator => 'Operator';

  @override
  String get graphTypeCountry => 'Bansa';

  @override
  String get graphTypeYears => 'Taon';

  @override
  String get graphTypeMaterial => 'Materyal';

  @override
  String get graphTypeItinerary => 'Itinerary';

  @override
  String typeStation(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'train': 'Station',
      'plane': 'Airport',
      'bus': 'Hintuan',
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
      'train': 'Station',
      'plane': 'Airport',
      'bus': 'Hintuan',
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
  String get statisticsGraphUnitTrips => 'Byahe';

  @override
  String get statisticsGraphUnitDistance => 'Layo';

  @override
  String get statisticsGraphUnitDuration => 'Haba ng byahe';

  @override
  String get statisticsGraphUnitCo2 => 'CO2';

  @override
  String get statisticsDisplayFilters => 'Ipakita ang filters';

  @override
  String get statisticsHideFilters => 'Itago ang filter';

  @override
  String get statisticsTripsUnitBase => 'byahe';

  @override
  String get statisticsTripsUnitKilo => 'isang libong byahe';

  @override
  String get statisticsTripsUnitMega => 'isang milyong byahe';

  @override
  String get statisticsTripsUnitGiga => 'isang bilyong byahe';

  @override
  String get statisticsOtherLabel => 'Other';

  @override
  String get statisticsTotalLabel => 'Lahat';

  @override
  String get statisticsUnitLabel => 'Unit:';

  @override
  String get statisticsNoDataLabel => 'Walang data';

  @override
  String get statisticsPieWip => 'Ang pie chart ay WIP';

  @override
  String get internationalWaters => 'Tubig international';

  @override
  String get addTripPageTitle => 'Magdagdag ng byahe';

  @override
  String get addTripStepBasics => 'Basics';

  @override
  String get addTripStepDate => 'Petsa';

  @override
  String get addTripStepDetails => 'Detalye';

  @override
  String get addTripStepPath => 'Path';

  @override
  String get addTripStepValidate => 'Ivalidate';

  @override
  String get addTripExitConfirmationDialogueTitle => 'Gusto mo umexit?';

  @override
  String get addTripExitConfirmationDialogueContent =>
      'Naibago ang data ng byahe, kung umexit ka ng hindi nag sasave mawawala ang data';

  @override
  String get addTripTransportationMode => 'Byahe mode';

  @override
  String get addTripImportFr24 => 'Import ang flight data sa FR24';

  @override
  String get addTripManualDeparture => 'I set ang pag depart manually';

  @override
  String get addTripManualArrival => 'I set ang pag arrive manually';

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
      'Sa manual mode, maari mong i pasok ang coordinates o i galaw ang marker sa tamang lugar sa mapa.';

  @override
  String get addTripOperator => 'Operator';

  @override
  String get addTripOperatorHelper =>
      'Gumamit ng comma o enter button para ivalidate ang operator kahit hindi mo alam';

  @override
  String get addTripOperatorHint => 'Hanapin ang operator...';

  @override
  String get addTripOperatorPlaceholderLogo => 'Piliin ang operator';

  @override
  String get addTripLine => 'Linya';

  @override
  String get addTripDateTypePrecise => 'Tumpak';

  @override
  String get addTripDateTypeUnknown => 'Hindi alam';

  @override
  String get addTripDateTypeDate => 'Petsa';

  @override
  String get addTripScheduledTime => 'Scheduled time';

  @override
  String get addTripStartDate => 'Simula ng byahe';

  @override
  String get addTripEndDate => 'Katapusan ng byahe';

  @override
  String get addTripDelay => 'Delay';

  @override
  String get addTripRealTime => 'Tamang oras';

  @override
  String get addTripOriginDayLabel => 'Araw ng byahe';

  @override
  String get addTripResetToScheduled => 'Ireset sa scheduled time';

  @override
  String get addTripDuration => 'Haba ng byahe';

  @override
  String get addTripPast => 'Nakaraan';

  @override
  String get addTripFuture => 'HInaharap';

  @override
  String get timezoneInformation =>
      'Ang time zone ay base sa coordinates ng departure at ng arrival';

  @override
  String get addTripDepartureAfterArrival => 'Departure pagkatapos ng arrival!';

  @override
  String get addTripFacultative => 'Optional fields';

  @override
  String get addTripMaterial => 'Materyal';

  @override
  String get addTripRegistration => 'Rehistrasyon';

  @override
  String get addTripSeat => 'Upuan';

  @override
  String get addTripNotes => 'Note';

  @override
  String get addTripTicketTitle => 'Tiket';

  @override
  String get addTripTicketPrice => 'Presyo ng tiket';

  @override
  String get addTripPurchaseDate => 'Petsa ng pagbili';

  @override
  String get continueTripButton => 'Validate at ituloy ang byahe';

  @override
  String get addTripPathUseNewRouter => 'Gamitin ang bagong router';

  @override
  String addTripNameEnd(String departure, String arrival) {
    return '$departure hanggang $arrival';
  }

  @override
  String get addTripPathHelp =>
      'Ang bagong router ay nasa beta mode at mukang electric ang sasakyan.\n\nAng mga router (luma at bago) ay pareho para sa tren, tram, at subway. Pwede mo i fine-tune ang peg para i tama ang ruta sa ikagugusto mo.';

  @override
  String get addTicketPageTitle => 'Bagong tiket';

  @override
  String get addTagPageTitle => 'Bagong tag';

  @override
  String get addTripPathRoutingErrorBannerMessage =>
      'May mali sa ruta. Paki check ang byahe at i adjust ang peg points kung kailangan.';

  @override
  String get addTripRecordingMsg =>
      'Ang byahe mo ay rinerecord, maghintay ng saglit';

  @override
  String get addTripFinishMsg => 'Na record ang byahe mo';

  @override
  String addTripFinishErrorMsg(String errorCode) {
    return 'Nagka error habang rinerecord ang byahe, pakiulit ulit (error: $errorCode).';
  }

  @override
  String get addTripFinishFeedbackWarning =>
      'Na record ang byahe pero ang feedback galing sa server ay hindi kumpleto. Paki refresh at i check ang detalye ng byahe.';

  @override
  String get addTripPathGeodesic => 'Geodesic path';

  @override
  String get addTripPathFr24 => 'FR24 path';

  @override
  String addTripDelayMinuteDelay(String delay) {
    return 'i.e. $delay late';
  }

  @override
  String addTripDelayMinuteAdvance(String advance) {
    return 'i.e. $advance early';
  }

  @override
  String addTripDelayTime(String time) {
    return 'i.e. sa $time';
  }

  @override
  String get aboutPageAboutSubPageTitle => 'Trainlog';

  @override
  String get aboutPageHowToSubPageTitle => 'Paano gamitin';

  @override
  String get aboutPagePrivacySubPageTitle => 'Privacy';

  @override
  String get supportTrainlogButton => 'Isupport ang Trainlog';

  @override
  String get joinDiscordButton => 'Sumali sa discord community';

  @override
  String get websiteRepoButton => 'Repositoryo ng website';

  @override
  String get applicationRepoButton => 'Repositoryo ng application';

  @override
  String get pageNotAvailableInUserLanguage =>
      'Ang page na ito ay naka display sa English kasi hindi pa sya available sa Tagalog.';

  @override
  String get tableOfContents => 'Talaan ng mga nilalaman';

  @override
  String get prerecorderExplanationTitle => 'Paliwanag';

  @override
  String get prerecorderExplanation =>
      'Ang Geolog tool ay isang matalinong pre-recorder. Kapag pinindot mo ang record button, awtomatiko nitong ise-save ang iyong kasalukuyang coordinate kasama ang petsa at oras. Sa susunod, maaari kang pumili ng dalawang geolog at gamitin ang mga ito upang lumikha ng isang bagong biyahe gamit ang naka-save na data.';

  @override
  String get prerecorderExplanationStation =>
      'Awtomatikong hahanapin ng tool na ito ang pangalan ng istasyon at ipapakita ito kung makita (gumagana lamang ito para sa tren, bus, at ferry). Ipapakita ang pinakamalapit na mga istasyon (maaari mong baguhin ang radius sa mga setting) at maaari mong piliin ang pinakamahusay.';

  @override
  String get prerecorderExplanationDelete =>
      'Pagkatapos malikha ang biyahe, awtomatikong mabubura ang dalawang geolog.';

  @override
  String get prerecorderExplanationPrivacy =>
      'Ang data ay naka-save lamang sa iyong device.';

  @override
  String get prerecorderRecordButton => 'Record';

  @override
  String get prerecorderCreateTripButton => 'Gumawa ng byahe';

  @override
  String get prerecorderNoData => 'Walang data';

  @override
  String get prerecorderUnknownStation => 'Hindi kilalang station';

  @override
  String get prerecorderDeleteSelectionConfirm =>
      'SIgurado ka na gusto mo ibura ang selection? Hindi ito reversible.';

  @override
  String get prerecorderDeleteAllConfirm =>
      'Sigurado ka na gusto mo ibura ang lahat ng recorded gelogs? Hindi ito reversible.';

  @override
  String get prerecorderSelectStation => 'Pumili ng station';

  @override
  String get prerecorderSelectClosest => 'Pumili ng pinkamalapit';

  @override
  String get prerecorderNoStationReachable => 'Walang station na malapit';

  @override
  String prerecorderAway(String distance) {
    return '$distance m layo';
  }

  @override
  String prerecorderStationsFound(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count station ang natagpuan',
      zero: 'Walang nakitang station',
    );
    return '$_temp0';
  }

  @override
  String get prerecorderErrorLessThanTwoSelected =>
      'Pumili ng dalawang geologs para gumawa ng byahe';

  @override
  String get prerecorderErrorMoreThanTwoSelected =>
      'Pumili ng dalawang geologs lamang para gumawa ng byahe';

  @override
  String get prerecorderErrorDepartureAfterArrival =>
      'Hindi maaaring ang departure ay pagkatapos ng arrival.';

  @override
  String get prerecorderErrorTypeSameForDepartureArrival =>
      'Ang departure at arrival ay dapat parehas ng sasakyan, o unknown type';

  @override
  String get prerecorderErrorFetchingStation =>
      'Nagka error sa pagkuha ng data ng station';

  @override
  String get inboxPageTitle => 'Mga balita at update';

  @override
  String inboxAuthor(String author) {
    return 'Gawa ni $author';
  }

  @override
  String get inboxModified => '(naibago)';

  @override
  String inboxModifiedIndication(String date) {
    return '(naibago sa $date)';
  }

  @override
  String get trainglogStatusPageTitle => 'Trainlog Status';
}
