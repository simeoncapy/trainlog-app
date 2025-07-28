// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Trainlog';

  @override
  String get language => 'English';

  @override
  String get mainMenuButtonTooltip => 'Ouvrir le menu';

  @override
  String get settingsAppCategory => 'Paramètres de l\'application';

  @override
  String get settingsMapCategory => 'Paramètres de la carte';

  @override
  String get settingsAccountCategory => 'Paramètres du compte';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsThemeMode => 'Thème';

  @override
  String get settingsDark => 'Sombre';

  @override
  String get settingsLight => 'Clair';

  @override
  String get settingsSystem => 'Système';

  @override
  String get settingsMapPathDisplayOrder => 'Ordre des trajets sur la carte';

  @override
  String get settingMapPathDisplayOrderByCreation => 'Par date de création';

  @override
  String get settingMapPathDisplayOrderByTrip => 'Par date du trajet';

  @override
  String get settingMapPathDisplayOrderByTripAndPlane =>
      'Par date du trajet (avec les vols au-dessus)';

  @override
  String get settingsMapColorPalette => 'Palette de couleurs des trajets';

  @override
  String get settingsMapColorPaletteTrainlogWeb => 'Trainlog Web';

  @override
  String get settingsMapColorPaletteTrainlogVariation => 'Trainlog (variation)';

  @override
  String get settingsMapColorPaletteTrainlogRed => 'Rouge';

  @override
  String get settingsMapColorPaletteTrainlogGreen => 'Vert';

  @override
  String get settingsMapColorPaletteTrainlogBlue => 'Bleu';

  @override
  String get menuMapTitle => 'Carte';

  @override
  String get menuTripsTitle => 'Trajets';

  @override
  String get menuRankingTitle => 'Classement';

  @override
  String get menuStatisticsTitle => 'Statistiques';

  @override
  String get menuCoverageTitle => 'Couverture';

  @override
  String get menuTagsTitle => 'Tags';

  @override
  String get menuTicketsTitle => 'Tickets';

  @override
  String get menuFriendsTitle => 'Amis';

  @override
  String get menuSettingsTitle => 'Paramètres';

  @override
  String get menuAboutTitle => 'À propos';

  @override
  String get tripPathLoading =>
      'Chemin des trajets en cours de chargement, veuillez patienter';

  @override
  String get yearTitle => 'Années';

  @override
  String get yearAllList => 'Tout';

  @override
  String get yearPastList => 'Passé';

  @override
  String get yearFutureList => 'Futur';

  @override
  String get yearYearList => 'Années...';

  @override
  String get typeTitle => 'Types de véhicule';

  @override
  String get typeTrain => 'Train';

  @override
  String get typeTram => 'Tramway';

  @override
  String get typeMetro => 'Métro';

  @override
  String get typeBus => 'Bus';

  @override
  String get typeCar => 'Voiture';

  @override
  String get typePlane => 'Avion';

  @override
  String get typeFerry => 'Ferry';
}
