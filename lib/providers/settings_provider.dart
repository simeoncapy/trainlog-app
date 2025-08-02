import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trainlog_app/utils/map_color_palette.dart';

enum PathDisplayOrder {
  creationDate,
  tripDate,
  tripDatePlaneOver,
}

class SettingsProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');
  PathDisplayOrder _pathDisplayOrder = PathDisplayOrder.creationDate;
  MapColorPalette _mapColorPalette = MapColorPalette.trainlogWeb;
  bool _shouldReloadPolylines = true;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  PathDisplayOrder get pathDisplayOrder => _pathDisplayOrder;
  MapColorPalette get mapColorPalette => _mapColorPalette;
  bool get shouldReloadPolylines => _shouldReloadPolylines;

  SettingsProvider() {
    _loadTheme();
    _loadLocale();
    _loadPathDisplayOrder();
    _loadMapColorPalette();
    _loadShouldReloadPolylines();
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
}
