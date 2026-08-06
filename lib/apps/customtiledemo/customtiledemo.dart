import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:metro_ui/page_scaffold.dart';
import 'package:metro_ui/widgets/stack_panel.dart';
import 'package:windows_phone_simulator/app_registry.dart';
import 'package:windows_phone_simulator/start_menu.dart';

/// 自驱动的 Phone 磁贴：不关心外界的创建/销毁，
/// 挂载后即按时间轴自由切换磁贴内容（文字、图片、动画、组合……），
/// 卸载时自动停止。内容更新完全由 [ValueListenableBuilder] 驱动，不受任何限制。
class CustomTileDemo extends StatefulWidget {
  final LiveTileSize size;
  final Widget? name;
  final double iconHeight;

  const CustomTileDemo({
    super.key,
    required this.size,
    this.name,
    this.iconHeight = 72,
  });

  @override
  State<CustomTileDemo> createState() => _CustomTileDemoState();
}

class _CustomTileDemoState extends State<CustomTileDemo> {
  /// 磁贴内容：可以是任意 Widget（文字、图片、动画、组合……）
  /// 任何地方改动 `.value`，磁贴立即重建显示新内容。
  late final ValueNotifier<Widget> _content;

  @override
  void initState() {
    super.initState();
    _content = ValueNotifier<Widget>(
      Center(child: CustomTileDemoApp.appIcon(widget.iconHeight)),
    );
    _playContentSequence();
  }

  /// 演示时间轴（循环播放，花里胡哨版）：
  /// 彩虹背景+光晕文字 → 脉冲弹跳 → 自转变色 → 渐变组合 → 轨道环绕 → 还原，然后从头循环。
  /// 每步之后检查 mounted，组件卸载时循环自动结束。
  Future<void> _playContentSequence() async {
    while (mounted) {
      // 等 2 秒才开始变化
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      // 1. 彩虹流动背景 + 色相流动的 NEW!（带光晕）
      _content.value = const _RainbowBackdrop(
        child: _HueText('NEW!'),
      );

      // 0.6s 后：脉冲弹跳 + 变色图标
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      _content.value = const _PulsingIcon();

      // 0.6s 后：自转 + 变色图标
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      _content.value = const _SpinningIcon();

      // 1s 后：渐变组合（呼吸图标 + 变色文字）
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      _content.value = const _ComboContent();

      // 1.5s 后：双图标轨道环绕
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      _content.value = const _OrbitingIcons();

      // 1.5s 后：还原静态图标，进入下一轮循环
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      _content.value = Center(
        child: CustomTileDemoApp.appIcon(widget.iconHeight),
      );
    }
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
            // 每次内容切换：弹性缩放 + 淡入淡出过渡
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              // 用 StackFit.expand 保证子组件占满整个画布
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: animation.drive(Tween(begin: 0.5, end: 1.0)),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(content.runtimeType),
                child: content,
              ),
            ),
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
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final hue = _controller.value * 360;
          return RotationTransition(
            turns: _controller,
            child: Icon(
              Icons.addchart,
              size: 56,
              color: HSLColor.fromAHSL(1, hue, 1, 0.6).toColor(),
            ),
          );
        },
      ),
    );
  }
}

/// 彩虹流动渐变背景（占满整个画布）
class _RainbowBackdrop extends StatefulWidget {
  final Widget child;
  const _RainbowBackdrop({required this.child});

  @override
  State<_RainbowBackdrop> createState() => _RainbowBackdropState();
}

class _RainbowBackdropState extends State<_RainbowBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final h1 = _controller.value * 360;
        final h2 = (h1 + 120) % 360;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                HSLColor.fromAHSL(1, h1, 1, 0.5).toColor(),
                HSLColor.fromAHSL(1, h2, 1, 0.45).toColor(),
              ],
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// 色相流动 + 光晕的文字
class _HueText extends StatefulWidget {
  final String text;
  const _HueText(this.text);

  @override
  State<_HueText> createState() => _HueTextState();
}

