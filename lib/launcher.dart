import 'dart:async';
import 'dart:math' as math;
import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:metro_ui/animations.dart';
import 'package:metro_ui/metro_page_push.dart';
import 'package:metro_ui/page.dart';
import 'package:metro_ui/page_scaffold.dart';
import 'package:metro_ui/widgets/context_menu.dart';
import 'package:metro_ui/widgets/tile.dart';
import 'package:windows_phone_simulator/splashscreen_page.dart';

class LauncherPage extends StatefulWidget {
  const LauncherPage({super.key, required this.title});

  final String title;

  @override
  State<LauncherPage> createState() => _LauncherPageState();
}

class _LauncherPageState extends State<LauncherPage>
    with TickerProviderStateMixin {
  final List<GlobalKey> _keys = [];

  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  late List<bool> _tileVisibility; // 控制每个 tile 的可见性

  bool _isEditMode = false; // 是否处于编辑模式
  final GlobalKey<_StartMenuState> _startMenuKey = GlobalKey<_StartMenuState>();

  final int pushTime = 350; //非被点击的Tile总飞出时间
  final int singleTileTime = 150; //单个Tile飞出时间

  late List<TileModel> _pinnedTiles;

  List<App> get apps => [
        App(
          id: 'com.ms.weather',
          name: '天气',
          themeColor: Colors.blue,
          icon: const Icon(Icons.wb_sunny),
          page: const Splashscreen(),
          smallTile: const MetroAppTile(
            icon: Icon(Icons.wb_sunny, color: Colors.white, size: 24),
            count: 2,
          ),
          mediumTile: LiveTile(
            size: LiveTileSize.medium,
            flipStyle: FlipStyle.elastic,
            name: const Text('Panorama'),
            children: [
              MetroAppTile(
                icon: const Icon(
                  Icons.map,
                  size: 70,
                ),
                count: 2,
              ),
              const Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  'Panorama Hub页面，具有浓郁的WP特色',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          wideTile: LiveTile(
              size: LiveTileSize.wide,
              flipStyle: FlipStyle.elastic,
              name: const Text('Panorama'),
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
          id: 'com.ms.weather2',
          name: '天气2',
          themeColor: Colors.blue,
          icon: const Icon(Icons.wb_sunny),
          page: const Splashscreen(),
          smallTile: const MetroAppTile(
              icon: Icon(Icons.wb_sunny, color: Colors.white, size: 24)),
          mediumTile: LiveTile(
            size: LiveTileSize.medium,
            flipStyle: FlipStyle.elastic,
            name: const Text('Panorama2'),
            children: [
              MetroAppTile(
                icon: const Icon(
                  Icons.map,
                  size: 70,
                ),
                count: 2,
              ),
              const Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  'Panorama Hub页面，具有浓郁的WP特色',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          wideTile: const Row(
            // 宽磁贴可以放更多信息
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Icon(Icons.wb_sunny, color: Colors.white, size: 40),
              Text('新北市板桥区\n晴天 24°C', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ];

  @override
  void initState() {
    super.initState();
    //打印设备屏幕宽度

    _keys.addAll(List.generate(apps.length, (index) => GlobalKey()));

    _tileVisibility =
        List.generate(apps.length, (index) => false); // 初始化所有 tile 为可见

    _controllers = List.generate(apps.length, (index) {
      return AnimationController(
        vsync: this,
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 0.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.linear,
      ));
    }).toList();

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
  bool _isWidgetVisible(GlobalKey key) {
    //return true;
    final RenderBox? renderBox =
        key.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) return false;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenSize = MediaQuery.of(context).size;

    return position.dx + size.width > 0 &&
        position.dx < screenSize.width &&
        position.dy + size.height > 0 &&
        position.dy < screenSize.height;
  }

  Future<void> _startPushNextAnimations(GlobalKey tapKey) async {
    // 找出所有可见的元素索引
    final List<int> visibleIndices = [];
    for (int i = 0; i < apps.length; i++) {
      if (_isWidgetVisible(_keys[i])) {
        visibleIndices.add(i);
      }
    }

    setState(() {
      _controllers = List.generate(apps.length, (index) {
        // 只为可见元素创建真正的控制器
        if (visibleIndices.contains(index)) {
          return AnimationController(
            duration: Duration(milliseconds: singleTileTime),
            vsync: this,
          );
        } else {
          // 不可见元素创建空控制器
          return AnimationController(vsync: this);
        }
      });

      _animations = _controllers.asMap().entries.map((entry) {
        int index = entry.key;
        AnimationController controller = entry.value;

        // 只为可见元素创建真正的动画
        if (visibleIndices.contains(index)) {
          return Tween<double>(
            begin: 0.0,
            end: 3.1416 / 2,
          ).animate(CurvedAnimation(
            parent: controller,
            curve: MetroCurves.normalPageRotateOut,
          ));
        } else {
          // 不可见元素创建空动画
          return Tween<double>(
            begin: 0.0,
            end: 0.0,
          ).animate(CurvedAnimation(
            parent: controller,
            curve: Curves.linear,
          ));
        }
      }).toList();
    });

    int thisIndex = 0;
    final int visibleTilesCount = visibleIndices.length;

    // 计算每个元素之间的延迟时间
    final int delayTime =
        ((pushTime - singleTileTime) / (visibleTilesCount - 1)).round();

    // 执行动画（只对可见元素）
    for (int i = apps.length - 1; i >= 0; i--) {
      if (visibleIndices.contains(i)) {
        if (_keys[i] == tapKey) {
          thisIndex = i;
          continue;
        }
        _controllers[i].forward();
        await Future.delayed(Duration(milliseconds: delayTime));
      }
    }

    await Future.delayed(Duration(milliseconds: delayTime * 2));
    _controllers[thisIndex].forward();

    //结束await后执行动画重置
    await Future.delayed(Duration(milliseconds: singleTileTime));
    for (var controller in _controllers) {
      controller.reset();
      //透明度设置为0
      setState(() {
        _tileVisibility = List.generate(apps.length, (index) => false);
      });
    }
  }

  Future<void> _startPushAnimations() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 找出所有可见的元素索引
      final List<int> visibleIndices = [];
      for (int i = 0; i < apps.length; i++) {
        if (_isWidgetVisible(_keys[i])) {
          visibleIndices.add(i);
        } else {
          _tileVisibility[i] = true;
        }
      }

      setState(() {
        for (int i in visibleIndices) {
          _tileVisibility[i] = false;
        }
        _controllers = List.generate(apps.length, (index) {
          // 只为可见元素创建真正的控制器
          if (visibleIndices.contains(index)) {
            return AnimationController(
              duration: Duration(milliseconds: singleTileTime * 3),
              vsync: this,
            );
          } else {
            // 不可见元素创建空控制器
            return AnimationController(vsync: this);
          }
        });

        _animations = _controllers.asMap().entries.map((entry) {
          int index = entry.key;
          AnimationController controller = entry.value;

          // 只为可见元素创建真正的动画
          if (visibleIndices.contains(index)) {
            return Tween<double>(
              begin: -3.1416 / 180 * 65,
              end: 0,
            ).animate(CurvedAnimation(
              parent: controller,
              curve: MetroCurves.normalPageRotateIn,
            ));
          } else {
            // 不可见元素创建空动画
            return Tween<double>(
              begin: 0.0,
              end: 0.0,
            ).animate(CurvedAnimation(
              parent: controller,
              curve: MetroCurves.normalPageRotateIn,
            ));
          }
        }).toList();
      });

      final int visibleTilesCount = visibleIndices.length;

      // 计算每个元素之间的延迟时间
      final int delayTime =
          ((pushTime - singleTileTime) / (visibleTilesCount - 1)).round();

      // 执行动画（只对可见元素）
      for (int i = apps.length - 1; i >= 0; i--) {
        if (visibleIndices.contains(i)) {
          setState(() {
            _tileVisibility[i] = true; // 动画开始前直接显示
          });
          _controllers[i].forward();
          await Future.delayed(Duration(milliseconds: delayTime));
        }
      }
    });
  }

  Future<void> _startPopNextAnimations() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 找出所有可见的元素索引
      final List<int> visibleIndices = [];
      for (int i = 0; i < apps.length; i++) {
        if (_isWidgetVisible(_keys[i])) {
          visibleIndices.add(i);
        } else {
          _tileVisibility[i] = true;
        }
      }

      setState(() {
        for (int i in visibleIndices) {
          _tileVisibility[i] = false;
        }
        _controllers = List.generate(apps.length, (index) {
          // 只为可见元素创建真正的控制器
          if (visibleIndices.contains(index)) {
            return AnimationController(
              duration: Duration(milliseconds: singleTileTime * 3),
              vsync: this,
            );
          } else {
            // 不可见元素创建空控制器
            return AnimationController(vsync: this);
          }
        });

        _animations = _controllers.asMap().entries.map((entry) {
          int index = entry.key;
          AnimationController controller = entry.value;

          // 只为可见元素创建真正的动画
          if (visibleIndices.contains(index)) {
            return Tween<double>(
              begin: 3.1416 / 180 * 50,
              end: 0,
            ).animate(CurvedAnimation(
              parent: controller,
              curve: MetroCurves.normalPageRotateIn,
            ));
          } else {
            // 不可见元素创建空动画
            return Tween<double>(
              begin: 0.0,
              end: 0.0,
            ).animate(CurvedAnimation(
              parent: controller,
              curve: MetroCurves.normalPageRotateIn,
            ));
          }
        }).toList();
      });

      final int visibleTilesCount = visibleIndices.length;

      // 计算每个元素之间的延迟时间
      final int delayTime =
          ((pushTime - singleTileTime) / visibleTilesCount).round();

      // 执行动画（只对可见元素）
      for (int i = apps.length - 1; i >= 0; i--) {
        if (visibleIndices.contains(i)) {
          setState(() {
            _tileVisibility[i] = true; // 动画开始前直接显示
          });
          _controllers[i].forward();
          await Future.delayed(Duration(milliseconds: delayTime));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MetroPageScaffold(
      onDidPushNext: <T>(T data) async {
        //如果arguments存在arguments是int类型
        if (data is int) {
          await _startPushNextAnimations(_keys[data]);
        }
      },
      onDidPush: () async {
        await _startPushAnimations();
      },
      onDidPopNext: () async {
        //print("object");
        await _startPopNextAnimations();
      },
      onDidPop: () async {
        print("object2");
        //await _startPushAnimations();
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
                                      //关闭上下文菜单然后回到第一页
                                      menuKey.currentState?.dismissMenu();
                                      setState(() {
                                        _pinnedTiles.add(TileModel(
                                          instanceId:
                                              '${app.id}_${DateTime.now().millisecondsSinceEpoch}',
                                          app: app,
                                          currentSize: TileSize.medium,
                                          gridX:
                                              0, // In reality, we should find an empty spot
                                          gridY: _pinnedTiles.lastOrNull != null
                                              ? _pinnedTiles.last.gridY + 2
                                              : 0,
                                        ));
                                      });
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

class MetroEditState extends InheritedWidget {
  final bool isEditMode;
  final bool isSelected;
  final bool isActuallyDragging;

  const MetroEditState({
    super.key,
    required this.isEditMode,
    required this.isSelected,
    required this.isActuallyDragging,
    required super.child,
  });

  double get targetOpacity =>
      isEditMode ? (isSelected ? (isActuallyDragging ? 0.8 : 1.0) : 0.5) : 1.0;

  bool get isFloating => isEditMode && !isSelected;

  static MetroEditState? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MetroEditState>();
  }

  @override
  bool updateShouldNotify(MetroEditState oldWidget) {
    return isEditMode != oldWidget.isEditMode ||
        isSelected != oldWidget.isSelected ||
        isActuallyDragging != oldWidget.isActuallyDragging;
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

class _StartMenuState extends State<StartMenu> {
  final int crossAxisCount = 4;
  final double gridSpacing = 10.0;

  late List<TileModel> tiles;

  @override
  void initState() {
    super.initState();
    tiles = List.from(widget.initialTiles);
  }

  @override
  void didUpdateWidget(StartMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Find new tiles added in initialTiles
    for (var newTile in widget.initialTiles) {
      if (!tiles.any((t) => t.instanceId == newTile.instanceId)) {
        setState(() {
          tiles.add(newTile);
        });
      }
    }
  }

  // --- UI状态 ---
  bool isEditMode = false;
  String? selectedTileId;
  String? draggingTileId;
  String? _resizingTileId; //用于记录正在调整大小的磁贴
  Offset? initialDragOffset;
  Offset? initialTouchPosition;
  bool hasMetDragThreshold = false;

  // --- 引擎状态 ---
  List<TileModel>? originalItems;
  List<TileModel>? _baseLayoutSnapshot; // 记住进入编辑状态时的初始布局快照
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

  // --- 🌟 完美移植：网格碰撞推挤引擎 ---
  void _updatePreview(int targetX, int targetY) {
    if (originalItems == null || draggingTileId == null) return;

// --- 🌟 核心修复 1：在覆盖前，先提取当前拖拽砖块的实时像素坐标 ---
    Offset? currentPixelOffset;
    try {
      currentPixelOffset = tiles
          .firstWhere((e) => e.instanceId == draggingTileId)
          .dragPixelOffset;
    } catch (e) {}
    // -------------------------------------------------------------

    List<TileModel> nextLayout = originalItems!.map((e) => e.clone()).toList();
    TileModel targetItem =
        nextLayout.firstWhere((e) => e.instanceId == draggingTileId);

    targetItem.gridX = targetX;
    targetItem.gridY = targetY;

    // --- 🌟 核心修复 2：将实时坐标强行注入给新的克隆体，防止丢失 ---
    targetItem.dragPixelOffset = currentPixelOffset;
    // -------------------------------------------------------------

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
  void _onDragStart(
      TileModel tile, Offset touchPosition, double left, double top) {
    setState(() {
      if (!isEditMode) {
        if (widget.onEditModeChanged != null) {
          widget.onEditModeChanged!(true);
        }
      }
      isEditMode = true;

      // 如果选中了不同的磁贴，马上拍一张布局快照
      if (selectedTileId != tile.instanceId) {
        _baseLayoutSnapshot = tiles.map((e) => e.clone()).toList();
      }

      selectedTileId = tile.instanceId;
      draggingTileId = tile.instanceId;
      initialDragOffset = Offset(left, top);
      initialTouchPosition = touchPosition;
      hasMetDragThreshold = false;
      tile.dragPixelOffset = initialDragOffset;

      // 🌟 保存布局快照
      originalItems = tiles.map((e) => e.clone()).toList();
    });
  }

  void _onDragUpdate(
      TileModel tile, Offset currentTouchPosition, double cellSize) {
    if (draggingTileId == tile.instanceId &&
        initialTouchPosition != null &&
        initialDragOffset != null) {
      final distance = (currentTouchPosition - initialTouchPosition!).distance;

      setState(() {
        //拖拽距离达到一定程度才允许图标拖拽
        if (!hasMetDragThreshold && distance > 70.0) {
          hasMetDragThreshold = true;
        }
        if (hasMetDragThreshold) {
          // 更新物理像素用于渲染
          tile.dragPixelOffset = initialDragOffset! +
              (currentTouchPosition - initialTouchPosition!);

          // 🌟 结合你的基于中心点的平滑吸附计算
          int newGridX = (tile.dragPixelOffset!.dx / cellSize).round();
          int newGridY = (tile.dragPixelOffset!.dy / cellSize).round();

          newGridX = newGridX.clamp(0, crossAxisCount - tile.widthCells);
          newGridY = newGridY >= 0 ? newGridY : 0;

          // 🌟 Hover防抖判断
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

        // 强制最后执行一次确保落地位置正确
        _updatePreview(finalX, finalY);
        _finalizeLayout();
        // 拖拽落地后，布局发生了实质性改变，更新快照！
        _baseLayoutSnapshot = tiles.map((e) => e.clone()).toList();
      } else {
        // 如果没有突破死区，恢复快照
        if (originalItems != null) {
          tiles = originalItems!;
        }
      }

      // 清理引擎状态
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
        child: Container(
          //color: Colors.yellow,
          width: double.infinity,
          height: double.infinity,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double cellSize = constraints.maxWidth / crossAxisCount;

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

              return Stack(
                clipBehavior: Clip.none,
                children: normalTiles,
              );
            },
          ),
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

    // 移除单体缩降逻辑，交由外部画布统一缩小
    double targetScale = 1.0;
    if (isEditMode) {
      // 补偿由于外部画布整体 0.9 缩小带来的影响，使选中图块在视觉上更为凸显
      targetScale = isSelected ? 1 : 0.9;
    }

    // 非拖拽状态下使用计算出的物理像素
    final double targetLeft = tile.gridX * cellSize;
    final double targetTop = tile.gridY * cellSize;

    // 拖拽时使用真实像素
    final double left = isActuallyDragging && tile.dragPixelOffset != null
        ? tile.dragPixelOffset!.dx
        : targetLeft;
    final double top = isActuallyDragging && tile.dragPixelOffset != null
        ? tile.dragPixelOffset!.dy
        : targetTop;
    final double width = tile.widthCells * cellSize - gridSpacing;
    final double height = tile.heightCells * cellSize - gridSpacing;

    // 为溢出边界的圆形按钮专门外扩布局空间，打破 Flutter 严格的 hitTest bounds 限制
    final double circleSize = 48.125 * 0.8;
    final double expandOffset = circleSize / 2;

    // 主要的拖拽手势和磁贴本身
    Widget tileGestureContent = GestureDetector(
      onTap: () {
        if (isEditMode && selectedTileId != tile.instanceId) {
          setState(() {
            selectedTileId = tile.instanceId;
            // 切换选中的磁贴时，记录当前稳定布局作为快照
            _baseLayoutSnapshot = tiles.map((e) => e.clone()).toList();
          });
        }
      },
      onLongPressStart: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        _onDragStart(tile, box.globalToLocal(details.globalPosition),
            targetLeft, targetTop);
      },
      onLongPressMoveUpdate: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        _onDragUpdate(
            tile, box.globalToLocal(details.globalPosition), cellSize);
      },
      onLongPressEnd: (details) => _onDragEnd(tile, cellSize),
      onPanStart: (isEditMode && isSelected)
          ? (details) {
              final RenderBox box = context.findRenderObject() as RenderBox;
              _onDragStart(tile, box.globalToLocal(details.globalPosition),
                  targetLeft, targetTop);
            }
          : null,
      onPanUpdate: (isEditMode && isSelected)
          ? (details) {
              final RenderBox box = context.findRenderObject() as RenderBox;
              _onDragUpdate(
                  tile, box.globalToLocal(details.globalPosition), cellSize);
            }
          : null,
      onPanEnd: (isEditMode && isSelected)
          ? (details) => _onDragEnd(tile, cellSize)
          : null,
      child: AbsorbPointer(
        absorbing: isEditMode,
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
            );
          },
        ),
      ),
    );

    Widget tileContent = Stack(
      clipBehavior: Clip.none,
      children: [
        // 把原本的瓷贴放到扩充中心位置
        Positioned(
          left: expandOffset,
          top: expandOffset,
          right: expandOffset,
          bottom: expandOffset,
          child: MetroEditState(
            isEditMode: isEditMode,
            isSelected: isSelected,
            isActuallyDragging: isActuallyDragging,
            child: tileGestureContent,
          ),
        ),
        if (isEditMode && isSelected && !isActuallyDragging) ...[
          // Top right: unpin
          Positioned(
            top: 0,
            right: 0,
            width: circleSize,
            height: circleSize,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: targetOpacity,
              child: _EditButton(
                icon: const Icon(Icons.push_pin_outlined), // 移除pin图标
                onPressed: () {
                  setState(() {
                    tiles.removeWhere((t) => t.instanceId == tile.instanceId);
                    _finalizeLayout();

                    // 移除磁贴后布局永久改变，更新快照
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
          // Bottom right: resize
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
                  child: const Icon(Icons.arrow_forward), // 调整大小箭头
                ),
                onPressed: () {
                  setState(() {
                    // 1. 标记当前磁贴正在调整大小关闭过渡动画
                    _resizingTileId = tile.instanceId;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _resizingTileId = null;
                        });
                      }
                    });

                    // 🌟 核心修复：先根据【当前屏幕上真实的尺寸】计算出下一步该变多大
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

                    // 🌟 核心：恢复初始布局快照 (清空之前所有的挤压变形)
                    if (_baseLayoutSnapshot != null) {
                      tiles =
                          _baseLayoutSnapshot!.map((e) => e.clone()).toList();
                    } else {
                      _baseLayoutSnapshot =
                          tiles.map((e) => e.clone()).toList();
                    }

                    // 3. 获取恢复后列表中的“真身”
                    TileModel activeTile = tiles
                        .firstWhere((t) => t.instanceId == tile.instanceId);

                    // 🌟 4. 把刚刚算好的下一步尺寸，强行赋予给快照中的真身
                    activeTile.currentSize = nextSize;

                    // 5. 边界夹逼：防止变宽后掉出右侧边界，强制往左靠拢
                    activeTile.gridX = activeTile.gridX
                        .clamp(0, crossAxisCount - activeTile.widthCells);

                    // 6. 推演排版：让引擎以为这是拖拽过来的，智能挤开其他磁贴
                    draggingTileId = activeTile.instanceId;
                    originalItems = tiles
                        .map((e) => e.clone())
                        .toList(); // 以当前恢复+变形后的状态作为推演基础

                    _updatePreview(activeTile.gridX, activeTile.gridY);
                    _finalizeLayout();

                    draggingTileId = null;
                    originalItems = null;
                  });
                },
              ),
            ),
          ),
        ],
      ],
    );

// 判断当前磁贴是否正在被调整大小
    final bool isResizing = tile.instanceId == _resizingTileId;

    // 🌟 核心：使用 AnimatedPositioned 实现布局改变时的自动顺滑挤推
    return AnimatedPositioned(
      key: tile.key,
      // 只有手指拖拽时立刻响应(0ms)。其他的任何坐标改变（包括自己变大时的防越界左移，以及被别人推开）都恢复为 300ms 平滑过渡
      duration: Duration(milliseconds: isActuallyDragging ? 0 : 300),
      curve: Curves.easeOutCubic,
      // 动画仅掌管左上角坐标
      left: left + gridSpacing / 2 - expandOffset,
      top: top + gridSpacing / 2 - expandOffset,

      // 🚨 注意：我们去掉了这里的 width 和 height，让 AnimatedPositioned 自动包裹子组件。
      // 将宽高的职责交给内部的 SizedBox，SizedBox 没有补间动画，因此形变会【瞬间】完成！
      child: SizedBox(
        width: width + expandOffset * 2,
        height: height + expandOffset * 2,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: targetScale,
          curve: Curves.easeOutCubic,
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

  const LiveTile({
    super.key,
    required this.children,
    this.name,
    this.size = LiveTileSize.medium,
    this.flipStyle = FlipStyle.normal,
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
    _startTimer();
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
  }

  @override
  Widget build(BuildContext context) {
    double width;
    double height;

    switch (widget.size) {
      case LiveTileSize.small:
        width = 80;
        height = 80;
        break;
      case LiveTileSize.medium:
        width = 168;
        height = 168;
        break;
      case LiveTileSize.wide:
        width = 345.6; // 168 * 2 + 9.6
        height = 168;
        break;
    }

    final editState = MetroEditState.of(context);
    final opacity = editState?.targetOpacity ?? 1.0;
    final isFloating = editState?.isFloating ?? false;

    return FloatingWrapper(
      isFloating: isFloating,
      child: SizedBox(
        width: width,
        height: height,
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
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: opacity,
                      child: Container(
                        color: Theme.of(context).colorScheme.primary,
                        child: Stack(
                          children: [
                            widget.children[index],
                            if (widget.name != null)
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
                  ),
                );
              }),
            ]);
          },
        ),
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
