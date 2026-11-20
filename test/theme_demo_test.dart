import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metro_ui/app.dart';
import 'package:metro_ui/metro_theme.dart';
import 'package:metro_ui/widgets/list_picker.dart';
import 'package:metro_ui/widgets/toggle_switch.dart';
import 'package:windows_phone_simulator/apps/theme_demo/theme_demo.dart';

void main() {
  testWidgets('theme demo previews presets locally', (tester) async {
    await tester.pumpWidget(
      const MetroApp(
        version: MetroDesignVersion.wp81,
        themeMode: MetroThemeMode.dark,
        highContrast: false,
        home: ThemeDemoPage(),
      ),
    );
    await tester.pumpAndSettle();

    final picker = find.byType(ListPicker<MetroDesignVersion>);
    BuildContext preview() => tester.element(picker);
    expect(MetroSystemThemeData.of(preview()).version, MetroDesignVersion.wp81);

    await tester.tap(picker);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Windows Phone 7'));
    await tester.pumpAndSettle();
    expect(MetroSystemThemeData.of(preview()).version, MetroDesignVersion.wp7);

    final switches = find.byType(ToggleSwitchBase);
    await tester.tap(switches.first);
    await tester.pumpAndSettle();
    await tester.tap(switches.last);
    await tester.pumpAndSettle();
    expect(Theme.of(preview()).brightness, Brightness.light);
    expect(MetroSystemThemeData.of(preview()).highContrast, isTrue);

    final host = tester.element(find.byType(ThemeDemoPage));
    expect(MetroSystemThemeData.of(host).version, MetroDesignVersion.wp81);
    expect(MetroSystemThemeData.of(host).highContrast, isFalse);
    expect(Theme.of(host).brightness, Brightness.dark);
  });
}
