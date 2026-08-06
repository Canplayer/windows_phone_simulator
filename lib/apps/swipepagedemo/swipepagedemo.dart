import 'package:flutter/material.dart';
import 'package:metro_ui/page_scaffold.dart';
import 'package:metro_ui/widgets/stack_panel.dart';
import 'package:metro_ui/widgets/swipe_title_indicator.dart';
import 'package:windows_phone_simulator/app_registry.dart';
import 'package:windows_phone_simulator/start_menu.dart';

/// SwipePages 使用示例。
///
/// [SwipePages] = 标题指示器（[SwipePageIndicator]）+ [SwipePageView] 的组合组件，
/// 二者自动同步：
/// - 顶部标题条随拖动进度平移，松手换页时新标题从反方向减速滑入；
/// - 无限滚动：5 个页面循环，index 可为任意整数；
/// - [onPageChanged] 在松手触发换页的瞬间回调 (旧页, 新页)；
/// - [onTransitionEnd] 在换页动画播放完毕后回调；
/// - [onSlideProgress] 实时上报归一化滑动进度（-1 ~ 1）。
class SwipePageDemoApp extends StatefulWidget {
  const SwipePageDemoApp({super.key});

  /// 注册到开始菜单
  static void register() {
    AppRegistry().register(App(
      id: 'com.demo.swipepage',
      name: 'Swipe Page',
      themeColor: Colors.teal,
      icon: const Icon(Icons.swipe),
      page: const SwipePageDemoApp(),
      smallTile: const LiveTile(
        size: LiveTileSize.small,
        flipStyle: FlipStyle.elastic,
        children: [
          MetroAppTile(
            icon: Icon(Icons.swipe, color: Colors.white, size: 26),
          ),
        ],
      ),
      mediumTile: const LiveTile(
        size: LiveTileSize.medium,
        flipStyle: FlipStyle.elastic,
        name: Text('Swipe Page'),
        children: [
          MetroAppTile(
            icon: Icon(Icons.swipe, color: Colors.white, size: 60),
            count: 3,
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Text(
              '左右滑动无限翻页 Demo',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    ));
  }

  @override
  State<SwipePageDemoApp> createState() => _SwipePageDemoAppState();
}

class _SwipePageDemoAppState extends State<SwipePageDemoApp> {
  /// 当前页码（初始 0，可为负数）。
  int _page = 0;

  /// 实时归一化滑动距离（-1 ~ 1）。
  double _distance = 0;

  /// 上一次换页的 from → to（仅展示用）。
  String _lastSwap = '—';

  /// 换页回调：松手触发换页的瞬间回调 (旧页, 新页)。
  void _onPageChanged(int oldIndex, int newIndex) {
    setState(() {
      _lastSwap = '$oldIndex → $newIndex';
      _page = newIndex;
    });
  }

  /// 换页动画结束回调：动画播放完毕后回调 (旧页, 新页)。
  void _onTransitionEnd(int oldIndex, int newIndex) {
    setState(() => _page = newIndex);
  }

  /// 滑动进度回调：拖动/动画过程中持续回调 -1.0 ~ 1.0，结束归零。
  void _onSlideProgress(double progress) {
    setState(() => _distance = progress);
  }


  @override
  Widget build(BuildContext context) {
    return MetroPageScaffold(
      stackPanel: StackPanel(
        top: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Swipe Page Demo'),
            Text('当前页 $_page'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── 状态栏：实时显示滑动状态 ──────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatusChip(label: '当前页', value: '$_page'),
                _StatusChip(
                  label: '滑动距离',
                  value: _distance.toStringAsFixed(2),
                ),
                _StatusChip(label: '上次换页', value: _lastSwap),
              ],
            ),
          ),

          // ── 滑动翻页区：标题指示器 + 滑动翻页组合 ──────────────
          Expanded(
            child: SwipePages(
              items: [
                for (var i = 0; i < _pageTitles.length; i++)
                  SwipePageItem(
                    title: Text(
                      _pageTitles[i],
                    ),
                    page: _buildPage(i),
                  ),
              ],
              // 演示参数透传：这些参数会传递给内部的 SwipePageView
              flyDuration: const Duration(milliseconds: 300),
              fadeDuration: const Duration(milliseconds: 120),
              snapBackDuration: const Duration(milliseconds: 150),
              onPageChanged: _onPageChanged,
              onTransitionEnd: _onTransitionEnd,
              onSlideProgress: _onSlideProgress,
            ),
          ),
        ],
      ),
    );
  }

  /// 页面标题（与 5 种渐变配色一一对应）。
  static const _pageTitles = ['applications', 'system', 'orange', 'zise', 'Red'];

  /// 页面内容：5 个渐变卡片，index 0~4，取模循环。
  Widget _buildPage(int index) {
    // 一组渐变配色，按 index 取模轮换
    const gradients = <List<Color>>[
      [Color(0xFF0078D7), Color(0xFF005A9E)], // 蓝
      [Color(0xFF00A300), Color(0xFF007A00)], // 绿
      [Color(0xFFFF8C00), Color(0xFFCC6600)], // 橙
      [Color(0xFFB4009E), Color(0xFF8A0078)], // 紫
      [Color(0xFFE81123), Color(0xFFB00000)], // 红
    ];
    final colors = gradients[index % gradients.length];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 大页码（1 起，更直观）
            Text(
              '${index + 1}',
            ),
            const SizedBox(height: 12),
            // 颜色名
            Text(
              _pageTitles[index % _pageTitles.length],
            ),
            const SizedBox(height: 6),
            Text(
              '左右滑动无限翻页',
              style: const TextStyle(fontSize: 14, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}

/// 状态栏里的小徽标：标签 + 数值。
class _StatusChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatusChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white54),
        ),
        const SizedBox(height: 4),
        Text(
          value,

        ),
      ],
    );
  }
}
