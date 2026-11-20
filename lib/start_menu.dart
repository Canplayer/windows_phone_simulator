import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:metro_ui/animations.dart';
import 'package:metro_ui/uix_metrics.dart';
import 'package:metro_ui/uix_typography.dart';
import 'package:metro_ui/widgets/tile.dart';
import 'package:windows_phone_simulator/global_perspective.dart';
import 'package:metro_ui/widgets/uix_text.dart';

import 'start_menu_motion.dart';

const startAssets = 'images/wp8_start';
const _gridCell = 99 * uixScale;
const _gridGap = 12 * uixScale;
const _gridWidth =
    StartMenu.columns * _gridCell + (StartMenu.columns - 1) * _gridGap;
const _gridTop = 95 * uixScale;
const _adornerExtent = 45 * uixScale;
const _gridScaleInEdit = .9;
const _rearrangeCurve = UixLog(150);
const _rearrangeDuration = Duration(milliseconds: 200);

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

  final Color? themeColor; // 应用主题色 (用于磁贴背景底色等)

  App({
    required this.id,
    required this.name,
    required this.icon,
    required this.page,
    required this.smallTile,
    required this.mediumTile,
    this.wideTile, // 宽磁贴可选
    this.themeColor,
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
  static const columns = 4;
  final VoidCallback? onOpenApps;
  final ValueChanged<TileModel>? onLaunchApp;
  final ValueChanged<bool>? onEditModeChanged;

  const StartMenu({
    super.key,
    required this.initialTiles,
    this.onOpenApps,
    this.onLaunchApp,
    this.onEditModeChanged,
  });

  @override
  StartMenuState createState() => StartMenuState();
}

enum _DragInput { hold, vertical, horizontal }

class StartMenuState extends State<StartMenu>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin<StartMenu> {
  @override
  bool get wantKeepAlive => true;

  late List<TileModel> tiles;
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _transitionController;
  StartTileTransition? _transition;
  Map<String, double> _transitionDelays = {};

  double _cellPitch(double gridWidth) =>
      (math.min(gridWidth, _gridWidth) + _gridGap) / StartMenu.columns;

  Future<void> startPushNextAnimations(String tileId) =>
      _playTransition(StartTileTransition.forwardOut, clickedId: tileId);

  Future<void> startPopNextAnimations() =>
      _playTransition(StartTileTransition.backwardIn);

  Future<void> startPushAnimations() =>
      _playTransition(StartTileTransition.forwardIn);

  Future<void> _playTransition(
    StartTileTransition transition, {
    String? clickedId,
  }) async {
    final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !_scrollController.hasClients) return;
    final scroll = _scrollController.position;
    final viewport = scroll.viewportDimension;
    final pitch = _cellPitch(box.size.width - 2 * _adornerExtent);
    final delays = <String, double>{};
    for (final tile in tiles) {
      final top = _gridTop + tile.gridY * pitch - scroll.pixels;
      final bottom = top + tile.heightCells * pitch - _gridGap;
      if (tile.instanceId != clickedId && (bottom <= 0 || top >= viewport)) {
        continue;
      }
      delays[tile.instanceId] = transition.delayFor(
        column: tile.gridX,
        columns: StartMenu.columns,
        topInViewport: top,
        viewportHeight: viewport,
        clicked: tile.instanceId == clickedId,
      );
    }
    if (delays.isEmpty) return;
    final endMs = delays.values.reduce(math.max) + transition.durationMs;
    setState(() {
      _transition = transition;
      _transitionDelays = delays;
      _transitionController.duration = Duration(
        microseconds: (endMs * 1000).round(),
      );
    });
    try {
      await _transitionController.forward(from: 0).orCancel;
    } on TickerCanceled {
      return;
    }
  }

  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _scrollViewportKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(vsync: this);
    _scrollController.addListener(_followHoverScroll);
    tiles = widget.initialTiles.map((tile) => tile.clone()).toList();
  }

  /// 自动寻找能够容纳指定宽高的空余网格坐标
  /// 逻辑：从“试图与最底部边缘平齐”的 Y 坐标开始尝试。
  /// 如果该行没有任何一列能放下，则一行一行（y++）向下移动，直到找到空位。
  Offset _findEmptySpot(List<TileModel> currentTiles, int width, int height) {
    int cols = StartMenu.columns; // 桌面总列数
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
  bool isPinned(App app) => tiles.any((tile) => tile.app.id == app.id);

  void pinApp(App app) {
    if (isPinned(app)) return;
    int newWidthCells = 2; // 默认中磁贴
    int newHeightCells = 2;

    Offset emptySpot = _findEmptySpot(tiles, newWidthCells, newHeightCells);

    setState(() {
      tiles.add(
        TileModel(
          instanceId: app.id,
          app: app,
          currentSize: TileSize.medium,
          gridX: emptySpot.dx.toInt(),
          gridY: emptySpot.dy.toInt(),
        ),
      );
    });

    _ensureTileVisible(tiles.last);
  }

  @override
  void dispose() {
    hoverTimer?.cancel();
    _edgeTimer?.cancel();
    _scrollController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  bool isEditMode = false;
  String? selectedTileId;
  String? draggingTileId;
  Offset? initialDragOffset;
  Offset? initialTouchPosition;
  bool hasMetDragThreshold = false;
  _DragInput? _dragInput;
  int? _editPointer;
  String? _removingTileId;
  Timer? _edgeTimer;
  bool _hoverScrolling = false;
  bool _followScheduled = false;
  Offset? _dragGlobal;
  Offset? _lastPreviewPointer;
  double? _dragPitch;

  // --- 引擎状态 ---
  List<TileModel>? originalItems;
  List<TileModel>? _baseLayoutSnapshot;
  Timer? hoverTimer;
  int lastHoverX = -1;
  int lastHoverY = -1;

  void exitEditMode() {
    if (isEditMode && _removingTileId == null) {
      setState(() {
        if (draggingTileId != null) _abandonDrag();
        isEditMode = false;
        selectedTileId = null;
        _baseLayoutSnapshot = null;
      });
      if (widget.onEditModeChanged != null) {
        widget.onEditModeChanged!(false);
      }
    }
  }

  void _finishUnpin(String id) {
    if (_removingTileId != id) return;
    setState(() {
      _removingTileId = null;
      tiles.removeWhere((tile) => tile.instanceId == id);
      selectedTileId = null;
      if (tiles.isNotEmpty) _finalizeLayout();
      _baseLayoutSnapshot = tiles.map((tile) => tile.clone()).toList();
    });
    if (tiles.isEmpty) exitEditMode();
  }

  void _ensureTileVisible(TileModel requested) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
      if (!mounted || box == null || !_scrollController.hasClients) return;
      final index = tiles.indexWhere(
        (tile) => tile.instanceId == requested.instanceId,
      );
      if (index < 0) return;
      final tile = tiles[index];
      final pitch = _cellPitch(box.size.width - 2 * _adornerExtent);
      final position = _scrollController.position;
      final controls = selectedTileId == tile.instanceId ? 45 * uixScale : 0.0;
      final top = _gridTop + tile.gridY * pitch - controls;
      final bottom = top + tile.heightCells * pitch - _gridGap + 2 * controls;
      final offset = position.pixels;
      final viewport = position.viewportDimension;
      final target = top < offset
          ? top
          : bottom > offset + viewport
          ? bottom - viewport
          : offset;
      final clamped = target.clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if (clamped != offset) {
        _scrollController.animateTo(
          clamped,
          duration: const Duration(milliseconds: 350),
          curve: const UixLog(150),
        );
      }
    });
  }

  /// 碰撞推挤计算（纯计算，不调 setState）
  ///
  /// 返回推挤后的新布局列表，若无需推挤则返回 `null`。
  List<TileModel>? _computePreview(int targetX, int targetY) {
    if (originalItems == null || draggingTileId == null) return null;

    Offset? currentPixelOffset;
    try {
      currentPixelOffset = tiles
          .firstWhere((e) => e.instanceId == draggingTileId)
          .dragPixelOffset;
    } catch (e) {
      return null;
    }

    List<TileModel> nextLayout = originalItems!.map((e) => e.clone()).toList();
    TileModel targetItem = nextLayout.firstWhere(
      (e) => e.instanceId == draggingTileId,
    );

    targetItem.gridX = targetX;
    targetItem.gridY = targetY;
    targetItem.dragPixelOffset = currentPixelOffset;

    List<TileModel> directCollisions = nextLayout
        .where(
          (item) =>
              item.instanceId != targetItem.instanceId &&
              item.overlaps(targetItem),
        )
        .toList();

    // GridModel's single-obstruction branch prefers a legal horizontal
    // move over a vertical one. Chained and block moves continue below.
    if (directCollisions.length == 1) {
      final obstruction = directCollisions.single;
      final right = targetItem.gridX + targetItem.widthCells;
      final left = targetItem.gridX - obstruction.widthCells;
      final rightDistance = right - obstruction.gridX;
      final leftDistance = obstruction.gridX - left;
      final candidates = [
        if (rightDistance <= leftDistance) ...[
          right,
          left,
        ] else ...[
          left,
          right,
        ],
      ];
      for (final x in candidates) {
        if (x < 0 || x + obstruction.widthCells > StartMenu.columns) continue;
        if (x == right && obstruction.gridX < targetItem.gridX) continue;
        final obstructionRight = obstruction.gridX + obstruction.widthCells;
        if (x == left && obstructionRight > right) continue;
        final moved = obstruction.clone()..gridX = x;
        if (nextLayout.any(
          (tile) => tile != obstruction && tile.overlaps(moved),
        )) {
          continue;
        }
        obstruction.gridX = x;
        return nextLayout;
      }
    }

    if (directCollisions.isNotEmpty) {
      bool moved = false;
      bool canBreakCeiling = false;
      int ceilingOffsetX = 0;
      int ceilingOffsetY = 0;

      int groupLeft = directCollisions
          .map((e) => e.gridX)
          .reduce((a, b) => a < b ? a : b);
      int groupRight = directCollisions
          .map((e) => e.gridX + e.widthCells)
          .reduce((a, b) => a > b ? a : b);
      int groupTop = directCollisions
          .map((e) => e.gridY)
          .reduce((a, b) => a < b ? a : b);
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
        const Offset(0, 1),
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

          if (nx < 0 || nx + item.widthCells > StartMenu.columns) {
            isOutOfBoundsX = true;
            break;
          }

          TileModel ghost = item.clone();
          ghost.gridX = nx;
          ghost.gridY = ny;

          for (var other in nextLayout) {
            if (other.instanceId == targetItem.instanceId) continue;
            if (directCollisions.any((e) => e.instanceId == other.instanceId)) {
              continue;
            }
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
        var belowRowCollisions = directCollisions
            .where((e) => e.gridY > targetItem.gridY)
            .toList();
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

        var topRowCollisions = directCollisions
            .where((e) => e.gridY <= targetItem.gridY)
            .toList();
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

    return nextLayout;
  }

  /// 碰撞推挤并刷新 UI（包含 setState）
  void _updatePreview(int targetX, int targetY) {
    final nextLayout = _computePreview(targetX, targetY);
    if (nextLayout != null) {
      setState(() {
        tiles = nextLayout;
      });
    }
  }

  /// 整理布局（纯计算，不调 setState）
  ///
  /// 注意：此方法假设 [tiles] 非空，调用前请自行判空。
  void _finalizeLayout() {
    // 只做计算，不套 setState —— 由外层业务方统一调用 setState
    final minY = tiles.map((e) => e.gridY).reduce((a, b) => a < b ? a : b);
    if (minY < 0) {
      final offset = minY.abs();
      for (final item in tiles) {
        item.gridY += offset;
      }
    }
    _compactLayout(tiles);
  }

  void _compactLayout(List<TileModel> allItems) {
    int maxY = allItems.fold(
      0,
      (max, e) => e.gridY + e.heightCells > max ? e.gridY + e.heightCells : max,
    );
    for (int y = 0; y < maxY; y++) {
      bool isRowOccupied = allItems.any(
        (item) => y >= item.gridY && y < item.gridY + item.heightCells,
      );
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
    TileModel tile,
    Offset touchPosition,
    double left,
    double top,
    _DragInput input,
  ) {
    if (_removingTileId != null) return;
    setState(() {
      _dragInput = input;
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
    _ensureTileVisible(tile);
  }

  int _dropColumn(TileModel tile, double pixels, double pitch) {
    final position = pixels / pitch;
    final left = position.floor();
    final threshold = left % tile.widthCells == 0 ? .7 : .4;
    final column = position - left < threshold ? left : left + 1;
    return column.clamp(0, StartMenu.columns - tile.widthCells);
  }

  // GridDrop.uix retains the finger-to-face offset and relays a preview
  // only after the normalized pointer has held steady for 120 ms.
  void _onDragUpdate(TileModel tile, Offset global, double pitch) {
    if (draggingTileId != tile.instanceId ||
        initialTouchPosition == null ||
        initialDragOffset == null) {
      return;
    }
    _dragGlobal = global;
    _dragPitch = pitch;
    _refreshDragPosition();
    if (!hasMetDragThreshold) return;

    final viewport =
        _scrollViewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (viewport == null || viewport.size.isEmpty) return;
    final local = viewport.globalToLocal(global);
    final normalized = Offset(
      local.dx / viewport.size.width,
      local.dy / viewport.size.height,
    );
    if (_hoverDirection == 0) {
      _stopHoverScroll();
    } else {
      _edgeTimer ??= Timer(const Duration(milliseconds: 500), _hoverScrollTick);
    }

    final previous = _lastPreviewPointer;
    if (previous == null ||
        (normalized.dx - previous.dx).abs() > .004 ||
        (normalized.dy - previous.dy).abs() > .003) {
      _lastPreviewPointer = normalized;
      _queueDropPreview();
    }
  }

  TileModel? get _draggedTile {
    final index = tiles.indexWhere((tile) => tile.instanceId == draggingTileId);
    return index < 0 ? null : tiles[index];
  }

  void _refreshDragPosition() {
    final global = _dragGlobal;
    final tile = _draggedTile;
    final anchor = initialTouchPosition;
    final origin = initialDragOffset;
    final grid = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (global == null ||
        tile == null ||
        anchor == null ||
        origin == null ||
        grid == null) {
      return;
    }
    final delta = grid.globalToLocal(global) - anchor;
    if (delta == Offset.zero && !hasMetDragThreshold) return;
    setState(() {
      hasMetDragThreshold = true;
      tile.dragPixelOffset = origin + delta;
    });
  }

  void _queueDropPreview() {
    hoverTimer?.cancel();
    if (_hoverScrolling) return;
    hoverTimer = Timer(const Duration(milliseconds: 120), () {
      final tile = _draggedTile;
      final offset = tile?.dragPixelOffset;
      final pitch = _dragPitch;
      if (!mounted || tile == null || offset == null || pitch == null) return;
      final x = _dropColumn(tile, offset.dx, pitch);
      final y = math.max(0, (offset.dy / pitch).round());
      if (x == lastHoverX && y == lastHoverY) return;
      lastHoverX = x;
      lastHoverY = y;
      _updatePreview(x, y);
    });
  }

  // GridScroll.uix: outer 20%, 500 ms dwell, then a 200 ms linear step
  // with a magnitude proportional to depth into the edge zone.
  double get _hoverDirection {
    final global = _dragGlobal;
    final viewport =
        _scrollViewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (global == null || viewport == null || viewport.size.isEmpty) return 0;
    final y = viewport.globalToLocal(global).dy / viewport.size.height;
    if (y < .2) return ((y - .2) / .2).clamp(-1.0, 0.0);
    if (y > .8) return ((y - .8) / .2).clamp(0.0, 1.0);
    return 0;
  }

  void _hoverScrollTick() {
    _edgeTimer = null;
    if (!mounted || !hasMetDragThreshold || !_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    final target = (position.pixels + _hoverDirection * 250 * uixScale).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (target == position.pixels) {
      _stopHoverScroll();
      _queueDropPreview();
      return;
    }
    if (!_hoverScrolling) {
      _hoverScrolling = true;
      hoverTimer?.cancel();
      lastHoverX = lastHoverY = -1;
      final previewOffset = _draggedTile?.dragPixelOffset;
      if (originalItems case final committed?) {
        setState(() {
          tiles = committed.map((tile) => tile.clone()).toList();
          _draggedTile?.dragPixelOffset = previewOffset;
        });
      }
    }
    const step = Duration(milliseconds: 200);
    _scrollController.animateTo(target, duration: step, curve: Curves.linear);
    _edgeTimer = Timer(step, _hoverScrollTick);
  }

  void _followHoverScroll() {
    if (!_hoverScrolling || _followScheduled) return;
    _followScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _followScheduled = false;
      if (mounted && _hoverScrolling) _refreshDragPosition();
    });
  }

  void _stopHoverScroll() {
    _edgeTimer?.cancel();
    _edgeTimer = null;
    if (!_hoverScrolling) return;
    _hoverScrolling = false;
    if (_scrollController.hasClients) {
      final position = _scrollController.position;
      position.jumpTo(position.pixels);
    }
    _queueDropPreview();
  }

  void _abandonDrag() {
    hoverTimer?.cancel();
    if (originalItems case final saved?) tiles = saved;
    _clearDrag();
  }

  void _clearDrag() {
    _stopHoverScroll();
    hoverTimer?.cancel();
    _dragGlobal = null;
    _dragPitch = null;
    _lastPreviewPointer = null;
    for (final tile in tiles) {
      tile.dragPixelOffset = null;
    }
    draggingTileId = null;
    _dragInput = null;
    initialDragOffset = null;
    initialTouchPosition = null;
    hasMetDragThreshold = false;
    originalItems = null;
    lastHoverX = -1;
    lastHoverY = -1;
  }

  void _onDragEnd(TileModel tile, double cellSize) {
    setState(() {
      hoverTimer?.cancel();

      if (tile.dragPixelOffset != null && hasMetDragThreshold) {
        final finalX = _dropColumn(tile, tile.dragPixelOffset!.dx, cellSize);
        final finalY = math.max(
          0,
          (tile.dragPixelOffset!.dy / cellSize).round(),
        );
        tiles = _computePreview(finalX, finalY) ?? tiles;
        _finalizeLayout();

        _baseLayoutSnapshot = tiles.map((e) => e.clone()).toList();
      } else {
        if (originalItems != null) {
          tiles = originalItems!;
        }
      }

      _clearDrag();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isEditMode ? exitEditMode : null,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gridWidth = math.min(_gridWidth, constraints.maxWidth);
          final gridLeft =
              (constraints.maxWidth - gridWidth) / 2 + _adornerExtent;
          final pitch = _cellPitch(gridWidth);
          final rows = tiles.fold(
            0,
            (bottom, tile) => math.max(bottom, tile.gridY + tile.heightCells),
          );
          final active = selectedTileId;
          final dark = Theme.of(context).brightness == Brightness.dark;
          return NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (notification.direction != ScrollDirection.idle &&
                  isEditMode &&
                  selectedTileId != null &&
                  draggingTileId == null) {
                setState(() => selectedTileId = null);
              }
              return false;
            },
            child: SingleChildScrollView(
              key: _scrollViewportKey,
              controller: _scrollController,
              clipBehavior: Clip.none,
              child: SizedBox(
                width: constraints.maxWidth,
                height:
                    _gridTop +
                    (rows == 0 ? 0 : rows * pitch - _gridGap) +
                    (widget.onOpenApps == null && !isEditMode
                        ? 0
                        : 50 * uixScale),
                child: OverflowBox(
                  minWidth: constraints.maxWidth + 2 * _adornerExtent,
                  maxWidth: constraints.maxWidth + 2 * _adornerExtent,
                  child: AnimatedScale(
                    duration: isEditMode
                        ? const Duration(milliseconds: 400)
                        : _rearrangeDuration,
                    scale: isEditMode ? _gridScaleInEdit : 1,
                    curve: const UixLog(10),
                    alignment: Alignment.topCenter,
                    child: Stack(
                      key: _stackKey,
                      clipBehavior: Clip.none,
                      children: [
                        for (final tile in tiles)
                          if (tile.instanceId != active)
                            _buildTile(tile, gridLeft, pitch, context),
                        for (final tile in tiles)
                          if (tile.instanceId == active)
                            _buildTile(tile, gridLeft, pitch, context),
                        if (widget.onOpenApps case final open?)
                          Positioned(
                            right: gridLeft - 11 * uixScale,
                            bottom: 5 * uixScale,
                            child: AnimatedOpacity(
                              opacity: isEditMode ? 0 : 1,
                              duration: _rearrangeDuration,
                              child: StartImageButton(
                                label: 'All apps',
                                onPressed: isEditMode ? null : open,
                                rest:
                                    'arrownext_${dark ? 'dark' : 'light'}_rest',
                                down:
                                    'arrownext_${dark ? 'dark' : 'light'}_down',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTile(
    TileModel tile,
    double gridLeft,
    double cellSize,
    BuildContext context,
  ) {
    final bool isSelected = tile.instanceId == selectedTileId;
    final bool isActuallyDragging =
        (tile.instanceId == draggingTileId) && hasMetDragThreshold;

    double targetOpacity = 1.0;
    if (isEditMode) {
      targetOpacity = isSelected ? 1 : .6;
    }

    final double targetLeft = tile.gridX * cellSize;
    final double targetTop = tile.gridY * cellSize;

    final double left = isActuallyDragging && tile.dragPixelOffset != null
        ? tile.dragPixelOffset!.dx
        : targetLeft;
    final double top = isActuallyDragging && tile.dragPixelOffset != null
        ? tile.dragPixelOffset!.dy
        : targetTop;
    final double width = tile.widthCells * cellSize - _gridGap;
    final double height = tile.heightCells * cellSize - _gridGap;

    const double circleSize = 43 * uixScale;
    const double expandOffset = _adornerExtent;

    // 提炼浮动状态判断
    final bool isFloating = isEditMode && !isSelected;

    final canDrag = isEditMode && isSelected && _removingTileId == null;
    Offset? gridPosition(Offset position) {
      final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
      return box?.globalToLocal(position);
    }

    void startDrag(Offset position, _DragInput input) {
      if (gridPosition(position) case final local?) {
        _onDragStart(tile, local, targetLeft, targetTop, input);
      }
    }

    void updateDrag(Offset position, _DragInput input) {
      if (_dragInput == input) _onDragUpdate(tile, position, cellSize);
    }

    void finishDrag(_DragInput input) {
      if (_dragInput == input) _onDragEnd(tile, cellSize);
    }

    void cancelDrag(_DragInput input) {
      if (_dragInput == input && draggingTileId == tile.instanceId) {
        setState(_abandonDrag);
      }
    }

    final tileGestureContent = Listener(
      onPointerDown: (event) => _editPointer ??= event.pointer,
      onPointerUp: (event) {
        if (_editPointer == event.pointer) _editPointer = null;
      },
      onPointerCancel: (event) {
        if (_editPointer != event.pointer) return;
        _editPointer = null;
        // An accepted Flutter pan also sends onEnd when its pointer cancels.
        if (draggingTileId == tile.instanceId) setState(_abandonDrag);
      },
      child: GestureDetector(
        onTap: () {
          if (isEditMode && selectedTileId != tile.instanceId) {
            setState(() {
              selectedTileId = tile.instanceId;
              _baseLayoutSnapshot = tiles.map((e) => e.clone()).toList();
            });
            // 🌟 选中时自动吸附对齐视口
            _ensureTileVisible(tile);
          }
        },
        onLongPressStart: (details) =>
            startDrag(details.globalPosition, _DragInput.hold),
        onLongPressMoveUpdate: (details) =>
            updateDrag(details.globalPosition, _DragInput.hold),
        onLongPressEnd: (_) => finishDrag(_DragInput.hold),
        onLongPressCancel: () => cancelDrag(_DragInput.hold),
        onVerticalDragStart: canDrag
            ? (details) =>
                  startDrag(details.globalPosition, _DragInput.vertical)
            : null,
        onVerticalDragUpdate: canDrag
            ? (details) =>
                  updateDrag(details.globalPosition, _DragInput.vertical)
            : null,
        onVerticalDragEnd: canDrag
            ? (_) => finishDrag(_DragInput.vertical)
            : null,
        onVerticalDragCancel: canDrag
            ? () => cancelDrag(_DragInput.vertical)
            : null,
        onHorizontalDragStart: canDrag
            ? (details) =>
                  startDrag(details.globalPosition, _DragInput.horizontal)
            : null,
        onHorizontalDragUpdate: canDrag
            ? (details) =>
                  updateDrag(details.globalPosition, _DragInput.horizontal)
            : null,
        onHorizontalDragEnd: canDrag
            ? (_) => finishDrag(_DragInput.horizontal)
            : null,
        onHorizontalDragCancel: canDrag
            ? () => cancelDrag(_DragInput.horizontal)
            : null,
        child: AbsorbPointer(
          absorbing: isEditMode,
          // 🌟 重构核心 1：用 TweenAnimationBuilder 在父级处理平滑的透明度过渡
          child: TweenAnimationBuilder<double>(
            duration: _rearrangeDuration,
            curve: _rearrangeCurve,
            tween: Tween<double>(begin: 1.0, end: targetOpacity),
            builder: (context, opacityValue, child) {
              // 终极 3D 摄像机透明度控件
              final opacity = isActuallyDragging
                  ? opacityValue * .85
                  : opacityValue;
              return Opacity(
                opacity: opacity,
                child: GlobalPerspective(
                  // 阻止叠加涂层，只有触发透明度的时候系统才会把坐标拍扁
                  enabled: opacity != 1.0,
                  child: child!,
                ),
              );
            },
            // 🌟 重构核心 2：把原本 LiveTile 里的浮动包装器提到了这里
            child: _RearrangeIdle(
              isFloating: isFloating,
              child: _StartTileContentChange(
                size: tile.currentSize,
                removing: _removingTileId == tile.instanceId,
                onRemoved: () => _finishUnpin(tile.instanceId),
                child: Tile(
                  onTap: widget.onLaunchApp == null
                      ? null
                      : () => widget.onLaunchApp!(tile),
                  child: tile.app.getTileWidget(tile.currentSize),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final dark = Theme.of(context).brightness == Brightness.dark;
    final theme = dark ? 'dark' : 'light';
    final resize = switch (tile.currentSize) {
      TileSize.small => 'small',
      TileSize.medium => 'med',
      TileSize.wide => 'large',
    };

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
        if (isEditMode &&
            isSelected &&
            !isActuallyDragging &&
            _removingTileId == null) ...[
          Positioned(
            top: 0,
            right: expandOffset - 32 * uixScale,
            width: circleSize,
            height: circleSize,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: targetOpacity,
              child: StartImageButton(
                label: 'Unpin',
                rest: 'unpin_${theme}_rest',
                down: 'unpin_${dark ? 'light' : 'dark'}_rest',
                onPressed: () =>
                    setState(() => _removingTileId = tile.instanceId),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: expandOffset - 32 * uixScale,
            width: circleSize,
            height: circleSize,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: targetOpacity,
              child: StartImageButton(
                label: 'Resize',
                rest: 'resize_${resize}_${theme}_rest',
                down: 'resize_${resize}_${theme}_down',
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
                      tiles = _baseLayoutSnapshot!
                          .map((e) => e.clone())
                          .toList();
                    } else {
                      _baseLayoutSnapshot = tiles
                          .map((e) => e.clone())
                          .toList();
                    }

                    TileModel activeTile = tiles.firstWhere(
                      (t) => t.instanceId == tile.instanceId,
                    );

                    activeTile.currentSize = nextSize;

                    activeTile.gridX = activeTile.gridX.clamp(
                      0,
                      StartMenu.columns - activeTile.widthCells,
                    );

                    draggingTileId = activeTile.instanceId;
                    originalItems = tiles.map((e) => e.clone()).toList();

                    // 使用纯计算版本，避免嵌套 setState
                    final preview = _computePreview(
                      activeTile.gridX,
                      activeTile.gridY,
                    );
                    if (preview != null) {
                      tiles = preview;
                    }

                    _finalizeLayout();

                    draggingTileId = null;
                    originalItems = null;

                    // 🌟 调整大小可能会被挤到屏幕外围，强行追随保持可见
                    _ensureTileVisible(activeTile);
                  });
                },
              ),
            ),
          ),
        ],
      ],
    );

    final transition = _transition;
    final delay = _transitionDelays[tile.instanceId];
    if (transition != null && delay != null) {
      tileContent = StartTransitionTransform(
        clock: _transitionController,
        transition: transition,
        delay: delay,
        origin: Offset(
          expandOffset + width * StartTileTransition.centerPointX,
          0,
        ),
        child: tileContent,
      );
    }

    return AnimatedPositioned(
      key: tile.key,
      duration: Duration(milliseconds: isActuallyDragging ? 0 : 350),
      curve: const UixLog(150),
      left: gridLeft + left - expandOffset,
      top: _gridTop + top - expandOffset,
      child: SizedBox(
        width: width + expandOffset * 2,
        height: height + expandOffset * 2,

        child: _RearrangeTileScale(
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
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

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

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: curve));
  }

  void _startTimer() {
    _timer?.cancel();
    // 🌟 3. 在定时器内部做双重拦截保护
    if (!widget.enableLiveTile || widget.children.length <= 1) return;
    // 生成一个 3.0 到 6.0 之间的随机浮点数
    final double randomSeconds = 3.0 + math.Random().nextDouble() * 3.0;
    _timer = Timer(
      Duration(milliseconds: (randomSeconds * 1000).round()),
      _flip,
    );
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
    final name = widget.name;
    final title = name is Text
        ? UixText.fromText(name, boundsType: UixTextBounds.tight)
        : name;
    double standardWidth;
    double standardHeight;

    switch (widget.size) {
      case LiveTileSize.small:
        standardWidth = _gridCell;
        standardHeight = _gridCell;
        break;
      case LiveTileSize.medium:
        standardWidth = 2 * _gridCell + _gridGap;
        standardHeight = standardWidth;
        break;
      case LiveTileSize.wide:
        standardWidth = _gridWidth;
        standardHeight = 2 * _gridCell + _gridGap;
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

          return Stack(
            fit: StackFit.expand,
            children: [
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
                          if (title != null &&
                              widget.size != LiveTileSize.small)
                            Positioned(
                              left: 12 * uixScale,
                              right: 6 * uixScale,
                              bottom: 11 * uixScale,
                              child: DefaultTextStyle.merge(
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: uixFontSize(15),
                                  fontWeight: UixFontWeight.semiBold,
                                ),
                                child: title,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
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
  late final AnimationController _numberAnimation;
  int _fromCount = 0;
  int _toCount = 0;
  int _steps = 0;

  int _normalize(int? count) => (count ?? 0).clamp(0, 999);

  @override
  void initState() {
    super.initState();
    _numberAnimation = AnimationController(vsync: this, value: 1);
    _toCount = _normalize(widget.count);
  }

  double get _numberTime =>
      _numberAnimation.value * (_numberAnimation.duration?.inMilliseconds ?? 0);

  int _countAt(double time) {
    if (_steps == 0) return _toCount;
    final step = ((time - 450) / 250).floor() + 1;
    return (_fromCount +
            (_toCount - _fromCount) * step.clamp(0, _steps) / _steps)
        .round();
  }

  @override
  void didUpdateWidget(covariant MetroAppTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _normalize(widget.count);
    if (next == _toCount) return;
    _fromCount = _countAt(_numberTime);
    _toCount = next;
    _steps = (_toCount - _fromCount).clamp(0, 4);
    if (_steps == 0) {
      _numberAnimation.stop();
      return;
    }
    _numberAnimation.duration = Duration(
      milliseconds: 450 + (_steps - 1) * 250 + 800,
    );
    _numberAnimation.forward(from: 0);
  }

  (double, double) _numberPose(double elapsedMs) {
    if (_steps == 0 || elapsedMs < 420) return (0, 1);
    final lastChange = 450.0 + (_steps - 1) * 250;
    final nextChange = math.min(
      lastChange,
      450.0 + math.max(0, ((elapsedMs - 420) / 250).floor()) * 250,
    );
    final t = elapsedMs - nextChange;
    if (t < 0) {
      final progress = ((t + 30) / 30).clamp(0.0, 1.0);
      return (90 * const UixLog(10).transform(progress), 1 - progress);
    }
    const curve = UixSCurve(10);
    if (t < 30) return (-70, t / 30);
    if (t < 250) return (-70 + 115 * curve.transform((t - 30) / 220), 1);
    if (t < 500) return (45 - 60 * curve.transform((t - 250) / 250), 1);
    if (t < 800) return (-15 + 15 * curve.transform((t - 500) / 300), 1);
    return (0, 1);
  }

  @override
  void dispose() {
    _numberAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: widget.backgroundColor ?? Theme.of(context).colorScheme.primary,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final small = constraints.maxWidth <= _gridCell;
        final iconSize = (small ? 65 : 126) * uixScale;
        return AnimatedBuilder(
          animation: _numberAnimation,
          builder: (context, child) {
            final count = _countAt(_numberTime);
            final (degrees, opacity) = _numberPose(_numberTime);
            return Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: iconSize,
                        maxHeight: iconSize,
                      ),
                      child: child,
                    ),
                  ),
                  if (count > 0) ...[
                    SizedBox(width: (small ? 8 : 12) * uixScale),
                    Flexible(
                      child: Opacity(
                        opacity: opacity,
                        child: GlobalPerspective(
                          enabled: opacity < 1,
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.rotationX(
                              degrees * math.pi / 180,
                            ),
                            child: UixText(
                              '$count',
                              boundsType: UixTextBounds.tight,
                              maxLines: 1,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: uixFontSize(small ? 24 : 48),
                                fontWeight: UixFontWeight.semiBold,
                                letterSpacing: (small ? -1 : -1.5) * uixScale,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
          child: widget.icon,
        );
      },
    ),
  );
}

/// GridCell.uix attaches these tracks to Content, inside the edit scale.
class _StartTileContentChange extends StatefulWidget {
  const _StartTileContentChange({
    required this.size,
    required this.removing,
    required this.onRemoved,
    required this.child,
  });

  final TileSize size;
  final bool removing;
  final VoidCallback onRemoved;
  final Widget child;

  @override
  State<_StartTileContentChange> createState() =>
      _StartTileContentChangeState();
}

class _StartTileContentChangeState extends State<_StartTileContentChange>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock =
      AnimationController(vsync: this, value: 1)..addStatusListener((status) {
        if (widget.removing && status == AnimationStatus.completed) {
          widget.onRemoved();
        }
      });
  double _resizeScale = 1;
  double _resizeX = 0;

  @override
  void didUpdateWidget(covariant _StartTileContentChange oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.removing && !oldWidget.removing) {
      _clock.duration = const Duration(milliseconds: 300);
      _clock.forward(from: 0);
    } else if (widget.size != oldWidget.size && !widget.removing) {
      _resizeScale = switch (widget.size) {
        TileSize.small => 1.5,
        _ when oldWidget.size == TileSize.small => .8,
        _ => 1,
      };
      _resizeX = oldWidget.size == TileSize.wide ? 40 * uixScale : 0;
      _clock.duration = const Duration(milliseconds: 350);
      _clock.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _clock,
    builder: (_, child) {
      final t = _clock.value;
      if (widget.removing) {
        final progress = const UixLog(10).transform((t * 1.5).clamp(0.0, 1.0));
        return Opacity(
          opacity: 1 - const UixLog(10).transform(t),
          child: Transform.scale(scale: 1 - .5 * progress, child: child),
        );
      }
      final remainder = 1 - const UixLog(150).transform(t);
      return Transform.translate(
        offset: Offset(_resizeX * remainder, 0),
        child: Transform.scale(
          scale: 1 + (_resizeScale - 1) * remainder,
          alignment: Alignment.topCenter,
          child: child,
        ),
      );
    },
    child: widget.child,
  );
}

// GridCell.uix TokenRearrangeIdle1 and TokenRearrangeIdle2.
class _RearrangeIdle extends StatefulWidget {
  const _RearrangeIdle({required this.isFloating, required this.child});

  final bool isFloating;
  final Widget child;

  @override
  State<_RearrangeIdle> createState() => _RearrangeIdleState();
}

class _RearrangeIdleState extends State<_RearrangeIdle>
    with SingleTickerProviderStateMixin {
  static const _paths = [
    [
      Offset.zero,
      Offset(5, -5),
      Offset(10, 10),
      Offset(-5, -5),
      Offset(-10, 5),
      Offset.zero,
    ],
    [Offset.zero, Offset(10, 0), Offset(-10, 0), Offset.zero],
  ];
  static const _weights = [
    [1.0, 1.0, 1.0, 1.0, 1.0],
    [1.0, 2.0, 1.0],
  ];

  late final AnimationController _controller;
  Animation<Offset>? _drift;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    if (widget.isFloating) _start();
  }

  void _start() {
    final random = math.Random();
    final track = random.nextInt(_paths.length);
    final timeScale = 1 + random.nextDouble() * 2;
    final strength =
        (.5 + random.nextDouble() / 2) * (random.nextBool() ? 1 : -1);
    final path = _paths[track];
    final weights = _weights[track];
    _controller.duration = Duration(
      milliseconds: (weights.reduce((a, b) => a + b) * 1000 / timeScale)
          .round(),
    );
    _drift = TweenSequence<Offset>([
      for (var i = 0; i < weights.length; i++)
        TweenSequenceItem(
          tween: Tween<Offset>(
            begin: path[i] * (strength * uixScale),
            end: path[i + 1] * (strength * uixScale),
          ).chain(CurveTween(curve: const UixSCurve(10))),
          weight: weights[i],
        ),
    ]).animate(_controller);
    _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _RearrangeIdle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFloating == widget.isFloating) return;
    if (widget.isFloating) {
      _start();
    } else {
      _controller.reset();
      _drift = null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (_, child) =>
        Transform.translate(offset: _drift?.value ?? Offset.zero, child: child),
    child: widget.child,
  );
}

class _RearrangeTileScale extends StatefulWidget {
  const _RearrangeTileScale({
    required this.isEditMode,
    required this.isSelected,
    required this.child,
  });

  final bool isEditMode, isSelected;
  final Widget child;

  @override
  State<_RearrangeTileScale> createState() => _RearrangeTileScaleState();
}

class _RearrangeTileScaleState extends State<_RearrangeTileScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animatable<double> _track;

  double get _idleScale {
    if (!widget.isEditMode) return 1;
    return widget.isSelected ? 1 / _gridScaleInEdit : .925;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, value: 1);
    _track = ConstantTween(_idleScale);
  }

  void _play(Animatable<double> track, int milliseconds) {
    _track = track;
    _controller.duration = Duration(milliseconds: milliseconds);
    _controller.forward(from: 0);
  }

  void _press() {
    final scale = _track.evaluate(_controller);
    _play(
      TweenSequence([
        TweenSequenceItem(tween: ConstantTween(scale), weight: 360),
        TweenSequenceItem(
          tween: Tween(
            begin: scale,
            end: 1.05,
          ).chain(CurveTween(curve: const UixExp(10))),
          weight: 600,
        ),
      ]),
      960,
    );
  }

  void _release() {
    if (widget.isEditMode) return;
    _play(
      Tween(
        begin: _track.evaluate(_controller),
        end: 1.0,
      ).chain(CurveTween(curve: const UixLog(10))),
      100,
    );
  }

  @override
  void didUpdateWidget(covariant _RearrangeTileScale oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isEditMode == widget.isEditMode &&
        oldWidget.isSelected == widget.isSelected) {
      return;
    }
    final start = _track.evaluate(_controller);
    final target = _idleScale;
    if (widget.isEditMode && widget.isSelected) {
      final peak = target * 1.05;
      _play(
        TweenSequence([
          TweenSequenceItem(
            tween: Tween(begin: start, end: peak),
            weight: 75,
          ),
          TweenSequenceItem(
            tween: Tween(begin: peak, end: target),
            weight: 125,
          ),
        ]),
        200,
      );
    } else {
      _play(
        Tween(
          begin: start,
          end: target,
        ).chain(CurveTween(curve: _rearrangeCurve)),
        200,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: widget.isEditMode ? null : (_) => _press(),
    onPointerUp: (_) => _release(),
    onPointerCancel: (_) => _release(),
    child: AnimatedBuilder(
      animation: _controller,
      builder: (_, child) =>
          Transform.scale(scale: _track.evaluate(_controller), child: child),
      child: widget.child,
    ),
  );
}

class StartImageButton extends StatefulWidget {
  const StartImageButton({
    required this.label,
    required this.rest,
    required this.down,
    required this.onPressed,
    this.size = 43,
    this.restColor,
    this.chromaReplacement,
    super.key,
  });

  final String label, rest, down;
  final double size;
  final Color? restColor, chromaReplacement;
  final VoidCallback? onPressed;

  @override
  State<StartImageButton> createState() => _StartImageButtonState();
}

class _StartImageButtonState extends State<StartImageButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      '$startAssets/${_pressed ? widget.down : widget.rest}.png',
      width: widget.size * uixScale,
      height: widget.size * uixScale,
      color: _pressed ? null : widget.restColor,
      excludeFromSemantics: true,
    );
    final accent = widget.chromaReplacement;
    if (_pressed && accent != null) {
      // The pressed Search PNG uses the same red accent mask as ShellChrome.
      final light = Theme.of(context).brightness == Brightness.light;
      List<double> channel(double component) => [
        light ? component : 0,
        light ? 0 : 1 - component,
        0,
        0,
        light ? 0 : component * 255,
      ];
      image = ColorFiltered(
        colorFilter: ColorFilter.matrix([
          ...channel(accent.r),
          ...channel(accent.g),
          ...channel(accent.b),
          0,
          0,
          0,
          1,
          0,
        ]),
        child: image,
      );
    }
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: widget.label,
      button: true,
      enabled: widget.onPressed != null,
      onTap: widget.onPressed,
      child: Tile(
        localTiltProjection: true,
        onTap: widget.onPressed,
        onTouch: widget.onPressed == null
            ? null
            : (pressed) => setState(() => _pressed = pressed),
        child: image,
      ),
    );
  }
}
