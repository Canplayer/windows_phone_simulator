import 'package:flutter/material.dart';
import 'package:metro_ui/application_bar.dart';
import 'package:metro_ui/page_scaffold.dart';
import 'package:metro_ui/widgets/button.dart';
import 'package:metro_ui/widgets/tile.dart';

/// 拨号键盘页面（纯静态、不可交互）。
class KeypadPage extends StatelessWidget {
  const KeypadPage({super.key, this.dialPressedColor});

  /// 拨号键按下时的背景色；为 null 时使用主题色（ColorScheme.primary）。
  final Color? dialPressedColor;

  @override
  Widget build(BuildContext context) {
    return MetroPageScaffold(
      backgroundColor: Colors.grey[900],
      applicationBar: MetroApplicationBar(
        backgroundColor: Colors.grey[900],
        buttons: [
          const SizedBox(
            width: 345,
            height: 38.5,
            child: Row(
              children: [
                Expanded(
                  child: MetroButton(
                    margin: EdgeInsets.zero,
                    child: Text("call", textAlign: TextAlign.center),
                  ),
                ),
                SizedBox(
                  width: 19,
                ),
                Expanded(
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
          // 拨号键盘：固定 300 高度、灰色背景、固定在屏幕底部，
          // 数字偏左、T9 字母偏右，* 和 # 居中
          Positioned(
            left: 0,
            right: 0,
            bottom: 72 * 0.8,
            height: 362.5,
            child: Container(
              color: Colors.grey[850],
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
                                pressedColor: dialPressedColor,
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
