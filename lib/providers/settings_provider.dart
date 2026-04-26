import 'package:flutter/material.dart';
import 'package:geodesy/geodesy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trainlog_app/data/models/polyline_filter_state.dart';
import 'package:trainlog_app/data/models/trips.dart';
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
  String _userInstanceUrl = ""; // Cannot be changed in settings, only on welcome page before login, and only if not authenticated yet.

  // _SP members are stored in the Shared Preferences only, they cannot be modified by the user in settings
  bool _SP_onboardingCompleted = false;
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

  SettingsProvider() {
    // Shared Preference in settings
    _loadTheme();
    _loadLocale();
    _loadDateFormat();
    _loadHourFormat12();
    _loadPathDisplayOrder();
    _loadMapColorPalette();
    _loadShouldReloadPolylines();
    _loadMapDisplayUserLocationMarker();
    _loadHideWarningMessage();
    _loadCurrency();
    _loadSprRadius();
    _loadUserInstanceUrl();

    // Shared Preference only (_SP) i.e. internal to the app
    _loadOnboardingCompleted();
    _loadLastUserPosition();
    _loadRefusedToSharePosition();
    _loadUsername();
    _loadShouldLoadTripsFromApi();
    _loadIsSmartPrerecorderExplanationExpanded();
    _loadLastNewsVisit();
    _loadLastFetchingTrips();
    _loadLastUsedInstanceUrl();
    _loadMapPolylineFilterState();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('theme');
    if (theme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (theme == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
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

  void _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code');
    if (languageCode != null) {
      _locale = Locale(languageCode);
    } else {
      _locale = const Locale('en', 'GB'); // Default locale
    }
    notifyListeners();
  }

  void setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
    notifyListeners();
  }

  // ------------------------------------------------------------------------------

  void _loadDateFormat() async {
    final prefs = await SharedPreferences.getInstance();
    final u = prefs.getString('date_format');
    _dateFormat = u ?? 'yyyy/MM/dd';
    notifyListeners();
  }

  void setDateFormat(String format) async {
    if (_dateFormat == format) return;
    _dateFormat = format;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('date_format', format);
    notifyListeners();
  }

  // ------------------------------------------------------------------------------

  void _loadHourFormat12() async {
    final prefs = await SharedPreferences.getInstance();
    final format12 = prefs.getBool('hour_format_12');
    _hourFormat12 = format12 ?? false;
    notifyListeners();
  }

  void setHourFormat12(bool format12) async {
    if (_hourFormat12 == format12) return;
    _hourFormat12 = format12;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hour_format_12', format12);
    notifyListeners();
  }

  // ------------------------------------------------------------------------------

  void _loadPathDisplayOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final pathOrder = prefs.getString('path_display_order');
    if (pathOrder != null) {
      _pathDisplayOrder = PathDisplayOrder.values.firstWhere(
        (e) => e.name == pathOrder,
        orElse: () => PathDisplayOrder.creationDate,
      );
    } else {
      _pathDisplayOrder = PathDisplayOrder.creationDate;
    }
    notifyListeners();
  }

  void setPathDisplayOrder(PathDisplayOrder pathOrder) async {
    if (_pathDisplayOrder == pathOrder) return;
    _pathDisplayOrder = pathOrder;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('path_display_order', pathOrder.name);
    notifyListeners();
  }

  // ------------------------------------------------------------------------------

  void _loadMapColorPalette() async {
    final prefs = await SharedPreferences.getInstance();
    final palette = prefs.getString('map_color_palette');
    if (palette != null) {
      _mapColorPalette = MapColorPalette.values.firstWhere(
        (e) => e.name == palette,
        orElse: () => MapColorPalette.trainlogWeb,
      );
    } else {
      _mapColorPalette = MapColorPalette.trainlogWeb;
    }
    notifyListeners();
  }

  void setMapColorPalette(MapColorPalette palette) async {
    if (_mapColorPalette == palette) return;
    _mapColorPalette = palette;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('map_color_palette', palette.name);
    notifyListeners();
  }

  // ------------------------------------------------------------------------------

  void _loadShouldReloadPolylines() async {
    final prefs = await SharedPreferences.getInstance();
    final reload = prefs.getBool('should_reload_polylines');
    _shouldReloadPolylines = reload ?? false;
    notifyListeners();
  }

  void setShouldReloadPolylines(bool reload) async {
    if (_shouldReloadPolylines == reload) return;
    _shouldReloadPolylines = reload;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('should_reload_polylines', reload);
    notifyListeners();
  }

  // ------------------------------------------------------------------------------

  void _loadMapDisplayUserLocationMarker() async {
    final prefs = await SharedPreferences.getInstance();
    final marker = prefs.getBool('display_user_marker');
    _mapDisplayUserLocationMarker = marker ?? false;
    notifyListeners();
  }

  void setMapDisplayUserLocationMarker(bool maker) async {
    if (_mapDisplayUserLocationMarker == maker) return;
    _mapDisplayUserLocationMarker = maker;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('display_user_marker', maker);
    notifyListeners();
  }

  // ------------------------------------------------------------------------------

  void _loadHideWarningMessage() async {
    final prefs = await SharedPreferences.getInstance();
    final h = prefs.getBool('hide_warning_message');
    _hideWarningMessage = h ?? false;
    notifyListeners();
  }

  void setHideWarningMessage(bool hide) async {
    if (_hideWarningMessage == hide) return;
    _hideWarningMessage = hide;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hide_warning_message', hide);
    notifyListeners();
  }

  // ------------------------------------------------------------------------------

  void _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final c = prefs.getString('currency');
    _currency = c ?? 'EUR';
    notifyListeners();
  }

  void setCurrency(String currency) async {
    if (_currency == currency) return;
    _currency = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', currency);
    notifyListeners();
  }

  // ------------------------------------------------------------------------------

  void _loadSprRadius() async {
    final prefs = await SharedPreferences.getInstance();
    final r = prefs.getInt('spr_radius');
    _sprRadius = r ?? 500;
    notifyListeners();
  }

  void setSprRadius(int sprRadius) async {
    if (_sprRadius == sprRadius) return;
    _sprRadius = sprRadius;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('spr_radius', sprRadius);
    notifyListeners();
  }

  // ------------------------------------------------------------------------------

  void _loadUserInstanceUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final u = prefs.getString('user_instance_url');
    _userInstanceUrl = u ?? '';
    notifyListeners();
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

  void _loadLastUserPosition() async {
    final prefs = await SharedPreferences.getInstance();
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
    notifyListeners();
  }

  void setLastUserPosition(LatLng pos) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kLastUserLat, pos.latitude);
    await prefs.setDouble(_kLastUserLng, pos.longitude);
  }

  // ------------------------------------------------------------------------------

  void _loadRefusedToSharePosition() async {
    final prefs = await SharedPreferences.getInstance();
    final p = prefs.getBool('refused_share_position');
    _SP_refusedToSharePosition = p ?? false;
    notifyListeners();
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

  void _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final u = prefs.getString(_kUsernameKey);
    _SP_authUsername = u;
    notifyListeners();
  }

  Future<void> clearUsername() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUsernameKey);
    _SP_authUsername = null;
    notifyListeners();
  }

  // ------------------------------------------------------------------------------

  void _loadShouldLoadTripsFromApi() async {
    final prefs = await SharedPreferences.getInstance();
    final p = prefs.getBool('should_load_trips_from_api');
    _SP_shouldLoadTripsFromApi = p ?? false;
    notifyListeners();
  }

  void setShouldLoadTripsFromApi(bool p) async {
    if (_SP_shouldLoadTripsFromApi == p) return;
    _SP_shouldLoadTripsFromApi = p;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('should_load_trips_from_api', p);
    notifyListeners();
  }

  // ------------------------------------------------------------------------------

  void _loadIsSmartPrerecorderExplanationExpanded() async {
    final prefs = await SharedPreferences.getInstance();
    final p = prefs.getBool('is_spr_explanation_expanded');
    _SP_isSmartPrerecorderExplanationExpanded = p ?? true;
    notifyListeners();
  }

  void setIsSmartPrerecorderExplanationExpanded(bool p) async {
    if (_SP_isSmartPrerecorderExplanationExpanded == p) return;
    _SP_isSmartPrerecorderExplanationExpanded = p;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_spr_explanation_expanded', p);
    notifyListeners();
  }

  // ------------------------------------------------------------------------------

  void _loadLastNewsVisit() async {
    final prefs = await SharedPreferences.getInstance();
    final p = prefs.getString('last_news_visit');
    _SP_lastNewsVisit = DateTime.parse(p ?? DateTime.now().toUtc().toIso8601String());
    notifyListeners();
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

  void _loadLastFetchingTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final p = prefs.getString('last_fetching_trips');
    _SP_lastFetchingTrips = p == null ? null : DateTime.parse(p);
    notifyListeners();
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

  // ------------------------------------------------------------------------------
  
  void _loadLastUsedInstanceUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final u = prefs.getString('last_used_instance_url');
    _SP_lastUsedInstanceUrl = u;
    notifyListeners();
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

  void _loadOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    _SP_onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    if (_SP_onboardingCompleted) return;
    _SP_onboardingCompleted = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    notifyListeners();
  }

  // ------------------------------------------------------------------------------

  void _loadMapPolylineFilterState() async {
    final prefs = await SharedPreferences.getInstance();

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

    notifyListeners();
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
