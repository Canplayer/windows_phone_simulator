import 'dart:async';
import 'dart:math' as math;
import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:metro_ui/animations.dart';
import 'package:metro_ui/animated_widgets.dart';
import 'package:metro_ui/metro_page_push.dart';
import 'package:metro_ui/page.dart';
import 'package:metro_ui/page_scaffold.dart';
import 'package:metro_ui/widgets/context_menu.dart';
import 'package:metro_ui/widgets/tile.dart';
import 'package:windows_phone_simulator/global_perspective.dart';
import 'package:windows_phone_simulator/splashscreen_page.dart';
import 'package:windows_phone_simulator/about.dart';

class LauncherPage extends StatefulWidget {
  const LauncherPage({super.key, required this.title});

  final String title;

  @override
  State<LauncherPage> createState() => _LauncherPageState();
}

class _LauncherPageState extends State<LauncherPage>
    with TickerProviderStateMixin {
  bool _isEditMode = false; // 是否处于编辑模式
  final GlobalKey<_StartMenuState> _startMenuKey = GlobalKey<_StartMenuState>();

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

//磁贴大小枚举
enum TileSize {
  small, // 1x1 小
  medium, // 2x2 中
  wide, // 4x2 宽
}

//应用数据模型
class App {
  final String id; // 应用包名/唯一标识，如 'com.example.weather'
  final String name; // 应用名称，如 '天气'
  final Widget icon; // 用于应用列表(App List)的图标
  final Widget page; // 点击磁贴后跳转的页面组件

  // --- 磁贴视觉层：将磁贴设计交给 App 自身决定 ---
  final Widget smallTile; // 1x1 磁贴组件 (必须)
  final Widget mediumTile; // 2x2 磁贴组件 (必须)
  final Widget? wideTile; // 4x2 磁贴组件 (可选)

  final Color themeColor; // 应用主题色 (用于磁贴背景底色等)

  App({
    required this.id,
    required this.name,
    required this.icon,
    required this.page,
    required this.smallTile,
    required this.mediumTile,
    this.wideTile, // 宽磁贴可选
    required this.themeColor,
  });

  // 提供一个便捷方法：根据尺寸获取对应的磁贴 UI
  Widget getTileWidget(TileSize size) {
    switch (size) {
      case TileSize.small:
        return smallTile;
      case TileSize.medium:
        return mediumTile;
      case TileSize.wide:
        // 如果请求宽磁贴但该 App 没有提供，就降级返回中等尺寸（或者给个警告）
        return wideTile ?? mediumTile;
    }
  }
}

//磁贴实例
class TileModel {
  final String instanceId; // 磁贴的实例ID (因为桌面上可能允许放两个相同的应用快捷方式)
  final App app; // 🌟 核心：它指向哪个应用

  TileSize currentSize; // 🌟 当前在桌面上展示的尺寸

  int gridX;
  int gridY;

  Offset? dragPixelOffset;
  GlobalKey key;

  TileModel({
    required this.instanceId,
    required this.app,
    required this.currentSize,
    required this.gridX,
    required this.gridY,
  }) : key = GlobalKey();

  TileModel clone() {
    return TileModel(
      instanceId: instanceId,
      app: app,
      currentSize: currentSize,
      gridX: gridX,
      gridY: gridY,
    )..key = key;
  }

  // --- 动态计算占用网格数 ---
  int get widthCells {
    switch (currentSize) {
      case TileSize.small:
        return 1;
      case TileSize.medium:
        return 2;
      case TileSize.wide:
        return 4;
    }
  }

  int get heightCells {
    switch (currentSize) {
      case TileSize.small:
        return 1;
      case TileSize.medium:
        return 2;
      case TileSize.wide:
        return 2;
    }
  }

  // AABB 碰撞检测保持不变
  bool overlaps(TileModel other) {
    return gridX < other.gridX + other.widthCells &&
        gridX + widthCells > other.gridX &&
        gridY < other.gridY + other.heightCells &&
        gridY + heightCells > other.gridY;
  }
}

class StartMenu extends StatefulWidget {
  final List<TileModel> initialTiles;
  final ValueChanged<bool>? onEditModeChanged;

  const StartMenu({
    super.key,
    required this.initialTiles,
    this.onEditModeChanged,
  });

  @override
  _StartMenuState createState() => _StartMenuState();
}

class _StartMenuState extends State<StartMenu> with TickerProviderStateMixin {
  final int crossAxisCount = 4;
  final double gridSpacing = 19 * 0.625 * 0.8;

  late List<TileModel> tiles;

  // 🌟 新增：纵向滚动控制器
  final ScrollController _scrollController = ScrollController();
  final Map<String, AnimationController> _flipControllers = {};
  final Map<String, Animation<double>> _flipAnimations = {};

  void _syncAnimations() {
    for (var tile in tiles) {
      if (!_flipControllers.containsKey(tile.instanceId)) {
        var ctrl = AnimationController(
            vsync: this, duration: const Duration(milliseconds: 150));
        _flipControllers[tile.instanceId] = ctrl;
        _flipAnimations[tile.instanceId] =
            Tween<double>(begin: 0.0, end: math.pi / 2)
                .animate(CurvedAnimation(parent: ctrl, curve: Curves.easeIn));
      }
    }
  }

  Future<void> startPushNextAnimations(String tapInstanceId) async {
    _syncAnimations();
    double currentOffset =
        _scrollController.hasClients ? _scrollController.offset : 0.0;
    double viewportHeight = _scrollController.hasClients
        ? _scrollController.position.viewportDimension
        : 1000.0;

    final renderBox =
        _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    double cellWidth = renderBox.size.width / crossAxisCount;
    double cellHeight = cellWidth;

    List<TileModel> visibleTiles = [];
    for (var tile in tiles) {
      double topEdge = tile.gridY * cellHeight;
      double bottomEdge = (tile.gridY + tile.heightCells) * cellHeight;
      if (bottomEdge > currentOffset - cellHeight &&
          topEdge < currentOffset + viewportHeight + cellHeight) {
        visibleTiles.add(tile);
      }
    }

    if (visibleTiles.isEmpty) return;

    int maxX = visibleTiles.map((e) => e.gridX).reduce(math.max);
    int maxY = visibleTiles.map((e) => e.gridY).reduce(math.max);

    Map<String, int> distances = {};
    int maxDistance = 0;
    for (var tile in visibleTiles) {
      if (tile.instanceId == tapInstanceId) continue;
      int dist = (maxX - tile.gridX) + (maxY - tile.gridY);
      distances[tile.instanceId] = dist;
      if (dist > maxDistance) {
        maxDistance = dist;
      }
    }

    final int pushTime = 350;
    final int singleTileTime = 150;
    final int groupDelay = maxDistance == 0
        ? 0
        : ((pushTime - singleTileTime) / maxDistance).round();

    for (var tile in visibleTiles) {
      if (tile.instanceId == tapInstanceId) continue;
      int delayMs = distances[tile.instanceId]! * groupDelay;

      Future.delayed(Duration(milliseconds: delayMs), () {
        if (mounted) {
          _flipControllers[tile.instanceId]?.duration =
              Duration(milliseconds: singleTileTime);
          _flipAnimations[tile.instanceId] =
              Tween<double>(begin: 0.0, end: math.pi / 2)
                  .animate(CurvedAnimation(
            parent: _flipControllers[tile.instanceId]!,
            curve: MetroCurves.normalPageRotateOut,
          ));
          _flipControllers[tile.instanceId]?.forward(from: 0.0);
        }
      });
    }

    int tappedDelay = (maxDistance * groupDelay) + groupDelay;
    if (tappedDelay == 0 || maxDistance == 0)
      tappedDelay = pushTime - singleTileTime;

    Future.delayed(Duration(milliseconds: tappedDelay), () {
      if (mounted) {
        _flipControllers[tapInstanceId]?.duration =
            Duration(milliseconds: singleTileTime);
        _flipAnimations[tapInstanceId] =
            Tween<double>(begin: 0.0, end: math.pi / 2).animate(CurvedAnimation(
          parent: _flipControllers[tapInstanceId]!,
          curve: MetroCurves.normalPageRotateOut,
        ));
        _flipControllers[tapInstanceId]?.forward(from: 0.0);
      }
    });

    await Future.delayed(
        Duration(milliseconds: tappedDelay + singleTileTime + 50));
  }

  Future<void> startPopNextAnimations() async {
    _syncAnimations();
    double currentOffset =
        _scrollController.hasClients ? _scrollController.offset : 0.0;
    double viewportHeight = _scrollController.hasClients
        ? _scrollController.position.viewportDimension
        : 1000.0;

    final renderBox =
        _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    double cellWidth = renderBox.size.width / crossAxisCount;
    double cellHeight = cellWidth;

    List<TileModel> visibleTiles = [];
    for (var tile in tiles) {
      double topEdge = tile.gridY * cellHeight;
      double bottomEdge = (tile.gridY + tile.heightCells) * cellHeight;
      if (bottomEdge > currentOffset - cellHeight &&
          topEdge < currentOffset + viewportHeight + cellHeight) {
        visibleTiles.add(tile);
      }
    }

    if (visibleTiles.isEmpty) return;

    int minX = visibleTiles.map((e) => e.gridX).reduce(math.min);
    int minY = visibleTiles.map((e) => e.gridY).reduce(math.min);

    Map<String, int> distances = {};
    int maxDistance = 0;
    for (var tile in visibleTiles) {
      int dist = (tile.gridX - minX) + (tile.gridY - minY);
      distances[tile.instanceId] = dist;
      if (dist > maxDistance) {
        maxDistance = dist;
      }
    }

    final int pushTime = 350;
    final int singleTileTime = 150;
    final int popDuration = singleTileTime * 3;
    final int groupDelay = maxDistance == 0
        ? 0
        : ((pushTime - singleTileTime) / maxDistance).round();

    for (var tile in visibleTiles) {
      int delayMs = distances[tile.instanceId]! * groupDelay;

      Future.delayed(Duration(milliseconds: delayMs), () {
        if (mounted) {
          _flipControllers[tile.instanceId]?.duration =
              Duration(milliseconds: popDuration);
          _flipAnimations[tile.instanceId] =
              Tween<double>(begin: 50 * math.pi / 180, end: 0.0)
                  .animate(CurvedAnimation(
            parent: _flipControllers[tile.instanceId]!,
            curve: MetroCurves.normalPageRotateIn,
          ));
          _flipControllers[tile.instanceId]?.forward(from: 0.0);
        }
      });
    }

    await Future.delayed(
        Duration(milliseconds: (maxDistance * groupDelay) + popDuration + 50));
  }

  Future<void> startPushAnimations() async {
    _syncAnimations();
    double currentOffset =
        _scrollController.hasClients ? _scrollController.offset : 0.0;
    double viewportHeight = _scrollController.hasClients
        ? _scrollController.position.viewportDimension
        : 1000.0;

    final renderBox =
        _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    double cellWidth = renderBox.size.width / crossAxisCount;
    double cellHeight = cellWidth;

    List<TileModel> visibleTiles = [];
    for (var tile in tiles) {
      double topEdge = tile.gridY * cellHeight;
      double bottomEdge = (tile.gridY + tile.heightCells) * cellHeight;
      if (bottomEdge > currentOffset - cellHeight &&
          topEdge < currentOffset + viewportHeight + cellHeight) {
        visibleTiles.add(tile);
      }
    }

    if (visibleTiles.isEmpty) return;

    int minX = visibleTiles.map((e) => e.gridX).reduce(math.min);
    int minY = visibleTiles.map((e) => e.gridY).reduce(math.min);

    Map<String, int> distances = {};
    int maxDistance = 0;
    for (var tile in visibleTiles) {
      int dist = (tile.gridX - minX) + (tile.gridY - minY);
      distances[tile.instanceId] = dist;
      if (dist > maxDistance) {
        maxDistance = dist;
      }
    }

    final int pushTime = 350;
    final int singleTileTime = 150;
    final int popDuration = singleTileTime * 3;
    final int groupDelay = maxDistance == 0
        ? 0
        : ((pushTime - singleTileTime) / maxDistance).round();

    for (var tile in visibleTiles) {
      int delayMs = distances[tile.instanceId]! * groupDelay;

      Future.delayed(Duration(milliseconds: delayMs), () {
        if (mounted) {
          _flipControllers[tile.instanceId]?.duration =
              Duration(milliseconds: popDuration);
          _flipAnimations[tile.instanceId] =
              Tween<double>(begin: -65 * math.pi / 180, end: 0.0)
                  .animate(CurvedAnimation(
            parent: _flipControllers[tile.instanceId]!,
            curve: MetroCurves.normalPageRotateIn,
          ));
          _flipControllers[tile.instanceId]?.forward(from: 0.0);
        }
      });
    }
  }

  final GlobalKey _stackKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    tiles = List.from(widget.initialTiles);
  }

  // @override
  // void didUpdateWidget(StartMenu oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   for (var newTile in widget.initialTiles) {
  //     if (!tiles.any((t) => t.instanceId == newTile.instanceId)) {
  //       setState(() {
  //         tiles.add(newTile);
  //       });
  //     }
  //   }
  // }

  /// 自动寻找能够容纳指定宽高的空余网格坐标
  /// 逻辑：从“试图与最底部边缘平齐”的 Y 坐标开始尝试。
  /// 如果该行没有任何一列能放下，则一行一行（y++）向下移动，直到找到空位。
  Offset _findEmptySpot(List<TileModel> currentTiles, int width, int height) {
    int cols = crossAxisCount; // 桌面总列数
    int maxGridY = 0;
    for (var tile in currentTiles) {
      if (tile.gridY + tile.heightCells > maxGridY) {
        maxGridY = tile.gridY + tile.heightCells;
      }
    }

    int y = math.max(0, maxGridY - height);

    while (true) {
      for (int x = 0; x <= cols - width; x++) {
        bool isOverlapping = false;
        for (var tile in currentTiles) {
          if (x < tile.gridX + tile.widthCells &&
              x + width > tile.gridX &&
              y < tile.gridY + tile.heightCells &&
              y + height > tile.gridY) {
            isOverlapping = true;
            break;
          }
        }
        if (!isOverlapping) {
          return Offset(x.toDouble(), y.toDouble());
        }
      }
      y++;
    }
  }

  // 3. 🌟 新增对外的公共方法，供 LauncherPage 调用
  void pinApp(App app) {
    int newWidthCells = 2; // 默认中磁贴
    int newHeightCells = 2;

    Offset emptySpot = _findEmptySpot(tiles, newWidthCells, newHeightCells);

    setState(() {
      tiles.add(TileModel(
        instanceId: '${app.id}_${DateTime.now().millisecondsSinceEpoch}',
        app: app,
        currentSize: TileSize.medium,
        gridX: emptySpot.dx.toInt(),
        gridY: emptySpot.dy.toInt(),
      ));
    });

    // 小彩蛋/体验优化：Pin 完之后，自动向下滚动，向用户展示刚刚固定的新磁贴
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? box =
          _stackKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        double cellSize = box.size.width / crossAxisCount;
        _ensureTileVisible(tiles.last, cellSize);
      }
    });
  }

  @override
  void dispose() {
    for (var ctrl in _flipControllers.values) {
      ctrl.dispose();
    }
    _scrollController.dispose(); // 🌟 记得释放控制器
    hoverTimer?.cancel();
    super.dispose();
  }

  // --- UI状态 ---
  bool isEditMode = false;
  String? selectedTileId;
  String? draggingTileId;
  Offset? initialDragOffset;
  Offset? initialTouchPosition;
  bool hasMetDragThreshold = false;

  // --- 引擎状态 ---
  List<TileModel>? originalItems;
  List<TileModel>? _baseLayoutSnapshot;
  Timer? hoverTimer;
  int lastHoverX = -1;
  int lastHoverY = -1;

  void exitEditMode() {
    if (isEditMode) {
      setState(() {
        isEditMode = false;
        selectedTileId = null;
        draggingTileId = null;
        _baseLayoutSnapshot = null;
      });
      if (widget.onEditModeChanged != null) {
        widget.onEditModeChanged!(false);
      }
    }
  }

  // 🌟 新增：边缘越界检测与自动滚动对齐
  void _ensureTileVisible(TileModel tile, double cellSize) {
    if (!_scrollController.hasClients) return;

    final double topEdge = tile.gridY * cellSize;
    final double bottomEdge = (tile.gridY + tile.heightCells) * cellSize;
    final double currentOffset = _scrollController.offset;
    final double viewportHeight = _scrollController.position.viewportDimension;

    // 留出一点边距，看着更舒服
    const double padding = 10.0;

    if (topEdge < currentOffset) {
      // 如果磁贴顶部超出了上方视口，向上滚动
      _scrollController.animateTo(
        math.max(0.0, topEdge - padding),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else if (bottomEdge > currentOffset + viewportHeight) {
      // 如果磁贴底部超出了下方视口，向下滚动
      _scrollController.animateTo(
        bottomEdge - viewportHeight + padding,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  // --- 🌟 完美移植：网格碰撞推挤引擎 ---
  void _updatePreview(int targetX, int targetY) {
    if (originalItems == null || draggingTileId == null) return;

    Offset? currentPixelOffset;
    try {
      currentPixelOffset = tiles
          .firstWhere((e) => e.instanceId == draggingTileId)
          .dragPixelOffset;
    } catch (e) {}

    List<TileModel> nextLayout = originalItems!.map((e) => e.clone()).toList();
    TileModel targetItem =
        nextLayout.firstWhere((e) => e.instanceId == draggingTileId);

    targetItem.gridX = targetX;
    targetItem.gridY = targetY;
    targetItem.dragPixelOffset = currentPixelOffset;

    List<TileModel> directCollisions = nextLayout
        .where((item) =>
            item.instanceId != targetItem.instanceId &&
            item.overlaps(targetItem))
        .toList();

    if (directCollisions.isNotEmpty) {
      bool moved = false;
      bool canBreakCeiling = false;
      int ceilingOffsetX = 0;
      int ceilingOffsetY = 0;

      int groupLeft =
          directCollisions.map((e) => e.gridX).reduce((a, b) => a < b ? a : b);
      int groupRight = directCollisions
          .map((e) => e.gridX + e.widthCells)
          .reduce((a, b) => a > b ? a : b);
      int groupTop =
          directCollisions.map((e) => e.gridY).reduce((a, b) => a < b ? a : b);
      int groupBottom = directCollisions
          .map((e) => e.gridY + e.heightCells)
          .reduce((a, b) => a > b ? a : b);

      double groupCenterX = groupLeft + (groupRight - groupLeft) / 2.0;
      double groupCenterY = groupTop + (groupBottom - groupTop) / 2.0;

      double targetCenterX = targetItem.gridX + targetItem.widthCells / 2.0;
      double targetCenterY = targetItem.gridY + targetItem.heightCells / 2.0;

      final directions = [
        const Offset(0, -1),
        const Offset(-1, 0),
        const Offset(1, 0),
        const Offset(0, 1)
      ];

      for (var dir in directions) {
        if (dir.dx < 0 && groupCenterX > targetCenterX) continue;
        if (dir.dx > 0 && groupCenterX < targetCenterX) continue;
        if (dir.dy < 0 && groupCenterY > targetCenterY) continue;
        if (dir.dy > 0 && groupCenterY < targetCenterY) continue;

        int offsetX = 0;
        int offsetY = 0;

        if (dir.dx < 0) {
          offsetX = targetItem.gridX - groupRight;
        } else if (dir.dx > 0) {
          offsetX = (targetItem.gridX + targetItem.widthCells) - groupLeft;
        } else if (dir.dy < 0) {
          offsetY = targetItem.gridY - groupBottom;
        } else if (dir.dy > 0) {
          offsetY = (targetItem.gridY + targetItem.heightCells) - groupTop;
        }

        bool isOutOfBoundsX = false;
        bool isColliding = false;
        bool isBreakingCeiling = false;

        for (var item in directCollisions) {
          int nx = item.gridX + offsetX;
          int ny = item.gridY + offsetY;

          if (nx < 0 || nx + item.widthCells > crossAxisCount) {
            isOutOfBoundsX = true;
            break;
          }

          TileModel ghost = item.clone();
          ghost.gridX = nx;
          ghost.gridY = ny;

          for (var other in nextLayout) {
            if (other.instanceId == targetItem.instanceId) continue;
            if (directCollisions.any((e) => e.instanceId == other.instanceId))
              continue;
            if (ghost.overlaps(other)) {
              isColliding = true;
              break;
            }
          }
          if (isColliding) break;
          if (ny < 0) isBreakingCeiling = true;
        }

        if (!isOutOfBoundsX && !isColliding) {
          if (!isBreakingCeiling) {
            for (var item in directCollisions) {
              item.gridX += offsetX;
              item.gridY += offsetY;
            }
            moved = true;
            break;
          } else if (dir.dy < 0 && directCollisions.length == 1) {
            canBreakCeiling = true;
            ceilingOffsetX = offsetX;
            ceilingOffsetY = offsetY;
          }
        }
      }

      if (!moved && canBreakCeiling) {
        for (var item in directCollisions) {
          item.gridX += ceilingOffsetX;
          item.gridY += ceilingOffsetY;
        }
        moved = true;
      }

      if (!moved) {
        var belowRowCollisions =
            directCollisions.where((e) => e.gridY > targetItem.gridY).toList();
        if (belowRowCollisions.isNotEmpty) {
          int maxShiftDown = 0;
          for (var item in belowRowCollisions) {
            int requiredShift =
                (targetItem.gridY + targetItem.heightCells) - item.gridY;
            if (requiredShift > maxShiftDown) maxShiftDown = requiredShift;
          }
          for (var item in nextLayout) {
            if (item.instanceId != targetItem.instanceId &&
                item.gridY > targetItem.gridY) {
              item.gridY += maxShiftDown;
            }
          }
        }

        var topRowCollisions =
            directCollisions.where((e) => e.gridY <= targetItem.gridY).toList();
        if (topRowCollisions.isNotEmpty) {
          int maxShiftUp = 0;
          for (var item in topRowCollisions) {
            int requiredShift =
                (item.gridY + item.heightCells) - targetItem.gridY;
            if (requiredShift > maxShiftUp) maxShiftUp = requiredShift;
          }
          for (var item in nextLayout) {
            if (item.instanceId != targetItem.instanceId &&
                item.gridY <= targetItem.gridY) {
              item.gridY -= maxShiftUp;
            }
          }
        }
      }
    }

    setState(() {
      tiles = nextLayout;
    });
  }

  void _finalizeLayout() {
    setState(() {
      int minY = tiles.map((e) => e.gridY).reduce((a, b) => a < b ? a : b);
      if (minY < 0) {
        int offset = minY.abs();
        for (var item in tiles) {
          item.gridY += offset;
        }
      }
      _compactLayout(tiles);
    });
  }

  void _compactLayout(List<TileModel> allItems) {
    int maxY = allItems.fold(
        0,
        (max, e) =>
            e.gridY + e.heightCells > max ? e.gridY + e.heightCells : max);
    for (int y = 0; y < maxY; y++) {
      bool isRowOccupied = allItems
          .any((item) => y >= item.gridY && y < item.gridY + item.heightCells);
      if (!isRowOccupied) {
        bool hasItemsBelow = allItems.any((item) => item.gridY > y);
        if (hasItemsBelow) {
          for (var item in allItems) {
            if (item.gridY > y) item.gridY -= 1;
          }
          y--;
          maxY--;
        }
      }
    }
  }

  // --- 滑动核心接管 ---
  void _onDragStart(TileModel tile, Offset touchPosition, double left,
      double top, double cellSize) {
    // 🌟 传入 cellSize
    setState(() {
      if (!isEditMode) {
        if (widget.onEditModeChanged != null) {
          widget.onEditModeChanged!(true);
        }
      }
      isEditMode = true;

      if (selectedTileId != tile.instanceId) {
        _baseLayoutSnapshot = tiles.map((e) => e.clone()).toList();
      }

      selectedTileId = tile.instanceId;
      draggingTileId = tile.instanceId;
      initialDragOffset = Offset(left, top);
      initialTouchPosition = touchPosition;
      hasMetDragThreshold = false;
      tile.dragPixelOffset = initialDragOffset;

      originalItems = tiles.map((e) => e.clone()).toList();
    });

    // 🌟 长按激活时也保证它在视口内
    _ensureTileVisible(tile, cellSize);
  }

  void _onDragUpdate(
      TileModel tile, Offset currentTouchPosition, double cellSize) {
    if (draggingTileId == tile.instanceId &&
        initialTouchPosition != null &&
        initialDragOffset != null) {
      final distance = (currentTouchPosition - initialTouchPosition!).distance;

      setState(() {
        if (!hasMetDragThreshold && distance > 70.0) {
          hasMetDragThreshold = true;
        }
        if (hasMetDragThreshold) {
          tile.dragPixelOffset = initialDragOffset! +
              (currentTouchPosition - initialTouchPosition!);

          int newGridX = (tile.dragPixelOffset!.dx / cellSize).round();
          int newGridY = (tile.dragPixelOffset!.dy / cellSize).round();

          newGridX = newGridX.clamp(0, crossAxisCount - tile.widthCells);
          newGridY = newGridY >= 0 ? newGridY : 0;

          if (newGridX != lastHoverX || newGridY != lastHoverY) {
            lastHoverX = newGridX;
            lastHoverY = newGridY;

            hoverTimer?.cancel();
            hoverTimer = Timer(const Duration(milliseconds: 120), () {
              _updatePreview(newGridX, newGridY);
            });
          }
        }
      });
    }
  }

  void _onDragEnd(TileModel tile, double cellSize) {
    setState(() {
      hoverTimer?.cancel();

      if (tile.dragPixelOffset != null && hasMetDragThreshold) {
        int finalX = (tile.dragPixelOffset!.dx / cellSize).round();
        int finalY = (tile.dragPixelOffset!.dy / cellSize).round();
        finalX = finalX.clamp(0, crossAxisCount - tile.widthCells);
        finalY = finalY >= 0 ? finalY : 0;

        _updatePreview(finalX, finalY);
        _finalizeLayout();

        _baseLayoutSnapshot = tiles.map((e) => e.clone()).toList();
      } else {
        if (originalItems != null) {
          tiles = originalItems!;
        }
      }

      draggingTileId = null;
      tile.dragPixelOffset = null;
      initialDragOffset = null;
      initialTouchPosition = null;
      hasMetDragThreshold = false;
      originalItems = null;
      lastHoverX = -1;
      lastHoverY = -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: exitEditMode,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: isEditMode ? 0.9 : 1.0,
        curve: Curves.easeOutCubic,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double cellSize = constraints.maxWidth / crossAxisCount;

            // 🌟 动态计算整个滚动内容的实际高度
            int maxGridY = 0;
            for (var t in tiles) {
              if (t.gridY + t.heightCells > maxGridY) {
                maxGridY = t.gridY + t.heightCells;
              }
            }
            // 确保高度至少撑满屏幕，且底部留出空白缓冲区
            final double stackHeight = math.max(
              constraints.maxHeight,
              (maxGridY * cellSize) + 200.0,
            );

            List<Widget> normalTiles = [];
            Widget? activeTileWidget;

            for (var tile in tiles) {
              Widget tileWidget = _buildTile(tile, cellSize, context);
              if (tile.instanceId == selectedTileId) {
                activeTileWidget = tileWidget;
              } else {
                normalTiles.add(tileWidget);
              }
            }

            if (activeTileWidget != null) normalTiles.add(activeTileWidget);

            // 🌟 核心：滚动时取消选中模式的监听器
            return NotificationListener<UserScrollNotification>(
              onNotification: (notification) {
                // 如果是用户手指主导的滚动行为
                if (notification.direction != ScrollDirection.idle) {
                  // 如果处于编辑模式且有选中元素，但是不在拖拽挪位过程中
                  if (isEditMode &&
                      selectedTileId != null &&
                      draggingTileId == null) {
                    setState(() {
                      selectedTileId = null;
                    });
                  }
                }
                return false; // 不拦截滚动事件，继续向下冒泡
              },
              // 🌟 包裹纵向滚动视图
              child: SingleChildScrollView(
                clipBehavior: Clip.none,
                controller: _scrollController,
                //physics: const BouncingScrollPhysics(),
                child: Container(
                  padding: const EdgeInsets.only(top: 80),
                  color: Colors.transparent, // 撑开透明区域以拦截点击退出事件
                  width: double.infinity,
                  height: stackHeight, // 给 Stack 设定计算出来的绝对高度
                  child: Stack(
                    key: _stackKey, // 🌟 挂载全局靶点
                    clipBehavior: Clip.none,
                    children: normalTiles,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTile(TileModel tile, double cellSize, BuildContext context) {
    final bool isSelected = tile.instanceId == selectedTileId;
    final bool isActuallyDragging =
        (tile.instanceId == draggingTileId) && hasMetDragThreshold;

    double targetOpacity = 1.0;
    if (isEditMode) {
      targetOpacity = isSelected ? (isActuallyDragging ? 0.8 : 1.0) : 0.5;
    }

    // double targetScale = 1.0;
    // if (isEditMode) {
    //   targetScale = isSelected ? 1 : 0.9;
    // }

    final double targetLeft = tile.gridX * cellSize;
    final double targetTop = tile.gridY * cellSize;

    final double left = isActuallyDragging && tile.dragPixelOffset != null
        ? tile.dragPixelOffset!.dx
        : targetLeft;
    final double top = isActuallyDragging && tile.dragPixelOffset != null
        ? tile.dragPixelOffset!.dy
        : targetTop;
    final double width = tile.widthCells * cellSize - gridSpacing;
    final double height = tile.heightCells * cellSize - gridSpacing;

    const double circleSize = 48.125 * 0.8;
    const double expandOffset = circleSize / 2;

    // 提炼浮动状态判断
    final bool isFloating = isEditMode && !isSelected;

    Widget tileGestureContent = GestureDetector(
      onTap: () {
        if (isEditMode && selectedTileId != tile.instanceId) {
          setState(() {
            selectedTileId = tile.instanceId;
            _baseLayoutSnapshot = tiles.map((e) => e.clone()).toList();
          });
          // 🌟 选中时自动吸附对齐视口
          _ensureTileVisible(tile, cellSize);
        }
      },
      onLongPressStart: (details) {
        final RenderBox? box =
            _stackKey.currentContext?.findRenderObject() as RenderBox?;
        if (box != null) {
          _onDragStart(tile, box.globalToLocal(details.globalPosition),
              targetLeft, targetTop, cellSize);
        }
      },
      onLongPressMoveUpdate: (details) {
        final RenderBox? box =
            _stackKey.currentContext?.findRenderObject() as RenderBox?;
        if (box != null) {
          _onDragUpdate(
              tile, box.globalToLocal(details.globalPosition), cellSize);
        }
      },
      onLongPressEnd: (details) => _onDragEnd(tile, cellSize),

      // 🌟 终极修复：拆分 onPan 为具体的垂直和水平手势，利用深度优先规则彻底秒杀外层列表的滚动！
      onVerticalDragStart: (isEditMode && isSelected)
          ? (details) {
              final RenderBox? box =
                  _stackKey.currentContext?.findRenderObject() as RenderBox?;
              if (box != null) {
                _onDragStart(tile, box.globalToLocal(details.globalPosition),
                    targetLeft, targetTop, cellSize);
              }
            }
          : null,
      onVerticalDragUpdate: (isEditMode && isSelected)
          ? (details) {
              final RenderBox? box =
                  _stackKey.currentContext?.findRenderObject() as RenderBox?;
              if (box != null) {
                _onDragUpdate(
                    tile, box.globalToLocal(details.globalPosition), cellSize);
              }
            }
          : null,
      onVerticalDragEnd: (isEditMode && isSelected)
          ? (details) => _onDragEnd(tile, cellSize)
          : null,

      onHorizontalDragStart: (isEditMode && isSelected)
          ? (details) {
              final RenderBox? box =
                  _stackKey.currentContext?.findRenderObject() as RenderBox?;
              if (box != null) {
                _onDragStart(tile, box.globalToLocal(details.globalPosition),
                    targetLeft, targetTop, cellSize);
              }
            }
          : null,
      onHorizontalDragUpdate: (isEditMode && isSelected)
          ? (details) {
              final RenderBox? box =
                  _stackKey.currentContext?.findRenderObject() as RenderBox?;
              if (box != null) {
                _onDragUpdate(
                    tile, box.globalToLocal(details.globalPosition), cellSize);
              }
            }
          : null,
      onHorizontalDragEnd: (isEditMode && isSelected)
          ? (details) => _onDragEnd(tile, cellSize)
          : null,
      child: AbsorbPointer(
        absorbing: isEditMode,
        // 🌟 重构核心 1：用 TweenAnimationBuilder 在父级处理平滑的透明度过渡
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 200),
          tween: Tween<double>(begin: 1.0, end: targetOpacity),
          builder: (context, opacityValue, child) {
            // 🌟 盖上你写的终极 3D 摄像机透明度控件！
            return Opacity(
              opacity: opacityValue,
              child: GlobalPerspective(
                child: child!,
              ),
            );
          },
          // 🌟 重构核心 2：把原本 LiveTile 里的浮动包装器提到了这里
          child: FloatingWrapper(
            isFloating: isFloating,
            child: Tile(
              child: tile.app.getTileWidget(tile.currentSize),
              onTap: () {
                metroPagePush(
                  context,
                  MetroPageRoute(
                    builder: (context) {
                      return tile.app.page;
                    },
                  ),
                  dataToPass: tile.instanceId,
                );
              },
            ),
          ),
        ),
      ),
    );

    Widget tileContent = Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: expandOffset,
          top: expandOffset,
          right: expandOffset,
          bottom: expandOffset,
          child: tileGestureContent,
        ),
        if (isEditMode && isSelected && !isActuallyDragging) ...[
          Positioned(
            top: 0,
            right: 0,
            width: circleSize,
            height: circleSize,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: targetOpacity,
              child: _EditButton(
                icon: const Icon(Icons.push_pin_outlined),
                onPressed: () {
                  setState(() {
                    tiles.removeWhere((t) => t.instanceId == tile.instanceId);
                    _finalizeLayout();

                    _baseLayoutSnapshot = tiles.map((e) => e.clone()).toList();

                    if (tiles.isEmpty) {
                      exitEditMode();
                    } else {
                      selectedTileId = null;
                    }
                  });
                },
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            width: circleSize,
            height: circleSize,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: targetOpacity,
              child: _EditButton(
                icon: Transform.rotate(
                  angle: pi / 4,
                  child: const Icon(Icons.arrow_forward),
                ),
                onPressed: () {
                  setState(() {
                    TileSize nextSize;
                    if (tile.currentSize == TileSize.medium) {
                      nextSize = TileSize.small;
                    } else if (tile.currentSize == TileSize.small) {
                      if (tile.app.wideTile != null) {
                        nextSize = TileSize.wide;
                      } else {
                        nextSize = TileSize.medium;
                      }
                    } else {
                      nextSize = TileSize.medium;
                    }

                    if (_baseLayoutSnapshot != null) {
                      tiles =
                          _baseLayoutSnapshot!.map((e) => e.clone()).toList();
                    } else {
                      _baseLayoutSnapshot =
                          tiles.map((e) => e.clone()).toList();
                    }

                    TileModel activeTile = tiles
                        .firstWhere((t) => t.instanceId == tile.instanceId);

                    activeTile.currentSize = nextSize;

                    activeTile.gridX = activeTile.gridX
                        .clamp(0, crossAxisCount - activeTile.widthCells);

                    draggingTileId = activeTile.instanceId;
                    originalItems = tiles.map((e) => e.clone()).toList();

                    _updatePreview(activeTile.gridX, activeTile.gridY);
                    _finalizeLayout();

                    draggingTileId = null;
                    originalItems = null;

                    // 🌟 调整大小可能会被挤到屏幕外围，强行追随保持可见
                    _ensureTileVisible(activeTile, cellSize);
                  });
                },
              ),
            ),
          ),
        ],
      ],
    );

    _syncAnimations();
    AnimationController? flipCtrl = _flipControllers[tile.instanceId];
    if (flipCtrl != null) {
      tileContent = AnimatedBuilder(
        animation: flipCtrl,
        builder: (context, child) {
          Animation<double>? currentAnim = _flipAnimations[tile.instanceId];
          return LeftEdgeRotateAnimation(
            rotation: currentAnim?.value ?? 0.0,
            child: child!,
          );
        },
        child: tileContent,
      );
    }

    return AnimatedPositioned(
      key: tile.key,
      duration: Duration(milliseconds: isActuallyDragging ? 0 : 300),
      curve: Curves.easeOutCubic,
      left: left + gridSpacing / 2 - expandOffset,
      top: top + gridSpacing / 2 - expandOffset,
      child: SizedBox(
        width: width + expandOffset * 2,
        height: height + expandOffset * 2,

        // 🌟 核心：换上我们新写的微交互控制器！
        child: TileInteractionAnimator(
          isEditMode: isEditMode,
          isSelected: isSelected,
          child: tileContent,
        ),
      ),
    );
  }
}

//动态磁贴大小预设
enum LiveTileSize { small, medium, wide }

//动态磁贴翻转方式
enum FlipStyle { normal, elastic }

//动态磁贴组件
// 这个组件会在内部自动循环显示提供的子组件列表
class LiveTile extends StatefulWidget {
  final List<Widget> children;
  final LiveTileSize size;
  final Widget? name;
  final FlipStyle flipStyle;
  final bool enableLiveTile;

  const LiveTile({
    super.key,
    required this.children,
    this.name,
    this.size = LiveTileSize.medium,
    this.flipStyle = FlipStyle.normal,
    this.enableLiveTile = true,
  });

  @override
  State<LiveTile> createState() => _LiveTileState();
}

class _LiveTileState extends State<LiveTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);

    _setupAnimation();
    // 🌟 2. 只有在开启状态且子组件大于 1 个时，才启动翻转定时器
    if (widget.enableLiveTile && widget.children.length > 1) {
      _startTimer();
    }
  }

  void _setupAnimation() {
    final curve = widget.flipStyle == FlipStyle.elastic
        ? Curves.elasticOut
        : Curves.easeInOut;

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: curve),
    );
  }

  void _startTimer() {
    _timer?.cancel();
    // 🌟 3. 在定时器内部做双重拦截保护
    if (!widget.enableLiveTile || widget.children.length <= 1) return;
    // 生成一个 3.0 到 6.0 之间的随机浮点数
    final double randomSeconds = 3.0 + math.Random().nextDouble() * 3.0;
    _timer =
        Timer(Duration(milliseconds: (randomSeconds * 1000).round()), _flip);
  }

  void _flip() async {
    if (!mounted) return;
    await _controller.forward();
    if (!mounted) return;
    setState(() {
      _currentIndex = (_currentIndex + 1) % widget.children.length;
    });
    _controller.reset();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LiveTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flipStyle != widget.flipStyle) {
      _setupAnimation();
    }

    // 🌟 核心修复 1：解决改变大小后出现黑屏空档期的问题
    // 如果磁贴的尺寸或者子页面的数量变了，立刻强制复位到第一页，并重启定时器
    if (oldWidget.size != widget.size ||
        oldWidget.children.length != widget.children.length) {
      _controller.reset();
      setState(() {
        _currentIndex = 0; // 强制画面切回第一页
      });
      if (widget.enableLiveTile && widget.children.length > 1) {
        _startTimer();
      } else {
        _timer?.cancel();
      }
    }
    // 🌟 4. 处理运行时动态切换开关状态 (比如你在代码里热重载改了 enableLiveTile)
    else if (oldWidget.enableLiveTile != widget.enableLiveTile) {
      if (widget.enableLiveTile && widget.children.length > 1) {
        _startTimer(); // 开启时恢复翻转
      } else {
        _timer?.cancel(); // 关闭时停止定时器
        if (_currentIndex != 0 || _controller.isAnimating) {
          _controller.reset();
          setState(() {
            _currentIndex = 0; // 强制将画面复位到第一个子组件
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 将变量重命名为标准画布尺寸，语义更清晰
    double standardWidth;
    double standardHeight;

    switch (widget.size) {
      case LiveTileSize.small:
        standardWidth = 159 * 0.625 * 0.8;
        standardHeight = 159 * 0.625 * 0.8;
        break;
      case LiveTileSize.medium:
        standardWidth = 336 * 0.625 * 0.8;
        standardHeight = 336 * 0.625 * 0.8;
        break;
      case LiveTileSize.wide:
        standardWidth = 691 * 0.625 * 0.8;
        standardHeight = 336 * 0.625 * 0.8;
        break;
    }

    // 最外层的 SizedBox 保留。当被放进 StartMenu (AnimatedPositioned) 时，
    // 它会被父级的紧约束强行拉伸/挤压到网格的真实大小。
    return SizedBox(
      width: standardWidth,
      height: standardHeight,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final double rotationValue = _animation.value * math.pi;
          final bool showBack = rotationValue > math.pi / 2;
          final int nextIndex = (_currentIndex + 1) % widget.children.length;

          return Stack(fit: StackFit.expand, children: [
            ...List.generate(widget.children.length, (index) {
              bool isVisibleFace = false;
              Matrix4 transform = Matrix4.identity();

              if (index == _currentIndex && !showBack) {
                isVisibleFace = true;
                transform.rotateX(rotationValue);
              } else if (index == nextIndex && showBack) {
                isVisibleFace = true;
                transform.rotateX(rotationValue);
                transform.rotateX(math.pi);
              }

              return Offstage(
                offstage: !isVisibleFace,
                child: Transform(
                  transform: transform,
                  alignment: Alignment.center,
                  child: Container(
                    color: Theme.of(context).colorScheme.primary,
                    child: Stack(
                      children: [
                        // 🌟 核心修改点：
                        // 给 children 包裹一层 FittedBox 和限定大小的 SizedBox
                        // 这样它们会以为自己画在一个标准尺寸的画布上，然后再等比缩放到真实大小
                        Positioned.fill(
                          child: FittedBox(
                            fit: BoxFit.contain, // 保证绝对不拉伸变形
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: standardWidth,
                              height: standardHeight,
                              child: widget.children[index],
                            ),
                          ),
                        ),

                        // 🌟 标题保持原样，置于 FittedBox 外部
                        // 这样它不会受到等比缩放的影响，字体大小永远是 16，左边距永远是 10
                        if (widget.name != null &&
                            widget.size != LiveTileSize.small)
                          Positioned(
                            left: 10,
                            bottom: 6,
                            child: DefaultTextStyle.merge(
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              child: widget.name!,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ]);
        },
      ),
    );
  }
}

//普通磁贴模板
class MetroAppTile extends StatefulWidget {
  final Widget icon;
  final int? count;
  final Color? backgroundColor;

  const MetroAppTile({
    super.key,
    required this.icon,
    this.count,
    this.backgroundColor,
  });

  @override
  State<MetroAppTile> createState() => _MetroAppTileState();
}

class _MetroAppTileState extends State<MetroAppTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  int? _displayCount;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    if (widget.count != null) {
      _displayCount = widget.count;
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(MetroAppTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count != oldWidget.count) {
      if (widget.count != null) {
        setState(() {
          _displayCount = widget.count;
        });
        _controller.reset();
        _controller.forward();
      } else {
        setState(() {
          _displayCount = null;
        });
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor ?? Theme.of(context).colorScheme.primary,
      child:
          // 图标与数字组合：居中
          Center(
        child: Row(
          //mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              child: widget.icon,
            ),
            if (_displayCount != null && _displayCount! > 0) ...[
              const SizedBox(width: 8),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..rotateX(_rotationAnimation.value * math.pi),
                    child: Text(
                      '$_displayCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
      // 标题：左下角
    );
  }
}

// --- 1. 浮动效果包装器保持不变 ---
class FloatingWrapper extends StatefulWidget {
  final bool isFloating;
  final Widget child;

  const FloatingWrapper(
      {super.key, required this.isFloating, required this.child});

  @override
  _FloatingWrapperState createState() => _FloatingWrapperState();
}

class _FloatingWrapperState extends State<FloatingWrapper> {
  double _dx = 0;
  double _dy = 0;
  int _durationMs = 300;
  Timer? _timer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    if (widget.isFloating) _startFloatingLoop();
  }

  @override
  void didUpdateWidget(FloatingWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFloating && !oldWidget.isFloating) {
      _startFloatingLoop();
    } else if (!widget.isFloating && oldWidget.isFloating) {
      _stopFloating();
    }
  }

  void _startFloatingLoop() {
    if (!widget.isFloating) return;
    setState(() {
      _dx = (_random.nextDouble() * 20) - 10;
      _dy = (_random.nextDouble() * 20) - 10;
      _durationMs = 1000 + _random.nextInt(1001);
    });
    _timer = Timer(Duration(milliseconds: _durationMs), _startFloatingLoop);
  }

  void _stopFloating() {
    _timer?.cancel();
    setState(() {
      _dx = 0;
      _dy = 0;
      _durationMs = 300;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: _durationMs),
      curve: Curves.easeInOutSine,
      transform: Matrix4.translationValues(_dx, _dy, 0),
      child: widget.child,
    );
  }
}

/// 磁贴专属微交互动画控制器
/// 负责处理：按下缓慢放大、弹性回落、非选中态缩小等复杂组合动画
/// 磁贴专属微交互动画控制器
/// 完美分离了【物理按压】与【状态变化】两条独立的动画流，互不干扰
class TileInteractionAnimator extends StatefulWidget {
  final bool isEditMode;
  final bool isSelected;
  final Widget child;

  const TileInteractionAnimator({
    super.key,
    required this.isEditMode,
    required this.isSelected,
    required this.child,
  });

  @override
  State<TileInteractionAnimator> createState() =>
      _TileInteractionAnimatorState();
}

class _TileInteractionAnimatorState extends State<TileInteractionAnimator>
    with TickerProviderStateMixin {
  // 控制流 1：物理按压
  late AnimationController _pressController;
  Timer? _pressTimer;

  // 控制流 2：系统状态
  late AnimationController _stateController;

  // ==========================================
  // 🎛️ 动画流 1：手指按下的缓慢放大 (独立受控)
  // ==========================================
  final double _pressTargetScale = 1.05; // 按下放大的目标大小
  final Duration _pressDelay = const Duration(milliseconds: 200); // 按下后多久开始放大
  final Duration _pressDuration = const Duration(milliseconds: 500); // 放大的持续时间
  final Curve _pressCurve = Curves.easeOutCubic; // 放大的曲线
  final Duration _releaseDuration = const Duration(milliseconds: 300); // 松手回缩的时间
  final Curve _releaseCurve = Curves.easeOutCubic; // 松手回缩的曲线

  // ==========================================
  // 🎛️ 动画流 2：选中时的弹性回落 (独立受控)
  // ==========================================
  final double _popScale = 1.2; // 🌟 瞬间放大的峰值 (改为了 1.2)
  final double _selectedScale = 1.1; // 🌟 新增：选中状态下的最终悬浮大小
  final double _unselectedScale = 0.9; // 编辑模式未选中时的缩小值

  final Duration _popDuration = const Duration(milliseconds: 50); // 冲向峰值的时间
  final Duration _bounceDuration = const Duration(milliseconds: 500); // 弹性回落的时间
  final Curve _bounceCurve = Curves.easeOutCubic; // 弹性回落的物理曲线
  // ==========================================

  @override
  void initState() {
    super.initState();

    // 负责 0.0 到 1.0 的按压进度
    _pressController = AnimationController(vsync: this);

    // 负责 0.0 到 2.0 的全局状态缩放
    _stateController = AnimationController(
      vsync: this,
      lowerBound: 0.0,
      upperBound: 2.0,
      // 🌟 初始化时，如果处于选中状态，直接赋予 1.1 的悬浮大小
      value: widget.isEditMode ? (widget.isSelected ? _selectedScale : _unselectedScale) : 1.0,
    );
  }

  @override
  void didUpdateWidget(TileInteractionAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ==========================================
    // 逻辑状态变更处理 (只操作 _stateController)
    // ==========================================
    if (!oldWidget.isEditMode && widget.isEditMode) {
      if (widget.isSelected) {
        _playPopBounce(); // 刚进入编辑模式的主磁贴：弹一下然后停在 1.1
      } else {
        _stateController.animateTo(_unselectedScale, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
      }
    } else if (oldWidget.isEditMode && !widget.isEditMode) {
      // 退出编辑模式，全部恢复到 1.0
      _stateController.animateTo(1.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
    } else if (widget.isEditMode && !oldWidget.isSelected && widget.isSelected) {
      // 在编辑模式下选中了该磁贴，触发弹跳并停在 1.1
      _playPopBounce();
    } else if (widget.isEditMode && oldWidget.isSelected && !widget.isSelected) {
      // 失去选中状态，缩小回 0.9
      _stateController.animateTo(_unselectedScale, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
    }
  }

  /// 播放组合拳：极速冲向 1.2 -> 弹性回落到 1.1
  void _playPopBounce() {
    _stateController.animateTo(_popScale, duration: _popDuration, curve: Curves.easeOut).then((_) {
      if (mounted) {
        // 🌟 核心修改：回落的终点不再是 1.0，而是 _selectedScale (1.1)
        _stateController.animateTo(_selectedScale, duration: _bounceDuration, curve: _bounceCurve);
      }
    });
  }

  // ==========================================
  // 物理触摸事件处理 (只操作 _pressController)
  // ==========================================
  void _handlePointerDown(PointerDownEvent event) {
    _pressTimer?.cancel();

    // 开启 200ms 倒计时，如果不松手，就开始执行 500ms 的缓慢放大
    _pressTimer = Timer(_pressDelay, () {
      _pressController.animateTo(1.0, duration: _pressDuration, curve: _pressCurve);
    });
  }

  void _handlePointerUpOrCancel(PointerEvent event) {
    // 手指松开，取消计时器（如果还没到 200ms 就不会触发放大）
    _pressTimer?.cancel();
    // 无论目前放大了多少，立刻平滑回缩
    _pressController.animateTo(0.0, duration: _releaseDuration, curve: _releaseCurve);
  }

  @override
  void dispose() {
    _pressTimer?.cancel();
    _pressController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUpOrCancel,
      onPointerCancel: _handlePointerUpOrCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pressController, _stateController]),
        builder: (context, child) {
          // 1. 算出按压带来的额外比例（进度 0~1 映射到 1.0~1.05）
          double pressScale = 1.0 + ((_pressTargetScale - 1.0) * _pressController.value);

          // 2. 算出逻辑状态带来的比例
          double stateScale = _stateController.value;

          // 3. 物理乘算叠加。互不干扰！
          double finalScale = pressScale * stateScale;

          return Transform.scale(
            scale: finalScale,
            alignment: Alignment.center,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _EditButton extends StatefulWidget {
  final Widget icon;
  final VoidCallback onPressed;

  const _EditButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  State<_EditButton> createState() => _EditButtonState();
}

class _EditButtonState extends State<_EditButton> {
  bool _isTouch = false;

  @override
  Widget build(BuildContext context) {
    final double circleSize = 48.125 * 0.8;
    return Semantics(
      button: true,
      child: Tile(
        onTap: widget.onPressed,
        onTouch: (isTouch) {
          setState(() {
            _isTouch = isTouch;
          });
        },
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isTouch
                    ? Theme.of(context).colorScheme.primary
                    : Colors.black, // 黑色底，防止透明导致透出磁贴内容
                border: Border.all(
                  color: Colors.white,
                  width: 5 * 0.625 * 0.8,
                ),
              ),
              alignment: Alignment.center,
              child: IconTheme(
                data: const IconThemeData(
                  color: Colors.white,
                  size: 24,
                ),
                child: widget.icon,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
