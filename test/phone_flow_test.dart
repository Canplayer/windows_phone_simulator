import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metro_ui/app.dart';
import 'package:metro_ui/application_bar.dart';
import 'package:metro_ui/widgets/phone_keypad.dart';
import 'package:metro_ui/widgets/pushable_double_line_list_item.dart';
import 'package:metro_ui/widgets/tile.dart';
import 'package:metro_ui/widgets/toggle_switch.dart';
import 'package:metro_ui/widgets/uix_page_slide.dart';
import 'package:metro_ui/widgets/uix_tight_text.dart';
import 'package:windows_phone_simulator/apps/phone/call_progress.dart';
import 'package:windows_phone_simulator/apps/phone/call_settings_page.dart';
import 'package:windows_phone_simulator/apps/phone/keypad_page.dart';
import 'package:windows_phone_simulator/apps/phone/phone.dart';

void main() {
  const scale = .8;

  Future<void> start(
    WidgetTester tester, {
    Widget home = const PhoneApp(),
    MetroThemeMode themeMode = MetroThemeMode.dark,
    bool highContrast = false,
  }) async {
    await tester.binding.setSurfaceSize(const Size(480 * scale, 800 * scale));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MetroApp(home: home, themeMode: themeMode, highContrast: highContrast),
    );
    await tester.pumpAndSettle();
  }

  Finder command(String label) => find.byWidgetPredicate(
    (widget) => widget is MetroAppBarButton && widget.label == label,
  );

  testWidgets('history uses the four original images and a flat row', (
    tester,
  ) async {
    await start(tester);
    final buttons = tester.widgetList<MetroAppBarButton>(
      find.byType(MetroAppBarButton),
    );
    expect(buttons.map((button) => button.label), [
      'voicemail',
      'keypad',
      'people',
      'search',
    ]);
    expect(
      buttons.map(
        (button) => ((button.icon as Image).image as AssetImage).assetName,
      ),
      [
        for (final asset in ['voicemail', 'dialpad', 'contacts', 'search'])
          'images/wp8_phone/$asset.png',
      ],
    );
    expect(find.text('PHONE'), findsOneWidget);
    expect(find.text('history'), findsOneWidget);
    expect(find.text('Missed call, 1/16/2015'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(CallHistoryTile),
        matching: find.byType(Tile),
      ),
      findsNothing,
    );
    expect(find.byType(ListTile), findsNothing);

    final row = find.byType(PushableDoubleLineListItem).at(1);
    final transform = find.descendant(
      of: row,
      matching: find.byType(Transform),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('13901234567', findRichText: true).first),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final matrix = tester.widget<Transform>(transform).transform;
    expect(matrix.entry(0, 0), closeTo(.975, .00001));
    expect(matrix.entry(1, 1), closeTo(.975, .00001));
    expect(matrix.entry(2, 3), 0);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.widget<Transform>(transform).transform.entry(0, 0), 1);
  });

  testWidgets('history uses tight rows and the 43-unit list-item button', (
    tester,
  ) async {
    await start(tester);
    final row = find.byType(PushableDoubleLineListItem).first;
    final callback = find.descendant(of: row, matching: find.byType(Image));
    final callbackBox = tester.getSize(callback);
    expect(callbackBox.width, closeTo(43 * scale, .00001));
    expect(callbackBox.height, closeTo(43 * scale, .00001));
    expect(tester.getSize(row).height, closeTo(82 * scale, .00001));
    final header = find.byType(UixTightText).at(0);
    final pivotHeader = find.byType(UixTightText).at(1);
    final headerBox = tester.getRect(header);
    final pivotBox = tester.getRect(pivotHeader);
    expect(pivotBox.top - headerBox.bottom, closeTo(22 * scale, .00001));
    final lines = find.descendant(of: row, matching: find.byType(UixTightText));
    final line1 = tester.getRect(lines.at(0));
    final line2 = tester.getRect(lines.at(1));
    expect(line2.top - line1.bottom, closeTo((4 + 8) * scale, .00001));
    for (final (box, line) in [(line1, lines.at(0)), (line2, lines.at(1))]) {
      final paragraph = find.descendant(
        of: line,
        matching: find.byType(RichText),
      );
      expect(box.height, lessThan(tester.getSize(paragraph).height));
    }
  });

  testWidgets('software Back closes the dialer and search', (tester) async {
    await start(tester);
    await tester.tap(command('keypad'));
    await tester.pumpAndSettle();
    expect(find.byType(KeypadPage), findsOneWidget);
    await tester.tapAt(const Offset(24, 24));
    await tester.pumpAndSettle();
    expect(find.byType(KeypadPage), findsNothing);
    await tester.tap(command('search'));
    await tester.pumpAndSettle();
    expect(find.byType(EditableText), findsOneWidget);
    await tester.tapAt(const Offset(24, 24));
    await tester.pumpAndSettle();
    expect(find.byType(EditableText), findsNothing);
    expect(command('keypad'), findsOneWidget);
  });

  testWidgets(
    'dialer uses the 480-wide keypad geometry and native key actions',
    (tester) async {
      final calls = <String>[];
      final saved = <String>[];
      await start(
        tester,
        home: PhoneApp(
          onPlaceCall: (number) {
            calls.add(number);
            return true;
          },
          onSaveContact: saved.add,
        ),
      );
      await tester.tap(command('keypad'));
      await tester.pumpAndSettle();
      expect(find.byType(KeypadPage), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.text('save'), findsOneWidget);
      expect(find.bySemanticsLabel('backspace'), findsNothing);

      Finder key(String digit) => find.byKey(ValueKey('phone-key-$digit'));
      final first = tester.getRect(key('1'));
      final next = tester.getRect(key('2'));
      final below = tester.getRect(key('4'));
      expect(
        tester.getSize(find.byType(PhoneKeypad)).height,
        closeTo(448 * scale, .00001),
      );
      expect(first.width, closeTo(154 * scale, .00001));
      expect(first.height, closeTo(106 * scale, .00001));
      expect(next.left - first.right, closeTo(6 * scale, .00001));
      expect(below.top - first.bottom, closeTo(6 * scale, .00001));
      expect(first.left, closeTo(3 * scale, .00001));

      await tester.longPress(key('0'));
      await tester.tap(key('2'));
      await tester.pumpAndSettle();
      expect(find.text('+2'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('backspace'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('dialer-accumulator')))
            .data,
        '+',
      );
      await tester.tap(key('2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('save'));
      expect(saved, ['+2']);
      await tester.tap(find.text('call'));
      await tester.pumpAndSettle();
      expect(calls, ['+2']);
      expect(find.byType(KeypadPage), findsNothing);
      expect(find.text('+2', findRichText: true), findsOneWidget);
    },
  );

  testWidgets('cancel and confirm the original delete-all prompt', (
    tester,
  ) async {
    await start(tester);
    final rows = find.byType(CallHistoryTile);
    final count = rows.evaluate().length;
    Future<void> open() async {
      await tester.tapAt(const Offset(369, 599));
      await tester.pumpAndSettle();
      await tester.tap(find.text('delete all'));
      await tester.pumpAndSettle();
      expect(find.text('Delete call history'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    }

    await open();
    await tester.tap(find.text('cancel'));
    await tester.pumpAndSettle();
    expect(rows, findsNWidgets(count));
    await open();
    await tester.tap(find.text('delete'));
    await tester.pumpAndSettle();
    expect(rows, findsNothing);
    expect(find.text('To make a call, tap an icon below.'), findsOneWidget);
  });

  testWidgets('long press deletes only the selected history entry', (
    tester,
  ) async {
    await start(tester);
    final rows = find.byType(CallHistoryTile);
    final count = rows.evaluate().length;
    final first = tester.widget<CallHistoryTile>(rows.first);

    await tester.longPress(
      find.descendant(
        of: find.byKey(first.key!),
        matching: find.text(first.record.number, findRichText: true),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('delete item'));
    await tester.pumpAndSettle();

    expect(find.byKey(first.key!), findsNothing);
    expect(rows, findsNWidgets(count - 1));
    expect(find.text(first.record.number, findRichText: true), findsOneWidget);
  });

  testWidgets('search filters history and hardware back restores the bar', (
    tester,
  ) async {
    await start(tester);
    await tester.tap(command('search'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(EditableText), findsOneWidget);
    expect(command('keypad'), findsNothing);
    await tester.enterText(find.byType(EditableText), '1390');
    await tester.pumpAndSettle();
    expect(find.byType(CallHistoryTile), findsNWidgets(2));
    expect(find.text('search contacts'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(EditableText), findsNothing);
    expect(command('keypad'), findsOneWidget);
  });

  testWidgets('dialer slide starts at 200 UIX units and fades in over 10ms', (
    tester,
  ) async {
    await start(tester);
    await tester.tap(command('keypad'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    final dialer = find.byType(KeypadPage);
    for (var i = 0; i < 5 && dialer.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 1));
    }
    expect(dialer, findsOneWidget);
    final slide = find.descendant(
      of: dialer,
      matching: find.byType(UixPageSlide),
    );
    final opacity = find
        .descendant(of: slide, matching: find.byType(Opacity))
        .first;
    expect(tester.widget<Opacity>(opacity).opacity, 0);
    expect(
      tester.getTopLeft(find.byType(PhoneKeypad)).dy,
      closeTo(640 - (72 + 448 - 200) * scale, .1),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 5));
    expect(tester.widget<Opacity>(opacity).opacity, closeTo(.5, .00001));
    await tester.pump(const Duration(milliseconds: 5));
    expect(tester.widget<Opacity>(opacity).opacity, 1);
    await tester.pumpAndSettle();
  });

  for (final contrast in [false, true]) {
    testWidgets('light keypad uses the WP8 color slots (contrast=$contrast)', (
      tester,
    ) async {
      await start(
        tester,
        themeMode: MetroThemeMode.light,
        highContrast: contrast,
      );
      await tester.tap(command('keypad'));
      await tester.pumpAndSettle();
      final keypad = tester.widget<PhoneKeypad>(find.byType(PhoneKeypad));
      expect(keypad.background, const Color(0xffffffff));
      expect(keypad.foreground, Color(contrast ? 0xff000000 : 0xde000000));
      expect(
        keypad.secondaryForeground,
        Color(contrast ? 0xff000000 : 0x73000000),
      );
      expect(keypad.highContrast, contrast);
      expect(keypad.pressedForeground, const Color(0xffffffff));
    });
  }

  testWidgets(
    'Phone settings uses native labels and edits a local forwarding setting',
    (tester) async {
      final model = PhoneSettingsModel(
        callerId: CallerIdSetting.everyone,
        callForwardingNumber: '',
        internationalAssist: true,
      );
      await start(tester, home: PhoneApp(settingsModel: model));
      await tester.tapAt(const Offset(369, 599));
      await tester.pumpAndSettle();
      await tester.tap(find.text('settings'));
      await tester.pumpAndSettle();
      expect(find.byType(CallSettingsPage), findsOneWidget);
      expect(find.text('SETTINGS'), findsOneWidget);
      expect(find.text('phone'), findsOneWidget);
      expect(find.text('Show my caller ID to'), findsOneWidget);
      expect(find.text('Call forwarding'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(model.callForwardingEnabled, isFalse);
      final forwardSwitch = find.descendant(
        of: find.byWidgetPredicate(
          (widget) => widget is ToggleSwitch && widget.label.isEmpty,
        ),
        matching: find.byType(ToggleSwitchBase),
      );
      await tester.ensureVisible(forwardSwitch);
      await tester.tap(forwardSwitch);
      await tester.pumpAndSettle();
      expect(find.text('Forward calls to'), findsOneWidget);
      await tester.enterText(find.byType(EditableText).last, '13901234567');
      await tester.pumpAndSettle();
      await tester.tap(find.text('save'));
      await tester.pumpAndSettle();
      expect(model.callForwardingEnabled, isTrue);
      expect(model.callForwardingNumber, '13901234567');
    },
  );

  testWidgets(
    'a local dial shows the PhoneShellUI progress layer and in-call keypad',
    (tester) async {
      await start(tester);
      await tester.tap(command('keypad'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('phone-key-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('call'));
      await tester.pumpAndSettle();
      final shell = find.byType(PhoneCallProgress);
      expect(shell, findsOneWidget);
      expect(find.text('DIALING...'), findsOneWidget);
      expect(find.text('END CALL'), findsOneWidget);
      expect(find.text('SPEAKER'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      final keypadToggle = find.descendant(
        of: shell,
        matching: find.bySemanticsLabel('keypad'),
      );
      await tester.tap(keypadToggle);
      await tester.pumpAndSettle();
      final keypad = tester.widget<PhoneKeypad>(find.byType(PhoneKeypad));
      expect(keypad.inCall, isTrue);
      expect(
        tester.getSize(find.byType(PhoneKeypad)).height,
        closeTo(304 * scale, .0001),
      );
      await tester.tap(find.text('END CALL'));
      await tester.pumpAndSettle();
      expect(shell, findsNothing);
      expect(find.text('history'), findsOneWidget);
    },
  );
}
