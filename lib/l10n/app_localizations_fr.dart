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
  String get language => 'Français';

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
  String get loginToYourAccount => 'Connectez-vous à votre compte';

  @override
  String menuHello(Object username) {
    return 'Bonjour $username';
  }

  @override
  String get connectionError =>
      'Echec de la connexion, vérifiez vos identifiants';

  @override
  String get refreshCompleted => 'Actualisation terminée';

  @override
  String get nextButton => 'Suivant';

  @override
  String get previousButton => 'Précédent';

  @override
  String get validateButton => 'Valider';

  @override
  String get continueButton => 'Continuer';

  @override
  String get nameField => 'Nom';

  @override
  String get auto => 'Auto';

  @override
  String get energy => 'Énergie';

  @override
  String get energyElectric => 'Électrique';

  @override
  String get energyElectricShort => 'Élec.';

  @override
  String get energyThermic => 'Thermique';

  @override
  String get energyThermicShort => 'Therm.';

  @override
  String get energyHydrogen => 'Hydrogène';

  @override
  String get energyHydrogenShort => 'H2';

  @override
  String get manual => 'manuel';

  @override
  String get fillRequiredFields => 'Veuillez remplir les champs obligatoires';

  @override
  String get facultative => 'facultatif';

  @override
  String get visibility => 'Visibilité';

  @override
  String get visibilityPublic => 'Public';

  @override
  String get visibilityFriends => 'Amis';

  @override
  String get visibilityPrivate => 'Privé';

  @override
  String get helpTitle => 'Aide';

  @override
  String get pageNotImplementedYet =>
      'Cette page n’est pas encore disponible dans l’application. La version web est affichée à la place, et l’interface utilisateur peut être moins adaptée.';

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
  String get typeAerialway => 'Téléphérique';

  @override
  String get typeWalk => 'Marche';

  @override
  String get typePoi => 'Point d\'intéret';

  @override
  String get typeCycle => 'Vélo';

  @override
  String get typeHelicopter => 'Hélicoptère';

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
  String get tripsDetailsEditButton => 'Modifier';

  @override
  String get tripsDetailsDeleteButton => 'Supprimer';

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
  String typeStation(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'train': 'Gare',
      'plane': 'Aéroport',
      'bus': 'Arrêts',
      'tram': 'Arrêt',
      'metro': 'Station',
      'ferry': 'Port',
      'helicopter': 'Héliport',
      'aerialway': 'Station',
      'other': 'Lieu',
    });
    return '$_temp0';
  }

  @override
  String typeStations(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'train': 'Gares',
      'plane': 'Aéroports',
      'bus': 'Arrêts',
      'tram': 'Arrêts',
      'metro': 'Stations',
      'ferry': 'Ports',
      'helicopter': 'Héliports',
      'aerialway': 'Stations',
      'other': 'Lieux',
    });
    return '$_temp0';
  }

  @override
  String typeStationAddress(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'train': 'Adresse de la gare',
      'plane': 'Adresse de l\'aéroport',
      'bus': 'Adresse de l\'arrêt',
      'tram': 'Adresse de l\'arrêt',
      'metro': 'Adresse de la station',
      'ferry': 'Adresse du port',
      'helicopter': 'Adresse de l\'héliport',
      'aerialway': 'Adresse de la station',
      'other': 'Adresse du lieu',
    });
    return '$_temp0';
  }

  @override
  String enterStation(String direction, String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'train': 'Veuillez saisir la gare de départ',
      'plane': 'Veuillez saisir l\'aéroport de départ',
      'bus': 'Veuillez saisir l\'arrêt de départ',
      'tram': 'Veuillez saisir l\'arrêt de départ',
      'metro': 'Veuillez saisir la station de départ',
      'ferry': 'Veuillez saisir le port de départ',
      'helicopter': 'Veuillez saisir l\'héliport de départ',
      'aerialway': 'Veuillez saisir la station de départ',
      'other': 'Veuillez saisir le lieu de départ',
    });
    String _temp1 = intl.Intl.selectLogic(type, {
      'train': 'Veuillez saisir la gare d\'arrivée',
      'plane': 'Veuillez saisir l\'aéroport d\'arrivée',
      'bus': 'Veuillez saisir l\'arrêt d\'arrivée',
      'tram': 'Veuillez saisir l\'arrêt d\'arrivée',
      'metro': 'Veuillez saisir la station d\'arrivée',
      'ferry': 'Veuillez saisir le port d\'arrivée',
      'helicopter': 'Veuillez saisir l\'héliport d\'arrivée',
      'aerialway': 'Veuillez saisir la station d\'arrivée',
      'other': 'Veuillez saisir le lieu d\'arrivée',
    });
    String _temp2 = intl.Intl.selectLogic(type, {
      'train': 'Veuillez saisir la gare',
      'plane': 'Veuillez saisir l\'aéroport',
      'bus': 'Veuillez saisir l\'arrêt',
      'tram': 'Veuillez saisir l\'arrêt',
      'metro': 'Veuillez saisir la station',
      'ferry': 'Veuillez saisir le port',
      'helicopter': 'Veuillez saisir l\'héliport',
      'aerialway': 'Veuillez saisir la station',
      'other': 'Veuillez saisir le lieu',
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
      'train': 'Nom manuel de la gare',
      'plane': 'Nom manuel de l\'aéroport',
      'bus': 'Nom manuel de l\'arrêt',
      'tram': 'Nom manuel de l\'arrêt',
      'metro': 'Nom manuel de la station',
      'ferry': 'Nom manuel du port',
      'helicopter': 'Nom manuel de l\'héliport',
      'aerialway': 'Nom manuel de la station',
      'other': 'Nom manuel du lieu',
    });
    return '$_temp0';
  }

  @override
  String searchStationHint(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'train': 'Rechercher une gare...',
      'plane': 'Rechercher un aéroport...',
      'bus': 'Rechercher un arrêt...',
      'tram': 'Rechercher un arrêt...',
      'metro': 'Rechercher une station...',
      'ferry': 'Rechercher un port...',
      'helicopter': 'Rechercher un héliport...',
      'aerialway': 'Rechercher une station...',
      'other': 'Rechercher un lieu...',
    });
    return '$_temp0';
  }

  @override
  String get statisticsGraphUnitTrips => 'Trajet';

  @override
  String get statisticsGraphUnitDistance => 'Distance';

  @override
  String get statisticsGraphUnitDuration => 'Durée';

  @override
  String get statisticsGraphUnitCo2 => 'CO2';

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
  String get statisticsTripsUnitGiga => 'milliard de trajet';

  @override
  String get statisticsOtherLabel => 'Autres';

  @override
  String get statisticsTotalLabel => 'Total';

  @override
  String get statisticsUnitLabel => 'Unités :';

  @override
  String get statisticsNoDataLabel => 'Pas de données';

  @override
  String get internationalWaters => 'Eaux internationales';

  @override
  String get addTripPageTitle => 'Ajouter un trajet';

  @override
  String get addTripStepBasics => 'Info';

  @override
  String get addTripStepDate => 'Date';

  @override
  String get addTripStepDetails => 'Détails';

  @override
  String get addTripStepPath => 'Trajet';

  @override
  String get addTripStepValidate => 'Valider';

  @override
  String get addTripTransportationMode => 'Moyen de transport';

  @override
  String get addTripImportFr24 => 'Importer les données du vol de FR24';

  @override
  String get addTipSearchStation => 'Search ';

  @override
  String get addTripManualDeparture => 'Départ manuel';

  @override
  String get addTripManualArrival => 'Arrivée manuelle';

  @override
  String get addTripDeparture => 'Départ';

  @override
  String get addTripArrival => 'Arrivée';

  @override
  String get addTripLatitudeShort => 'Lat';

  @override
  String get addTripLongitudeShort => 'Long';

  @override
  String get addTripMapUsageHelper =>
      'En mode manuel vous pouvez saisir les coordonnées directement ou déplacer le marqueur à l’emplacement souhaité après avoir agrandi la carte.';

  @override
  String get addTripOperator => 'Opérateur';

  @override
  String get addTripOperatorHelper =>
      'Virgule ou Entrée pour valider un opérateur inconnu';

  @override
  String get addTripOperatorHint => 'Rechercher un opérateur...';

  @override
  String get addTripOperatorPlaceholderLogo => 'Sélectionnez un opérateur';

  @override
  String get addTripLine => 'Ligne';

  @override
  String get addTripDateTypePrecise => 'Précise';

  @override
  String get addTripDateTypeUnknown => 'Inconnue';

  @override
  String get addTripDateTypeDate => 'Date';

  @override
  String get addTripStartDate => 'Début du trajet';

  @override
  String get addTripEndDate => 'Fin du trajet';

  @override
  String get addTripDuration => 'Durée';

  @override
  String get addTripPast => 'Passé';

  @override
  String get addTripFuture => 'Futur';

  @override
  String get timezoneInformation =>
      'Les fuseaux horaires sont déterminés en fonction des coordonnées du point de départ et du point d’arrivée.';

  @override
  String get addTripDepartureAfterArrival => 'Le départ est après l\'arrivée !';

  @override
  String get addTripFacultative => 'Champs facultatifs';

  @override
  String get addTripMaterial => 'Matérial';

  @override
  String get addTripRegistration => 'Immatriculation';

  @override
  String get addTripSeat => 'Siège';

  @override
  String get addTripNotes => 'Note';

  @override
  String get addTripTicketTitle => 'Billet';

  @override
  String get addTripTicketPrice => 'Prix du billet';

  @override
  String get addTripPurchaseDate => 'Date d\'achat';

  @override
  String get continueTripButton => 'Valider et continuer le voyage';

  @override
  String get addTripPathUseNewRouter => 'Utiliser le nouveau routeur';

  @override
  String addTripNameEnd(String departure, String arrival) {
    return '$departure à $arrival';
  }

  @override
  String get addTripPathHelp =>
      'Le nouveau routeur est en bêta et affiche l\'électrification.\n\nLes routeurs (ancien et nouveau) sont les mêmes pour le train, le tramway et le métro. Vous devrez peut-être ajuster la position des marqueurs pour que le trajet suive le parcours souhaité.';
}
