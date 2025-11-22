import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('ja'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Trainlog'**
  String get appTitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get language;

  /// No description provided for @mainMenuButtonTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open menu'**
  String get mainMenuButtonTooltip;

  /// No description provided for @filterButton.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterButton;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginButton;

  /// No description provided for @logoutButton.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logoutButton;

  /// No description provided for @createAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAccountButton;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get emailHint;

  /// No description provided for @emailHelper.
  ///
  /// In en, this message translates to:
  /// **'In case you forget your password'**
  String get emailHelper;

  /// No description provided for @emailRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequiredLabel;

  /// No description provided for @emailValidLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get emailValidLabel;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// No description provided for @usernameRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Username is required'**
  String get usernameRequiredLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordShowLabel.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get passwordShowLabel;

  /// No description provided for @passwordHideLabel.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get passwordHideLabel;

  /// No description provided for @passwordRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequiredLabel;

  /// No description provided for @createAccountButtonShort.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createAccountButtonShort;

  /// No description provided for @loginToYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Log in to your account'**
  String get loginToYourAccount;

  /// The username
  ///
  /// In en, this message translates to:
  /// **'Hello {username}'**
  String menuHello(Object username);

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Login failed, please check your credentials'**
  String get connectionError;

  /// No description provided for @refreshCompleted.
  ///
  /// In en, this message translates to:
  /// **'Refresh completed'**
  String get refreshCompleted;

  /// No description provided for @nextButton.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextButton;

  /// No description provided for @previousButton.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previousButton;

  /// No description provided for @validateButton.
  ///
  /// In en, this message translates to:
  /// **'Validate'**
  String get validateButton;

  /// No description provided for @nameField.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameField;

  /// No description provided for @auto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get auto;

  /// No description provided for @energyElectric.
  ///
  /// In en, this message translates to:
  /// **'Electric'**
  String get energyElectric;

  /// No description provided for @energyThermic.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get energyThermic;

  /// No description provided for @energyHydrogen.
  ///
  /// In en, this message translates to:
  /// **'Hydrogen'**
  String get energyHydrogen;

  /// No description provided for @settingsAppCategory.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get settingsAppCategory;

  /// No description provided for @settingsMapCategory.
  ///
  /// In en, this message translates to:
  /// **'Map Settings'**
  String get settingsMapCategory;

  /// No description provided for @settingsAccountCategory.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get settingsAccountCategory;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsThemeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get settingsThemeMode;

  /// No description provided for @settingsDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsDark;

  /// No description provided for @settingsLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsLight;

  /// No description provided for @settingsSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsSystem;

  /// No description provided for @settingsMapPathDisplayOrder.
  ///
  /// In en, this message translates to:
  /// **'Order of trip paths on the map'**
  String get settingsMapPathDisplayOrder;

  /// No description provided for @settingMapPathDisplayOrderByCreation.
  ///
  /// In en, this message translates to:
  /// **'By creation date'**
  String get settingMapPathDisplayOrderByCreation;

  /// No description provided for @settingMapPathDisplayOrderByTrip.
  ///
  /// In en, this message translates to:
  /// **'By trip date'**
  String get settingMapPathDisplayOrderByTrip;

  /// No description provided for @settingMapPathDisplayOrderByTripAndPlane.
  ///
  /// In en, this message translates to:
  /// **'By trip date (with flights above)'**
  String get settingMapPathDisplayOrderByTripAndPlane;

  /// No description provided for @settingsMapColorPalette.
  ///
  /// In en, this message translates to:
  /// **'Colour palette for trips'**
  String get settingsMapColorPalette;

  /// No description provided for @settingsMapColorPaletteTrainlogWeb.
  ///
  /// In en, this message translates to:
  /// **'Trainlog Web'**
  String get settingsMapColorPaletteTrainlogWeb;

  /// No description provided for @settingsMapColorPaletteTrainlogVariation.
  ///
  /// In en, this message translates to:
  /// **'Trainlog Variation'**
  String get settingsMapColorPaletteTrainlogVariation;

  /// No description provided for @settingsMapColorPaletteTrainlogRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get settingsMapColorPaletteTrainlogRed;

  /// No description provided for @settingsMapColorPaletteTrainlogGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get settingsMapColorPaletteTrainlogGreen;

  /// No description provided for @settingsMapColorPaletteTrainlogBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get settingsMapColorPaletteTrainlogBlue;

  /// Size in mebibytes (MiB)
  ///
  /// In en, this message translates to:
  /// **'Cached data ({size} MiB)'**
  String settingsCache(Object size);

  /// No description provided for @settingsCacheClearButton.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get settingsCacheClearButton;

  /// No description provided for @settingsCacheClearConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear cache?'**
  String get settingsCacheClearConfirmTitle;

  /// No description provided for @settingsCacheClearConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the cached data? This action is irreversible. The next loading of the app might take longer.'**
  String get settingsCacheClearConfirmMessage;

  /// No description provided for @settingsCacheClearedMessage.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared successfully.'**
  String get settingsCacheClearedMessage;

  /// No description provided for @settingsDisplayUserMarker.
  ///
  /// In en, this message translates to:
  /// **'Display current position'**
  String get settingsDisplayUserMarker;

  /// No description provided for @menuMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get menuMapTitle;

  /// No description provided for @menuTripsTitle.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get menuTripsTitle;

  /// No description provided for @menuRankingTitle.
  ///
  /// In en, this message translates to:
  /// **'Ranking'**
  String get menuRankingTitle;

  /// No description provided for @menuStatisticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get menuStatisticsTitle;

  /// No description provided for @menuCoverageTitle.
  ///
  /// In en, this message translates to:
  /// **'Coverage'**
  String get menuCoverageTitle;

  /// No description provided for @menuTagsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get menuTagsTitle;

  /// No description provided for @menuTicketsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get menuTicketsTitle;

  /// No description provided for @menuFriendsTitle.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get menuFriendsTitle;

  /// No description provided for @menuSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get menuSettingsTitle;

  /// No description provided for @menuAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get menuAboutTitle;

  /// No description provided for @tripPathLoading.
  ///
  /// In en, this message translates to:
  /// **'Trips\' path loading, please wait'**
  String get tripPathLoading;

  /// No description provided for @yearTitle.
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get yearTitle;

  /// No description provided for @yearAllList.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get yearAllList;

  /// No description provided for @yearPastList.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get yearPastList;

  /// No description provided for @yearFutureList.
  ///
  /// In en, this message translates to:
  /// **'Future'**
  String get yearFutureList;

  /// No description provided for @yearYearList.
  ///
  /// In en, this message translates to:
  /// **'Years...'**
  String get yearYearList;

  /// No description provided for @typeTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Types'**
  String get typeTitle;

  /// No description provided for @typeTrain.
  ///
  /// In en, this message translates to:
  /// **'Train'**
  String get typeTrain;

  /// No description provided for @typeTram.
  ///
  /// In en, this message translates to:
  /// **'Tramway'**
  String get typeTram;

  /// No description provided for @typeMetro.
  ///
  /// In en, this message translates to:
  /// **'Metro'**
  String get typeMetro;

  /// No description provided for @typeBus.
  ///
  /// In en, this message translates to:
  /// **'Bus'**
  String get typeBus;

  /// No description provided for @typeCar.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get typeCar;

  /// No description provided for @typePlane.
  ///
  /// In en, this message translates to:
  /// **'Plane'**
  String get typePlane;

  /// No description provided for @typeFerry.
  ///
  /// In en, this message translates to:
  /// **'Ferry'**
  String get typeFerry;

  /// No description provided for @typeAerialway.
  ///
  /// In en, this message translates to:
  /// **'Aerialway'**
  String get typeAerialway;

  /// No description provided for @typeWalk.
  ///
  /// In en, this message translates to:
  /// **'Walk'**
  String get typeWalk;

  /// No description provided for @typePoi.
  ///
  /// In en, this message translates to:
  /// **'Point of interest'**
  String get typePoi;

  /// No description provided for @typeCycle.
  ///
  /// In en, this message translates to:
  /// **'Bicycle'**
  String get typeCycle;

  /// No description provided for @typeHelicopter.
  ///
  /// In en, this message translates to:
  /// **'Helicopter'**
  String get typeHelicopter;

  /// No description provided for @tripsTableHeaderOriginDestination.
  ///
  /// In en, this message translates to:
  /// **'Origin/Destination'**
  String get tripsTableHeaderOriginDestination;

  /// No description provided for @tripsTableHeaderOrigin.
  ///
  /// In en, this message translates to:
  /// **'Origin'**
  String get tripsTableHeaderOrigin;

  /// No description provided for @tripsTableHeaderDestination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get tripsTableHeaderDestination;

  /// No description provided for @tripsTableHeaderStartTime.
  ///
  /// In en, this message translates to:
  /// **'Departure Time'**
  String get tripsTableHeaderStartTime;

  /// No description provided for @tripsTableHeaderEndTime.
  ///
  /// In en, this message translates to:
  /// **'Arrival Time'**
  String get tripsTableHeaderEndTime;

  /// No description provided for @tripsTableHeaderOperator.
  ///
  /// In en, this message translates to:
  /// **'Operator'**
  String get tripsTableHeaderOperator;

  /// No description provided for @tripsTableHeaderLineName.
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get tripsTableHeaderLineName;

  /// No description provided for @tripsTableHeaderTripLength.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get tripsTableHeaderTripLength;

  /// Transportation method
  ///
  /// In en, this message translates to:
  /// **'Trip in {vehicle}'**
  String tripsDetailTitle(Object vehicle);

  /// No description provided for @tripsDetailsTitleOperator.
  ///
  /// In en, this message translates to:
  /// **'Operator: '**
  String get tripsDetailsTitleOperator;

  /// No description provided for @tripsDetailsTitleVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle: '**
  String get tripsDetailsTitleVehicle;

  /// No description provided for @tripsDetailsTitleSeat.
  ///
  /// In en, this message translates to:
  /// **'Seat: '**
  String get tripsDetailsTitleSeat;

  /// No description provided for @tripsDetailsTitlePrice.
  ///
  /// In en, this message translates to:
  /// **'Price: '**
  String get tripsDetailsTitlePrice;

  /// date of the ticket purchase
  ///
  /// In en, this message translates to:
  /// **'purchased on {date}'**
  String tripsDetailPurchasedDate(Object date);

  /// No description provided for @tripsDetailsTitleNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes: '**
  String get tripsDetailsTitleNotes;

  /// No description provided for @tripsDetailsEditButton.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get tripsDetailsEditButton;

  /// No description provided for @tripsDetailsDeleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get tripsDetailsDeleteButton;

  /// No description provided for @tripsFilterAllCountry.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tripsFilterAllCountry;

  /// No description provided for @tripsFilterAllOperator.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tripsFilterAllOperator;

  /// No description provided for @tripsFilterAllYears.
  ///
  /// In en, this message translates to:
  /// **'All Years'**
  String get tripsFilterAllYears;

  /// No description provided for @tripsFilterKeyword.
  ///
  /// In en, this message translates to:
  /// **'Keyword'**
  String get tripsFilterKeyword;

  /// No description provided for @tripsFilterDateFrom.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get tripsFilterDateFrom;

  /// No description provided for @tripsFilterDateTo.
  ///
  /// In en, this message translates to:
  /// **'to (optional)'**
  String get tripsFilterDateTo;

  /// No description provided for @tripsFilterCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get tripsFilterCountry;

  /// No description provided for @tripsFilterOperator.
  ///
  /// In en, this message translates to:
  /// **'Operator'**
  String get tripsFilterOperator;

  /// No description provided for @tripsFilterType.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Type'**
  String get tripsFilterType;

  /// No description provided for @filterClearButton.
  ///
  /// In en, this message translates to:
  /// **'Clear filter'**
  String get filterClearButton;

  /// No description provided for @graphTypeOperator.
  ///
  /// In en, this message translates to:
  /// **'Operator'**
  String get graphTypeOperator;

  /// No description provided for @graphTypeCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get graphTypeCountry;

  /// No description provided for @graphTypeYears.
  ///
  /// In en, this message translates to:
  /// **'Years'**
  String get graphTypeYears;

  /// No description provided for @graphTypeMaterial.
  ///
  /// In en, this message translates to:
  /// **'Material'**
  String get graphTypeMaterial;

  /// No description provided for @graphTypeItinerary.
  ///
  /// In en, this message translates to:
  /// **'Itinerary'**
  String get graphTypeItinerary;

  /// Label for stations based on vehicle type (plural)
  ///
  /// In en, this message translates to:
  /// **'{type, select, train{Stations} plane{Airports} bus{Stops} tram{Stations} metro{Stations} ferry{Ports} helicopter{Heliports} aerialway{Stations} other{Locations}}'**
  String graphTypeStations(String type);

  /// No description provided for @statisticsGraphUnitTrips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get statisticsGraphUnitTrips;

  /// No description provided for @statisticsGraphUnitDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get statisticsGraphUnitDistance;

  /// No description provided for @statisticsGraphUnitDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get statisticsGraphUnitDuration;

  /// No description provided for @statisticsGraphUnitCo2.
  ///
  /// In en, this message translates to:
  /// **'CO2'**
  String get statisticsGraphUnitCo2;

  /// No description provided for @statisticsDisplayFilters.
  ///
  /// In en, this message translates to:
  /// **'Display the filters'**
  String get statisticsDisplayFilters;

  /// No description provided for @statisticsHideFilters.
  ///
  /// In en, this message translates to:
  /// **'Hide the filters'**
  String get statisticsHideFilters;

  /// No description provided for @statisticsTripsUnitBase.
  ///
  /// In en, this message translates to:
  /// **'trips'**
  String get statisticsTripsUnitBase;

  /// No description provided for @statisticsTripsUnitKilo.
  ///
  /// In en, this message translates to:
  /// **'thousand trips'**
  String get statisticsTripsUnitKilo;

  /// No description provided for @statisticsTripsUnitMega.
  ///
  /// In en, this message translates to:
  /// **'million trips'**
  String get statisticsTripsUnitMega;

  /// No description provided for @statisticsTripsUnitGiga.
  ///
  /// In en, this message translates to:
  /// **'billion trips'**
  String get statisticsTripsUnitGiga;

  /// No description provided for @statisticsOtherLabel.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get statisticsOtherLabel;

  /// No description provided for @statisticsTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get statisticsTotalLabel;

  /// No description provided for @statisticsUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit:'**
  String get statisticsUnitLabel;

  /// No description provided for @statisticsNoDataLabel.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get statisticsNoDataLabel;

  /// No description provided for @internationalWaters.
  ///
  /// In en, this message translates to:
  /// **'International waters'**
  String get internationalWaters;

  /// No description provided for @addTripPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a Trip'**
  String get addTripPageTitle;

  /// Label for the first step when adding a trip. Choose a short word if possible
  ///
  /// In en, this message translates to:
  /// **'Basics'**
  String get addTripStepBasics;

  /// Label for the second step when adding a trip. Choose a short word if possible
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get addTripStepDate;

  /// Label for the third step when adding a trip. Choose a short word if possible
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get addTripStepDetails;

  /// Label for the fourth step when adding a trip. Choose a short word if possible
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get addTripStepPath;

  /// Label for the last step when adding a trip. Choose a short word if possible
  ///
  /// In en, this message translates to:
  /// **'Validate'**
  String get addTripStepValidate;

  /// No description provided for @addTripTransportationMode.
  ///
  /// In en, this message translates to:
  /// **'Transportation mode'**
  String get addTripTransportationMode;

  /// No description provided for @addTripManualDeparture.
  ///
  /// In en, this message translates to:
  /// **'Manual departure'**
  String get addTripManualDeparture;

  /// No description provided for @addTripManualArrival.
  ///
  /// In en, this message translates to:
  /// **'Manual arrival'**
  String get addTripManualArrival;

  /// No description provided for @addTripDeparture.
  ///
  /// In en, this message translates to:
  /// **'Departure'**
  String get addTripDeparture;

  /// No description provided for @addTripArrival.
  ///
  /// In en, this message translates to:
  /// **'Arrival'**
  String get addTripArrival;

  /// No description provided for @addTripLatitudeShort.
  ///
  /// In en, this message translates to:
  /// **'Lat'**
  String get addTripLatitudeShort;

  /// No description provided for @addTripLongitudeShort.
  ///
  /// In en, this message translates to:
  /// **'Long'**
  String get addTripLongitudeShort;

  /// No description provided for @addTripOperator.
  ///
  /// In en, this message translates to:
  /// **'Operator'**
  String get addTripOperator;

  /// No description provided for @addTripOperatorHelper.
  ///
  /// In en, this message translates to:
  /// **'Use a comma or enter to validate an unknown operator'**
  String get addTripOperatorHelper;

  /// No description provided for @addTripOperatorHint.
  ///
  /// In en, this message translates to:
  /// **'Search operator...'**
  String get addTripOperatorHint;

  /// No description provided for @addTripOperatorPlaceholderLogo.
  ///
  /// In en, this message translates to:
  /// **'Select an operator'**
  String get addTripOperatorPlaceholderLogo;

  /// No description provided for @addTripLine.
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get addTripLine;

  /// No description provided for @addTripDateTypePrecise.
  ///
  /// In en, this message translates to:
  /// **'Precise'**
  String get addTripDateTypePrecise;

  /// No description provided for @addTripDateTypeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get addTripDateTypeUnknown;

  /// No description provided for @addTripDateTypeDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get addTripDateTypeDate;

  /// No description provided for @addTripStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start of the trip'**
  String get addTripStartDate;

  /// No description provided for @addTripEndDate.
  ///
  /// In en, this message translates to:
  /// **'End of the trip'**
  String get addTripEndDate;

  /// No description provided for @addTripDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get addTripDuration;

  /// No description provided for @addTripPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get addTripPast;

  /// No description provided for @addTripFuture.
  ///
  /// In en, this message translates to:
  /// **'Future'**
  String get addTripFuture;

  /// No description provided for @addTripFacultative.
  ///
  /// In en, this message translates to:
  /// **'Facultative fields'**
  String get addTripFacultative;

  /// No description provided for @addTripMaterial.
  ///
  /// In en, this message translates to:
  /// **'Material'**
  String get addTripMaterial;

  /// No description provided for @addTripRegistration.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get addTripRegistration;

  /// No description provided for @addTripSeat.
  ///
  /// In en, this message translates to:
  /// **'Seat'**
  String get addTripSeat;

  /// No description provided for @addTripNotes.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get addTripNotes;

  /// No description provided for @addTripTicketTitle.
  ///
  /// In en, this message translates to:
  /// **'Ticket'**
  String get addTripTicketTitle;

  /// No description provided for @addTripTicketPrice.
  ///
  /// In en, this message translates to:
  /// **'Ticket price'**
  String get addTripTicketPrice;

  /// No description provided for @addTripPurchaseDate.
  ///
  /// In en, this message translates to:
  /// **'Purchase date'**
  String get addTripPurchaseDate;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