class _HueTextState extends State<_HueText>
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
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final color =
              HSLColor.fromAHSL(1, _controller.value * 360, 1, 0.65).toColor();
          return Text(
            widget.text,
            style: TextStyle(
              color: color,
              fontSize: 40,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(color: color, blurRadius: 24),
                Shadow(color: Colors.white54, blurRadius: 6),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 脉冲弹跳 + 变色图标
class _PulsingIcon extends StatefulWidget {
  const _PulsingIcon();

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final scale = 0.7 + _controller.value * 0.45;
          final hue = _controller.value * 360;
          return Transform.scale(
            scale: scale,
            child: Icon(
              Icons.bolt,
              size: 56,
              color: HSLColor.fromAHSL(1, hue, 1, 0.6).toColor(),
            ),
          );
        },
      ),
    );
  }
}

/// 组合：径向渐变背景 + 呼吸缩放图标 + 变色文字
class _ComboContent extends StatefulWidget {
  const _ComboContent();

  @override
  State<_ComboContent> createState() => _ComboContentState();
}

class _ComboContentState extends State<_ComboContent>
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final hue = _controller.value * 360;
        final hue2 = (hue + 180) % 360;
        final breathe = 1 + 0.1 * math.sin(_controller.value * 2 * math.pi * 2);
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                HSLColor.fromAHSL(1, hue, 1, 0.45).toColor(),
                HSLColor.fromAHSL(1, hue2, 1, 0.2).toColor(),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: breathe,
                child: const Icon(
                  Icons.addchart,
                  size: 44,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'New!',
                style: TextStyle(
                  color:
                      HSLColor.fromAHSL(1, (hue + 90) % 360, 1, 0.7).toColor(),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 双图标轨道环绕 + 中心呼吸
class _OrbitingIcons extends StatefulWidget {
  const _OrbitingIcons();

  @override
  State<_OrbitingIcons> createState() => _OrbitingIconsState();
}

class _OrbitingIconsState extends State<_OrbitingIcons>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final angle = _controller.value * 2 * math.pi;
          final radius = 26.0;
          final hueA = (_controller.value * 720) % 360;
          final hueB = (hueA + 180) % 360;
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: 1 + 0.08 * math.sin(angle * 2),
                child: const Icon(
                  Icons.addchart,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              Transform.translate(
                offset: Offset(
                  math.cos(angle) * radius,
                  math.sin(angle) * radius,
                ),
                child: Icon(
                  Icons.star,
                  size: 20,
                  color: HSLColor.fromAHSL(1, hueA, 1, 0.65).toColor(),
                ),
              ),
              Transform.translate(
                offset: Offset(
                  math.cos(angle + math.pi) * radius,
                  math.sin(angle + math.pi) * radius,
                ),
                child: Icon(
                  Icons.favorite,
                  size: 16,
                  color: HSLColor.fromAHSL(1, hueB, 1, 0.65).toColor(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CustomTileDemoApp extends StatefulWidget {
  const CustomTileDemoApp({super.key});

  // ─── 图标模板 ─────────────────────────────────
  // 以“高度”为基准等比缩放：传目标高度即可，宽度按 SVG 宽高比自动计算。
  // 不要包 FittedBox —— LiveTile 外层已有画布 FittedBox 做等比缩放，
  // 嵌套 FittedBox 在紧约束下会退化失效（上一轮已验证）。
  static Widget appIcon(double height) {
    return Icon(
      Icons.addchart,
      size: height,
      color: Colors.white,
    );
  }

  static void register() {
    AppRegistry().register(App(
      id: 'com.demo.customtiledemo',
      name: 'Custom Tile Demo',
      //themeColor: Colors.purple,
      icon: appIcon(32), // 应用列表图标
      page: const CustomTileDemoApp(),
      smallTile: const CustomTileDemo(
        size: LiveTileSize.small,
        iconHeight: 36, // 小磁贴：画布 79.5px，占比约 45%
      ),
      mediumTile: const CustomTileDemo(
        size: LiveTileSize.medium,
        name: Text('Custom Tile Demo'),
        iconHeight: 72, // 中磁贴：画布 168px，占比约 43%
      ),
    ));
  }

  @override
  State<CustomTileDemoApp> createState() => _CustomTileDemoAppState();
}

class _CustomTileDemoAppState extends State<CustomTileDemoApp> {
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
