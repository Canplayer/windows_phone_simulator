import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter_test/flutter_test.dart';
import 'package:windows_phone_simulator/app_registry.dart';
import 'package:windows_phone_simulator/apps/phone/phone.dart';
import 'package:windows_phone_simulator/launcher.dart';
import 'package:windows_phone_simulator/main.dart' as app;
import 'package:windows_phone_simulator/splashscreen_page.dart';

void main() {
  testWidgets('Android simulator boots, opens Phone, and returns from it', (
    tester,
  ) async {
    addTearDown(AppRegistry().clear);
    app.main();
    await tester.pump();
    expect(find.byType(Splashscreen), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byType(LauncherPage), findsOneWidget);
    await tester.tap(find.byType(PhoneLiveTile));
    await tester.pumpAndSettle();
    expect(find.byType(PhoneApp), findsOneWidget);
    expect(find.text('history'), findsOneWidget);
    final back = find.bySemanticsLabel('Back');
    expect(back, findsOneWidget);
    await tester.tapAt(const Offset(22, 24));
    await tester.pumpAndSettle();
    expect(find.byType(PhoneApp), findsNothing);
    expect(find.byType(LauncherPage), findsOneWidget);
    // Finish the pinned tile's pending demo updates before teardown.
    for (var i = 0; i < 7; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
  }, variant: const TargetPlatformVariant({TargetPlatform.android}));
}
