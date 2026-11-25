import 'package:flutter_test/flutter_test.dart';
import 'package:trainlog_app/core/data/models/ranking.dart';
import 'package:trainlog_app/features/ranking/ranking_page_controller.dart';

RankingDisplayEntry _entry(int rank, String name) =>
    RankingDisplayEntry(rank: rank, username: name);

void main() {
  final entries = [
    _entry(1, 'lea.voyage'),
    _entry(2, 'railfan_kyoto'),
    _entry(3, 'Leandro'),
  ];

  test('no query keeps every row', () {
    final c = RankingPageController();
    expect(c.filter(entries), same(entries));
  });

  test('the query filters usernames, case-insensitively, keeping ranks', () {
    final c = RankingPageController()..query = ' LEA ';
    final rows = c.filter(entries);
    expect(rows.map((e) => e.username), ['lea.voyage', 'Leandro']);
    expect(rows.map((e) => e.rank), [1, 3]);
  });

  test('closing the search clears the query', () {
    final c = RankingPageController();
    var notified = 0;
    c.addListener(() => notified++);

    c.toggleSearch();
    expect(c.searchOpen, isTrue);
    c.query = 'kyoto';
    c.toggleSearch();

    expect(c.searchOpen, isFalse);
    expect(c.query, isEmpty);
    expect(c.filter(entries), same(entries));
    expect(notified, 3);
  });
}
