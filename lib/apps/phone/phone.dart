import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:metro_ui/page_scaffold.dart';
import 'package:metro_ui/widgets/stack_panel.dart';
import 'package:windows_phone_simulator/app_registry.dart';
import 'package:windows_phone_simulator/start_menu.dart';

/// 自驱动的 Phone 磁贴：内部维护角标数字，可通过 [PhoneLiveTileState.increment] 手动 +1。
/// 每个磁贴实例持有自己的角标状态，互不干扰。
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
  State<PhoneLiveTile> createState() => PhoneLiveTileState();
}

class PhoneLiveTileState extends State<PhoneLiveTile> {
  /// 当前角标数字
  int _number = 0;

  /// 磁贴内容（SVG 图标 + 角标数字）
  late final ValueNotifier<Widget> _content;

  @override
  void initState() {
    super.initState();
    _content = ValueNotifier<Widget>(_buildBadge(_number));
  }

  /// 外部调用：角标 +1
  void increment() {
    if (!mounted) return;
    setState(() {
      _number += 1;
    });
    _content.value = _buildBadge(_number);
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

  /// 指向桌面上的 Phone 磁贴（如果有），用于点击按钮时让它 +1。
  /// 静态：注册的磁贴在 register() 静态方法中构建，且由 StartMenu 渲染，
  /// 因此必须用静态 key 才能从页面按钮里访问到。
  static final GlobalKey<PhoneLiveTileState> tileKey =
      GlobalKey<PhoneLiveTileState>();

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
        key: PhoneApp.tileKey,
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
        top: Text('FLUMETRO'),
        bottom: Text('about'),
      ),
      body: Builder(
        // 使用 Builder 来获取正确的 context
        builder: (scaffoldContext) {
          return Column(
            children: <Widget>[
              const SizedBox(height: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 19.0),
                  child: SingleChildScrollView(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '''hello world''',
                            style: TextStyle(fontSize: 20),
                          ),
                        ]),
                  ),
                ),
              ),
              // 按钮：点击后桌面上的 Phone 磁贴角标 +1
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: FilledButton(
                  onPressed: () {
                    PhoneApp.tileKey.currentState?.increment();
                  },
                  child: const Text('磁贴角标 +1'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
