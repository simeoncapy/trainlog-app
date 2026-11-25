import 'package:flutter/foundation.dart';

import 'package:trainlog_app/core/data/models/ranking.dart';

/// State of the Ranking page around the leaderboard data
/// ([RankingProvider]): the username search.
///
/// The search filters the rows shown, never their ranks.
class RankingPageController extends ChangeNotifier {
  bool _searchOpen = false;
  String _query = '';

  /// Whether the search field is shown.
  bool get searchOpen => _searchOpen;

  /// The text typed in the search field.
  String get query => _query;

  void openSearch() {
    if (_searchOpen) return;
    _searchOpen = true;
    notifyListeners();
  }

  /// Hides the search field and clears its text.
  void closeSearch() {
    if (!_searchOpen && _query.isEmpty) return;
    _searchOpen = false;
    _query = '';
    notifyListeners();
  }

  void toggleSearch() => _searchOpen ? closeSearch() : openSearch();

  set query(String value) {
    if (value == _query) return;
    _query = value;
    notifyListeners();
  }

  /// The [entries] whose username contains the query (all of them when the
  /// query is blank), in the same order.
  List<RankingDisplayEntry> filter(List<RankingDisplayEntry> entries) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return entries;
    return entries
        .where((e) => e.username.toLowerCase().contains(q))
        .toList();
  }
}
