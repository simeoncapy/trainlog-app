import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainlog_app/l10n/app_localizations.dart';
import 'package:trainlog_app/ui/adaptive/bottom_sheet_picker.dart';
import 'package:trainlog_app/ui/cupertino/glass_filter_parts.dart';
import 'package:trainlog_app/ui/design.dart';
import 'package:trainlog_app/ui/tokens/app_theme.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

void main() {
  tearDown(() => AppPlatform.debugDesignOverride = null);

  for (final design in DesignLanguage.values) {
    testWidgets('${design.name}: picks an option and closes', (t) async {
      AppPlatform.debugDesignOverride = design;
      String? picked;
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showBottomSheetPicker<String>(
                  context: context,
                  title: 'Country',
                  selected: 'FR',
                  onChanged: (v) => picked = v,
                  options: const [
                    BottomSheetPickerOption(value: 'FR', label: 'France'),
                    BottomSheetPickerOption(value: 'JP', label: 'Japan'),
                  ],
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();

      expect(find.text('Country'), findsOneWidget);
      // iOS: an inset grouped list of form rows.
      expect(
        find.byType(GlassFormRow),
        design == DesignLanguage.cupertino ? findsNWidgets(2) : findsNothing,
      );

      await t.tap(find.text('Japan'));
      await t.pumpAndSettle();
      expect(picked, 'JP');
      expect(find.text('Country'), findsNothing);
    });
  }
}
