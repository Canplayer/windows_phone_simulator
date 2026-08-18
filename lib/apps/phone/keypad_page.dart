import 'package:flutter/material.dart';
import 'package:metro_ui/application_bar.dart';
import 'package:metro_ui/page_scaffold.dart';
import 'package:metro_ui/widgets/button.dart';
import 'package:metro_ui/widgets/metro_circle_button.dart';
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

  /// 已输入的号码（由键盘输入，显示在顶部号码框）。
  String _number = '';

  /// 是否处于“正在呼叫”状态：点 call 后置 true，号码框显示 calling 提示；
  /// 再次输入/删除时自动恢复为编辑态。
  bool _isCalling = false;

  @override
  void initState() {
    super.initState();
    _riseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
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

  /// 拨号键输入：把按键主字符追加到号码末尾，并退出 calling 态。
  void _onKeyInput(String ch) {
    setState(() {
      _isCalling = false;
      _number += ch;
    });
  }

  /// 删除最后一个字符；号码为空时不操作，并退出 calling 态。
  void _onDelete() {
    if (_number.isEmpty) return;
    setState(() {
      _isCalling = false;
      _number = _number.substring(0, _number.length - 1);
    });
  }

  /// 点击 call：先播上浮动画，号码非空时进入“正在呼叫”状态。
  Future<void> _onCallPressed() async {
    await _playRiseAnimation();
    if (!mounted) return;
    if (_number.isEmpty) return;
    setState(() {
      _isCalling = true;
    });
  }

  /// 美式号码智能格式化：边输入边把纯数字拼成用户习惯的
  /// (XXX) XXX-XXXX 形式（括号区号 + 空格 + 连字符）。
  ///
  /// 规则：
  /// - 1-3 位：原样显示；
  /// - 4-6 位：(XXX) XXX（开始补区号括号）；
  /// - 7-10 位：(XXX) XXX-XXXX（第 7 位起补连字符）；
  /// - 11 位且首位为 1：1 (XXX) XXX-XXXX（北美长途前缀）；
  /// - 以 + 开头：格式前加 + 前缀（国际格式）；
  /// - 含 * 或 #（如 USSD 码 *100#）或无法识别时原样返回。
  String _formatNumber(String raw) {
    if (raw.isEmpty) return raw;
    // * 与 # 是电话功能码，不做格式化
    if (raw.contains('*') || raw.contains('#')) return raw;

    final bool plus = raw.startsWith('+');
    final String digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return raw;

    final int n = digits.length;
    final String body;
    if (n <= 3) {
      body = digits;
    } else if (n <= 6) {
      body = '(${digits.substring(0, 3)}) ${digits.substring(3)}';
    } else if (n <= 10) {
      body =
          '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    } else if (n == 11 && digits.startsWith('1')) {
      body =
          '1 (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7)}';
    } else if (n == 11) {
      body =
          '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6, 10)} ${digits.substring(10)}';
    } else {
      // 超过 11 位：前 10 位按标准格式，剩余数字追加在后
      final rest = digits.substring(10);
      body =
          '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6, 10)} $rest';
    }
    return plus ? '+$body' : body;
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
                      onTap: (){},
                      child: const Text("call", textAlign: TextAlign.center),
                    ),
                  ),
                  const SizedBox(
                    width: 19,
                  ),
                  Expanded(
                    child: MetroButton(
                      margin: EdgeInsets.zero,
                      onTap: (){},
                      child: const Text("save", textAlign: TextAlign.center),
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
            // 顶部号码显示区：大号白色号码右对齐 + 右侧删除键
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 6, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // calling 状态提示：点 call 后显示在号码上方
                          if (_isCalling)
                            Text(
                              'calling…',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                            ),
                          // 智能格式化后的号码：自动补括号/空格/连字符，
                          // 过长时 FittedBox 自动缩小适配，不截断
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _formatNumber(_number),
                              maxLines: 1,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 删除键：号码为空时禁用（半透明）
                    MetroCircleButton(
                      size: 44,
                      iconSize: 24,
                      icon: const Icon(
                        Icons.backspace_outlined,
                        color: Colors.white,
                      ),
                      onPressed: _number.isEmpty ? null : _onDelete,
                    ),
                  ],
                ),
              ),
            ),
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
                                  onPressed: () => _onKeyInput(key.main),
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
    this.onPressed,
  });

  final String main;
  final String? sub;
  final bool centered;

  /// 按下时的背景色；为 null 时使用主题色（ColorScheme.primary）。
  final Color? pressedColor;

  /// 亮起状态下抬起手指时触发，用于把按键字符输入号码。
  final VoidCallback? onPressed;

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
        onPressed: onPressed,
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
