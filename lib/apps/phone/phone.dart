import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:metro_ui/application_bar.dart';
import 'package:metro_ui/metro_page_push.dart';
import 'package:metro_ui/page.dart';
import 'package:metro_ui/page_scaffold.dart';
import 'package:metro_ui/widgets/context_menu.dart';
import 'package:metro_ui/widgets/metro_circle_button.dart';
import 'package:metro_ui/widgets/stack_panel.dart';
import 'package:windows_phone_simulator/app_registry.dart';
import 'package:windows_phone_simulator/start_menu.dart';
import 'keypad_page.dart';

/// 自驱动的 Phone 磁贴：不关心外界的创建/销毁，
/// 挂载到屏幕上即开始播放角标时序：等 2s → 1 → 2 → 3 → 4 → 5，卸载时自动停止。
/// 每个磁贴实例持有自己的角标与时序任务，互不干扰。
class PhoneLiveTile extends StatefulWidget {
  final LiveTileSize size;
  final Widget? name;
  final Widget icon;

  const PhoneLiveTile({
    super.key,
    required this.size,
    required this.icon,
    this.name,
  });

  @override
  State<PhoneLiveTile> createState() => _PhoneLiveTileState();
}

class _PhoneLiveTileState extends State<PhoneLiveTile> {
  /// 磁贴内容（可以是任意 Widget：文字、图片、动画、组合……）
  late final ValueNotifier<Widget> _content;

  @override
  void initState() {
    super.initState();
    _content = ValueNotifier<Widget>(widget.icon);
    _playBadgeSequence();
  }

  /// 角标动画
  Future<void> _playBadgeSequence() async {
    // 等 2 秒才开始计数
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    _content.value = _buildBadge(1);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _content.value = _buildBadge(2);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _content.value = _buildBadge(3);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    _content.value = _buildBadge(4);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    _content.value = _buildBadge(5);
  }

  /// 数字角标：SVG 图标 + 角标数字
  Widget _buildBadge(int number) {
    return MetroAppTile(
      icon: widget.icon, // 直接用传入的 SVG 图标
      count: number, // 角标数字
    );
  }

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 注意：ValueListenableBuilder 只包内容，不包 LiveTile 本体，
    // 这样 LiveTile 的 3D 翻转动画 State 保持稳定，不会因内容更新而重置。
    return LiveTile(
      size: widget.size,
      flipStyle: FlipStyle.elastic,
      name: widget.name,
      children: [
        ValueListenableBuilder<Widget>(
          valueListenable: _content,
          builder: (context, content, _) {
            return MetroAppTile(icon: content);
          },
        ),
      ],
    );
  }
}

class PhoneApp extends StatefulWidget {
  const PhoneApp({super.key});

  // ─── 图标模板 ─────────────────────────────────
  // 以“高度”为基准等比缩放：传目标高度即可，宽度按 SVG 宽高比自动计算。
  // 不要包 FittedBox —— LiveTile 外层已有画布 FittedBox 做等比缩放，
  // 嵌套 FittedBox 在紧约束下会退化失效（上一轮已验证）。
  static Widget appIcon(double height) {
    return SvgPicture.asset(
      'images/icons/phone_icon.svg',
      height: height,
      fit: BoxFit.contain, // 保持宽高比，等价于“以高度缩放”
      colorFilter: const ColorFilter.mode(
        Colors.white,
        BlendMode.srcIn,
      ),
    );
  }

  static void register() {
    AppRegistry().register(App(
      id: 'com.ms.phone',
      name: 'Phone',
      //themeColor: Colors.purple,
      icon: appIcon(32), // 应用列表图标
      page: const PhoneApp(),
      smallTile: PhoneLiveTile(
        size: LiveTileSize.small,
        icon: appIcon(36), // 小磁贴：画布 79.5px，占比约 45%
      ),
      mediumTile: PhoneLiveTile(
        size: LiveTileSize.medium,
        name: const Text('Phone'),
        icon: appIcon(72), // 中磁贴：画布 168px，占比约 43%
      ),
    ));
  }

  @override
  State<PhoneApp> createState() => _PhoneAppState();
}

