import 'dart:async';

import 'package:flutter/material.dart';

import 'package:trainlog_app/data/models/ranking_model.dart';
import 'package:trainlog_app/data/models/trips.dart';
import 'package:trainlog_app/features/ranking/ranking_type.dart';
import 'package:trainlog_app/providers/trainlog_provider.dart';

/// Drives the native Ranking feature: which leaderboard is shown, how it is
/// sorted, and the loaded/normalized rows.
///
/// Data is fetched through [TrainlogProvider.rankingApi]. The competitive
/// [RankingDisplayEntry.rank] is computed from the active [sortUnit] (highest
/// first) and is independent of the display-only [alphabetical] / [descending]
/// toggles.
class RankingProvider extends ChangeNotifier {
  final TrainlogProvider _trainlog;

  RankingProvider(this._trainlog);

  // ── UI state ───────────────────────────────────────────────────────────────

  RankingSelection _selection = const RankingSelection.all();
  RankingSortUnit _sortUnit = RankingSortUnit.distance;
  bool _alphabetical = false;
  bool _descending = true;

  RankingSelection get selection => _selection;
  RankingSortUnit get sortUnit => _sortUnit;
  bool get alphabetical => _alphabetical;
  bool get descending => _descending;

  /// World-squares has a single (percentage) unit, so the unit dropdown is
  /// hidden for it.
  bool get showsUnitDropdown => !_selection.isWorldSquares;

  /// The current user's login name, used to highlight their row.
  String? get currentUsername => _trainlog.username;

  // ── Data state ───────────────────────────────────────────────────────────────

  bool _loading = false;
  String? _error;
  List<RankingDisplayEntry> _ranked = const [];

  bool get isLoading => _loading;
  String? get error => _error;

  /// All rows with their competitive rank assigned.
  List<RankingDisplayEntry> get entries => _ranked;

  /// The current user's row, if they appear in the public leaderboard.
  RankingDisplayEntry? get currentUserEntry {
    final me = _trainlog.username;
    if (me == null) return null;
    for (final e in _ranked) {
      if (e.username.toLowerCase() == me.toLowerCase()) return e;
    }
    return null;
  }

  /// Rows in the order they should be displayed (applies the alphabetical and
  /// direction toggles without touching the competitive rank).
  List<RankingDisplayEntry> get displayEntries {
    final list = List<RankingDisplayEntry>.of(_ranked);
    if (_alphabetical) {
      // Natural order: A→Z.
      list.sort(
        (a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()),
      );
    } else {
      // Natural order: highest metric first.
      list.sort((a, b) => _metric(b).compareTo(_metric(a)));
    }
    if (!_descending) {
      return list.reversed.toList();
    }
    return list;
  }

  // ── Mutations ────────────────────────────────────────────────────────────────

  void select(RankingSelection selection) {
    if (selection == _selection || !selection.type.isImplemented) return;
    _selection = selection;
    // World-squares only ranks by percentage; reset to distance otherwise.
    if (selection.isWorldSquares) {
      _sortUnit = RankingSortUnit.distance; // unused while hidden
    }
    unawaited(load());
  }

  set sortUnit(RankingSortUnit unit) {
    if (unit == _sortUnit) return;
    _sortUnit = unit;
    _assignRanks(); // ranking metric changed
    notifyListeners();
  }

  void toggleAlphabetical() {
    _alphabetical = !_alphabetical;
    notifyListeners();
  }

  void toggleDirection() {
    _descending = !_descending;
    notifyListeners();
  }

  // ── Loading ──────────────────────────────────────────────────────────────────

  Future<void> load() async {
    _loading = true;
    _error = null;
    _ranked = const [];
    notifyListeners();

    try {
      final entries = await _fetch(_selection);
      _ranked = entries;
      _assignRanks();
    } catch (e) {
      _error = e.toString();
      _ranked = const [];
    }

    _loading = false;
    notifyListeners();
  }

  Future<List<RankingDisplayEntry>> _fetch(RankingSelection selection) async {
    switch (selection.type) {
      case RankingType.all:
        final res = await _trainlog.fetchRankingAll();
        return _fromLeaderboard(res);
      case RankingType.vehicles:
        final res =
            await _trainlog.fetchRankingForVehicle(selection.vehicle!);
        return _fromLeaderboard(res);
      case RankingType.worldSquares:
        final res = await _trainlog.fetchRankingForWorldSquares();
        return _fromWorldSquares(res);
      case RankingType.railwayCoverage:
      case RankingType.country:
      case RankingType.carbon:
        // Not implemented in this batch; rendered as disabled pills.
        return const [];
    }
  }

  List<RankingDisplayEntry> _fromLeaderboard(
    RankingResult<LeaderboardEntry> res,
  ) {
    return res.entries
        .map(
          (e) => RankingDisplayEntry(
            rank: 0,
            username: e.username,
            distanceKm: e.length / 1000.0,
            trips: e.trips,
            lastModified: e.lastModified,
          ),
        )
        .toList();
  }

  List<RankingDisplayEntry> _fromWorldSquares(WorldSquaresResult res) {
    // Each coverage tier lists the users who reached that percentage. Flatten
    // to one row per user.
    final rows = <RankingDisplayEntry>[];
    for (final tier in res.coverages) {
      for (final user in tier.usernames) {
        rows.add(
          RankingDisplayEntry(
            rank: 0,
            username: user,
            percent: tier.percent,
          ),
        );
      }
    }
    return rows;
  }

  /// The value used both for ranking and for the natural (value) display order.
  double _metric(RankingDisplayEntry e) {
    if (_selection.isWorldSquares) return e.percent ?? 0;
    return _sortUnit == RankingSortUnit.distance
        ? e.distanceKm
        : e.trips.toDouble();
  }

  /// (Re)assigns competitive ranks by the active metric, highest first.
  void _assignRanks() {
    final sorted = List<RankingDisplayEntry>.of(_ranked)
      ..sort((a, b) => _metric(b).compareTo(_metric(a)));
    for (var i = 0; i < sorted.length; i++) {
      sorted[i] = sorted[i].copyWithRank(i + 1);
    }
    _ranked = sorted;
  }
}
