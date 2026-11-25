import 'package:flutter/foundation.dart';

import 'package:trainlog_app/core/data/models/ranking_model.dart';

/// State of one area's rail-coverage leaderboard (a country or a region):
/// the contenders ranked once by coverage, the sort toggles and the search.
///
/// The competitive rank is computed once from the coverage percentage
/// (highest first); sorting and searching only change what is displayed.
class RailAreaRankingController extends ChangeNotifier {
  RailAreaRankingController({
    required RailPercentageEntry entry,
    required this.currentUsername,
  }) : ranked = buildRailUserRows(entry);

  /// Every contender, by coverage (highest first).
  final List<RailUserRow> ranked;

  /// The signed-in user's login name, whose row is highlighted.
  final String? currentUsername;

  bool _alphabetical = false;
  bool _descending = true;
  bool _searchOpen = false;
  String _query = '';

  bool get alphabetical => _alphabetical;
  bool get descending => _descending;
  bool get searchOpen => _searchOpen;
  String get query => _query;

  void toggleAlphabetical() {
    _alphabetical = !_alphabetical;
    notifyListeners();
  }

  void toggleDirection() {
    _descending = !_descending;
    notifyListeners();
  }

  void openSearch() {
    if (_searchOpen) return;
    _searchOpen = true;
    notifyListeners();
  }

  /// Closes the search and clears the query.
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

  /// Whether [row] is the signed-in user's.
  bool isCurrentUser(RailUserRow row) {
    final me = currentUsername?.toLowerCase();
    return me != null && row.username.toLowerCase() == me;
  }

  /// The signed-in user's row, or null when they are not ranked here.
  RailUserRow? get myRow {
    for (final r in ranked) {
      if (isCurrentUser(r)) return r;
    }
    return null;
  }

  /// Rows in display order, filtered by the search (each row keeps its
  /// competitive rank).
  List<RailUserRow> get displayRows {
    final list = List<RailUserRow>.of(ranked);
    if (_alphabetical) {
      list.sort(
        (a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()),
      );
    } else {
      list.sort((a, b) {
        final cmp = b.percent.compareTo(a.percent);
        if (cmp != 0) return cmp;
        return a.username.toLowerCase().compareTo(b.username.toLowerCase());
      });
    }
    final ordered = _descending ? list : list.reversed.toList();
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return ordered;
    return ordered.where((r) => r.username.toLowerCase().contains(q)).toList();
  }

  /// Whether the row at [index] of [rows] shows its rank: tied rows next to
  /// each other show it on the first one only, unless sorted by name.
  bool showsRank(List<RailUserRow> rows, int index) =>
      index == 0 ||
      _alphabetical ||
      rows[index - 1].percent != rows[index].percent;
}
