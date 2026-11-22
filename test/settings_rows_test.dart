import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainlog_app/features/settings/widgets/cupertino/settings_cupertino.dart';
import 'package:trainlog_app/features/settings/widgets/material/settings_material.dart';
import 'package:trainlog_app/features/settings/widgets/settings_group.dart';
import 'package:trainlog_app/ui/design.dart';
import 'package:trainlog_app/ui/tokens/app_theme.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

void main() {
  tearDown(() => AppPlatform.debugDesignOverride = null);

  Future<void> pump(
    WidgetTester t,
    DesignLanguage design,
    List<Widget> rows,
  ) async {
    AppPlatform.debugDesignOverride = design;
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppDesign(
            language: design,
            child: ListView(children: [SettingsGroup(children: rows)]),
          ),
        ),
      ),
    );
  }

  testWidgets('Android draws the Material rows; a row tap is not the iOS one', (
    t,
  ) async {
    var appleTaps = 0;
    var pressed = 0;
    await pump(t, DesignLanguage.material, [
      SettingsTile(
        icon: Icons.attach_money,
        title: 'Currency',
        appleOnTap: () => appleTaps++,
        trailing: SettingsValueButton(value: 'EUR', onPressed: () => pressed++),
      ),
      const SettingsTile(icon: Icons.info, title: 'Version'),
    ]);

    expect(find.byType(MaterialSettingsGroup), findsOneWidget);
    expect(find.byType(MaterialSettingsTile), findsNWidgets(2));
    expect(find.byType(CupertinoSettingsRow), findsNothing);

    await t.tap(find.text('Currency'));
    expect(appleTaps, 0);
    await t.tap(find.text('EUR'));
    expect(pressed, 1);
  });

  testWidgets('iOS draws the grouped rows; the whole row is tapped', (t) async {
    var appleTaps = 0;
    await pump(t, DesignLanguage.cupertino, [
      SettingsTile(
        icon: Icons.attach_money,
        title: 'Currency',
        appleOnTap: () => appleTaps++,
        trailing: SettingsValueButton(value: 'EUR', onPressed: () {}),
      ),
      const SettingsTile(icon: Icons.info, title: 'Version'),
    ]);

    expect(find.byType(CupertinoSettingsGroup), findsOneWidget);
    expect(find.byType(CupertinoSettingsRow), findsNWidgets(2));
    expect(find.byType(CupertinoSettingsDisclosure), findsOneWidget);
    expect(find.byType(MaterialSettingsTile), findsNothing);

    await t.tap(find.text('Currency'));
    expect(appleTaps, 1);
  });

  testWidgets('a row can drop the divider under it', (t) async {
    await pump(t, DesignLanguage.material, [
      const SettingsTile(icon: Icons.palette, title: 'A', noDivider: true),
      const SettingsTile(icon: Icons.palette, title: 'B'),
      const SettingsTile(icon: Icons.palette, title: 'C'),
    ]);
    expect(find.byType(Divider), findsOneWidget);
  });

  testWidgets('the iOS clear cache row clears on tap, only with a cache', (
    t,
  ) async {
    var cleared = 0;
    Widget row(bool enabled) => SettingsClearCacheTile(
      icon: Icons.delete,
      title: 'Cache',
      subtitle: '0 B',
      buttonLabel: 'Clear',
      enabled: enabled,
      onClear: () => cleared++,
    );

    await pump(t, DesignLanguage.cupertino, [row(false)]);
    await t.tap(find.text('Cache'));
    expect(cleared, 0);

    await pump(t, DesignLanguage.cupertino, [row(true)]);
    await t.tap(find.text('Cache'));
    expect(cleared, 1);
  });
}
