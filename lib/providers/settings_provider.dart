import 'package:country_codes_plus/country_codes_plus.dart';
import 'package:flutter/material.dart';
import 'package:geodesy/geodesy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trainlog_app/data/models/polyline_filter_state.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';
import 'package:trainlog_app/providers/trips_provider.dart';
import 'package:trainlog_app/services/geo_permission_service.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';

enum PathDisplayOrder {
  creationDate,
  tripDate,
  tripDatePlaneOver,
}

class SettingsProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');
  String _dateFormat = 'yyyy/MM/dd';
  bool _hourFormat12 = false;
  PathDisplayOrder _pathDisplayOrder = PathDisplayOrder.creationDate;
  MapColorPalette _mapColorPalette = MapColorPalette.trainlogWeb;
  bool _shouldReloadPolylines = true;
  bool _mapDisplayUserLocationMarker = true;
  bool _hideWarningMessage = false;
  String _currency = "EUR";
  int _sprRadius = 500;
  String _userInstanceUrl = ""; // Cannot be changed in settings, only on login page before login, and only if not authenticated yet.

  // _SP members are stored in the Shared Preferences only, they cannot be modified by the user in settings
  bool _SP_onboardingCompleted = false;
  bool _SP_hasRunBefore = false;
  LatLng? _SP_userPosition;
  bool _SP_refusedToSharePosition = false;
  String? _SP_authUsername;
  bool _SP_shouldLoadTripsFromApi = true;
  DateTime? _SP_mostRecentFutureTripOnMap;
  bool _SP_isSmartPrerecorderExplanationExpanded = true;
  DateTime _SP_lastNewsVisit = DateTime.now().toUtc();
  DateTime? _SP_lastFetchingTrips;
  String? _SP_lastUsedInstanceUrl;

  // Map filters
  PolylineYearFilter _SP_mapPolylineYearFilter = PolylineYearFilter.all;
  Set<int> _SP_mapPolylineSelectedYears = {};
  Set<VehicleType> _SP_mapPolylineDeselectedTypes = {};
  int _SP_mapPolylineYearFilterOption = 0;

  static const _kLastUserLat = 'last_user_lat';
  static const _kLastUserLng = 'last_user_lng';
  static const _kUsernameKey = 'auth.username';

  static const _kMapPolylineYearFilter = 'map_polyline_year_filter';
  static const _kMapPolylineSelectedYears = 'map_polyline_selected_years';
  static const _kMapPolylineDeselectedTypes = 'map_polyline_deselected_types';
  static const _kMapPolylineYearFilterOption = 'map_polyline_year_filter_option';

  // Getters
  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  String get dateFormat => _dateFormat;
  bool get hourFormat12 => _hourFormat12;
  PathDisplayOrder get pathDisplayOrder => _pathDisplayOrder;
  MapColorPalette get mapColorPalette => _mapColorPalette;
  bool get shouldReloadPolylines => _shouldReloadPolylines;
  bool get mapDisplayUserLocationMarker => _mapDisplayUserLocationMarker;
  bool get hideWarningMessage => _hideWarningMessage;
  String get currency => _currency;
  int get sprRadius => _sprRadius;
  String get userInstanceUrl => _userInstanceUrl;

  bool get onboardingCompleted => _SP_onboardingCompleted;
  bool get hasRunBefore => _SP_hasRunBefore;
  LatLng? get userPosition => _SP_userPosition;
  bool get refusedToSharePosition => _SP_refusedToSharePosition;
  String? get authUsername => _SP_authUsername;
  bool get shouldLoadTripsFromApi => _SP_shouldLoadTripsFromApi;
  DateTime? get mostRecentFutureTripOnMap => _SP_mostRecentFutureTripOnMap;
  bool get isSmartPrerecorderExplanationExpanded => _SP_isSmartPrerecorderExplanationExpanded;
  DateTime get lastNewsVisit => _SP_lastNewsVisit;
  DateTime? get lastFetchingTrips => _SP_lastFetchingTrips;
  String? get lastUsedInstanceUrl => _SP_lastUsedInstanceUrl;

  PolylineYearFilter get mapPolylineYearFilter => _SP_mapPolylineYearFilter;
  Set<int> get mapPolylineSelectedYears => Set.unmodifiable(_SP_mapPolylineSelectedYears);
  Set<VehicleType> get mapPolylineDeselectedTypes => Set.unmodifiable(_SP_mapPolylineDeselectedTypes);
  int get mapPolylineYearFilterOption => _SP_mapPolylineYearFilterOption;

  late final Future<void> _ready;

  /// Completes once every persisted value has been loaded into memory.
  /// Await this before reading settings during app startup.
  Future<void> get ready => _ready;

  SettingsProvider() {
    _ready = _loadAll();
  }

  /// Loads every persisted value into memory. Reading from an empty
  /// SharedPreferences store yields the documented defaults, so this also
  /// doubles as a "reset to defaults" once the store has been cleared.
  ///
  /// All values are loaded from a single SharedPreferences instance and
  /// listeners are notified exactly once, after everything is in memory.
  Future<void> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();

    // Each loader is run in isolation: a corrupt or incompatible stored
    // value (e.g. an unparseable date, or a vehicle-type/year-filter name
    // left over from an older app version) must fall back to its default
    // rather than abort the whole load. Since _ready is awaited before
    // runApp, an uncaught throw here would prevent the app from starting.
    final loaders = <void Function(SharedPreferences)>[
      // Shared Preference in settings
      _loadTheme,
      _loadLocale,
      _loadDateFormat,
      _loadHourFormat12,
      _loadPathDisplayOrder,
      _loadMapColorPalette,
      _loadShouldReloadPolylines,
      _loadMapDisplayUserLocationMarker,
      _loadHideWarningMessage,
      _loadCurrency,
      _loadSprRadius,
      _loadUserInstanceUrl,

      // Shared Preference only (_SP) i.e. internal to the app
      _loadOnboardingCompleted,
      _loadHasRunBefore,
      _loadLastUserPosition,
      _loadRefusedToSharePosition,
      _loadUsername,
      _loadShouldLoadTripsFromApi,
      _loadIsSmartPrerecorderExplanationExpanded,
      _loadLastNewsVisit,
      _loadLastFetchingTrips,
      _loadLastUsedInstanceUrl,
      _loadMapPolylineFilterState,
    ];

    for (final load in loaders) {
      try {
        load(prefs);
      } catch (e) {
        debugPrint('⚠️ SettingsProvider: a value failed to load, keeping default: $e');
      }
    }

    notifyListeners();
  }

  void _loadTheme(SharedPreferences prefs) {
    final theme = prefs.getString('theme');
    if (theme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (theme == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }
  }

  void setTheme(ThemeMode themeMode) async {
    if (_themeMode == themeMode) return;
    _themeMode = themeMode;
    final prefs = await SharedPreferences.getInstance();
    if (themeMode == ThemeMode.dark) {
      await prefs.setString('theme', 'dark');
    } else if (themeMode == ThemeMode.light) {
      await prefs.setString('theme', 'light');
    } else {
      await prefs.remove('theme');
    }
    notifyListeners();
  }

  // ------------------------------------------------------------------------------

  void _loadLocale(SharedPreferences prefs) {
    final languageCode = prefs.getString('language_code');
    if (languageCode != null) {
      _locale = Locale(languageCode);
    } else {
      // No saved preference: use the phone's language if the app supports it,
      // otherwise fall back to English.
      final supportedLanguageCodes = AppLocalizations.supportedLocales
          .map((locale) => locale.languageCode)
          .toSet();
      final deviceLanguageCode =
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      if (supportedLanguageCodes.contains(deviceLanguageCode)) {
        _locale = Locale(deviceLanguageCode);
      } else {
        _locale = const Locale('en', 'GB');
      }
    }
  }

  void setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    await CountryCodes.init(_locale);
    notifyListeners();
  }

  // ------------------------------------------------------------------------------

  void _loadDateFormat(SharedPreferences prefs) {
    final u = prefs.getString('date_format');
    _dateFormat = u ?? 'yyyy/MM/dd';
  }

  void setDateFormat(String format) async {
    if (_dateFormat == format) return;
    _dateFormat = format;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('date_format', format);
    notifyListeners();
  }

  // ------------------------------------------------------------------------------

  void _loadHourFormat12(SharedPreferences prefs) {
    final format12 = prefs.getBool('hour_format_12');
    _hourFormat12 = format12 ?? false;
  }

  void setHourFormat12(bool format12) async {
    if (_hourFormat12 == format12) return;
    _hourFormat12 = format12;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hour_format_12', format12);
    notifyListeners();
  }

  // ------------------------------------------------------------------------------

  void _loadPathDisplayOrder(SharedPreferences prefs) {
    final pathOrder = prefs.getString('path_display_order');
    if (pathOrder != null) {
      _pathDisplayOrder = PathDisplayOrder.values.firstWhere(
        (e) => e.name == pathOrder,
        orElse: () => PathDisplayOrder.creationDate,
      );
    } else {
      _pathDisplayOrder = PathDisplayOrder.creationDate;
    }
  }

  void setPathDisplayOrder(PathDisplayOrder pathOrder) async {
    if (_pathDisplayOrder == pathOrder) return;
    _pathDisplayOrder = pathOrder;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('path_display_order', pathOrder.name);
    notifyListeners();
  }

  // ------------------------------------------------------------------------------

  void _loadMapColorPalette(SharedPreferences prefs) {
    final palette = prefs.getString('map_color_palette');
    if (palette != null) {
      _mapColorPalette = MapColorPalette.values.firstWhere(
        (e) => e.name == palette,
        orElse: () => MapColorPalette.trainlogWeb,
      );
    } else {
      _mapColorPalette = MapColorPalette.trainlogWeb;
    }
  }

  void setMapColorPalette(MapColorPalette palette) async {
    if (_mapColorPalette == palette) return;
    _mapColorPalette = palette;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('map_color_palette', palette.name);
    notifyListeners();
  }

  // ------------------------------------------------------------------------------

  void _loadShouldReloadPolylines(SharedPreferences prefs) {
    final reload = prefs.getBool('should_reload_polylines');
    _shouldReloadPolylines = reload ?? false;
  }

  void setShouldReloadPolylines(bool reload) async {
    if (_shouldReloadPolylines == reload) return;
    _shouldReloadPolylines = reload;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('should_reload_polylines', reload);
    notifyListeners();
  }

  // ------------------------------------------------------------------------------

  void _loadMapDisplayUserLocationMarker(SharedPreferences prefs) {
    final marker = prefs.getBool('display_user_marker');
    _mapDisplayUserLocationMarker = marker ?? false;
  }

  void setMapDisplayUserLocationMarker(bool maker) async {
    if (_mapDisplayUserLocationMarker == maker) return;
    _mapDisplayUserLocationMarker = maker;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('display_user_marker', maker);
    notifyListeners();
  }

  // ------------------------------------------------------------------------------

  void _loadHideWarningMessage(SharedPreferences prefs) {
    final h = prefs.getBool('hide_warning_message');
    _hideWarningMessage = h ?? false;
  }

  void setHideWarningMessage(bool hide) async {
    if (_hideWarningMessage == hide) return;
    _hideWarningMessage = hide;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hide_warning_message', hide);
    notifyListeners();
  }

  // ------------------------------------------------------------------------------

  void _loadCurrency(SharedPreferences prefs) {
    final c = prefs.getString('currency');
    _currency = c ?? 'EUR';
  }

  void setCurrency(String currency) async {
    if (_currency == currency) return;
    _currency = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', currency);
    notifyListeners();
  }

  // ------------------------------------------------------------------------------

  void _loadSprRadius(SharedPreferences prefs) {
    final r = prefs.getInt('spr_radius');
    _sprRadius = r ?? 500;
  }

  void setSprRadius(int sprRadius) async {
    if (_sprRadius == sprRadius) return;
    _sprRadius = sprRadius;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('spr_radius', sprRadius);
    notifyListeners();
  }

  // ------------------------------------------------------------------------------

  void _loadUserInstanceUrl(SharedPreferences prefs) {
    final u = prefs.getString('user_instance_url');
    _userInstanceUrl = u ?? '';
  }

  void setUserInstanceUrl(String url) async {
    if (_userInstanceUrl == url) return;
    _userInstanceUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_instance_url', url);
    notifyListeners();
  }

  // ------------------------------------------------------------------------------
  // ------- SHARED PREFERENCES NOT IN SETTINGS MENU ------------------------------
  // ------------------------------------------------------------------------------

  void _loadLastUserPosition(SharedPreferences prefs) {
    if (!prefs.containsKey(_kLastUserLat) || !prefs.containsKey(_kLastUserLng)) {
      _SP_userPosition = null;
    }
    final lat = prefs.getDouble(_kLastUserLat);
    final lng = prefs.getDouble(_kLastUserLng);
    if (lat == null || lng == null)
    {
      _SP_userPosition = null;
    }
    else
    {
      _SP_userPosition = LatLng(lat, lng);
    }
  }

  void setLastUserPosition(LatLng pos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kLastUserLat, pos.latitude);
    await prefs.setDouble(_kLastUserLng, pos.longitude);
  }

  // ------------------------------------------------------------------------------

  void _loadRefusedToSharePosition(SharedPreferences prefs) {
    final p = prefs.getBool('refused_share_position');
    _SP_refusedToSharePosition = p ?? false;
  }

  void setRefusedToSharePosition(bool p) async {
    if (_SP_refusedToSharePosition == p) return;
    _SP_refusedToSharePosition = p;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('refused_share_position', p);
    notifyListeners();
  }

  // ------------------------------------------------------------------------------

  Future<void> setUsername(String username) async {
    if(_SP_authUsername == username) return;
    _SP_authUsername = username;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUsernameKey, username);
    notifyListeners();
  }

  void _loadUsername(SharedPreferences prefs) {
    final u = prefs.getString(_kUsernameKey);
    _SP_authUsername = u;
  }

  Future<void> clearUsername() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUsernameKey);
    _SP_authUsername = null;
    notifyListeners();
  }

  // ------------------------------------------------------------------------------

  void _loadShouldLoadTripsFromApi(SharedPreferences prefs) {
    final p = prefs.getBool('should_load_trips_from_api');
    _SP_shouldLoadTripsFromApi = p ?? false;
  }

  void setShouldLoadTripsFromApi(bool p) async {
    if (_SP_shouldLoadTripsFromApi == p) return;
    _SP_shouldLoadTripsFromApi = p;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('should_load_trips_from_api', p);
    notifyListeners();
  }

  // ------------------------------------------------------------------------------

  void _loadIsSmartPrerecorderExplanationExpanded(SharedPreferences prefs) {
    final p = prefs.getBool('is_spr_explanation_expanded');
    _SP_isSmartPrerecorderExplanationExpanded = p ?? true;
  }

  void setIsSmartPrerecorderExplanationExpanded(bool p) async {
    if (_SP_isSmartPrerecorderExplanationExpanded == p) return;
    _SP_isSmartPrerecorderExplanationExpanded = p;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_spr_explanation_expanded', p);
    notifyListeners();
  }

  // ------------------------------------------------------------------------------

  void _loadLastNewsVisit(SharedPreferences prefs) {
    final p = prefs.getString('last_news_visit');
    _SP_lastNewsVisit = DateTime.parse(p ?? DateTime.now().toUtc().toIso8601String());
  }

  void setLastNewsVisit(DateTime p) async {
    if (_SP_lastNewsVisit == p) return;
    _SP_lastNewsVisit = p;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_news_visit', p.toIso8601String());
    notifyListeners();
  }

  void setLastNewsVisitNowUtc() async {
    setLastNewsVisit(DateTime.now().toUtc());
  }

  // ------------------------------------------------------------------------------

  void _loadLastFetchingTrips(SharedPreferences prefs) {
    final p = prefs.getString('last_fetching_trips');
    _SP_lastFetchingTrips = p == null ? null : DateTime.parse(p);
  }

  void setLastFetchingTrips(DateTime p) async {
    if (_SP_lastFetchingTrips == p) return;
    _SP_lastFetchingTrips = p;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_fetching_trips', p.toIso8601String());
    notifyListeners();
  }

  void setLastFetchingTripsNowUtc() async {
    setLastFetchingTrips(DateTime.now().toUtc());
  }

  Future<void> clearLastFetchingTrips() async {
    if (_SP_lastFetchingTrips == null) return;
    _SP_lastFetchingTrips = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_fetching_trips');
    notifyListeners();
  }

  // ------------------------------------------------------------------------------
  
  void _loadLastUsedInstanceUrl(SharedPreferences prefs) {
    final u = prefs.getString('last_used_instance_url');
    _SP_lastUsedInstanceUrl = u;
  }

  void setLastUsedInstanceUrl(String? url) async {
    if (_SP_lastUsedInstanceUrl == url) return;
    _SP_lastUsedInstanceUrl = url;
    final prefs = await SharedPreferences.getInstance();
    if (url != null) {
      await prefs.setString('last_used_instance_url', url);
    } else {
      await prefs.remove('last_used_instance_url');
    }
    notifyListeners();
  }

  // ------------------------------------------------------------------------------

  void _loadOnboardingCompleted(SharedPreferences prefs) {
    _SP_onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
  }

  void _loadHasRunBefore(SharedPreferences prefs) {
    _SP_hasRunBefore = prefs.getBool('has_run_before') ?? false;
  }

  /// SharedPreferences are wiped on uninstall (unlike the iOS Keychain),
  /// so the absence of this flag identifies a fresh install at startup.
  Future<void> markHasRunBefore() async {
    if (_SP_hasRunBefore) return;
    _SP_hasRunBefore = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_run_before', true);
  }

  Future<void> completeOnboarding() async {
    if (_SP_onboardingCompleted) return;
    _SP_onboardingCompleted = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    notifyListeners();
  }

  Future<void> resetOnboarding(TrainlogProvider trainlog, TripsProvider trips) async {
    await clearSharedPreference();
    const GeoPermissionService().removePermission(this);
    _SP_onboardingCompleted = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_completed');
    await trainlog.logout(this, trips);
    notifyListeners();
  }

  /// Wipes every persisted SharedPreferences value and resets the in-memory
  /// state back to its defaults.
  Future<void> clearSharedPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _loadAll();
  }

  // ------------------------------------------------------------------------------

  void _loadMapPolylineFilterState(SharedPreferences prefs) {
    _SP_mapPolylineYearFilter = PolylineYearFilter.values[
        prefs.getInt(_kMapPolylineYearFilter) ?? 0];

    _SP_mapPolylineSelectedYears =
        (prefs.getStringList(_kMapPolylineSelectedYears) ?? [])
            .map(int.parse)
            .toSet();

    _SP_mapPolylineDeselectedTypes =
        (prefs.getStringList(_kMapPolylineDeselectedTypes) ?? [])
            .map((name) => VehicleType.values.firstWhere((e) => e.name == name))
            .toSet();

    _SP_mapPolylineYearFilterOption =
        prefs.getInt(_kMapPolylineYearFilterOption) ?? 0;
  }

  Future<void> setMapPolylineFilterState({
    required PolylineYearFilter yearFilter,
    required Set<int> selectedYears,
    required Set<VehicleType> deselectedTypes,
    required int yearFilterOption,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    _SP_mapPolylineYearFilter = yearFilter;
    _SP_mapPolylineSelectedYears = {...selectedYears};
    _SP_mapPolylineDeselectedTypes = {...deselectedTypes};
    _SP_mapPolylineYearFilterOption = yearFilterOption;

    await prefs.setInt(_kMapPolylineYearFilter, yearFilter.index);
    await prefs.setStringList(
      _kMapPolylineSelectedYears,
      selectedYears.map((e) => e.toString()).toList(),
    );
    await prefs.setStringList(
      _kMapPolylineDeselectedTypes,
      deselectedTypes.map((e) => e.name).toList(),
    );
    await prefs.setInt(_kMapPolylineYearFilterOption, yearFilterOption);

    notifyListeners();
  }
}
