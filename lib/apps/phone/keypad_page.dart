import 'package:flutter/material.dart';
import 'package:metro_ui/application_bar.dart';
import 'package:metro_ui/page_scaffold.dart';
import 'package:metro_ui/widgets/button.dart';
import 'package:metro_ui/widgets/tile.dart';

/// 拨号键盘页面。
/// 以减速曲线（easeOut）上浮归位。
class KeypadPage extends StatefulWidget {
  const KeypadPage({super.key, this.dialPressedColor});

  /// 拨号键按下时的背景色；为 null 时使用主题色（ColorScheme.primary）。
  final Color? dialPressedColor;

  @override
  State<KeypadPage> createState() => _KeypadPageState();
}

class _KeypadPageState extends State<KeypadPage>
    with SingleTickerProviderStateMixin {
  /// 上浮动画控制器：0 → 页面位于下方 400px，1 → 归位。
  late final AnimationController _riseController;

  /// 页面整体的竖直位移（px）。
  late final Animation<double> _riseOffset;

  @override
  void initState() {
    super.initState();
    _riseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    // 减速动画曲线（easeOutCubic）应用在位移插值上
    _riseOffset = Tween<double>(begin: 400, end: 0)
        .chain(CurveTween(curve: Curves.easeOutCubic))
        .animate(_riseController);
  }

  @override
  void dispose() {
    _riseController.dispose();
    super.dispose();
  }

  /// 点击 call：整个页面从下方 400px 减速上浮归位。
  /// await 在动画播放结束后返回。
  Future<void> _playRiseAnimation() async {
    try {
      // orCancel：页面在动画中途被销毁（强制退出）时避免 TickerCanceled 异常
      await _riseController.forward(from: 0).orCancel;
    } on TickerCanceled {
      // 动画被取消，忽略即可
    }
  }

  /// 反向动画：页面从归位位置（顶部）减速下滑 400px，await 播放完成。
  ///
  /// 供 [MetroPageScaffold.onWillPop] 使用：先播放下滑动画再退出页面。
  Future<void> _playReverseAnimation() async {
    // 若动画未处于归位状态（未播放完/未开始），先直接跳到归位位置，
    // 保证反向动画总是从顶部完整下滑 400px。
    if (_riseController.value != 1.0) {
      _riseController.value = 1.0;
    }
    try {
      // 从 1 → 0：offset 0 → 400，页面整体下滑；
      // orCancel：页面在动画中途被销毁（强制退出）时避免 TickerCanceled 异常
      await _riseController.reverse().orCancel;
    } on TickerCanceled {
      // 动画被取消，忽略即可
    }
  }

  @override
  Widget build(BuildContext context) {
    // 动画作用在 MetroPageScaffold 外层，整个页面（含 Application Bar）一起上浮
    return AnimatedBuilder(
      animation: _riseOffset,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _riseOffset.value),
          child: child,
        );
      },
      child: MetroPageScaffold(
        extendBodyToApplicationBar: false,
        onDidPop: () async {
          await _playReverseAnimation();
        },
        onDidPush: () async {
          await _playRiseAnimation();
        },
        applicationBar: MetroApplicationBar(
          buttons: [
            SizedBox(
              width: 345,
              height: 38.5,
              child: Row(
                children: [
                  Expanded(
                    child: MetroButton(
                      margin: EdgeInsets.zero,
                      onTap: _playRiseAnimation,
                      child: const Text("call", textAlign: TextAlign.center),
                    ),
                  ),
                  const SizedBox(
                    width: 19,
                  ),
                  const Expanded(
                    child: MetroButton(
                      margin: EdgeInsets.zero,
                      child: Text("save", textAlign: TextAlign.center),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            // 背景参考图：对照还原界面布局用，调整完可删
            // Positioned.fill(
            //   child: Opacity(
            //     opacity: 0.25,
            //     child: Image.asset(
            //       'images/reference/phone_history_ref.png',
            //       fit: BoxFit.fitWidth,
            //       alignment: AlignmentGeometry.bottomStart,
            //     ),
            //   ),
            // ),
            // 拨号键盘：固定高度、灰色背景、固定在屏幕底部安全区之上，
            // 数字偏左、T9 字母偏右，* 和 # 居中
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 362.5,
              child: Container(
                color: Theme.of(context).colorScheme.surfaceContainer,
                padding: const EdgeInsets.only(top: 2.5),
                child: Column(
                  children: [
                    for (final row in _keyRows)
                      Expanded(
                        child: Row(
                          children: [
                            for (final key in row) ...[
                              //if (key != row.first) const SizedBox(width: 10),
                              Expanded(
                                child: _DialKey(
                                  main: key.main,
                                  sub: key.sub,
                                  centered: key.centered,
                                  pressedColor: widget.dialPressedColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 单个拨号键的配置。
class _KeyData {
  const _KeyData(this.main, {this.sub, this.centered = false});

  final String main;
  final String? sub;
  final bool centered;
}

/// 键盘布局：1-9 按 T9 排列，最后一行 * 0 #。
/// 数字键：数字偏左、T9 字母偏右；* 与 # 居中。
const List<List<_KeyData>> _keyRows = [
  [_KeyData('1'), _KeyData('2', sub: 'ABC'), _KeyData('3', sub: 'DEF')],
  [
    _KeyData('4', sub: 'GHI'),
    _KeyData('5', sub: 'JKL'),
    _KeyData('6', sub: 'MNO'),
  ],
  [
    _KeyData('7', sub: 'PQRS'),
    _KeyData('8', sub: 'TUV'),
    _KeyData('9', sub: 'WXYZ'),
  ],
  [
    _KeyData('*', centered: true),
    _KeyData('0', sub: '+'),
    _KeyData('#', centered: true),
  ],
];

/// 单个方形拨号键（纯静态）：数字偏左、T9 字母偏右；* 与 # 居中。
/// 尺寸由外层 Expanded 撑满，内容自动缩放避免溢出。
class _DialKey extends StatelessWidget {
  const _DialKey({
    required this.main,
    this.sub,
    this.centered = false,
    this.pressedColor,
  });

  final String main;
  final String? sub;
  final bool centered;

  /// 按下时的背景色；为 null 时使用主题色（ColorScheme.primary）。
  final Color? pressedColor;

  @override
  Widget build(BuildContext context) {
    const TextStyle mainStyle = TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w300,
      color: Colors.white,
    );

    final Widget content = centered
        ? Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(main, style: mainStyle),
            ),
          )
        : Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(main, style: mainStyle),
                ),
              ),
              const Spacer(),
              if (sub != null && sub!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      sub!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ),
                ),
            ],
          );

    return Tile(
      child: MetroPressDetector(
        child: Builder(
          builder: (context) {
            // 按下时（手指停留）背景变为主题色，抬起后恢复灰色
            final bool isPressed = MetroPressScope.maybeOf(context) ?? false;
            return Container(
              color: isPressed
                  ? (pressedColor ?? Theme.of(context).colorScheme.primary)
                  : Colors.grey[800],
              margin: const EdgeInsets.all(2.5),
              alignment: Alignment.center,
              child: content,
            );
          },
        ),
      ),
    );
  }
}
