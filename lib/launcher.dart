import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:metro_ui/page_scaffold.dart';
import 'package:metro_ui/widgets/context_menu.dart';
import 'package:windows_phone_simulator/splashscreen_page.dart';
import 'package:windows_phone_simulator/about.dart';
import 'package:windows_phone_simulator/start_menu.dart';

class LauncherPage extends StatefulWidget {
  const LauncherPage({super.key, required this.title});

  final String title;

  @override
  State<LauncherPage> createState() => _LauncherPageState();
}

class _LauncherPageState extends State<LauncherPage>
    with TickerProviderStateMixin {
  bool _isEditMode = false; // 是否处于编辑模式
  final GlobalKey<StartMenuState> _startMenuKey = GlobalKey<StartMenuState>();

  late List<TileModel> _pinnedTiles;

  List<App> get apps => [
        App(
          id: 'com.ms.weather',
          name: '天气',
          themeColor: Colors.blue,
          icon: const Icon(Icons.wb_sunny),
          page: const Splashscreen(),
          smallTile: const LiveTile(
              name: Text('天气'),
              size: LiveTileSize.small,
              flipStyle: FlipStyle.elastic,
              children: [
                MetroAppTile(
                    icon: Icon(Icons.wb_sunny, color: Colors.white, size: 24)),
              ]),
          mediumTile: const LiveTile(
            size: LiveTileSize.medium,
            flipStyle: FlipStyle.elastic,
            name: Text('Panorama'),
            children: [
              MetroAppTile(
                icon: Icon(
                  Icons.map,
                  size: 70,
                ),
                count: 2,
              ),
              Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  'Panorama Hub页面，具有浓郁的WP特色',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          wideTile: const LiveTile(
              size: LiveTileSize.wide,
              flipStyle: FlipStyle.elastic,
              name: Text('Panorama'),
              children: [
                MetroAppTile(
                    icon: Icon(Icons.wb_sunny, color: Colors.white, size: 24)),
                Row(
                  // 宽磁贴可以放更多信息
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Icon(Icons.wb_sunny, color: Colors.white, size: 40),
                    Text('新北市板桥区\n晴天 24°C',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ]),
        ),
        App(
          id: 'com.ms.about',
          name: '关于',
          themeColor: Colors.blue,
          icon: const Icon(Icons.info),
          page: const AboutPage(),
          smallTile: const LiveTile(
              size: LiveTileSize.small,
              flipStyle: FlipStyle.elastic,
              children: [
                MetroAppTile(
                    icon: Icon(Icons.wb_sunny, color: Colors.white, size: 24)),
              ]),
          mediumTile: const LiveTile(
            size: LiveTileSize.medium,
            flipStyle: FlipStyle.elastic,
            name: Text('关于'),
            children: [
              MetroAppTile(
                icon: Icon(
                  Icons.map,
                  size: 70,
                ),
                count: 2,
              ),
              Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  '关于页面',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ];

  @override
  void initState() {
    super.initState();
    //打印设备屏幕宽度

    _pinnedTiles = [
      TileModel(
        instanceId: 'weather_1',
        app: apps[0],
        currentSize: TileSize.medium,
        gridX: 0,
        gridY: 0,
      ),
    ];
  }

  /// 判断组件是否在屏幕可见范围内
  ///
  /// [key] 要检查的 GlobalKey
  /// 返回 true 表示组件可见，false 表示不可见

  @override
  Widget build(BuildContext context) {
    return MetroPageScaffold(
      onDidPushNext: <T>(T data) async {
        if (data is String) {
          await _startMenuKey.currentState?.startPushNextAnimations(data);
        }
      },
      onDidPush: () async {
        await _startMenuKey.currentState?.startPushAnimations();
      },
      onDidPopNext: () async {
        await _startMenuKey.currentState?.startPopNextAnimations();
      },
      onDidPop: () async {
        // await _startMenuKey.currentState?.startPushAnimations();
      },
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          return ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                },
              ),
              child: SingleChildScrollView(
                clipBehavior: Clip.none,
                scrollDirection: Axis.horizontal,
                physics: _isEditMode
                    ? const NeverScrollableScrollPhysics()
                    : LauncherSnapPhysics(
                        snapOffsets: [0, screenWidth - 60],
                        parent: const ClampingScrollPhysics(), // 禁用边界回弹
                      ),
                child: Row(
                  children: [
                    SizedBox(
                      width: screenWidth - 60,
                      child: StartMenu(
                        key: _startMenuKey,
                        crossAxisCount: 4,
                        initialTiles: _pinnedTiles,
                        onEditModeChanged: (isEdit) {
                          setState(() {
                            _isEditMode = isEdit;
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      width: screenWidth,
                      child: GestureDetector(
                        onTap: _isEditMode
                            ? () => _startMenuKey.currentState?.exitEditMode()
                            : null,
                        behavior: HitTestBehavior.opaque,
                        child: AbsorbPointer(
                          absorbing: _isEditMode,
                          child: Container(
                            //color: Colors.transparent,
                            padding: const EdgeInsets.only(top: 40, left: 20),
                            child: ListView.builder(
                              itemCount: apps.length,
                              itemBuilder: (context, index) {
                                final app = apps[index];
                                final GlobalKey<MetroContextMenuState> menuKey =
                                    GlobalKey<MetroContextMenuState>();
                                return MetroContextMenu(
                                  key: menuKey,
                                  menu: MetroContextMenuItem(
                                    child: const Text('pin to start'),
                                    onTap: () {
                                      // 关闭上下文菜单
                                      menuKey.currentState?.dismissMenu();

                                      // 外层不参与磁贴排版，直接把 App 丢给 StartMenu 内部处理！
                                      _startMenuKey.currentState?.pinApp(app);
                                    },
                                  ),
                                  child: ListTile(
                                    leading: Container(
                                      width: 48,
                                      height: 48,
                                      color: app.themeColor,
                                      child: app.icon,
                                    ),
                                    title: Text(
                                      app.name,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 24),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ));
        },
      ),
    );
  }
}

class LauncherSnapPhysics extends ScrollPhysics {
  final List<double> snapOffsets;

  const LauncherSnapPhysics({
    required this.snapOffsets,
    super.parent,
  });

  @override
  LauncherSnapPhysics applyTo(ScrollPhysics? ancestor) {
    return LauncherSnapPhysics(
      snapOffsets: snapOffsets,
      parent: buildParent(ancestor),
    );
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    // 处理触底或超出边界的情况（防止越界后无法归位或失去阻尼限制）
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    final double expectedScrollOffset = position.pixels;

    double target;
    if (velocity.abs() < 500) {
      // 滑动速度很小或是缓慢拖动停止，直接吸附到离当前位置最近的点
      target = _findNearestSnap(expectedScrollOffset);
    } else if (velocity > 0) {
      // 向右滑动（看后面内容）
      target = snapOffsets.last;
    } else {
      // 向左滑动（看前面内容）
      target = snapOffsets.first;
    }

    if (target != position.pixels) {
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        target,
        velocity,
        tolerance: toleranceFor(position),
      );
    }

    return super.createBallisticSimulation(position, velocity);
  }

  double _findNearestSnap(double offset) {
    double nearest = snapOffsets[0];
    double minDistance = (offset - snapOffsets[0]).abs();
    for (double snap in snapOffsets) {
      double distance = (offset - snap).abs();
      if (distance < minDistance) {
        minDistance = distance;
        nearest = snap;
      }
    }
    return nearest;
  }
}