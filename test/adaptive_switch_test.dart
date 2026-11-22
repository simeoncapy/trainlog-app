import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart' as lg;
import 'package:trainlog_app/ui/adaptive/adaptive_switch.dart';
import 'package:trainlog_app/ui/design.dart';
import 'package:trainlog_app/ui/tokens/app_colors.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

void main() {
  tearDown(() => AppPlatform.debugDesignOverride = null);

  Widget host() => MaterialApp(
    home: Scaffold(body: AdaptiveSwitch(value: true, onChanged: (_) {})),
  );

  testWidgets('iOS switch uses the app amber, not the system green', (t) async {
    AppPlatform.debugDesignOverride = DesignLanguage.cupertino;
    await t.pumpWidget(host());
    final glass = t.widget<lg.GlassSwitch>(find.byType(lg.GlassSwitch));
    expect(glass.activeColor, AppColors.amber);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('Android keeps the Material switch', (t) async {
    AppPlatform.debugDesignOverride = DesignLanguage.material;
    await t.pumpWidget(host());
    expect(find.byType(Switch), findsOneWidget);
    expect(find.byType(lg.GlassSwitch), findsNothing);
  });
}
