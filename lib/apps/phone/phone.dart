import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:metro_ui/application_bar.dart';
import 'package:metro_ui/page_scaffold.dart';
import 'package:metro_ui/widgets/stack_panel.dart';
import 'package:metro_ui/widgets/swipe_page_view.dart';
import 'package:metro_ui/widgets/swipe_title_indicator.dart';
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
      //backgroundColor: Colors.blueGrey,
      stackPanel: const StackPanel(
        top: Text('CHINA UNICOM'),
        //通话记录
        //bottom: Text('history'),
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
      body: Builder(
        // 使用 Builder 来获取正确的 context
        builder: (scaffoldContext) {
          return Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 18),
              child: SwipePages(
                items: [
                  SwipePageItem(title: Text('system'), page: Text("data")),
                  SwipePageItem(
                      title: Text('applications'), page: Text("data")),
                ],
              ));
        },
      ),
    );
  }
}
