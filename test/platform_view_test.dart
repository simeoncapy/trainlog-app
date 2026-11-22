import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainlog_app/ui/design.dart';
import 'package:trainlog_app/utils/platform_utils.dart';

void main() {
  tearDown(() => AppPlatform.debugDesignOverride = null);

  Widget view() => Directionality(
    textDirection: TextDirection.ltr,
    child: PlatformView(
      material: (_) => const Text('material'),
      cupertino: (_) => const Text('cupertino'),
    ),
  );

  testWidgets('follows the design override', (t) async {
    AppPlatform.debugDesignOverride = DesignLanguage.cupertino;
    await t.pumpWidget(view());
    expect(find.text('cupertino'), findsOneWidget);
    expect(AppPlatform.isApple, isTrue);

    AppPlatform.debugDesignOverride = DesignLanguage.material;
    // The override is read when the app is built: rebuild from scratch.
    await t.pumpWidget(KeyedSubtree(key: UniqueKey(), child: view()));
    expect(find.text('material'), findsOneWidget);
    expect(AppPlatform.isApple, isFalse);
  });

  testWidgets('an AppDesign above wins over the platform', (t) async {
    AppPlatform.debugDesignOverride = DesignLanguage.material;
    await t.pumpWidget(
      AppDesign(language: DesignLanguage.cupertino, child: view()),
    );
    expect(find.text('cupertino'), findsOneWidget);
  });
}
