import 'package:diacritic/diacritic.dart';
import 'package:flutter/foundation.dart';

/// State of a user's visited-countries page: the country codes in the
/// backend order (most visited first) and the two sort toggles. Display
/// only: the data is never refetched.
class UserCountriesController extends ChangeNotifier {
  UserCountriesController({required this.username, required this.countryCodes});

  /// The user whose countries are listed (the page title).
  final String username;

  /// ISO country codes in the backend order (by trip count, most visited
  /// first).
  final List<String> countryCodes;

  bool _alphabetical = false;
  bool _descending = true;

  bool get alphabetical => _alphabetical;
  bool get descending => _descending;

  void toggleAlphabetical() {
    _alphabetical = !_alphabetical;
    notifyListeners();
  }

  void toggleDirection() {
    _descending = !_descending;
    notifyListeners();
  }

  /// Case- and diacritic-insensitive key, so e.g. "Île de Man" and
  /// "États-Unis" sort under I and E rather than at the end of the list.
  static String collate(String s) => removeDiacritics(s).toLowerCase();

  /// [items] in display order: the backend order by default, or by their
  /// localized [nameOf] when alphabetical; the direction reverses either.
  List<T> arrange<T>(List<T> items, String Function(T item) nameOf) {
    final list = List<T>.of(items);
    if (_alphabetical) {
      list.sort((a, b) => collate(nameOf(a)).compareTo(collate(nameOf(b))));
    }
    return _descending ? list : list.reversed.toList();
  }
}
