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
  String get filterButton => 'Filtrer';

  @override
  String get loginButton => 'Connexion';

  @override
  String get logoutButton => 'Déconnexion';

  @override
  String get createAccountButton => 'Créer un compte';

  @override
  String get emailLabel => 'Courriel';

  @override
  String get emailHint => 'vous@example.com';

  @override
  String get emailHelper => 'En cas d\'oubli du mot de passe';

  @override
  String get emailRequiredLabel => 'Le courriel est obligatoire';

  @override
  String get emailValidLabel => 'Saisissez une adresse e-mail valide';

  @override
  String get usernameLabel => 'Nom d\'utilisateur';

  @override
  String get usernameRequiredLabel => 'Le nom d\'utilisateur est obligatoire';

  @override
  String get passwordLabel => 'Mot de passe';

  @override
  String get passwordShowLabel => 'Afficher le mot de passe';

  @override
  String get passwordHideLabel => 'Masquer le mot de passe';

  @override
  String get passwordRequiredLabel => 'Le mot de passe est obligatoire';

  @override
  String get createAccountButtonShort => 'Créer';

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
  String settingsCache(Object size) {
    return 'Données en cache ($size Mio)';
  }

  @override
  String get settingsCacheClearButton => 'Vider';

  @override
  String get settingsCacheClearConfirmTitle => 'Vider le cache ?';

  @override
  String get settingsCacheClearConfirmMessage =>
      'Êtes-vous sûr de vouloir supprimer les données en cache ? Cette action est irréversible. Le prochain chargement de l\'application pourra être plus long.';

  @override
  String get settingsCacheClearedMessage => 'Cache vidé avec succes.';

  @override
  String get settingsDisplayUserMarker => 'Afficher votre position';

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

  @override
  String get tripsTableHeaderOriginDestination => 'Origine/Destination';

  @override
  String get tripsTableHeaderOrigin => 'Origine';

  @override
  String get tripsTableHeaderDestination => 'Destination';

  @override
  String get tripsTableHeaderStartTime => 'Heure de départ';

  @override
  String get tripsTableHeaderEndTime => 'Heure d\'arrivée';

  @override
  String get tripsTableHeaderOperator => 'Transporteur';

  @override
  String get tripsTableHeaderLineName => 'Ligne';

  @override
  String get tripsTableHeaderTripLength => 'Distance';

  @override
  String tripsDetailTitle(Object vehicle) {
    return 'Trajet en $vehicle';
  }

  @override
  String get tripsDetailsTitleOperator => 'Transporteur : ';

  @override
  String get tripsDetailsTitleVehicle => 'Vehicule : ';

  @override
  String get tripsDetailsTitleSeat => 'Siège : ';

  @override
  String get tripsDetailsTitlePrice => 'Prix : ';

  @override
  String tripsDetailPurchasedDate(Object date) {
    return 'acheté le $date';
  }

  @override
  String get tripsDetailsTitleNotes => 'Notes : ';

  @override
  String get tripsFilterAllCountry => 'Tous';

  @override
  String get tripsFilterAllOperator => 'Tous';

  @override
  String get tripsFilterAllYears => 'Toutes les années';

  @override
  String get tripsFilterKeyword => 'Mot-clef';

  @override
  String get tripsFilterDateFrom => 'Le';

  @override
  String get tripsFilterDateTo => 'au (facultatif)';

  @override
  String get tripsFilterCountry => 'Pays';

  @override
  String get tripsFilterOperator => 'Opérateur';

  @override
  String get tripsFilterType => 'Types de véhicule';

  @override
  String get filterClearButton => 'Supprimer les filtres';

  @override
  String get graphTypeOperator => 'Opérateur';

  @override
  String get graphTypeCountry => 'Pays';

  @override
  String get graphTypeYears => 'Années';

  @override
  String get graphTypeMaterial => 'Matériel';

  @override
  String get graphTypeItinerary => 'Itinéraire';

  @override
  String get graphTypeStations => 'Gares';

  @override
  String get statisticsDisplayFilters => 'Afficher les filtres';

  @override
  String get statisticsHideFilters => 'Masquer les filtres';

  @override
  String get statisticsTripsUnitBase => 'trajets';

  @override
  String get statisticsTripsUnitKilo => 'mille trajets';

  @override
  String get statisticsTripsUnitMega => 'million de trajet';

  @override
  String get statisticsTripsUnitGiga => 'billion de trajet';

  @override
  String get statisticsOtherLabel => 'Autres';

  @override
  String get statisticsTotalLabel => 'Total';

  @override
  String get statisticsUnitLabel => 'Unités :';

  @override
  String get statisticsNoDataLabel => 'Pas de données';
}
