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
  String get createAccountTitle => 'Gumawa ng account';

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
  String get createAccountPrivacyPolicy =>
      'Sa pag sign up, sumasang-ayon ka sa aming Privacy Policy.';

  @override
  String get loginWelcomeBack => 'Maligayang pagbabalik';

  @override
  String get loginSubtitle => 'I-log ang iyong susunod na biyahe';

  @override
  String get loginNewHere => 'Bago dito?';

  @override
  String get changeInstance => 'Baguhin ang instance';

  @override
  String get instanceSelectorLabel => 'Instance';

  @override
  String get errorCreationAccount => 'May mali sa pag gawa ng account.';

  @override
  String get connectionError => 'May mali sa credentials mo';

  @override
  String get refreshCompleted => 'Na refresh na';

  @override
  String get nextButton => 'Sunod';

  @override
  String get previousButton => 'Balik';

  @override
  String get validateButton => 'I-save';

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
    return '$count pasahero';
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
  String get appLoading => 'Ina-load ang app, maghintay ng saglit';

  @override
  String get dataLoading => 'Ina-load ang data, maghintay ng saglit';

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
  String get settingsMapColorPaletteTrainlogApp => 'Trainlog App';

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
    return '$size MiB';
  }

  @override
  String get settingsCacheClearButton => 'Ibura';

  @override
  String get settingsCacheTitle => 'Naka-cache na data';

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
  String get settingsLicenses => 'Mga lisensya';

  @override
  String get menuMapTitle => 'Mapa';

  @override
  String get menuTripsTitle => 'Byahe';

  @override
  String get menuRankingTitle => 'Ranking';

  @override
  String get rankingYourPosition => 'Iyong posisyon';

  @override
  String rankingPositionValue(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '#$count',
    );
    return '$_temp0';
  }

  @override
  String get rankingTypeTotal => 'Kabuuan';

  @override
  String get rankingTypeVehicles => 'Sasakyan';

  @override
  String get rankingTypeWorld => 'Mundo';

  @override
  String get rankingTypeRailwayCoverage => 'Saklaw ng riles';

  @override
  String get rankingTypeCountries => 'Mga bansa';

  @override
  String get rankingTypeCarbon => 'CO2e';

  @override
  String get rankingUnitDistance => 'Distansya';

  @override
  String get rankingUnitTrips => 'Mga biyahe';

  @override
  String get rankingUnitTotalCarbon => 'Kabuuang CO2e';

  @override
  String get rankingUnitCarbonPerKm => 'CO2e/km';

  @override
  String get rankingCarbonExplanation =>
      'Mas mababang g/km ay mas mabuti — ang pinaka-carbon-efficient na manlalakbay ang nangunguna.';

  @override
  String get rankingSortAlphabetical => 'Ayusin ayon sa alpabeto';

  @override
  String get rankingSortByValue => 'Ayusin ayon sa halaga';

  @override
  String get rankingOrderAscending => 'Pataas';

  @override
  String get rankingOrderDescending => 'Pababa';

  @override
  String get rankingWorldCovered => 'Na-cover na mga squares sa mundo';

  @override
  String get rankingCountriesVisited => 'Mga bansang nabisita';

  @override
  String rankingCountryCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'mga bansa',
      one: 'bansa',
    );
    return '$_temp0';
  }

  @override
  String get rankingNoData => 'Walang datos';

  @override
  String get rankingNotRanked => 'Hindi naka-ranggo';

  @override
  String get rankingSearchHint => 'Maghanap ng user…';

  @override
  String get railCoverageCountriesTab => 'Mga bansa';

  @override
  String get railCoverageRegionsTab => 'Mga rehiyon';

  @override
  String get railCoverageSelectRegion => 'Pumili ng bansa';

  @override
  String railCoverageRegionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count na rehiyon',
      one: '$count rehiyon',
    );
    return '$_temp0';
  }

  @override
  String railCoverageAreaSubtitle(String area) {
    return 'Saklaw ng riles ng $area';
  }

  @override
  String get railCoverageYou => 'Ikaw';

  @override
  String get menuStatisticsTitle => 'Istatistika';

  @override
  String get menuDashboardTitle => 'Dashboard';

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
  String get menuYouTitle => 'Ikaw';

  @override
  String get menuExploreSectionTitle => 'TUKLASIN';

  @override
  String get menuMenuSectionTitle => 'MENU';

  @override
  String get menuInboxTitle => 'Inbox';

  @override
  String menuTripCountLabel(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'biyahe',
    );
    return '$_temp0';
  }

  @override
  String menuTripCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count biyahe',
      zero: 'Walang biyahe',
    );
    return '$_temp0';
  }

  @override
  String get mapFilterYearsAllBtn => 'Lahat';

  @override
  String get mapFilterYearsNoneBtn => 'Wala';

  @override
  String get mapFilterVehicleTypeAllBtn => 'Lahat';

  @override
  String get mapFilterVehicleTypeNoneBtn => 'Wala';

  @override
  String get mapFilterTitle => 'I-filter ang mapa';

  @override
  String get mapFilterReset => 'I-reset';

  @override
  String get mapFilterTimeRange => 'Saklaw ng panahon';

  @override
  String get mapFilterSelectYears => 'Pumili ng mga taon';

  @override
  String get mapFilterUnknownFuture => 'Hindi alam na hinaharap';

  @override
  String get mapFilterUnknownPast => 'Hindi alam na nakaraan';

  @override
  String mapFilterShowTrips(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ipakita ang $count byahe',
      zero: 'Walang byahe',
    );
    return '$_temp0';
  }

  @override
  String get tripPathLoading =>
      'Ang byahe mo ay nag loload, mag hintay ng saglit';

  @override
  String get mapLockedOnPosition => 'Sinusundan ng mapa ang iyong posisyon';

  @override
  String get yearTitle => 'Taon';

  @override
  String get yearAllList => 'Lahat';

  @override
  String get yearPastList => 'Nakaraan';

  @override
  String get yearFutureList => 'Future';

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
  String get typeEScooter => 'E-Scooter';

  @override
  String get typeFunicular => 'Funicular';

  @override
  String get typeSki => 'Ski';

  @override
  String get typeRail => 'Rail (others)';

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
  String tripsDetailPurchasedDate(Object date) {
    return 'binili sa $date';
  }

  @override
  String get tripsDetailsSectionDetails => 'Detalye';

  @override
  String get tripsDetailsLabelVehicle => 'Sasakyan';

  @override
  String get tripsDetailsLabelMaterial => 'Materyal';

  @override
  String get tripsDetailsLabelSeat => 'Upuan';

  @override
  String get tripsDetailsLabelRegistration => 'Rehistrasyon';

  @override
  String tripsDetailsSectionOperator(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Operators',
      one: 'Operator',
    );
    return '$_temp0';
  }

  @override
  String tripsDetailsSectionCountry(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mga bansa',
      one: 'Bansa',
    );
    return '$_temp0';
  }

  @override
  String get tripsDetailsSectionTicket => 'Tiket';

  @override
  String get tripsDetailsSectionNotes => 'Notes';

  @override
  String get tripsDetailsMetricDistance => 'Distansya';

  @override
  String get tripsDetailsMetricAvgSpeed => 'Karaniwang bilis';

  @override
  String get tripsDetailsNoDate => 'Walang petsa';

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
  String get tripsFilterAllYears => 'Lahat ng Taon';

  @override
  String get tripsSearchFilterTitle => 'Maghanap ng biyahe';

  @override
  String get tripsSearchFilterSearchHint => 'Mga istasyon, linya, tag...';

  @override
  String get tripsSearchFilterWhen => 'Kailan';

  @override
  String get tripsSearchFilterAllTime => 'Lahat ng panahon';

  @override
  String get tripsSearchFilterThisYear => 'Ngayong taon';

  @override
  String get tripsSearchFilterPast30Days => 'Nakaraang 30 araw';

  @override
  String get tripsSearchFilterFrom => 'Mula';

  @override
  String get tripsSearchFilterTo => 'Hanggang';

  @override
  String get tripsSearchFilterOn => 'Sa';

  @override
  String get tripsSearchFilterOnHelper =>
      'Mga biyahe lang sa eksaktong araw na ito';

  @override
  String get tripsSearchFilterCountries => 'Mga bansa';

  @override
  String get tripsSearchFilterOperators => 'Mga operator';

  @override
  String get tripsSearchFilterAdd => 'Idagdag';

  @override
  String get tripsSearchFilterAllCountriesFromTrips =>
      'Lahat ng bansa mula sa iyong mga biyahe';

  @override
  String get tripsSearchFilterAllOperatorsFromTrips =>
      'Lahat ng operator mula sa iyong mga biyahe';

  @override
  String get tripsSearchFilterSearchCountries => 'Maghanap ng bansa...';

  @override
  String get tripsSearchFilterSearchOperators => 'Maghanap ng operator...';

  @override
  String get tripsSearchFilterDone => 'Tapos na';

  @override
  String get filterClearButton => 'Ibura ang filter';

  @override
  String get tripsAddButton => 'Bag. biyahe';

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
  String get statisticsTitle => 'Statistics';

  @override
  String get statisticsViewBar => 'Bar';

  @override
  String get statisticsViewPie => 'Pie';

  @override
  String get statisticsViewTable => 'Table';

  @override
  String get internationalWaters => 'Tubig international';

  @override
  String addTripStepProgress(int current, int total) {
    return 'STEP $current / $total';
  }

  @override
  String get addTripVehicleTypeTitle => 'Paano ka bumiyahe?';

  @override
  String get addTripVehicleTypeSubtitle =>
      'Piliin ang uri ng sasakyan para sa biyaheng ito';

  @override
  String get addTripRouteTitle => 'Saan ka nagpunta?';

  @override
  String get addTripRouteSubtitle =>
      'Maghanap gamit ang pangalan, o lumipat sa Manual para maglagay ng pin';

  @override
  String get addTripSwapTooltip => 'Ipagpalit ang departure at arrival';

  @override
  String get addTripModeByName => 'Sa pangalan';

  @override
  String get addTripModeManual => 'Manual';

  @override
  String get addTripOperatorTitle => 'Sino ang nag-operate nito?';

  @override
  String get addTripSelectedOperators => 'Mga napiling operator';

  @override
  String get addTripSuggestedOperators => 'Mungkahi para sa rutang ito';

  @override
  String get addTripSuggestedOperatorsHelper =>
      'Base sa iyong mga nakaraang biyahe sa bansang ito at uri ng sasakyan.';

  @override
  String get addTripAddCustomOperator => 'Idagdag bilang custom na operator';

  @override
  String addTripOperatorTripCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count biyahe',
      one: '1 biyahe',
    );
    return '$_temp0';
  }

  @override
  String get addTripSkipButton => 'Laktawan — hindi ko alam';

  @override
  String get addTripExitConfirmationDialogueTitle => 'Gusto mo umexit?';

  @override
  String get addTripExitConfirmationDialogueContent =>
      'Naibago ang data ng byahe, kung umexit ka ng hindi nag sasave mawawala ang data';

  @override
  String get addTripTransportationMode => 'Byahe mode';

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
  String get addTripOperatorHint => 'Hanapin ang operator...';

  @override
  String get addTripDateTypePrecise => 'Tumpak';

  @override
  String get addTripDateTypeUnknown => 'Hindi alam';

  @override
  String get addTripDateTypeDate => 'Petsa';

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
  String get addTripMaterial => 'Materyal';

  @override
  String get addTripSeat => 'Upuan';

  @override
  String get addTripNotes => 'Note';

  @override
  String get addTripTicketTitle => 'Tiket';

  @override
  String get addTripPurchaseDate => 'Petsa ng pagbili';

  @override
  String get continueTripButton => 'I-save at ituloy ang byahe';

  @override
  String get addTripPathUseNewRouter => 'Gamitin ang bagong router';

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
  String get addTripWhenTitle => 'Kailan ito nangyari?';

  @override
  String get addTripOnTime => 'Nasa oras';

  @override
  String get addTripDelayed => 'Na-delay';

  @override
  String get addTripRoughlyWhen => 'Mga kailan';

  @override
  String get addTripOptional => 'opsyonal';

  @override
  String get addTripDurationNotSet => 'Hindi nakatakda';

  @override
  String get addTripDateOnlyHelper =>
      'Walang eksaktong oras — ang araw lang ng byahe.';

  @override
  String addTripDurationSummary(String duration) {
    return 'Haba ng byahe: $duration';
  }

  @override
  String addTripDurationSummaryScheduled(String duration, String scheduled) {
    return 'Haba ng byahe: $duration (nakatakda $scheduled)';
  }

  @override
  String get addTripDetailsTitle => 'May iba pang detalye?';

  @override
  String get addTripDetailsSubtitle => 'Lahat opsyonal — ilagay ang alam mo';

  @override
  String get addTripLineName => 'Pangalan ng linya';

  @override
  String get addTripRegistrationNumber => 'Registration number';

  @override
  String get addTripTicketExtrasTitle => 'Ticket at iba pa';

  @override
  String get addTripPrice => 'Presyo';

  @override
  String get addTripSelectScheduledTimeFirst =>
      'Piliin muna ang nakatakdang oras';

  @override
  String get addTripTimezoneLabel => 'Timezone:';

  @override
  String get addTripDelayHelper =>
      'Itakda ang delay o advance gamit ang minuto o ang aktwal na oras.';

  @override
  String get addTripCheckRouteTitle => 'Suriin ang ruta';

  @override
  String get addTripCheckRouteSubtitle =>
      'Ayusin ang ruta sa mapa kung hindi ito tama';

  @override
  String get addTripSummaryTitle => 'Buod';

  @override
  String get addTripSummaryVehicle => 'Sasakyan';

  @override
  String get addTripSummaryDistance => 'Distansya';

  @override
  String get addTripSummaryTheoreticalDuration => 'Teoretikal na tagal';

  @override
  String get addTripSummaryEstimatedDuration => 'Tinatayang tagal ng ruta';

  @override
  String get addTripTodayButton => 'Ngayon';

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
  String get prerecorderSelectRailType => 'Type of rail transport';

  @override
  String get prerecorderSelectVehicleType => 'Type of transport';

  @override
  String get inboxPageTitle => 'Mga balita at update';

  @override
  String get inboxModified => '(naibago)';

  @override
  String inboxModifiedIndication(String date) {
    return '(naibago sa $date)';
  }

  @override
  String get trainglogStatusPageTitle => 'Trainlog Status';

  @override
  String get onboardingGetStarted => 'Magsimula';

  @override
  String get onboardingPage1Title => 'Biswalisa ang iyong mga paglalakbay';

  @override
  String get onboardingPage1Subtitle =>
      'Madaling subaybayan ang iyong mga biyahe. Makita ang lahat ng iyong biyahe sa tren, bus, barko, at eroplano sa isang mapa.';

  @override
  String get onboardingPage2Title => 'Tuklasin ang iyong mga istatistika';

  @override
  String get onboardingPage2Subtitle =>
      'Tingnan ang estadistikang detalye kung paano, kailan, at saan ka naglakbay.\n\nMakakuha ng kapaki-pakinabang na istatistika tungkol sa mga istasyong pinaka-madalas mong binibisita, mga operator na pinaka-madalas mong ginagamit, at kung gaano karami sa riles ng iyong bansa ang iyong nalakbay.';

  @override
  String get onboardingPage3Title => 'Ibahagi ang iyong mga paglalakbay';

  @override
  String get onboardingPage3Subtitle =>
      'Gumawa ng mga link na maaaring ibahagi para sa iyong mga biyahe upang ibahagi ang iyong mga plano sa paglalakbay sa sinuman.';

  @override
  String get onboardingPage4Title => 'Mga Leaderboard';

  @override
  String get onboardingPage4Subtitle =>
      'Ikaw ba ay madalas maglakbay? Tingnan kung paano ang iyong mga paglalakbay kumpara sa ibang mga miyembro sa buong mundo.';

  @override
  String get onboardingLocationTitle =>
      'Pag-activate ng mga serbisyo ng lokasyon';

  @override
  String get onboardingLocationSubtitle =>
      'Ginamit ng Trainlog ang lokasyon ng iyong device upang i-center ang mapa sa iyong posisyon, o upang i-record ang iyong posisyon kapag ginamit mo ang function na Geolog. Ito ay hindi sapilitan.';

  @override
  String get onboardingLocationActivate => 'I-activate ang lokasyon';

  @override
  String get onboardingLocationSkip => 'Laktawan';

  @override
  String get tapAgainToExit => 'I-tap muli para lumabas';

  @override
  String get tripsEmptyList => 'Wala pang biyahe';

  @override
  String get tripCardDateUndefined => 'Hindi natukoy';
}
