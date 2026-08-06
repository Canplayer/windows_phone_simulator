import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:metro_ui/page_scaffold.dart';
import 'package:metro_ui/widgets/stack_panel.dart';
import 'package:windows_phone_simulator/app_registry.dart';
import 'package:windows_phone_simulator/start_menu.dart';

/// 自驱动的 Phone 磁贴：不关心外界的创建/销毁，
/// 挂载后即按时间轴自由切换磁贴内容（文字、图片、动画、组合……），
/// 卸载时自动停止。内容更新完全由 [ValueListenableBuilder] 驱动，不受任何限制。
class LivePhotoDemoLiveTile extends StatefulWidget {
  final LiveTileSize size;
  final Widget? name;
  final double iconHeight;

  const LivePhotoDemoLiveTile({
    super.key,
    required this.size,
    this.name,
    this.iconHeight = 72,
  });

  @override
  State<LivePhotoDemoLiveTile> createState() => _LivePhotoDemoLiveTileState();
}

class _LivePhotoDemoLiveTileState extends State<LivePhotoDemoLiveTile> {
  /// 磁贴内容：可以是任意 Widget（文字、图片、动画、组合……）
  /// 任何地方改动 `.value`，磁贴立即重建显示新内容。
  late final ValueNotifier<Widget> _content;

  @override
  void initState() {
    super.initState();
    _content = ValueNotifier<Widget>(LivePhotoDemoApp.appIcon(widget.iconHeight));
    _playContentSequence();
  }

  /// 演示时间轴：等 2s → 文字 →(0.5s)→ 图片 →(0.5s)→ 动画 →(等 1s)→ 组合 →(等 2s)→ 还原。
  /// 每步之后检查 mounted，组件卸载时后续步骤自动作废。
  Future<void> _playContentSequence() async {
    // 等 2 秒才开始变化
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    _content.value = const Center(
      child: Text(
        'NEW!',
        style: TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    // 0.5s 后：换成图片（SVG 图标）
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _content.value = LivePhotoDemoApp.appIcon(widget.iconHeight);

    // 0.5s 后：换成动画（自转图标）
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _content.value = const _SpinningIcon();

    // 等 1s：换成组合内容（图标 + 文字）
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    _content.value = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        LivePhotoDemoApp.appIcon(widget.iconHeight * 0.7),
        const SizedBox(height: 8),
        const Text(
          'Phone',
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ],
    );

    // 再等 2s：还原为静态图标，结束
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    _content.value = LivePhotoDemoApp.appIcon(widget.iconHeight);
  }

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Widget>(
      valueListenable: _content,
      builder: (context, content, _) {
        return LiveTile(
          size: widget.size,
          flipStyle: FlipStyle.elastic,
          name: widget.name,
          children: [
            MetroAppTile(icon: content),
          ],
        );
      },
    );
  }
}

/// 演示用：一个自转的图标动画 Widget
class _SpinningIcon extends StatefulWidget {
  const _SpinningIcon();

  @override
  State<_SpinningIcon> createState() => _SpinningIconState();
}

class _SpinningIconState extends State<_SpinningIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: LivePhotoDemoApp.appIcon(64),
    );
  }
}

class LivePhotoDemoApp extends StatefulWidget {
  const LivePhotoDemoApp({super.key});

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
      id: 'com.canplayer.livephotodemo',
      name: 'Live Photo Demo',
      //themeColor: Colors.purple,
      icon: appIcon(32), // 应用列表图标
      page: const LivePhotoDemoApp(),
      smallTile: LivePhotoDemoLiveTile(
        size: LiveTileSize.small,
        iconHeight: 36, // 小磁贴：画布 79.5px，占比约 45%
      ),
      mediumTile: LivePhotoDemoLiveTile(
        size: LiveTileSize.medium,
        name: const Text('Live Photo Demo'),
        iconHeight: 72, // 中磁贴：画布 168px，占比约 43%
      ),
    ));
  }

  @override
  State<LivePhotoDemoApp> createState() => _LivePhotoDemoAppState();
}

class _LivePhotoDemoAppState extends State<LivePhotoDemoApp> {
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
          return const Column(
            children: <Widget>[
              SizedBox(height: 20),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 19.0),
                  child: SingleChildScrollView(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '''hello world''',
                            style: TextStyle(fontSize: 20),
                          ),
                        ]),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