class _PhoneAppState extends State<PhoneApp> {
  /// 页面 Scaffold 的 key：跳转到下一页时传给 metroPagePush，
  /// 以便找到当前页面的 MetroPageScaffoldState 播放推场动画
  /// （不传的话，跳转 context 在 Scaffold 之上，maybeOf 找不到 → 无动画直接切页）。
  final GlobalKey<MetroPageScaffoldState> _scaffoldKey =
      GlobalKey<MetroPageScaffoldState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MetroPageScaffold(
      key: _scaffoldKey,
      stackPanel: const StackPanel(
        top: Text('CHINA UNICOM'),
        bottom: Text('history'),
      ),
      applicationBar:
          MetroApplicationBar(backgroundColor: Colors.grey[900], buttons: [
        MetroAppBarButton(
          icon: SvgPicture.asset(
            'images/icons/phone_1.svg',
            fit: BoxFit.contain,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
          ),
          label: 'voicemail',
          onPressed: () {},
        ),
        MetroAppBarButton(
          icon: SvgPicture.asset(
            'images/icons/phone_2.svg',
            fit: BoxFit.contain,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
          ),
          label: 'keypad',
          onPressed: () {
            metroPagePush(
              context,
              MetroPageRoute(builder: (context) => const KeypadPage()),
              // 传入当前页面 Scaffold 的 key，触发默认推场动画
              // （当前页 Y 轴旋转 40.5°，动画完成后才真正 push 新页面）
              scaffoldKey: _scaffoldKey,
            );
          },
        ),
        MetroAppBarButton(
          icon: SvgPicture.asset(
            'images/icons/phone_3.svg',
            fit: BoxFit.contain,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
          ),
          label: 'people',
          onPressed: () {},
        ),
        MetroAppBarButton(
          icon: SvgPicture.asset(
            'images/icons/phone_4.svg',
            fit: BoxFit.contain,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
          ),
          label: 'search',
          onPressed: () {},
        ),
      ], menuItems: [
        MetroAppBarMenuItem(
          label: 'delete all',
          onPressed: () {},
        ),
        MetroAppBarMenuItem(
          label: 'settings',
          onPressed: () {},
        ),
        MetroAppBarMenuItem(
          label: 'blocked calls',
          onPressed: () {},
        ),
      ]),
      body: Stack(
        children: [
          // 通话记录列表
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsetsGeometry.symmetric(horizontal: 18),
              //padding: const EdgeInsetsGeometry.symmetric(horizontal: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final record in _sampleCallRecords)
                    CallHistoryTile(
                      icon: SvgPicture.asset(
                        height: 18,
                        'images/icons/phone_icon.svg',
                        fit: BoxFit.contain, // 保持宽高比，等价于“以高度缩放”
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      record: record,
                      menu: const MetroContextMenuItem(
                        child: Text('delete item'),
                      ),
                    ),
                    const SizedBox(height: 60,),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─── demo 数据：示例通话记录 ─────────────────────────
const List<CallRecord> _sampleCallRecords = [
  CallRecord(
    kind: CallKind.outgoing,
    number: 'Emergency call',
    timeLabel: '1/16/2015',
  ),
  CallRecord(
    kind: CallKind.missed,
    number: '13901234567',
    timeLabel: '1/16/2015',
  ),
  CallRecord(
    kind: CallKind.outgoing,
    number: '9981123456',
    timeLabel: '1/16/2015',
  ),
  CallRecord(
    kind: CallKind.outgoing,
    number: '95588',
    timeLabel: '1/15/2015',
  ),
  CallRecord(
    kind: CallKind.incoming,
    number: '10086',
    timeLabel: '1/14/2015',
  ),
  CallRecord(
    kind: CallKind.missed,
    number: '400-800-8888',
    timeLabel: '1/14/2015',
  ),
  CallRecord(
    kind: CallKind.outgoing,
    number: '1713704502848',
    timeLabel: '1/17/2015',
  ),
  CallRecord(
    kind: CallKind.incoming,
    number: '13901234567',
    timeLabel: '1/16/2015',
  ),
  CallRecord(
    kind: CallKind.outgoing,
    number: 'Emergency call',
    timeLabel: '1/16/2015',
  ),
  CallRecord(
    kind: CallKind.outgoing,
    number: '95588',
    timeLabel: '1/15/2015',
  ),
  CallRecord(
    kind: CallKind.incoming,
    number: '10086',
    timeLabel: '1/14/2015',
  ),
  CallRecord(
    kind: CallKind.missed,
    number: '400-800-8888',
    timeLabel: '1/14/2015',
  ),
];

/// 通话方向
enum CallKind { outgoing, incoming, missed }

/// 单条通话记录的数据模型
class CallRecord {
  final CallKind kind;
  final String number;
  final String timeLabel;

  const CallRecord({
    required this.kind,
    required this.number,
    required this.timeLabel,
  });

  /// 方向文案（WP 风格）
  String get directionLabel => switch (kind) {
        CallKind.outgoing => 'Outgoing',
        CallKind.incoming => 'Incoming',
        CallKind.missed => 'Missed',
      };

  /// 号码颜色：未接来电用 WP 红，其余白色
  Color get numberColor => switch (kind) {
        CallKind.missed => const Color(0xFFE81123),
        _ => Colors.white,
      };
}

/// 通用的通话记录行组件：圆形图标 + 号码 + 方向/时间，
/// 支持长按上下文菜单与点击回调。
class CallHistoryTile extends StatelessWidget {
  final Widget icon;
  final CallRecord record;
  final MetroContextMenuItem? menu;
  final VoidCallback? onTap;
  final double iconSize;
  final TextStyle? numberStyle;
  final TextStyle? detailStyle;

  const CallHistoryTile({
    super.key,
    required this.icon,
    required this.record,
    this.menu,
    this.onTap,
    this.iconSize = 34.5, // 43.125 * 0.8
    this.numberStyle,
    this.detailStyle,
  });

  @override
  Widget build(BuildContext context) {
    Widget row = Stack(
      clipBehavior: Clip.none,
      children: [
        const SizedBox(
          height: 82 * 0.8,
          width: double.infinity,
        ),
        Positioned(
          top: 5 * 0.8,
          left: 2 * 0.8,
          child: MetroCircleButton(
            size: iconSize,
            icon: Center(child: icon),
            onPressed: () {},
          ),
        ),
        // 号码 + 方向/时间：嵌套一个 Stack 组合成整体，方便对整个组合做动画
        Positioned.fill(
          // 按压缩放反馈：参考 metro_ui Tile 的按压逻辑（即时反馈、松手回弹），
          // 去掉 3D 旋转，仅保留缩放
          child: _PressScale(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 60.5 * 0.8,
                  top: -3.5 * 0.8,
                  child: Text(
                    record.number,
                    style: numberStyle ??
                        const TextStyle(
                          fontSize: 37 * 0.8,
                          fontWeight: FontWeight(300),
                          letterSpacing: 0.5,
                        ),
                  ),
                ),
                Positioned(
                  top: 42 * 0.8,
                  left: 63 * 0.8,
                  child: Text(
                    '${record.directionLabel}, ${record.timeLabel}',
                    style: detailStyle ??
                        TextStyle(
                          fontWeight: FontWeight(300),
                          fontSize: 19 * 0.8,
                          letterSpacing: 0.8,
                          color: record.kind == CallKind.missed
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (onTap != null) {
      row = GestureDetector(onTap: onTap, child: row);
    }
    if (menu != null) {
      row = MetroContextMenu(menu: menu!, child: row);
    }
    return row;
  }
}

/// 按压缩放反馈组件。
///
/// 参考 metro_ui 的 Tile 按压逻辑：按下立即反馈（PanDown 比 TapDown 更即时），
/// 松手弹性回弹。去掉了 Tile 的 3D 旋转部分，仅保留按压缩放。
///
/// ⚠️ 为什么用 GestureDetector 而不是 Listener：
/// 长按弹出上下文菜单时，外层 MetroContextMenu 的 LongPress 会在手势竞技场中
/// 获胜，本组件的 Pan/Tap 手势随之失败 → 触发 onPanCancel / onTapCancel →
/// 立即归位。而 Listener 不参与手势竞技场：菜单弹出后手指未抬起，
/// onPointerUp 不会触发、事件流也没被取消（onPointerCancel 不触发），
/// 组件会一直停在按下状态。
class _PressScale extends StatefulWidget {
  final Widget child;

  const _PressScale({required this.child});

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isTouch = false;

  /// 按下缩小的目标比例
  static const double _pressedScale = 0.95;

  /// 按下时的目标不透明度（1.0 → 0.5，配合缩放做按压反馈）
  static const double _pressedOpacity = 0.5;

  /// 按下缩小的时长（快速反馈）
  static const Duration _pressDuration = Duration(milliseconds: 100);

  /// 松手回弹的时长
  static const Duration _releaseDuration = Duration(milliseconds: 400);

  /// 按下缩小的曲线
  static const Curve _pressCurve = Curves.easeOutCubic;

  /// 松手回弹的曲线（弹性）
  static const Curve _releaseCurve = Curves.elasticOut;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  /// 按下即缩小（即时反馈，同 Tile 的 PanDown 立即触发）
  void _handlePanDown(DragDownDetails details) {
    _isTouch = true;
    _controller.animateTo(1.0, duration: _pressDuration, curve: _pressCurve);
  }

  /// 手指滑出组件区域：立即回弹（同 Tile 的 PanUpdate 越界逻辑）
  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isTouch) return;
    final RenderBox box = context.findRenderObject()! as RenderBox;
    if (!box.attached || box.size.isEmpty) return;
    final Offset local = box.globalToLocal(details.globalPosition);
    final bool inside = local.dx >= 0 &&
        local.dx <= box.size.width &&
        local.dy >= 0 &&
        local.dy <= box.size.height;
    if (!inside) _handleRelease();
  }

  /// 归位：松手 / 手势被抢占（长按菜单、滑动列表）/ 快速点击都走这里
  void _handleRelease() {
    _isTouch = false;
    _controller.animateTo(
      0.0,
      duration: _releaseDuration,
      curve: _releaseCurve,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 只响应文字区域本身，避免挡住下方圆形按钮的点击
      behavior: HitTestBehavior.deferToChild,
      // Pan 手势：按下立即反馈；长按时被外层 LongPress 抢占 → onPanCancel 归位
      onPanDown: _handlePanDown,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: (_) => _handleRelease(),
      onPanCancel: _handleRelease,
      // Tap 手势：保证快速点击（无移动、Pan 未获胜）也能归位
      onTap: _handleRelease,
      onTapCancel: _handleRelease,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final double t = _controller.value;
          // 1. Z 轴缩放：1.0 → 0.95
          final double scale = 1.0 - ((1.0 - _pressedScale) * t);
          // 2. 透明度：1.0 → 0.5
          final double opacity =
              1.0 - ((1.0 - _pressedOpacity) * t);
          return Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}
