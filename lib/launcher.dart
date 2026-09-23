import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:metro_ui/metro_page_push.dart';
import 'package:metro_ui/page.dart';
import 'package:metro_ui/page_scaffold.dart';
import 'package:metro_ui/widgets/context_menu.dart';
import 'package:metro_ui/widgets/metro_circle_button.dart';
import 'package:metro_ui/widgets/tile.dart';
import 'package:windows_phone_simulator/app_registry.dart';
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

  final GlobalKey<MetroPageScaffoldState> _scaffoldKey =
      GlobalKey<MetroPageScaffoldState>();

  /// 控制左右两个页面（开始屏幕 / 应用列表）水平切换的滚动控制器。
  final ScrollController _pageController = ScrollController();

  /// 箭头旋转动画控制器：value 0 → 箭头指向右（第一页），
  /// value 1 → 箭头指向左（第二页，已逆时针转过 180°）。
  late final AnimationController _arrowController;

  /// 箭头旋转圈数：0 → 0 圈，1 → -0.5 圈（逆时针 180°）。
  late final Animation<double> _arrowTurns;

  late List<TileModel> _pinnedTiles;

  /// 所有已注册的应用（来自 [AppRegistry]）
  List<App> get apps => AppRegistry().apps;

  /// 注册内置应用（天气、关于等）
  /// 应用可以在自己的文件中通过 [AppRegistry().register()] 自注册，
  /// 无需修改此文件。
  void _registerBuiltinApps() {
    // AppRegistry()
    //   ..register(App(
    //     id: 'com.ms.about',
    //     name: '关于',
    //     themeColor: Colors.blue,
    //     icon: const Icon(Icons.info),
    //     page: const AboutPage(),
    //     smallTile: const LiveTile(
    //         size: LiveTileSize.small,
    //         flipStyle: FlipStyle.elastic,
    //         children: [
    //           MetroAppTile(
    //               icon: Icon(Icons.wb_sunny, color: Colors.white, size: 24)),
    //         ]),
    //     mediumTile: const LiveTile(
    //       size: LiveTileSize.medium,
    //       flipStyle: FlipStyle.elastic,
    //       name: Text('关于'),
    //       children: [
    //         MetroAppTile(
    //           icon: Icon(
    //             Icons.map,
    //             size: 70,
    //           ),
    //           count: 2,
    //         ),
    //         Padding(
    //           padding: EdgeInsets.all(10),
    //           child: Text(
    //             '关于页面',
    //             style: TextStyle(fontSize: 18),
    //           ),
    //         ),
    //       ],
    //     ),
    //   ));
  }

  @override
  void initState() {
    super.initState();

    // 箭头旋转动画：正向播放 = 0 → -0.5 圈（逆时针 180°，去第二页），
    // 反向播放 = -0.5 → 0 圈（顺时针 180°，回第一页）
    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _arrowTurns = Tween<double>(begin: 0, end: -0.5).animate(
      CurvedAnimation(
        parent: _arrowController,
        curve: Curves.easeInOutCubic,
      ),
    );

    // 注册内置应用
    _registerBuiltinApps();

    // Phone 已在 main.dart 中注册，这里直接按 id 取（铁定存在，不做判空）
    final App phoneApp =
        AppRegistry().apps.firstWhere((app) => app.id == 'com.ms.phone');
    _pinnedTiles = [
      TileModel(
        instanceId: '${phoneApp.id}_1',
        app: phoneApp,
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

  /// 在左右两个页面（开始屏幕 ↔ 应用列表）之间切换。
  ///
  /// 通过外层水平 [SingleChildScrollView] 的 [ScrollController] 滚动到对应偏移：
  /// 第一页偏移 0，第二页偏移为 [screenWidth] - 60（第一页的宽度）。
  /// 滚动结束后会由 [LauncherSnapPhysics] 吸附到最近的 snap 点。
  void _togglePages(double screenWidth) {
    if (!_pageController.hasClients) return;
    final double secondPageOffset = screenWidth - 60;
    final bool isOnFirstPage = _pageController.offset < secondPageOffset / 2;
    _pageController.animateTo(
      isOnFirstPage ? secondPageOffset : 0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
    // 箭头特效：点击是“切换”，朝目标页方向旋转——
    // 当前在第一页 → 目标第二页 → 逆时针转 180°（指向左）；
    // 当前在第二页 → 目标第一页 → 顺时针转回（指向右）。
    _syncArrowWithPage(!isOnFirstPage);
  }

  /// 根据箭头应指向的目标页同步旋转状态：
  /// 目标为第一页 → 指向右（controller value 0）；
  /// 目标为第二页 → 指向左（value 1，逆时针转过 180°）。
  /// 供点击按钮（传入目标页）与滑动换页（onTargetCalculated 传入
  /// 吸附目标所在页）两条路径共用。
  void _syncArrowWithPage(bool targetIsFirstPage) {
    if (targetIsFirstPage) {
      _arrowController.reverse();
    } else {
      _arrowController.forward();
    }
  }

  /// 滚动通知兜底（参考 MetroPanorama）：正常情况下松手瞬间已由
  /// LauncherSnapPhysics.onTargetCalculated 同步箭头（主路径）；
  /// 这里仅覆盖「松手时恰好停在吸附点上、未产生归位动画」的边界情况，
  /// 此时按最终位置再同步一次，结果与当前状态一致，箭头不会空转。
  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification) {
      _syncArrowWithPage(notification.metrics.pixels < 0.01);
    }
    return false;
  }

  @override
  void dispose() {
    _arrowController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MetroPageScaffold(
      key: _scaffoldKey,
      enableZAxisEffect: true,
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
      disableDefaultPushAnimation: true,
      disableDefaultPopAnimation: true,
      disableDefaultPopNextAnimation: true,
      disableDefaultPushNextAnimation: true,
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
              child: NotificationListener<ScrollNotification>(
                // 参考 Panorama：滑动换页后同步箭头指向（只感知、不消费通知）
                onNotification: _onScrollNotification,
                child: SingleChildScrollView(
                  controller: _pageController,
                  clipBehavior: Clip.none,
                  scrollDirection: Axis.horizontal,
                  physics: _isEditMode
                      ? const NeverScrollableScrollPhysics()
                      : LauncherSnapPhysics(
                          snapOffsets: [0, screenWidth - 60],
                          //snapOffsets: [0, screenWidth],
                          parent: const ClampingScrollPhysics(), // 禁用边界回弹
                          // 松手瞬间感知即将换页：目标落在第二页范围 → 箭头逆时针转 180°，
                          // 回到第一页 → 顺时针转回（参考 MetroPanorama.onTargetCalculated）
                          onTargetCalculated: (target) {
                            _syncArrowWithPage(
                              target < (screenWidth - 60) / 2,
                            );
                          },
                        ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: screenWidth - 60,
                        //width: screenWidth,
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
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                      width: 60,
                                      child: Column(
                                        children: [
                                          const SizedBox(height: 80),
                                          MetroCircleButton(
                                            icon: RotationTransition(
                                              turns: _arrowTurns,
                                              child: Icon(
                                                Icons.arrow_forward,
                                                color: Colors.white,
                                              ),
                                            ),
                                            onPressed: () {
                                              // 在左右两个页面（开始屏幕 ↔ 应用列表）之间切换
                                              _togglePages(screenWidth);
                                            },
                                          ),
                                          const SizedBox(height: 15),
                                          MetroCircleButton(
                                            icon: Icon(
                                              Icons.search_rounded,
                                              color: Colors.white,
                                            ),
                                            onPressed: () {},
                                          ),
                                        ],
                                      )),
                                  Expanded(
                                    child: Container(
                                      //color: Colors.transparent,
                                      padding: const EdgeInsets.only(
                                          top: 40, left: 20),
                                      child: ListView.builder(
                                        itemCount: apps.length,
                                        itemBuilder: (context, index) {
                                          final app = apps[index];
                                          final GlobalKey<MetroContextMenuState>
                                              menuKey = GlobalKey<
                                                  MetroContextMenuState>();
                                          return MetroContextMenu(
                                            key: menuKey,
                                            menu: MetroContextMenuItem(
                                              child: const Text('pin to start'),
                                              onTap: () {
                                                // 关闭上下文菜单
                                                menuKey.currentState
                                                    ?.dismissMenu();

                                                // 外层不参与磁贴排版，直接把 App 丢给 StartMenu 内部处理！
                                                _startMenuKey.currentState
                                                    ?.pinApp(app);
                                              },
                                            ),
                                            child: Tile(
                                              onTap: () {
                                                metroPagePush(context,
                                                    MetroPageRoute(
                                                  builder: (context) {
                                                    return app.page;
                                                  },
                                                ), scaffoldKey: _scaffoldKey
                                                    //提供一种便利的方法，可以将范型参数传递给onDidPushNext，主要设计目的是为了方便动画传参
                                                    //例如：Windows Phone中，被点击的Tile往往是最后一个飞出的，可能需要把Tile的index传递过去，然后在onDidPushNext中处理动画
                                                    //dataToPass: index,
                                                    );
                                              },
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                child: Row(
                                                  children: [
                                                    // 应用图标块
                                                    // 注意：Container 的 48×48 是紧约束，会强制拉伸
                                                    // child 填满（SvgPicture 的 height 会被覆盖）。
                                                    // 用 Align 提供宽松约束，让图标保持自身尺寸居中。
                                                    Container(
                                                      width: 48,
                                                      height: 48,
                                                      color: app.themeColor ??
                                                          Theme.of(context)
                                                              .primaryColor,
                                                      child: Align(
                                                        alignment:
                                                            Alignment.center,
                                                        child: app.icon,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    // 应用名称
                                                    Expanded(
                                                      child: Text(
                                                        app.name,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 24),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              )),
                        ),
                      ),
                    ],
                  ),
                ),
              ));
        },
      ),
    );
  }
}

class LauncherSnapPhysics extends ScrollPhysics {
  final List<double> snapOffsets;

  /// 归位目标确定（手指松手瞬间）时回调，参数为即将吸附的目标偏移。
  /// 参考 [MetroPanorama] 的 PanoramaScrollPhysics.onTargetCalculated。
  final void Function(double target)? onTargetCalculated;

  const LauncherSnapPhysics({
    required this.snapOffsets,
    this.onTargetCalculated,
    super.parent,
  });

  @override
  LauncherSnapPhysics applyTo(ScrollPhysics? ancestor) {
    return LauncherSnapPhysics(
      snapOffsets: snapOffsets,
      onTargetCalculated: onTargetCalculated,
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
      // 松手瞬间立即通知即将吸附的目标，由外部同步箭头旋转
      // （与 MetroPanorama 的 onTargetCalculated 时机一致，不等动画结束）
      onTargetCalculated?.call(target);
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
