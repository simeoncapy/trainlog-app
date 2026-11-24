import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainlog_app/ui/adaptive/adaptive_bottom_navbar.dart';
import 'package:trainlog_app/ui/design.dart';
import 'package:trainlog_app/ui/tokens/app_theme.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

void main() {
  tearDown(() => AppPlatform.debugDesignOverride = null);

  testWidgets('iOS: four tabs, and "Home" is the trailing button', (t) async {
    AppPlatform.debugDesignOverride = DesignLanguage.cupertino;
    final tapped = <int>[];
    var menuTaps = 0;

    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: AdaptiveBottomNavBar(
              currentIndex: 0,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
                BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Trips'),
                BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Ranking'),
                BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
              ],
              onTap: tapped.add,
              onMenuTap: () => menuTaps++,
              menuLabel: 'Home',
            ),
          ),
        ),
      ),
    );
    await t.pump();

    // The menu is not a tab: no "Home" label among them. (The glass bar
    // draws its labels twice, under and inside the lens.)
    expect(find.text('Home'), findsNothing);
    for (final label in ['Map', 'Trips', 'Ranking', 'Stats']) {
      expect(find.text(label), findsWidgets);
    }

    await t.tap(find.text('Ranking').first);
    await t.pump(const Duration(milliseconds: 500));
    expect(tapped, [2]);

    // The menu button holds the Trainlog logo, at the trailing end.
    final logo = find.byType(SvgPicture);
    expect(logo, findsOneWidget);
    expect(
      t.getCenter(logo).dx,
      greaterThan(t.getCenter(find.text('Stats').first).dx),
    );
    await t.tap(logo);
    await t.pump(const Duration(milliseconds: 500));
    expect(menuTaps, 1);
    expect(tapped, [2]);
  });
}
