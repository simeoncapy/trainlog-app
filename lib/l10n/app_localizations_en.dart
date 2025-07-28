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
}
