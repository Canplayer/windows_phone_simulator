import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:metro_ui/application_bar.dart';
import 'package:metro_ui/page_scaffold.dart';
import 'package:metro_ui/widgets/context_menu.dart';
import 'package:metro_ui/widgets/metro_circle_button.dart';
import 'package:metro_ui/widgets/stack_panel.dart';
import 'package:windows_phone_simulator/app_registry.dart';
import 'package:windows_phone_simulator/start_menu.dart';

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
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MetroPageScaffold(
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
          onPressed: () {},
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
          // 背景参考图：对照还原界面布局用，调整完可删
          // Positioned.fill(
          //   child: Opacity(
          //     opacity: 1,
          //     child: Image.asset(
          //       'images/reference/phone_history_ref.png',
          //       fit: BoxFit.fitWidth,
          //       alignment: AlignmentGeometry.topStart,
          //     ),
          //   ),
          // ),

          // 通话记录列表
          SingleChildScrollView(
            child: 
          Padding(
            padding: const EdgeInsetsGeometry.symmetric(horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final record in _sampleCallRecords)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: CallHistoryTile(
                      icon: SvgPicture.asset(
                        height: 20,
                        'images/icons/phone_icon.svg',
                        fit: BoxFit.contain, // 保持宽高比，等价于“以高度缩放”
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      record: record,
                      menu: const MetroContextMenuItem(
                        child: Text('pin to start'),
                      ),
                    ),
                  ),
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
          height: 50,
          width: double.infinity,
        ),
        Positioned(
          top: 0,
          left: 2 * 0.8,
          child: MetroCircleButton(
            size: iconSize,
            icon: Center(child: icon),
            onPressed: () {},
          ),
        ),
        Positioned(
          left: 60 * 0.8,
          top: -10.5*0.8,
          child: Text(
            record.number,
            style: numberStyle ??
                const TextStyle(
                  fontSize: 36.5 * 0.8,
                  fontFamily: "Segoe UI Light",
                  letterSpacing: 0.68,
                ),
          ),
        ),
        Positioned(
          top: 36 * 0.8,
          left: 50,
          child: Text(
            '${record.directionLabel},${record.timeLabel}',
            style: TextStyle(
              fontFamily: "Segoe UI Light",
              fontSize: 19 * 0.8,
              letterSpacing: 0.8,
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
