import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metro_ui/app.dart';
import 'package:windows_phone_simulator/app_registry.dart';
import 'package:windows_phone_simulator/launcher.dart';
import 'package:windows_phone_simulator/start_menu.dart';
import 'package:windows_phone_simulator/start_menu_motion.dart';

App _app(String id, String name) => App(
  id: id,
  name: name,
  icon: const Icon(Icons.phone),
  page: Text('$name page'),
  smallTile: ColoredBox(color: Colors.blue, key: ValueKey('$id-small')),
  mediumTile: ColoredBox(color: Colors.blue, key: ValueKey('$id-medium')),
  wideTile: ColoredBox(color: Colors.blue, key: ValueKey('$id-wide')),
);

TileModel _tile(App app, TileSize size, int x, int y) => TileModel(
  instanceId: app.id,
  app: app,
  currentSize: size,
  gridX: x,
  gridY: y,
);

Future<void> _designViewport(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(384, 640));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

String _imageAt(WidgetTester tester, Finder button) =>
    (tester
                .widget<Image>(
                  find.descendant(of: button, matching: find.byType(Image)),
                )
                .image
            as AssetImage)
        .assetName;

void main() {
  test('WP8 grid motion follows the tile resource tracks', () {
    const out = StartTileTransition.forwardOut;
    const back = StartTileTransition.backwardIn;
    expect(out.rotationAt(0), 0);
    expect(out.rotationAt(167), closeTo(50 * math.pi / 180, .00001));
    expect(out.opacityAt(166), 1);
    expect(out.opacityAt(167), 0);
    expect(back.rotationAt(0), closeTo(80 * math.pi / 180, .00001));
    expect(back.rotationAt(250), 0);
    expect(back.opacityAt(10), 0);
    expect(back.opacityAt(20), 1);
    expect(
      out.delayFor(
        column: 1,
        columns: 4,
        topInViewport: 30,
        viewportHeight: 640,
        clicked: true,
      ),
      350,
    );
    expect(
      out.delayFor(
        column: 1,
        columns: 4,
        topInViewport: 600,
        viewportHeight: 640,
        clicked: false,
      ),
      50,
    );
  });

  testWidgets('WVGA grid holds four 99-unit cells with a 12-unit gap', (
    tester,
  ) async {
    await _designViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: StartMenu(
          initialTiles: [
            _tile(_app('a', 'Alpha'), TileSize.medium, 0, 0),
            _tile(_app('b', 'Beta'), TileSize.small, 2, 0),
            _tile(_app('c', 'Charlie'), TileSize.wide, 0, 2),
          ],
          onOpenApps: () {},
        ),
      ),
    );
    final medium = tester.getRect(find.byKey(const ValueKey('a-medium')));
    final small = tester.getRect(find.byKey(const ValueKey('b-small')));
    final wide = tester.getRect(find.byKey(const ValueKey('c-wide')));
    expect(medium.left, closeTo(24 * .8, .001));
    expect(medium.top, closeTo(95 * .8, .001));
    expect(medium.width, closeTo(210 * .8, .001));
    expect(small.width, closeTo(99 * .8, .001));
    expect(small.left - medium.right, closeTo(12 * .8, .001));
    expect(wide.width, closeTo(432 * .8, .001));
    expect(wide.top - medium.bottom, closeTo(12 * .8, .001));
    final footer = tester.getRect(find.bySemanticsLabel('All apps'));
    expect(footer.top - wide.bottom, closeTo(2 * .8, .001));
  });

  testWidgets('a cancelled drag restores the committed cell', (tester) async {
    await _designViewport(tester);
    final grid = GlobalKey<StartMenuState>();
    await tester.pumpWidget(
      MaterialApp(
        home: StartMenu(
          key: grid,
          initialTiles: [_tile(_app('a', 'Alpha'), TileSize.medium, 0, 0)],
        ),
      ),
    );
    final face = find.byKey(const ValueKey('a-medium'));
    await tester.longPress(face);
    await tester.pumpAndSettle();
    final drag = await tester.startGesture(tester.getCenter(face));
    await drag.moveBy(const Offset(25, 0));
    await drag.moveBy(const Offset(94, 0));
    await tester.pump(const Duration(milliseconds: 120));
    expect(grid.currentState!.tiles.single.gridX, 1);
    await drag.cancel();
    await tester.pumpAndSettle();
    expect(grid.currentState!.tiles.single.gridX, 0);
    expect(grid.currentState!.isEditMode, isTrue);
  });

  testWidgets('a single obstruction moves sideways before it moves up', (
    tester,
  ) async {
    await _designViewport(tester);
    final grid = GlobalKey<StartMenuState>();
    await tester.pumpWidget(
      MaterialApp(
        home: StartMenu(
          key: grid,
          initialTiles: [
            _tile(_app('anchor', 'Anchor'), TileSize.small, 0, 0),
            _tile(_app('a', 'Alpha'), TileSize.small, 0, 1),
            _tile(_app('b', 'Beta'), TileSize.small, 2, 1),
          ],
        ),
      ),
    );
    final face = find.byKey(const ValueKey('a-small'));
    await tester.longPress(face);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    final drag = await tester.startGesture(tester.getCenter(face));
    await drag.moveBy(const Offset(25, 0));
    await drag.moveBy(const Offset(179, 0));
    await tester.pump(const Duration(milliseconds: 120));
    await drag.up();
    await tester.pump();
    final placed = grid.currentState!.tiles;
    final active = placed.singleWhere((tile) => tile.instanceId == 'a');
    final obstruction = placed.singleWhere((tile) => tile.instanceId == 'b');
    expect((active.gridX, active.gridY), (2, 1));
    expect((obstruction.gridX, obstruction.gridY), (3, 1));
  });

  testWidgets('edit mode applies scale and alpha by focus and drag state', (
    tester,
  ) async {
    await _designViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: StartMenu(
          initialTiles: [
            _tile(_app('a', 'Alpha'), TileSize.medium, 0, 0),
            _tile(_app('b', 'Beta'), TileSize.medium, 2, 0),
          ],
        ),
      ),
    );
    final selected = find.byKey(const ValueKey('a-medium'));
    final idle = find.byKey(const ValueKey('b-medium'));
    final original = tester.getRect(selected).width;
    await tester.longPress(selected);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    expect(tester.getRect(selected).width, closeTo(original, .001));
    expect(tester.getRect(idle).width, closeTo(original * .9 * .925, .001));

    double alpha(Finder tile) => tester
        .widgetList<Opacity>(
          find.ancestor(of: tile, matching: find.byType(Opacity)),
        )
        .fold(1.0, (value, opacity) => value * opacity.opacity);
    expect(alpha(selected), 1);
    expect(alpha(idle), closeTo(.6, .0001));
    final selectedPosition = tester.getCenter(selected);
    final idlePositions = <Offset>{tester.getCenter(idle)};
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 137));
      expect(tester.getCenter(selected), selectedPosition);
      idlePositions.add(tester.getCenter(idle));
    }
    expect(idlePositions.length, greaterThan(1));

    final drag = await tester.startGesture(tester.getCenter(selected));
    await drag.moveBy(const Offset(25, 0));
    await drag.moveBy(const Offset(35, 0));
    await tester.pump();
    expect(alpha(selected), closeTo(.85, .0001));
    await drag.cancel();
    await tester.pump();
    expect(alpha(selected), 1);
  });

  testWidgets('dragging into the bottom edge starts scrolling after 500 ms', (
    tester,
  ) async {
    await _designViewport(tester);
    final grid = GlobalKey<StartMenuState>();
    await tester.pumpWidget(
      MaterialApp(
        home: StartMenu(
          key: grid,
          initialTiles: [
            for (var row = 0; row < 8; row++)
              _tile(_app('app$row', 'App $row'), TileSize.medium, 0, row * 2),
          ],
        ),
      ),
    );
    final face = find.byKey(const ValueKey('app0-medium'));
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
    await tester.longPress(face);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final drag = await tester.startGesture(tester.getCenter(face));
    await drag.moveBy(const Offset(0, 25));
    await drag.moveTo(const Offset(96, 635));
    await tester.pump(const Duration(milliseconds: 499));
    expect(scroll.position.pixels, 0);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 100));
    expect(scroll.position.pixels, greaterThan(70));
    await drag.cancel();
    final stopped = scroll.position.pixels;
    await tester.pump(const Duration(seconds: 1));
    expect(scroll.position.pixels, stopped);
    expect(grid.currentState!.tiles.first.gridY, 0);
  });

  testWidgets('badge updates use the native number steps and cap', (
    tester,
  ) async {
    Widget host(int count) => MaterialApp(
      home: Center(
        child: SizedBox.square(
          dimension: 168,
          child: MetroAppTile(icon: const Icon(Icons.phone), count: count),
        ),
      ),
    );

    await tester.pumpWidget(host(0));
    await tester.pumpWidget(host(5));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 449));
    expect(find.text('1'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.text('1'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 750));
    expect(find.text('5'), findsOneWidget);
    await tester.pumpWidget(host(1024));
    await tester.pumpAndSettle();
    expect(find.text('999'), findsOneWidget);
    await tester.pumpWidget(host(2));
    expect(find.text('2'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets('editing uses the original ${brightness.name} controls', (
      tester,
    ) async {
      await _designViewport(tester);
      final grid = GlobalKey<StartMenuState>();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: StartMenu(
            key: grid,
            initialTiles: [_tile(_app('a', 'Alpha'), TileSize.medium, 0, 0)],
          ),
        ),
      );

      await tester.longPress(find.byKey(const ValueKey('a-medium')));
      await tester.pumpAndSettle();
      expect(grid.currentState!.isEditMode, isTrue);
      final resize = find.bySemanticsLabel('Resize');
      final unpin = find.bySemanticsLabel('Unpin');
      expect(
        _imageAt(tester, resize),
        endsWith('resize_med_${brightness.name}_rest.png'),
      );
      expect(
        _imageAt(tester, unpin),
        endsWith('unpin_${brightness.name}_rest.png'),
      );
      expect(tester.getSize(resize).width, closeTo(43 * .8, .001));
      final press = await tester.startGesture(tester.getCenter(resize));
      await tester.pump();
      expect(
        _imageAt(tester, resize),
        endsWith('resize_med_${brightness.name}_down.png'),
      );
      await press.up();
      await tester.pump();
      expect(
        tester.getRect(find.byKey(const ValueKey('a-small'))).width,
        closeTo(99 * .8 * 1.5, .01),
      );
      await tester.pumpAndSettle();
      expect(grid.currentState!.tiles.single.currentSize, TileSize.small);
      expect(
        _imageAt(tester, resize),
        endsWith('resize_small_${brightness.name}_rest.png'),
      );
      await tester.tap(resize);
      await tester.pumpAndSettle();
      expect(grid.currentState!.tiles.single.currentSize, TileSize.wide);
      expect(
        _imageAt(tester, resize),
        endsWith('resize_large_${brightness.name}_rest.png'),
      );
      await tester.tap(unpin);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 299));
      expect(grid.currentState!.tiles, isNotEmpty);
      // Flutter reports AnimationStatus.completed just after the last sample.
      await tester.pump(const Duration(milliseconds: 2));
      expect(grid.currentState!.tiles, isEmpty);
    });
  }

  testWidgets(
    'all apps opens a separate pane and pin brings the app to Start',
    (tester) async {
      await _designViewport(tester);
      final registry = AppRegistry();
      addTearDown(registry.clear);
      registry.register(_app('com.ms.phone', 'Phone'));
      registry.register(_app('calendar', 'Calendar'));
      await tester.pumpWidget(const MetroApp(home: LauncherPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('All apps'));
      await tester.pumpAndSettle();
      final title = find.text('Calendar');
      expect(title, findsOneWidget);
      final row = find.ancestor(of: title, matching: find.byType(Row)).first;
      expect(tester.getTopLeft(row).dx, closeTo(90 * .8, .001));
      await tester.longPress(title);
      await tester.pumpAndSettle();
      await tester.tap(find.text('pin to start'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('calendar-medium')), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('All apps'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Search apps'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'cal');
      await tester.pumpAndSettle();
      expect(title, findsOneWidget);
      expect(find.text('Phone'), findsNothing);

      await tester.tap(title);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Calendar page'), findsNothing);
      await tester.pumpAndSettle();
      final app = find.text('Calendar page');
      expect(app, findsOneWidget);
      Navigator.of(tester.element(app)).pop();
      await tester.pumpAndSettle();
      expect(title, findsOneWidget);
      expect(find.byType(EditableText), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(EditableText), findsNothing);
      expect(find.text('Phone'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('calendar-medium')), findsOneWidget);
    },
  );
}
