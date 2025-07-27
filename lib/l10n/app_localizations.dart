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

  /// No description provided for @settingsAppCategory.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get settingsAppCategory;

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
