import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metro_ui/app.dart';
import 'package:metro_ui/application_bar.dart';
import 'package:metro_ui/widgets/metro_circle_button.dart';
import 'package:metro_ui/widgets/page_header.dart';
import 'package:metro_ui/widgets/phone_keypad.dart';
import 'package:metro_ui/widgets/pivot.dart';
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

  testWidgets('history uses the four authored SVGs and a flat row', (
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
        (button) => ((button.icon as SvgPicture).bytesLoader as SvgAssetLoader)
            .assetName,
      ),
      [
        for (final name in ['voicemail', 'keypad', 'people', 'search'])
          'images/icons/phone_appbar_$name.svg',
      ],
    );
    expect(find.text('PHONE'), findsOneWidget);
    expect(find.text('history'), findsOneWidget);
    expect(find.text('Missed call, 1/16/2015'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);

    final row = find.byType(PushableDoubleLineListItem).at(1);
    final number = find.descendant(
      of: row,
      matching: find.text('13901234567', findRichText: true),
    );
    final transform = find.descendant(
      of: row,
      matching: find.ancestor(of: number, matching: find.byType(Transform)),
    );
    final gesture = await tester.startGesture(tester.getCenter(number));
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
    final header = find.descendant(
      of: find.byType(MetroPageHeader),
      matching: find.byType(UixTightText),
    );
    final pivotHeader = find.byType(PivotHeader);
    final headerBox = tester.getRect(header);
    final pivotBox = tester.getRect(pivotHeader);
    expect(pivotBox.top - headerBox.bottom, closeTo(22 * scale, .00001));
    expect(
      tester.getTopLeft(row).dy - pivotBox.bottom,
      closeTo(28 * scale, .00001),
    );
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

  Transform pressTransform(WidgetTester tester, Finder tile) => tester.widget(
    find.descendant(of: tile, matching: find.byType(Transform)).first,
  );

  testWidgets('history callback tilts its own bitmap and clears on cancel', (
    tester,
  ) async {
    await start(tester);
    final row = find.byType(CallHistoryTile).at(1);
    final tile = find.descendant(of: row, matching: find.byType(Tile));
    final image = find.descendant(of: tile, matching: find.byType(Image));
    String asset() =>
        (tester.widget<Image>(image).image as AssetImage).assetName;
    final rect = tester.getRect(image);
    final finger = await tester.startGesture(rect.center);
    await tester.pump(const Duration(milliseconds: 51));
    expect(asset(), endsWith('callback_dark_down.png'));
    expect(tester.getRect(image).width, lessThan(rect.width));
    await finger.cancel();
    await tester.pumpAndSettle();
    expect(asset(), endsWith('callback_dark_rest.png'));
    expect(tester.getRect(image), rect);
    expect(find.byType(PhoneCallProgress), findsNothing);
  });

  testWidgets('application bar presses the vector ring and fires one command', (
    tester,
  ) async {
    var calls = 0;
    await start(tester, home: PhoneApp(onVoicemail: () => calls++));
    final circle = find.descendant(
      of: command('voicemail'),
      matching: find.byType(MetroCircleButton),
    );
    final ring = find.descendant(
      of: circle,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            (widget.decoration as BoxDecoration).shape == BoxShape.circle,
      ),
    );
    Color? fill() =>
        (tester.widget<DecoratedBox>(ring).decoration as BoxDecoration).color;
    final accent = Theme.of(tester.element(circle)).colorScheme.primary;
    final rest = tester.getRect(circle);
    expect(fill(), isNull);
    final finger = await tester.startGesture(rest.center);
    await tester.pump(const Duration(milliseconds: 51));
    expect(fill(), accent);
    expect(tester.getRect(ring).width, lessThan(rest.width));
    expect(
      find.descendant(of: circle, matching: find.byType(SvgPicture)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: circle, matching: find.byType(Image)),
      findsNothing,
    );
    await finger.up();
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(fill(), isNull);
    expect(tester.getRect(circle), rest);
  });

  for (final mode in [MetroThemeMode.light, MetroThemeMode.dark]) {
    testWidgets(
      'classic frame recolors the fill and retains the ${mode.name} rim',
      (tester) async {
        const key = ValueKey('classic frame');
        const accent = Color(0xffa04010);
        await start(
          tester,
          themeMode: mode,
          home: const Center(
            child: RepaintBoundary(
              key: key,
              child: MetroCircleButton(
                iconMode: true,
                icon: SizedBox.shrink(),
                frameStyle: MetroCircleFrameStyle.classicBitmap,
                themeColor: accent,
                size: 48,
                pressed: true,
              ),
            ),
          ),
        );
        final image = tester.widget<Image>(find.byType(Image));
        final asset = image.image as AssetImage;
        expect(asset.package, 'metro_ui');
        expect(
          asset.assetName,
          endsWith('appbar_circle_${mode.name}_down.png'),
        );
        await tester.runAsync(
          () => precacheImage(asset, tester.element(find.byKey(key))),
        );
        await tester.pump();

        await tester.runAsync(() async {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(key),
          );
          final rendered = await boundary.toImage();
          final bytes = (await rendered.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          int pixel(int x, int y) =>
              bytes.getUint32((y * rendered.width + x) * 4);
          expect(pixel(24, 24), 0xa04010ff);
          expect(
            pixel(2, 24),
            mode == MetroThemeMode.dark ? 0xffffffff : 0x000000ff,
          );
          expect(pixel(0, 0), 0);
          rendered.dispose();
        });
      },
    );
  }

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
    final cancel = find.text('cancel');
    final tile = find.ancestor(of: cancel, matching: find.byType(Tile));
    final gesture = await tester.startGesture(tester.getCenter(cancel));
    await tester.pump(const Duration(milliseconds: 51));
    expect(pressTransform(tester, tile).transform.entry(3, 3), greaterThan(1));
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(pressTransform(tester, tile).transform.entry(3, 3), 1);
    await tester.tap(cancel);
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
