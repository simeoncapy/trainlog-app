import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_tl.dart';

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
    Locale('tl'),
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

  /// No description provided for @languageWithEmoji.
  ///
  /// In en, this message translates to:
  /// **'🇬🇧 English'**
  String get languageWithEmoji;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get appVersion;

  /// No description provided for @appVersionCopied.
  ///
  /// In en, this message translates to:
  /// **'Version number copied'**
  String get appVersionCopied;

  /// No description provided for @filterButton.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterButton;

  /// No description provided for @descendingOrder.
  ///
  /// In en, this message translates to:
  /// **'Descending order'**
  String get descendingOrder;

  /// No description provided for @ascendingOrder.
  ///
  /// In en, this message translates to:
  /// **'Ascending order'**
  String get ascendingOrder;

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get deleteAll;

  /// No description provided for @deleteAllShort.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get deleteAllShort;

  /// No description provided for @deleteSelection.
  ///
  /// In en, this message translates to:
  /// **'Delete selection'**
  String get deleteSelection;

  /// No description provided for @deleteSelectionShort.
  ///
  /// In en, this message translates to:
  /// **'Selection'**
  String get deleteSelectionShort;

  /// Shared label for delete buttons (trip details action, delete confirmation dialog)
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

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

  /// No description provided for @loggedOut.
  ///
  /// In en, this message translates to:
  /// **'Logged out'**
  String get loggedOut;

  /// No description provided for @createAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAccountButton;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createAccountTitle;

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

  /// No description provided for @createAccountPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'By signing up, you agree to our Privacy Policy.'**
  String get createAccountPrivacyPolicy;

  /// No description provided for @loginWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginWelcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log your next journey'**
  String get loginSubtitle;

  /// No description provided for @loginNewHere.
  ///
  /// In en, this message translates to:
  /// **'New here?'**
  String get loginNewHere;

  /// No description provided for @changeInstance.
  ///
  /// In en, this message translates to:
  /// **'Change instance'**
  String get changeInstance;

  /// No description provided for @instanceSelectorLabel.
  ///
  /// In en, this message translates to:
  /// **'Instance'**
  String get instanceSelectorLabel;

  /// No description provided for @errorCreationAccount.
  ///
  /// In en, this message translates to:
  /// **'Error while creating account.'**
  String get errorCreationAccount;

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
  /// **'Save'**
  String get validateButton;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

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

  /// No description provided for @energy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get energy;

  /// No description provided for @energyElectric.
  ///
  /// In en, this message translates to:
  /// **'Electric'**
  String get energyElectric;

  /// No description provided for @energyElectricShort.
  ///
  /// In en, this message translates to:
  /// **'Elec.'**
  String get energyElectricShort;

  /// No description provided for @energyThermic.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get energyThermic;

  /// No description provided for @energyThermicShort.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get energyThermicShort;

  /// No description provided for @energyHydrogen.
  ///
  /// In en, this message translates to:
  /// **'Hydrogen'**
  String get energyHydrogen;

  /// No description provided for @energyHydrogenShort.
  ///
  /// In en, this message translates to:
  /// **'H2'**
  String get energyHydrogenShort;

  /// manual (opposed as automatic). Should be gender and number neutral.
  ///
  /// In en, this message translates to:
  /// **'manual'**
  String get manual;

  /// Shared label for the trip's seat (trip details, add-trip form)
  ///
  /// In en, this message translates to:
  /// **'Seat'**
  String get seat;

  /// Shared label for a distance (ranking unit, trip details metric, add-trip route summary)
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// Shared label for a duration (statistics graph unit, add-trip form)
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// Shared empty-state message when there is no data to display (ranking, statistics)
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// Shared label for the trip's operator (trips table header, statistics graph dimension, add-trip form)
  ///
  /// In en, this message translates to:
  /// **'Operator'**
  String get operator;

  /// Shared label for the trip's material / rolling stock (trip details, statistics graph dimension, add-trip form)
  ///
  /// In en, this message translates to:
  /// **'Material'**
  String get material;

  /// No description provided for @fillRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill the required fields'**
  String get fillRequiredFields;

  /// No description provided for @visibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get visibility;

  /// No description provided for @visibilityPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get visibilityPublic;

  /// No description provided for @visibilityPublicLong.
  ///
  /// In en, this message translates to:
  /// **'Public trip'**
  String get visibilityPublicLong;

  /// No description provided for @visibilityFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get visibilityFriends;

  /// No description provided for @visibilityFriendsLong.
  ///
  /// In en, this message translates to:
  /// **'Trip visible to friends only'**
  String get visibilityFriendsLong;

  /// No description provided for @visibilityPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get visibilityPrivate;

  /// No description provided for @visibilityPrivateLong.
  ///
  /// In en, this message translates to:
  /// **'Private trip'**
  String get visibilityPrivateLong;

  /// No description provided for @visibilityRestricted.
  ///
  /// In en, this message translates to:
  /// **'Restricted'**
  String get visibilityRestricted;

  /// No description provided for @visibilityRestrictedLong.
  ///
  /// In en, this message translates to:
  /// **'Restricted trip'**
  String get visibilityRestrictedLong;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpTitle;

  /// No description provided for @pageNotImplementedYet.
  ///
  /// In en, this message translates to:
  /// **'This page has not been implemented in the application yet. The website version will be displayed instead. The user interface may not be optimal.'**
  String get pageNotImplementedYet;

  /// No description provided for @departureSingleCharacter.
  ///
  /// In en, this message translates to:
  /// **'D'**
  String get departureSingleCharacter;

  /// No description provided for @arrivalSingleCharacter.
  ///
  /// In en, this message translates to:
  /// **'A'**
  String get arrivalSingleCharacter;

  /// No description provided for @locationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled'**
  String get locationServicesDisabled;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get locationPermissionDenied;

  /// No description provided for @duplicateBtnLabel.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicateBtnLabel;

  /// No description provided for @newBadge.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get newBadge;

  /// Number of passengers
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0 {{count} passengers} =1 {1 passenger} other {{count} passengers}}'**
  String nbrPassengers(num count);

  /// No description provided for @dialogueDefaultInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get dialogueDefaultInfoTitle;

  /// No description provided for @dialogueChangeInstanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Trainlog instance'**
  String get dialogueChangeInstanceTitle;

  /// No description provided for @dialogueChangeInstanceButton.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get dialogueChangeInstanceButton;

  /// No description provided for @dialogueChangeInstanceCustomLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom instance'**
  String get dialogueChangeInstanceCustomLabel;

  /// No description provided for @daySingleCharacter.
  ///
  /// In en, this message translates to:
  /// **'D'**
  String get daySingleCharacter;

  /// No description provided for @setBtnLabel.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get setBtnLabel;

  /// No description provided for @appLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading the app, please wait'**
  String get appLoading;

  /// No description provided for @dataLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading your data, please wait'**
  String get dataLoading;

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

  /// No description provided for @settingsDangerZoneCategory.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get settingsDangerZoneCategory;

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

  /// No description provided for @settingsDateFormat.
  ///
  /// In en, this message translates to:
  /// **'Date Format'**
  String get settingsDateFormat;

  /// No description provided for @settingsHourFormat12.
  ///
  /// In en, this message translates to:
  /// **'12-hour format'**
  String get settingsHourFormat12;

  /// No description provided for @settingsExampleShort.
  ///
  /// In en, this message translates to:
  /// **'Ex:'**
  String get settingsExampleShort;

  /// No description provided for @settingsCurrency.
  ///
  /// In en, this message translates to:
  /// **'Default Currency'**
  String get settingsCurrency;

  /// No description provided for @settingsSprRadius.
  ///
  /// In en, this message translates to:
  /// **'Maximum radius for station search in Geolog'**
  String get settingsSprRadius;

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

  /// No description provided for @settingsMapColorPaletteTrainlogApp.
  ///
  /// In en, this message translates to:
  /// **'Trainlog App'**
  String get settingsMapColorPaletteTrainlogApp;

  /// No description provided for @settingsMapColorPaletteTrainlogWeb.
  ///
  /// In en, this message translates to:
  /// **'Trainlog Web'**
  String get settingsMapColorPaletteTrainlogWeb;

  /// No description provided for @settingsMapColorPaletteColourBlind.
  ///
  /// In en, this message translates to:
  /// **'Palette for colour blindness'**
  String get settingsMapColorPaletteColourBlind;

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

  /// No description provided for @settingsMapColorPaletteVibrantTones.
  ///
  /// In en, this message translates to:
  /// **'Vibrant Tones'**
  String get settingsMapColorPaletteVibrantTones;

  /// Size in mebibytes (MiB)
  ///
  /// In en, this message translates to:
  /// **'{size} MiB'**
  String settingsCache(Object size);

  /// No description provided for @settingsCacheClearButton.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get settingsCacheClearButton;

  /// No description provided for @settingsCacheTitle.
  ///
  /// In en, this message translates to:
  /// **'Cached data'**
  String get settingsCacheTitle;

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

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteAccountRequest.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get settingsDeleteAccountRequest;

  /// email address to request the account deletion
  ///
  /// In en, this message translates to:
  /// **'Unable to open email client, request at {email}'**
  String settingsDeleteAccountError(Object email);

  /// No description provided for @settingsHideWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'Hide warning messages'**
  String get settingsHideWarningMessage;

  /// No description provided for @settingsAccountLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Appear in the public leaderboard'**
  String get settingsAccountLeaderboard;

  /// No description provided for @settingsAccountFriendSearch.
  ///
  /// In en, this message translates to:
  /// **'Appear in friend search'**
  String get settingsAccountFriendSearch;

  /// No description provided for @settingsAccountAppearGlobal.
  ///
  /// In en, this message translates to:
  /// **'Appear on the global live map'**
  String get settingsAccountAppearGlobal;

  /// No description provided for @settingsAccountAppearGlobalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'(public trips only)'**
  String get settingsAccountAppearGlobalSubtitle;

  /// No description provided for @settingsAccountVisibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility to others'**
  String get settingsAccountVisibility;

  /// No description provided for @settingsAccountVisibilitPrivateHelper.
  ///
  /// In en, this message translates to:
  /// **'Your account remains entirely private. No one can view any details or content.'**
  String get settingsAccountVisibilitPrivateHelper;

  /// No description provided for @settingsAccountVisibilitRestrictedHelper.
  ///
  /// In en, this message translates to:
  /// **'Individual trips can be shared using trip-IDs, hiding personal data. But the public profile remains inaccessible.'**
  String get settingsAccountVisibilitRestrictedHelper;

  /// No description provided for @settingsAccountVisibilitPublicHelper.
  ///
  /// In en, this message translates to:
  /// **'Your public profile can be accessed via your username.'**
  String get settingsAccountVisibilitPublicHelper;

  /// No description provided for @settingsInstanceUrl.
  ///
  /// In en, this message translates to:
  /// **'Trainlog instance'**
  String get settingsInstanceUrl;

  /// No description provided for @settingsInstanceMsg.
  ///
  /// In en, this message translates to:
  /// **'You can change the path of the Trainlog instance used by the application on the login page.'**
  String get settingsInstanceMsg;

  /// No description provided for @settingsLicenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get settingsLicenses;

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

  /// No description provided for @rankingYourPosition.
  ///
  /// In en, this message translates to:
  /// **'Your position'**
  String get rankingYourPosition;

  /// The user's position in the ranking, displayed with a # in front of the number
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other {#{count}}}'**
  String rankingPositionValue(num count);

  /// No description provided for @rankingTypeTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get rankingTypeTotal;

  /// No description provided for @rankingTypeVehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get rankingTypeVehicles;

  /// No description provided for @rankingTypeWorld.
  ///
  /// In en, this message translates to:
  /// **'World'**
  String get rankingTypeWorld;

  /// No description provided for @rankingTypeRailwayCoverage.
  ///
  /// In en, this message translates to:
  /// **'Railway coverage'**
  String get rankingTypeRailwayCoverage;

  /// No description provided for @rankingTypeCountries.
  ///
  /// In en, this message translates to:
  /// **'Countries'**
  String get rankingTypeCountries;

  /// No description provided for @rankingTypeCarbon.
  ///
  /// In en, this message translates to:
  /// **'CO2e'**
  String get rankingTypeCarbon;

  /// No description provided for @rankingUnitTrips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get rankingUnitTrips;

  /// No description provided for @rankingUnitTotalCarbon.
  ///
  /// In en, this message translates to:
  /// **'Total CO2e'**
  String get rankingUnitTotalCarbon;

  /// No description provided for @rankingUnitCarbonPerKm.
  ///
  /// In en, this message translates to:
  /// **'CO2e/km'**
  String get rankingUnitCarbonPerKm;

  /// No description provided for @rankingCarbonExplanation.
  ///
  /// In en, this message translates to:
  /// **'Lower g/km is better — most carbon-efficient travellers rank first.'**
  String get rankingCarbonExplanation;

  /// No description provided for @rankingSortAlphabetical.
  ///
  /// In en, this message translates to:
  /// **'Sort alphabetically'**
  String get rankingSortAlphabetical;

  /// No description provided for @rankingSortByValue.
  ///
  /// In en, this message translates to:
  /// **'Sort by value'**
  String get rankingSortByValue;

  /// No description provided for @rankingOrderAscending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get rankingOrderAscending;

  /// No description provided for @rankingOrderDescending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get rankingOrderDescending;

  /// No description provided for @rankingWorldCovered.
  ///
  /// In en, this message translates to:
  /// **'World squares covered'**
  String get rankingWorldCovered;

  /// Subtitle of the user position block in the countries ranking
  ///
  /// In en, this message translates to:
  /// **'Countries visited'**
  String get rankingCountriesVisited;

  /// Unit label shown under the number of countries visited in the ranking list
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {country} other {countries}}'**
  String rankingCountryCountLabel(int count);

  /// No description provided for @rankingNotRanked.
  ///
  /// In en, this message translates to:
  /// **'Not ranked'**
  String get rankingNotRanked;

  /// No description provided for @rankingSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search users…'**
  String get rankingSearchHint;

  /// No description provided for @railCoverageCountriesTab.
  ///
  /// In en, this message translates to:
  /// **'Countries'**
  String get railCoverageCountriesTab;

  /// No description provided for @railCoverageRegionsTab.
  ///
  /// In en, this message translates to:
  /// **'Regions'**
  String get railCoverageRegionsTab;

  /// No description provided for @railCoverageSelectRegion.
  ///
  /// In en, this message translates to:
  /// **'Select a country'**
  String get railCoverageSelectRegion;

  /// Number of regions (subdivisions) of a country in the railway coverage dropdown
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {{count} region} other {{count} regions}}'**
  String railCoverageRegionCount(int count);

  /// Subtitle on the railway coverage drill-down page, e.g. 'Japan railway coverage'
  ///
  /// In en, this message translates to:
  /// **'{area} railway coverage'**
  String railCoverageAreaSubtitle(String area);

  /// Label shown in place of the current user's own name in leader lists
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get railCoverageYou;

  /// No description provided for @menuStatisticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get menuStatisticsTitle;

  /// No description provided for @menuDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get menuDashboardTitle;

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

  /// No description provided for @menuSmartPrerecorderTitle.
  ///
  /// In en, this message translates to:
  /// **'Geolog'**
  String get menuSmartPrerecorderTitle;

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

  /// No description provided for @menuYouTitle.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get menuYouTitle;

  /// No description provided for @menuExploreSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'EXPLORE'**
  String get menuExploreSectionTitle;

  /// No description provided for @menuMenuSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'MENU'**
  String get menuMenuSectionTitle;

  /// No description provided for @menuInboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get menuInboxTitle;

  /// trips label without the number, used after the number in the menu summary card
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0 {trips} =1 {trip} other {trips}}'**
  String menuTripCountLabel(num count);

  /// Number of trips shown in the menu summary card
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0 {No trips yet} =1 {1 trip} other {{count} trips}}'**
  String menuTripCount(num count);

  /// No description provided for @mapFilterYearsAllBtn.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get mapFilterYearsAllBtn;

  /// No description provided for @mapFilterYearsNoneBtn.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get mapFilterYearsNoneBtn;

  /// No description provided for @mapFilterVehicleTypeAllBtn.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get mapFilterVehicleTypeAllBtn;

  /// No description provided for @mapFilterVehicleTypeNoneBtn.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get mapFilterVehicleTypeNoneBtn;

  /// No description provided for @mapFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter map'**
  String get mapFilterTitle;

  /// No description provided for @mapFilterReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get mapFilterReset;

  /// No description provided for @mapFilterTimeRange.
  ///
  /// In en, this message translates to:
  /// **'Time range'**
  String get mapFilterTimeRange;

  /// No description provided for @mapFilterSelectYears.
  ///
  /// In en, this message translates to:
  /// **'Select years'**
  String get mapFilterSelectYears;

  /// Button in the year filter grid that toggles trips with an unknown future date
  ///
  /// In en, this message translates to:
  /// **'Unknown future'**
  String get mapFilterUnknownFuture;

  /// Button in the year filter grid that toggles trips with an unknown past date
  ///
  /// In en, this message translates to:
  /// **'Unknown past'**
  String get mapFilterUnknownPast;

  /// Primary action button in the map filter sheet showing how many trips match the current filters
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0 {Show no trips} =1 {Show 1 trip} other {Show {count} trips}}'**
  String mapFilterShowTrips(num count);

  /// No description provided for @tripPathLoading.
  ///
  /// In en, this message translates to:
  /// **'Trips\' path loading, please wait'**
  String get tripPathLoading;

  /// No description provided for @mapLockedOnPosition.
  ///
  /// In en, this message translates to:
  /// **'Map following your position'**
  String get mapLockedOnPosition;

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

  /// No description provided for @typeEScooter.
  ///
  /// In en, this message translates to:
  /// **'E-Scooter'**
  String get typeEScooter;

  /// No description provided for @typeFunicular.
  ///
  /// In en, this message translates to:
  /// **'Funicular'**
  String get typeFunicular;

  /// No description provided for @typeSki.
  ///
  /// In en, this message translates to:
  /// **'Ski'**
  String get typeSki;

  /// No description provided for @typeRail.
  ///
  /// In en, this message translates to:
  /// **'Rail (others)'**
  String get typeRail;

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

  /// No description provided for @tripsTableHeaderVisibility.
  ///
  /// In en, this message translates to:
  /// **'Visi.'**
  String get tripsTableHeaderVisibility;

  /// Transportation method
  ///
  /// In en, this message translates to:
  /// **'Trip in {vehicle}'**
  String tripsDetailTitle(Object vehicle);

  /// date of the ticket purchase
  ///
  /// In en, this message translates to:
  /// **'purchased on {date}'**
  String tripsDetailPurchasedDate(Object date);

  /// No description provided for @tripsDetailsSectionDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get tripsDetailsSectionDetails;

  /// No description provided for @tripsDetailsLabelVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get tripsDetailsLabelVehicle;

  /// No description provided for @tripsDetailsLabelRegistration.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get tripsDetailsLabelRegistration;

  /// Section header for the trip operator(s)
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {Operator} other {Operators}}'**
  String tripsDetailsSectionOperator(int count);

  /// Section header for the trip country/countries
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {Country} other {Countries}}'**
  String tripsDetailsSectionCountry(int count);

  /// No description provided for @tripsDetailsSectionTicket.
  ///
  /// In en, this message translates to:
  /// **'Ticket'**
  String get tripsDetailsSectionTicket;

  /// No description provided for @tripsDetailsSectionNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get tripsDetailsSectionNotes;

  /// No description provided for @tripsDetailsMetricAvgSpeed.
  ///
  /// In en, this message translates to:
  /// **'Avg speed'**
  String get tripsDetailsMetricAvgSpeed;

  /// No description provided for @tripsDetailsNoDate.
  ///
  /// In en, this message translates to:
  /// **'No date set'**
  String get tripsDetailsNoDate;

  /// No description provided for @tripsDetailsEditButton.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get tripsDetailsEditButton;

  /// No description provided for @tripsDetailsDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this trip?'**
  String get tripsDetailsDeleteDialogTitle;

  /// No description provided for @tripsDetailsDeleteDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this trip?'**
  String get tripsDetailsDeleteDialogMessage;

  /// No description provided for @tripsDetailsDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete trip'**
  String get tripsDetailsDeleteFailed;

  /// No description provided for @tripsDetailsDeleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Trip deleted successfully'**
  String get tripsDetailsDeleteSuccess;

  /// No description provided for @tripsFilterAllYears.
  ///
  /// In en, this message translates to:
  /// **'All Years'**
  String get tripsFilterAllYears;

  /// No description provided for @tripsSearchFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Search trips'**
  String get tripsSearchFilterTitle;

  /// No description provided for @tripsSearchFilterSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Stations, lines, tags...'**
  String get tripsSearchFilterSearchHint;

  /// No description provided for @tripsSearchFilterWhen.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get tripsSearchFilterWhen;

  /// No description provided for @tripsSearchFilterAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get tripsSearchFilterAllTime;

  /// No description provided for @tripsSearchFilterThisYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get tripsSearchFilterThisYear;

  /// No description provided for @tripsSearchFilterPast30Days.
  ///
  /// In en, this message translates to:
  /// **'Past 30 days'**
  String get tripsSearchFilterPast30Days;

  /// No description provided for @tripsSearchFilterFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get tripsSearchFilterFrom;

  /// No description provided for @tripsSearchFilterTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get tripsSearchFilterTo;

  /// Replaces the 'From' date label when no 'To' date is set, meaning the filter matches that exact day
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get tripsSearchFilterOn;

  /// Helper text shown under the date pickers while the From date acts as an exact-day filter
  ///
  /// In en, this message translates to:
  /// **'Only trips on this exact day'**
  String get tripsSearchFilterOnHelper;

  /// No description provided for @tripsSearchFilterCountries.
  ///
  /// In en, this message translates to:
  /// **'Countries'**
  String get tripsSearchFilterCountries;

  /// No description provided for @tripsSearchFilterOperators.
  ///
  /// In en, this message translates to:
  /// **'Operators'**
  String get tripsSearchFilterOperators;

  /// No description provided for @tripsSearchFilterAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get tripsSearchFilterAdd;

  /// Sub-headline above the country list in the picker (rendered uppercase)
  ///
  /// In en, this message translates to:
  /// **'All countries from your trips'**
  String get tripsSearchFilterAllCountriesFromTrips;

  /// Sub-headline above the operator list in the picker (rendered uppercase)
  ///
  /// In en, this message translates to:
  /// **'All operators from your trips'**
  String get tripsSearchFilterAllOperatorsFromTrips;

  /// No description provided for @tripsSearchFilterSearchCountries.
  ///
  /// In en, this message translates to:
  /// **'Search countries...'**
  String get tripsSearchFilterSearchCountries;

  /// No description provided for @tripsSearchFilterSearchOperators.
  ///
  /// In en, this message translates to:
  /// **'Search operators...'**
  String get tripsSearchFilterSearchOperators;

  /// No description provided for @tripsSearchFilterDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get tripsSearchFilterDone;

  /// No description provided for @filterClearButton.
  ///
  /// In en, this message translates to:
  /// **'Clear filter'**
  String get filterClearButton;

  /// No description provided for @tripsAddButton.
  ///
  /// In en, this message translates to:
  /// **'New trip'**
  String get tripsAddButton;

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

  /// No description provided for @graphTypeItinerary.
  ///
  /// In en, this message translates to:
  /// **'Itinerary'**
  String get graphTypeItinerary;

  /// Label for station based on vehicle type (singular)
  ///
  /// In en, this message translates to:
  /// **'{type, select, train{Station} plane{Airport} bus{Stop} tram{Station} metro{Station} ferry{Port} helicopter{Heliport} aerialway{Station} funicular{Station} rail{Station} other{Location}}'**
  String typeStation(String type);

  /// Label for stations based on vehicle type (plural)
  ///
  /// In en, this message translates to:
  /// **'{type, select, train{Stations} plane{Airports} bus{Stops} tram{Stations} metro{Stations} ferry{Ports} helicopter{Heliports} aerialway{Stations} funicular{Stations} rail{Stations} other{Locations}}'**
  String typeStations(String type);

  /// Label for stations address based on vehicle type
  ///
  /// In en, this message translates to:
  /// **'{type, select, train{Address of the station} plane{Address of the airport} bus{Address of the stop} tram{Address of the station} metro{Address of the station} ferry{Address of the port} helicopter{Address of the heliport} aerialway{Address of the station} funicular{Address of the station} rail{Address of the station} other{Address of the location}}'**
  String typeStationAddress(String type);

  /// Prompts the user to enter a departure or arrival station, airport, port, stop, etc., depending on the vehicle type.
  ///
  /// In en, this message translates to:
  /// **'{direction, select, departure{{type, select, train{Please enter the departure station} plane{Please enter the departure airport} bus{Please enter the departure stop} tram{Please enter the departure station} metro{Please enter the departure station} ferry{Please enter the departure port} helicopter{Please enter the departure heliport} aerialway{Please enter the departure station} funicular{Please enter the departure station} rail{Please enter the departure station} other{Please enter the departure location}}} arrival{{type, select, train{Please enter the arrival station} plane{Please enter the arrival airport} bus{Please enter the arrival stop} tram{Please enter the arrival station} metro{Please enter the arrival station} ferry{Please enter the arrival port} helicopter{Please enter the arrival heliport} aerialway{Please enter the arrival station} funicular{Please enter the arrival station} rail{Please enter the arrival station} other{Please enter the arrival location}}} other{{type, select, train{Please enter the station} plane{Please enter the airport} bus{Please enter the stop} tram{Please enter the station} metro{Please enter the station} ferry{Please enter the port} helicopter{Please enter the heliport} aerialway{Please enter the station} funicular{Please enter the station} rail{Please enter the station} other{Please enter the location}}}}'**
  String enterStation(String direction, String type);

  /// Label asking for the manual/custom name of the station (airport, port, stop, heliport, etc.) depending on the vehicle type.
  ///
  /// In en, this message translates to:
  /// **'{type, select, train{Manual name of the station} plane{Manual name of the airport} bus{Manual name of the stop} tram{Manual name of the station} metro{Manual name of the station} ferry{Manual name of the port} helicopter{Manual name of the heliport} aerialway{Manual name of the station} funicular{Manual name of the station} rail{Manual name of the station} other{Manual name of the location}}'**
  String manualNameStation(String type);

  /// Hint for the search field for stations
  ///
  /// In en, this message translates to:
  /// **'{type, select, train{Search station...} plane{Search airport...} bus{Search stop...} tram{Search station...} metro{Search station...} ferry{Search port...} helicopter{Search heliport...} aerialway{Search station...} funicular{Search station...} rail{Search station...} other{Search location...}}'**
  String searchStationHint(String type);

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

  /// No description provided for @statisticsGraphUnitCo2.
  ///
  /// In en, this message translates to:
  /// **'CO2'**
  String get statisticsGraphUnitCo2;

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

  /// No description provided for @statisticsPieWip.
  ///
  /// In en, this message translates to:
  /// **'The pie chart is WIP'**
  String get statisticsPieWip;

  /// No description provided for @statisticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statisticsTitle;

  /// No description provided for @statisticsViewBar.
  ///
  /// In en, this message translates to:
  /// **'Bar'**
  String get statisticsViewBar;

  /// No description provided for @statisticsViewPie.
  ///
  /// In en, this message translates to:
  /// **'Pie'**
  String get statisticsViewPie;

  /// No description provided for @statisticsViewTable.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get statisticsViewTable;

  /// No description provided for @internationalWaters.
  ///
  /// In en, this message translates to:
  /// **'International waters'**
  String get internationalWaters;

  /// Fractional progress label of the add-trip wizard, e.g. 'STEP 1 / 7'
  ///
  /// In en, this message translates to:
  /// **'STEP {current} / {total}'**
  String addTripStepProgress(int current, int total);

  /// Headline of the vehicle type selection step of the add-trip wizard
  ///
  /// In en, this message translates to:
  /// **'How did you travel?'**
  String get addTripVehicleTypeTitle;

  /// Muted instruction subtitle under the headline of the vehicle type selection step
  ///
  /// In en, this message translates to:
  /// **'Pick the vehicle type for this trip'**
  String get addTripVehicleTypeSubtitle;

  /// Headline of the departure/arrival selection step of the add-trip wizard
  ///
  /// In en, this message translates to:
  /// **'Where did you go?'**
  String get addTripRouteTitle;

  /// Muted instruction subtitle under the headline of the departure/arrival selection step
  ///
  /// In en, this message translates to:
  /// **'Search by name, or switch to Manual to drop a pin'**
  String get addTripRouteSubtitle;

  /// Tooltip of the button swapping the departure and arrival of the trip being created
  ///
  /// In en, this message translates to:
  /// **'Swap departure and arrival'**
  String get addTripSwapTooltip;

  /// Tab selecting the by-name station search mode on the route step
  ///
  /// In en, this message translates to:
  /// **'By name'**
  String get addTripModeByName;

  /// Tab selecting the manual coordinates mode on the route step
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get addTripModeManual;

  /// Headline of the operator selection step of the add-trip wizard
  ///
  /// In en, this message translates to:
  /// **'Who operated it?'**
  String get addTripOperatorTitle;

  /// Label of the block listing the operators already selected for the trip
  ///
  /// In en, this message translates to:
  /// **'Selected operators'**
  String get addTripSelectedOperators;

  /// Label of the block listing operator suggestions based on the trip's route
  ///
  /// In en, this message translates to:
  /// **'Suggested for this route'**
  String get addTripSuggestedOperators;

  /// Helper text for the block listing operator suggestions based on the trip's route
  ///
  /// In en, this message translates to:
  /// **'Based on your previous trips in this country and vehicle type.'**
  String get addTripSuggestedOperatorsHelper;

  /// Dashed button in the operator search overlay creating a custom operator from the typed text
  ///
  /// In en, this message translates to:
  /// **'Add as a custom operator'**
  String get addTripAddCustomOperator;

  /// Subtitle of an operator suggestion: how many saved trips used this operator
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {1 trip} other {{count} trips}}'**
  String addTripOperatorTripCount(int count);

  /// Small text action above the Continue button on optional wizard steps, skipping the step
  ///
  /// In en, this message translates to:
  /// **'Skip — I don\'t know'**
  String get addTripSkipButton;

  /// No description provided for @addTripExitConfirmationDialogueTitle.
  ///
  /// In en, this message translates to:
  /// **'Do you want to exit?'**
  String get addTripExitConfirmationDialogueTitle;

  /// No description provided for @addTripExitConfirmationDialogueContent.
  ///
  /// In en, this message translates to:
  /// **'The trip data have been modified, they will be lost. Do you really want to exit the creation of the trip?'**
  String get addTripExitConfirmationDialogueContent;

  /// No description provided for @addTripTransportationMode.
  ///
  /// In en, this message translates to:
  /// **'Transportation mode'**
  String get addTripTransportationMode;

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

  /// No description provided for @addTripMapUsageHelper.
  ///
  /// In en, this message translates to:
  /// **'In manual mode you can enter the coordinates directly or move the marker to the desired position after expanding the map.'**
  String get addTripMapUsageHelper;

  /// No description provided for @addTripOperatorHint.
  ///
  /// In en, this message translates to:
  /// **'Search operator...'**
  String get addTripOperatorHint;

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

  /// No description provided for @addTripRealTime.
  ///
  /// In en, this message translates to:
  /// **'Real time'**
  String get addTripRealTime;

  /// No description provided for @addTripOriginDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Scheduled day'**
  String get addTripOriginDayLabel;

  /// No description provided for @addTripResetToScheduled.
  ///
  /// In en, this message translates to:
  /// **'Reset to scheduled time'**
  String get addTripResetToScheduled;

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

  /// No description provided for @timezoneInformation.
  ///
  /// In en, this message translates to:
  /// **'The time zones are based on the coordinates of the departure and the arrival.'**
  String get timezoneInformation;

  /// No description provided for @addTripDepartureAfterArrival.
  ///
  /// In en, this message translates to:
  /// **'Departure after arrival!'**
  String get addTripDepartureAfterArrival;

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

  /// No description provided for @addTripPurchaseDate.
  ///
  /// In en, this message translates to:
  /// **'Purchase date'**
  String get addTripPurchaseDate;

  /// No description provided for @continueTripButton.
  ///
  /// In en, this message translates to:
  /// **'Save and continue the journey'**
  String get continueTripButton;

  /// No description provided for @addTripPathUseNewRouter.
  ///
  /// In en, this message translates to:
  /// **'Use the new router'**
  String get addTripPathUseNewRouter;

  /// No description provided for @addTripPathHelp.
  ///
  /// In en, this message translates to:
  /// **'The new router is in beta and shows electrification.\n\nThe routers (old and new) are the same for train, tram, and metro. You may need to fine-tune the peg placement to get it to route on the desired path.'**
  String get addTripPathHelp;

  /// No description provided for @addTicketPageTitle.
  ///
  /// In en, this message translates to:
  /// **'New Ticket'**
  String get addTicketPageTitle;

  /// No description provided for @addTagPageTitle.
  ///
  /// In en, this message translates to:
  /// **'New Tag'**
  String get addTagPageTitle;

  /// No description provided for @addTripPathRoutingErrorBannerMessage.
  ///
  /// In en, this message translates to:
  /// **'Routing error detected. Please check the trip path and adjust the peg points if necessary.'**
  String get addTripPathRoutingErrorBannerMessage;

  /// No description provided for @addTripRecordingMsg.
  ///
  /// In en, this message translates to:
  /// **'Your trip is being recorded, please wait'**
  String get addTripRecordingMsg;

  /// No description provided for @addTripFinishMsg.
  ///
  /// In en, this message translates to:
  /// **'Your trip has been added successfully'**
  String get addTripFinishMsg;

  /// Error message displayed when adding a trip fails
  ///
  /// In en, this message translates to:
  /// **'An error occurred while adding your trip, please try again (error: {errorCode}).'**
  String addTripFinishErrorMsg(String errorCode);

  /// No description provided for @addTripFinishFeedbackWarning.
  ///
  /// In en, this message translates to:
  /// **'The trip has been added but the feedback from the server is incomplete. Please refresh and verify the trip details.'**
  String get addTripFinishFeedbackWarning;

  /// No description provided for @addTripPathGeodesic.
  ///
  /// In en, this message translates to:
  /// **'Geodesic path'**
  String get addTripPathGeodesic;

  /// No description provided for @addTripPathFr24.
  ///
  /// In en, this message translates to:
  /// **'FR24 path'**
  String get addTripPathFr24;

  /// Headline of the temporal data step of the add-trip wizard
  ///
  /// In en, this message translates to:
  /// **'When was it?'**
  String get addTripWhenTitle;

  /// Tab of an endpoint block on the when step: the trip ran with no delay
  ///
  /// In en, this message translates to:
  /// **'On time'**
  String get addTripOnTime;

  /// Tab of an endpoint block on the when step: the trip was delayed or early, showing the delay inputs
  ///
  /// In en, this message translates to:
  /// **'Delayed'**
  String get addTripDelayed;

  /// Label of the Past/Future selector of the unknown-date mode of the when step
  ///
  /// In en, this message translates to:
  /// **'Roughly when'**
  String get addTripRoughlyWhen;

  /// Lowercase tag appended in parentheses to the label of optional inputs, e.g. 'Duration (optional)'
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get addTripOptional;

  /// Gray placeholder of the optional duration row when no duration has been entered
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get addTripDurationNotSet;

  /// Muted helper text under the card of the date-only mode of the when step
  ///
  /// In en, this message translates to:
  /// **'No exact times — just the day it happened.'**
  String get addTripDateOnlyHelper;

  /// Inline computed trip duration at the bottom of the precise mode of the when step
  ///
  /// In en, this message translates to:
  /// **'Duration: {duration}'**
  String addTripDurationSummary(String duration);

  /// Inline computed trip duration including delays, with the scheduled duration in parentheses
  ///
  /// In en, this message translates to:
  /// **'Duration: {duration} (scheduled {scheduled})'**
  String addTripDurationSummaryScheduled(String duration, String scheduled);

  /// Headline of the optional details step of the add-trip wizard
  ///
  /// In en, this message translates to:
  /// **'Any more details?'**
  String get addTripDetailsTitle;

  /// Muted instruction subtitle under the headline of the optional details step
  ///
  /// In en, this message translates to:
  /// **'All optional — add what you know'**
  String get addTripDetailsSubtitle;

  /// Label of the line name field of the details step
  ///
  /// In en, this message translates to:
  /// **'Line name'**
  String get addTripLineName;

  /// Label of the vehicle registration number field of the details step
  ///
  /// In en, this message translates to:
  /// **'Registration number'**
  String get addTripRegistrationNumber;

  /// Headline of the ticket, energy and visibility step of the add-trip wizard
  ///
  /// In en, this message translates to:
  /// **'Ticket & extras'**
  String get addTripTicketExtrasTitle;

  /// Label of the ticket price field of the ticket step
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get addTripPrice;

  /// Snackbar shown when opening the actual-time picker while the scheduled time is not set yet
  ///
  /// In en, this message translates to:
  /// **'Select the scheduled time first'**
  String get addTripSelectScheduledTimeFirst;

  /// Prefix in front of the endpoint timezone string under the date/time pickers of the when step
  ///
  /// In en, this message translates to:
  /// **'Timezone:'**
  String get addTripTimezoneLabel;

  /// Helper text above the delay inputs of a delayed endpoint on the when step
  ///
  /// In en, this message translates to:
  /// **'Set the delay or advance using minutes or the actual time.'**
  String get addTripDelayHelper;

  /// Headline of the final route-check step of the add-trip wizard
  ///
  /// In en, this message translates to:
  /// **'Check the route'**
  String get addTripCheckRouteTitle;

  /// Muted instruction subtitle under the headline of the route-check step
  ///
  /// In en, this message translates to:
  /// **'Adjust the path on the map if it isn\'t quite right'**
  String get addTripCheckRouteSubtitle;

  /// Uppercase section label above the summary card of the route-check step
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get addTripSummaryTitle;

  /// Label of the vehicle type row of the summary card of the route-check step
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get addTripSummaryVehicle;

  /// Label of the summary card row showing the duration derived from the user's manual time inputs
  ///
  /// In en, this message translates to:
  /// **'Theoretical duration'**
  String get addTripSummaryTheoreticalDuration;

  /// Label of the summary card row showing the duration computed live by the mapping router engine
  ///
  /// In en, this message translates to:
  /// **'Estimated route duration'**
  String get addTripSummaryEstimatedDuration;

  /// Small button filling the purchase date with the current date. Keep it short — abbreviate if needed (e.g. 'Auj.' in French)
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get addTripTodayButton;

  /// No description provided for @aboutPageAboutSubPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Trainlog'**
  String get aboutPageAboutSubPageTitle;

  /// No description provided for @aboutPageHowToSubPageTitle.
  ///
  /// In en, this message translates to:
  /// **'How To'**
  String get aboutPageHowToSubPageTitle;

  /// No description provided for @aboutPagePrivacySubPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get aboutPagePrivacySubPageTitle;

  /// No description provided for @supportTrainlogButton.
  ///
  /// In en, this message translates to:
  /// **'Support Trainlog'**
  String get supportTrainlogButton;

  /// No description provided for @joinDiscordButton.
  ///
  /// In en, this message translates to:
  /// **'Join the community on Discord'**
  String get joinDiscordButton;

  /// No description provided for @websiteRepoButton.
  ///
  /// In en, this message translates to:
  /// **'Repository of the website'**
  String get websiteRepoButton;

  /// No description provided for @applicationRepoButton.
  ///
  /// In en, this message translates to:
  /// **'Repository of the application'**
  String get applicationRepoButton;

  /// Text displayed if a page file doesn't exist in the user langue. Please replace '**your language**' by the name of the language.
  ///
  /// In en, this message translates to:
  /// **'This page is currently displayed in English because it is not yet available in **your language**.'**
  String get pageNotAvailableInUserLanguage;

  /// No description provided for @tableOfContents.
  ///
  /// In en, this message translates to:
  /// **'Table of content'**
  String get tableOfContents;

  /// No description provided for @prerecorderExplanationTitle.
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get prerecorderExplanationTitle;

  /// No description provided for @prerecorderExplanation.
  ///
  /// In en, this message translates to:
  /// **'The Geolog tool is a smart pre-recorder. When you click on the record button, it will automatically save your current coordinate with the date and time. Later on, you could select two geologs and use them to create a new trip with the saved data.'**
  String get prerecorderExplanation;

  /// No description provided for @prerecorderExplanationStation.
  ///
  /// In en, this message translates to:
  /// **'This tool will automatically look for the station name and display it if found (this works only for rail, bus, and ferry). The closest stations (you can change the radius in settings) will be displayed and you can select the best one.'**
  String get prerecorderExplanationStation;

  /// No description provided for @prerecorderExplanationDelete.
  ///
  /// In en, this message translates to:
  /// **'After the trip has been created, the two geologs are automatically deleted.'**
  String get prerecorderExplanationDelete;

  /// No description provided for @prerecorderExplanationPrivacy.
  ///
  /// In en, this message translates to:
  /// **'The data are saved on your device only.'**
  String get prerecorderExplanationPrivacy;

  /// No description provided for @prerecorderRecordButton.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get prerecorderRecordButton;

  /// No description provided for @prerecorderCreateTripButton.
  ///
  /// In en, this message translates to:
  /// **'Create a trip'**
  String get prerecorderCreateTripButton;

  /// No description provided for @prerecorderNoData.
  ///
  /// In en, this message translates to:
  /// **'No data recorded'**
  String get prerecorderNoData;

  /// No description provided for @prerecorderUnknownStation.
  ///
  /// In en, this message translates to:
  /// **'Unknown station'**
  String get prerecorderUnknownStation;

  /// No description provided for @prerecorderDeleteSelectionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure to delete the selection? This action is irreversible.'**
  String get prerecorderDeleteSelectionConfirm;

  /// No description provided for @prerecorderDeleteAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure to delete all the recorded geologs? This action is irreversible.'**
  String get prerecorderDeleteAllConfirm;

  /// No description provided for @prerecorderSelectStation.
  ///
  /// In en, this message translates to:
  /// **'Select a station'**
  String get prerecorderSelectStation;

  /// No description provided for @prerecorderNoStationReachable.
  ///
  /// In en, this message translates to:
  /// **'No station reachable'**
  String get prerecorderNoStationReachable;

  /// Indicates how far the user is from the station
  ///
  /// In en, this message translates to:
  /// **'{distance} m away'**
  String prerecorderAway(String distance);

  /// Indicates how many stations were found
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0 {No stations found} =1 {1 station found} other {{count} stations found}}'**
  String prerecorderStationsFound(num count);

  /// No description provided for @prerecorderErrorLessThanTwoSelected.
  ///
  /// In en, this message translates to:
  /// **'Please select two geologs to create a trip'**
  String get prerecorderErrorLessThanTwoSelected;

  /// No description provided for @prerecorderErrorMoreThanTwoSelected.
  ///
  /// In en, this message translates to:
  /// **'Please select only two geologs to create a trip'**
  String get prerecorderErrorMoreThanTwoSelected;

  /// No description provided for @prerecorderErrorDepartureAfterArrival.
  ///
  /// In en, this message translates to:
  /// **'The departure cannot be after the arrival'**
  String get prerecorderErrorDepartureAfterArrival;

  /// No description provided for @prerecorderErrorTypeSameForDepartureArrival.
  ///
  /// In en, this message translates to:
  /// **'The departure and arrival must be of the same vehicle type, or unknown type'**
  String get prerecorderErrorTypeSameForDepartureArrival;

  /// No description provided for @prerecorderErrorFetchingStation.
  ///
  /// In en, this message translates to:
  /// **'Error while fetching the stations'**
  String get prerecorderErrorFetchingStation;

  /// No description provided for @prerecorderSelectRailType.
  ///
  /// In en, this message translates to:
  /// **'Type of rail transport'**
  String get prerecorderSelectRailType;

  /// No description provided for @prerecorderSelectVehicleType.
  ///
  /// In en, this message translates to:
  /// **'Type of transport'**
  String get prerecorderSelectVehicleType;

  /// No description provided for @inboxPageTitle.
  ///
  /// In en, this message translates to:
  /// **'News & Updates'**
  String get inboxPageTitle;

  /// No description provided for @inboxModified.
  ///
  /// In en, this message translates to:
  /// **'(modified)'**
  String get inboxModified;

  /// The date of modification of a message
  ///
  /// In en, this message translates to:
  /// **'(modified on {date})'**
  String inboxModifiedIndication(String date);

  /// No description provided for @trainglogStatusPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Trainlog Status'**
  String get trainglogStatusPageTitle;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingPage1Title.
  ///
  /// In en, this message translates to:
  /// **'Visualise your travels'**
  String get onboardingPage1Title;

  /// No description provided for @onboardingPage1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Keeping track of your journeys made easy. See all your train, bus, ferry, and aeroplane journeys neatly on a map.'**
  String get onboardingPage1Subtitle;

  /// No description provided for @onboardingPage2Title.
  ///
  /// In en, this message translates to:
  /// **'Explore your statistics'**
  String get onboardingPage2Title;

  /// No description provided for @onboardingPage2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'See a statistical breakdown of how, when, and where you have travelled.\n\nGet useful statistics on your most frequently visited stations, most frequently used operators, and how much of your country\'s railway network you have been on.'**
  String get onboardingPage2Subtitle;

  /// No description provided for @onboardingPage3Title.
  ///
  /// In en, this message translates to:
  /// **'Share your travels'**
  String get onboardingPage3Title;

  /// No description provided for @onboardingPage3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Create shareable links about your trips to share your travel plans with anyone.'**
  String get onboardingPage3Subtitle;

  /// No description provided for @onboardingPage4Title.
  ///
  /// In en, this message translates to:
  /// **'Leaderboards'**
  String get onboardingPage4Title;

  /// No description provided for @onboardingPage4Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Are you a frequent traveller? See how your travels stack up against other members worldwide.'**
  String get onboardingPage4Subtitle;

  /// No description provided for @onboardingLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Activation of location services'**
  String get onboardingLocationTitle;

  /// No description provided for @onboardingLocationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Trainlog uses the location of your device to centre the map on your position, or to record your position when you use the Geolog function. This is not mandatory.'**
  String get onboardingLocationSubtitle;

  /// No description provided for @onboardingLocationActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate location'**
  String get onboardingLocationActivate;

  /// No description provided for @onboardingLocationSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingLocationSkip;

  /// No description provided for @tapAgainToExit.
  ///
  /// In en, this message translates to:
  /// **'Tap again to exit'**
  String get tapAgainToExit;

  /// No description provided for @tripsEmptyList.
  ///
  /// In en, this message translates to:
  /// **'No trips yet'**
  String get tripsEmptyList;

  /// No description provided for @tripCardDateUndefined.
  ///
  /// In en, this message translates to:
  /// **'Undefined'**
  String get tripCardDateUndefined;
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
      <String>['en', 'fr', 'ja', 'tl'].contains(locale.languageCode);

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
    case 'tl':
      return AppLocalizationsTl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
