import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:metro_ui/animations.dart';
import 'package:metro_ui/metro_page_push.dart';
import 'package:metro_ui/page.dart';
import 'package:metro_ui/page_scaffold.dart';
import 'package:metro_ui/uix_metrics.dart';
import 'package:metro_ui/uix_typography.dart';
import 'package:metro_ui/widgets/context_menu.dart';
import 'package:metro_ui/widgets/search_bar.dart';
import 'package:metro_ui/widgets/tile.dart';
import 'package:metro_ui/widgets/uix_text.dart';

import 'app_registry.dart';
import 'start_menu.dart';
import 'start_menu_motion.dart';

class LauncherPage extends StatefulWidget {
  const LauncherPage({super.key});

  @override
  State<LauncherPage> createState() => _LauncherPageState();
}

class _LauncherPageState extends State<LauncherPage>
    with SingleTickerProviderStateMixin {
  final _startMenuKey = GlobalKey<StartMenuState>();
  final _scaffoldKey = GlobalKey<MetroPageScaffoldState>();
  final _panes = PageController();
  final _appsScroll = ScrollController();
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  late final _appsMotion = AnimationController(vsync: this);
  StartTileTransition? _appsTransition;
  Map<String, double> _appDelays = {};
  bool _editing = false;
  bool _searching = false;
  bool _openingApp = false;
  int _pane = 0;

  late final List<TileModel> _initialTiles = [
    for (final app in AppRegistry().apps)
      if (app.id == 'com.ms.phone')
        TileModel(
          instanceId: app.id,
          app: app,
          currentSize: TileSize.medium,
          gridX: 0,
          gridY: 0,
        ),
  ];

  Future<void> _showPane(int index) => _panes.animateToPage(
    index,
    duration: const Duration(milliseconds: 800),
    curve: const UixLog(300),
  );

  void _showSearch() {
    if (_appsScroll.hasClients) _appsScroll.jumpTo(0);
    setState(() => _searching = true);
    _searchFocus.requestFocus();
  }

  void _closeSearch() {
    _searchFocus.unfocus();
    _search.clear();
    setState(() => _searching = false);
  }

  bool get _canGoBack => _editing || _searching || _pane == 1;

  Future<bool> _back() async {
    if (_searching) {
      _closeSearch();
    } else if (_editing) {
      _startMenuKey.currentState?.exitEditMode();
    } else if (_pane == 1) {
      await _showPane(0);
    }
    return false;
  }

  Future<void> _launchApp(App app, {String? tileId}) async {
    if (_openingApp) return;
    _openingApp = true;
    try {
      _searchFocus.unfocus();
      await metroPagePush(
        context,
        MetroPageRoute(builder: (_) => app.page),
        dataToPass: (id: tileId ?? app.id, isTile: tileId != null),
        scaffoldKey: _scaffoldKey,
      );
    } finally {
      _openingApp = false;
    }
  }

  List<App> get _apps {
    final term = _search.text.trim().toLowerCase();
    return AppRegistry().apps
        .where((app) => app.name.toLowerCase().contains(term))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<void> _animateApps(
    StartTileTransition transition, {
    String? clickedId,
  }) async {
    if (!_appsScroll.hasClients) return;
    final scroll = _appsScroll.position;
    final viewport = scroll.viewportDimension;
    final apps = _apps;
    final delays = <String, double>{};
    for (var index = 0; index < apps.length; index++) {
      final id = apps[index].id;
      final listTop = _searching ? 0 : 62 * uixScale;
      final rowTop = listTop + index * 74 * uixScale - scroll.pixels;
      if (id != clickedId &&
          (rowTop >= viewport || rowTop + 62 * uixScale <= 0)) {
        continue;
      }
      delays[id] = transition.delayForApp(
        topInViewport: rowTop + (_searching ? 95 : 32) * uixScale,
        viewportHeight: viewport + (_searching ? 95 : 32) * uixScale,
        clicked: id == clickedId,
      );
    }
    if (delays.isEmpty) return;
    final milliseconds = delays.values.reduce(math.max) + transition.durationMs;
    setState(() {
      _appsTransition = transition;
      _appDelays = delays;
      _appsMotion.duration = Duration(
        microseconds: (milliseconds * 1000).round(),
      );
    });
    try {
      await _appsMotion.forward(from: 0).orCancel;
    } on TickerCanceled {
      return;
    }
  }

  void _pinApp(App app) {
    final grid = _startMenuKey.currentState;
    if (grid == null || grid.isPinned(app)) return;
    if (_searching) _closeSearch();
    grid.pinApp(app);
    _showPane(0);
  }

  @override
  void dispose() {
    _panes.dispose();
    _appsScroll.dispose();
    _search.dispose();
    _searchFocus.dispose();
    _appsMotion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MetroPageScaffold(
    key: _scaffoldKey,
    enableZAxisEffect: true,
    disableDefaultPushAnimation: true,
    disableDefaultPopAnimation: true,
    disableDefaultPopNextAnimation: true,
    disableDefaultPushNextAnimation: true,
    onDidPush: () async {
      await _startMenuKey.currentState?.startPushAnimations();
    },
    onDidPushNext: <T>(T target) async {
      if (target case (id: final String id, isTile: true)) {
        await _startMenuKey.currentState?.startPushNextAnimations(id);
      } else if (target case (id: final String id, isTile: false)) {
        await _animateApps(StartTileTransition.forwardOut, clickedId: id);
      }
    },
    onDidPopNext: () async {
      if (_pane == 0) {
        await _startMenuKey.currentState?.startPopNextAnimations();
      } else {
        await _animateApps(StartTileTransition.backwardIn);
      }
    },
    showSoftwareBackButton: false,
    onWillPop: _canGoBack ? _back : null,
    body: ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
      ),
      child: PopScope(
        canPop: !_canGoBack,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView(
              controller: _panes,
              physics: _editing || _searching
                  ? const NeverScrollableScrollPhysics()
                  : const ClampingScrollPhysics(),
              onPageChanged: (pane) => setState(() => _pane = pane),
              children: [
                StartMenu(
                  key: _startMenuKey,
                  initialTiles: _initialTiles,
                  onOpenApps: () => _showPane(1),
                  onLaunchApp: (tile) =>
                      _launchApp(tile.app, tileId: tile.instanceId),
                  onEditModeChanged: (value) =>
                      setState(() => _editing = value),
                ),
                _buildApps(context),
              ],
            ),
            if (_canGoBack)
              Positioned(
                left: 0,
                top: MediaQuery.paddingOf(context).top,
                child: Semantics(
                  container: true,
                  excludeSemantics: true,
                  button: true,
                  label: 'Back',
                  onTap: _back,
                  child: Tile(
                    onTap: _back,
                    child: SizedBox.square(
                      dimension: 44,
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/ic_back.svg',
                          package: 'metro_ui',
                          width: 26,
                          height: 26,
                          excludeFromSemantics: true,
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).colorScheme.onSurface,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  Widget _buildApps(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final light = Theme.of(context).brightness == Brightness.light;
    final term = _search.text.trim().toLowerCase();
    final apps = _apps;
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 100),
            curve: const UixLog(150),
            padding: EdgeInsets.only(
              top: (_searching ? 95 : 32) * uixScale,
              left: (_searching ? 24 : 90) * uixScale,
              right: 24 * uixScale,
            ),
            child: ListView.separated(
              key: const PageStorageKey('start-apps'),
              controller: _appsScroll,
              padding: EdgeInsets.only(top: _searching ? 0 : 62 * uixScale),
              itemCount: apps.isEmpty && term.isNotEmpty ? 1 : apps.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12 * uixScale),
              itemBuilder: (_, index) => apps.isEmpty
                  ? const UixText('No results', boundsType: UixTextBounds.tight)
                  : _appRow(apps[index], scheme),
            ),
          ),
        ),
        if (_searching)
          Positioned(
            top: 42 * uixScale,
            left: 24 * uixScale,
            right: 24 * uixScale,
            child: MetroSearchBar(
              controller: _search,
              focusNode: _searchFocus,
              backgroundImage: AssetImage(
                'images/wp8_phone/editbox_${light ? 'light' : 'dark'}.png',
              ),
              onChanged: (_) {
                if (_appsScroll.hasClients) _appsScroll.jumpTo(0);
                setState(() {});
              },
            ),
          )
        else
          Positioned(
            top: 72 * uixScale,
            left: 14 * uixScale,
            child: StartImageButton(
              label: 'Search apps',
              onPressed: _showSearch,
              rest: 'search_rest',
              restColor: scheme.onSurface,
              down: light ? 'search_light_down' : 'search_down',
              chromaReplacement: scheme.primary,
              size: 45,
            ),
          ),
      ],
    );
  }

  Widget _appRow(App app, ColorScheme scheme) {
    // Evaluated when the list is revealed after pinning/editing.
    final pinned =
        _startMenuKey.currentState?.isPinned(app) ??
        _initialTiles.any((tile) => tile.app.id == app.id);
    final row = MetroContextMenu(
      key: ValueKey(app.id),
      menu: MetroContextMenuItem(
        onTap: pinned ? null : () => _pinApp(app),
        child: const Text('pin to start'),
      ),
      child: Tile(
        onTap: () => _launchApp(app),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 62 * uixScale,
              child: ColoredBox(
                color: app.themeColor ?? scheme.primary,
                child: Center(child: app.icon),
              ),
            ),
            const SizedBox(width: 17 * uixScale),
            Expanded(
              child: UixText(
                app.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                boundsType: UixTextBounds.tight,
                style: TextStyle(
                  fontSize: uixFontSize(24),
                  fontWeight: UixFontWeight.semiLight,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    final delay = _appDelays[app.id];
    final transition = _appsTransition;
    return transition == null || delay == null
        ? row
        : StartTransitionTransform(
            clock: _appsMotion,
            transition: transition,
            delay: delay,
            child: row,
          );
  }
}
