import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainlog_app/features/ranking/cupertino/user_countries_cupertino_view.dart';
import 'package:trainlog_app/features/ranking/material/user_countries_material_view.dart';
import 'package:trainlog_app/features/ranking/user_countries_controller.dart';
import 'package:trainlog_app/features/ranking/user_countries_page.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/design.dart';
import 'package:trainlog_app/ui/tokens/app_theme.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

void main() {
  group('UserCountriesController', () {
    final names = {'FR': 'France', 'IS': 'Island', 'US': 'États-Unis'};
    UserCountriesController make() => UserCountriesController(
      username: 'lea',
      countryCodes: const ['FR', 'IS', 'US'],
    );

    test('keeps the backend order, reversed by the direction', () {
      final c = make();
      expect(c.arrange(c.countryCodes, (x) => names[x]!), ['FR', 'IS', 'US']);
      c.toggleDirection();
      expect(c.arrange(c.countryCodes, (x) => names[x]!), ['US', 'IS', 'FR']);
    });

    test('sorts by name, ignoring accents', () {
      final c = make()..toggleAlphabetical();
      expect(c.arrange(c.countryCodes, (x) => names[x]!), ['US', 'FR', 'IS']);
    });
  });

  group('UserCountriesPage', () {
    tearDown(() => AppPlatform.debugDesignOverride = null);

    for (final design in DesignLanguage.values) {
      testWidgets('${design.name}: its own view and the countries', (t) async {
        AppPlatform.debugDesignOverride = design;
        await t.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const UserCountriesPage(
              username: 'lea',
              countryCodes: ['FR', 'JP'],
            ),
          ),
        );
        await t.pump();
        final isMaterial = design == DesignLanguage.material;
        expect(
          find.byType(UserCountriesMaterialView),
          isMaterial ? findsOneWidget : findsNothing,
        );
        expect(
          find.byType(UserCountriesCupertinoView),
          isMaterial ? findsNothing : findsOneWidget,
        );
        expect(find.text('lea'), findsOneWidget);
        // One row per country (the names need the country localizations).
        expect(find.text('🇫🇷'), findsOneWidget);
        expect(find.text('🇯🇵'), findsOneWidget);
        if (!isMaterial) expect(find.text('2 countries'), findsOneWidget);
      });
    }
  });
}
